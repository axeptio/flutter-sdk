import 'package:axeptio_sdk/src/channel/axeptio_sdk_platform_interface.dart';
import 'package:axeptio_sdk/src/events/event_listener.dart';
import 'package:axeptio_sdk/src/events/events_handler.dart';
import 'package:axeptio_sdk/src/model/model.dart';
import 'package:axeptio_sdk/src/webview/axeptio_consent_view.dart';
import 'package:axeptio_sdk/src/webview/consent_url_builder.dart';
import 'package:axeptio_sdk/src/webview/tcf_storage.dart';
import 'package:flutter/material.dart';

class WebViewAxeptioSdk extends AxeptioSdkPlatform {
  static GlobalKey<NavigatorState>? navigatorKey;

  String? _clientId;
  String? _cookiesVersion;
  AxeptioService? _targetService;
  String? _token;
  bool _attDenied = false;
  TcfStorage? _storage;

  late final EventsHandler _eventsHandler;

  WebViewAxeptioSdk() : super() {
    _eventsHandler = EventsHandler();
  }

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
    _storage = await TcfStorage.create();
  }

  @override
  Future<void> setupUI() async {
    final storage = _storage;
    if (storage == null) return;
    if (storage.tcString == null || storage.tcString!.isEmpty) {
      await showConsentScreen();
    }
  }

  @override
  Future<void> setUserDeniedTracking() async {
    _attDenied = true;
  }

  @override
  Future<void> showConsentScreen() async {
    final key = navigatorKey;
    if (key == null || key.currentState == null) return;

    final clientId = _clientId;
    final cookiesVersion = _cookiesVersion;
    final service = _targetService;
    if (clientId == null || cookiesVersion == null || service == null) return;

    final url = ConsentUrlBuilder.build(
      service: service,
      clientId: clientId,
      cookiesVersion: cookiesVersion,
      token: _storage?.axeptioToken ?? _token,
      showConsentManager: true,
    );

    key.currentState!.push(
      MaterialPageRoute(
        builder: (_) => AxeptioConsentView(
          consentUrl: url,
          attDenied: _attDenied,
          storedTcString: _storage?.tcString,
          showConsentManager: true,
          onJsEvent: (name, payload) => handleJsEvent(name, payload),
          onClose: () => key.currentState?.pop(),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Future<void> clearConsent() async {
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
    final clientId = _clientId;
    final cookiesVersion = _cookiesVersion;
    if (clientId == null || cookiesVersion == null) return url;
    return ConsentUrlBuilder.appendToken(url, clientId, cookiesVersion, token)
            ?.toString() ??
        url;
  }

  @visibleForTesting
  Future<void> handleJsEvent(String name, Map<String, dynamic>? payload) async {
    switch (name) {
      case 'iabtcf':
        await _storage?.writeIabTcfFields(payload);
        break;
      case 'consent:saved':
        await _storage?.writeConsentSaved(payload);
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

  void handleGoogleConsentMode(Map<String, dynamic>? payload) {
    if (payload == null) return;
    final consents = ConsentsV2(
      payload['analytics_storage'] == true,
      payload['ad_storage'] == true,
      payload['ad_user_data'] == true,
      payload['ad_personalization'] == true,
    );
    for (final listener in List.of(_eventsHandler.listeners)) {
      listener.onGoogleConsentModeUpdate(consents);
    }
  }
}
