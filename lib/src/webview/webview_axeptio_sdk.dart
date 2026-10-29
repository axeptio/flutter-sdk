import 'dart:async';
import 'dart:io';

import 'package:axeptio_sdk/src/channel/axeptio_sdk_platform_interface.dart';
import 'package:axeptio_sdk/src/events/event_listener.dart';
import 'package:axeptio_sdk/src/events/events_handler.dart';
import 'package:axeptio_sdk/src/exceptions/axeptio_exceptions.dart';
import 'package:axeptio_sdk/src/model/model.dart';
import 'package:axeptio_sdk/src/network/axeptio_uploader.dart';
import 'package:axeptio_sdk/src/webview/axeptio_consent_view.dart';
import 'package:axeptio_sdk/src/webview/consent_url_builder.dart';
import 'package:axeptio_sdk/src/webview/tcf_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WebViewAxeptioSdk extends AxeptioSdkPlatform {
  static GlobalKey<NavigatorState>? navigatorKey;

  String? _clientId;
  String? _cookiesVersion;
  AxeptioService? _targetService;
  String? _token;
  bool _attDenied = false;
  TcfStorage? _storage;
  AxeptioUploader? _uploader;

  late final EventsHandler _eventsHandler;
  final http.Client _httpClient;

  WebViewAxeptioSdk({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        super() {
    _eventsHandler = EventsHandler();
  }

  @visibleForTesting
  AxeptioUploader? get uploader => _uploader;

  @override
  Future<String?> getPlatformVersion() async => null;

  @override
  Future<String?> get axeptioToken async => _storage?.axeptioToken ?? _token;

  @override
  Future<void> initialize(AxeptioService targetService, String clientId,
      String cookiesVersion, String? token) async {
    _targetService = targetService;
    _clientId = clientId;
    _cookiesVersion = cookiesVersion;
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    _storage = TcfStorage(prefs);
    _uploader?.dispose();
    final uploader = AxeptioUploader(prefs, _httpClient);
    _uploader = uploader;
    unawaited(uploader.start());
  }

  @override
  Future<void> setupUI() async {
    final storage = _storage;
    if (storage == null) {
      throw const AxeptioNotInitializedException(
          'SDK not initialized. Call initialize() before setupUI().');
    }
    if (!_hasStoredConsent(storage)) {
      await showConsentScreen();
    }
  }

  bool _hasStoredConsent(TcfStorage storage) {
    if (_targetService == AxeptioService.brands) {
      final cookies = storage.getAllData()['axeptio_cookies'];
      return cookies != null && cookies.toString().isNotEmpty;
    }
    return storage.tcString?.isNotEmpty ?? false;
  }

  @override
  Future<void> setUserDeniedTracking() async {
    _attDenied = true;
  }

  @override
  Future<void> showConsentScreen() async {
    final clientId = _clientId;
    final cookiesVersion = _cookiesVersion;
    final service = _targetService;
    if (clientId == null || cookiesVersion == null || service == null) {
      throw const AxeptioNotInitializedException();
    }

    final key = navigatorKey;
    if (key == null || key.currentState == null) {
      throw const AxeptioException(
          'navigatorKey is not set or has no active state. '
          'Set AxeptioSdk.navigatorKey before calling showConsentScreen().');
    }

    final url = ConsentUrlBuilder.build(
      service: service,
      clientId: clientId,
      cookiesVersion: cookiesVersion,
      token: _storage?.axeptioToken ?? _token,
      showConsentManager: true,
    );

    await key.currentState!.push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => AxeptioConsentView(
          consentUrl: url,
          attDenied: _attDenied,
          storedTcString: _storage?.tcString,
          showConsentManager: true,
          onJsEvent: (name, payload) => handleJsEvent(name, payload),
          onClose: () => key.currentState?.pop(),
          onError: (error) => _eventsHandler.handleDAxeptioErrorEvent(error),
        ),
      ),
    );
  }

  @override
  Future<void> clearConsent() async {
    await _uploader?.cancelConsentProof();
    await _storage?.clearAll();
    _token = null;
    for (final listener in List.of(_eventsHandler.listeners)) {
      listener.onConsentCleared();
    }
  }

  @override
  Future<Map<String, dynamic>?> getConsentSavedData(
      {String? preferenceKey}) async {
    final storage = _storage;
    if (storage == null) return null;
    final all = storage.getAllData();
    if (preferenceKey != null) {
      final value = all[preferenceKey];
      return value != null ? {preferenceKey: value} : null;
    }
    return all.isNotEmpty ? all : null;
  }

  @override
  Future<Map<String, dynamic>?> getConsentDebugInfo(
      {String? preferenceKey}) async {
    return getConsentSavedData(preferenceKey: preferenceKey);
  }

  @override
  Future<Map<int, bool>> getVendorConsents() async {
    return _storage?.getVendorConsents() ?? {};
  }

  @override
  Future<List<int>> getConsentedVendors() async {
    final consents = await getVendorConsents();
    return consents.entries.where((e) => e.value).map((e) => e.key).toList();
  }

  @override
  Future<List<int>> getRefusedVendors() async {
    final consents = await getVendorConsents();
    return consents.entries.where((e) => !e.value).map((e) => e.key).toList();
  }

  @override
  Future<bool> isVendorConsented(int vendorId) async {
    final consents = await getVendorConsents();
    return consents[vendorId] ?? false;
  }

  @override
  addEventListener(AxeptioEventListener listener) {
    _eventsHandler.addEventListener(listener);
  }

  @override
  removeEventListener(AxeptioEventListener listener) {
    _eventsHandler.removeEventListener(listener);
  }

  @override
  Future<String?> appendAxeptioTokenURL(String url, String token) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final params = Map<String, String>.from(uri.queryParameters);
    params['axeptio_token'] = token;
    return uri.replace(queryParameters: params).toString();
  }

  @visibleForTesting
  Future<void> handleJsEvent(String name, Map<String, dynamic>? payload) async {
    switch (name) {
      case 'iabtcf':
        await _storage?.writeIabTcfFields(payload);
        break;
      case 'consent:saved':
        await _storage?.writeConsentSaved(payload);
        await _uploader?.sendConsentProof(_clientId!, payload);
        break;
      case 'analytics:collect':
        if (_attDenied) break;
        await _uploader?.enqueueEvent(_withSdkSource(payload));
        break;
      case 'axeptio:cookies':
        await _storage?.writeCookies(payload);
        break;
      case 'cookies:complete':
        await _storage?.writeScope(payload);
        break;
      case 'cookies:close':
        for (final listener in List.of(_eventsHandler.listeners)) {
          listener.onPopupClosedEvent();
        }
        break;
      case 'google:consent-mode-v2-update':
        handleGoogleConsentMode(payload);
        break;
    }
  }

  Map<String, dynamic>? _withSdkSource(Map<String, dynamic>? event) {
    final source = event?['source'];
    if (source is! String || !source.startsWith('sdk-app-')) return event;
    final os = Platform.operatingSystem;
    return {...event!, 'source': source.replaceFirst('sdk-app-', 'sdk-$os-')};
  }

    void handleGoogleConsentMode(Map<String, dynamic>? payload) {
    if (payload == null) return;
    final consents = ConsentsV2(
      payload['analytics_storage'] == 'granted',
      payload['ad_storage'] == 'granted',
      payload['ad_user_data'] == 'granted',
      payload['ad_personalization'] == 'granted',
    );
    for (final listener in List.of(_eventsHandler.listeners)) {
      listener.onGoogleConsentModeUpdate(consents);
    }
  }
}
