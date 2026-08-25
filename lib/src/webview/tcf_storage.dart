import 'dart:convert';

import 'package:axeptio_sdk/src/preferences/native_default_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TcfStorage {
  final SharedPreferences _prefs;

  TcfStorage(this._prefs);

  static Future<TcfStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TcfStorage(prefs);
  }

  String? get tcString => _prefs.getString('IABTCF_TCString');

  String? get axeptioToken =>
      _prefs.getString('AX_CLIENT_TOKEN') ?? _prefs.getString('_ax_token');

  Future<void> writeIabTcfFields(Map<String, dynamic>? fields) async {
    if (fields == null) return;
    for (final entry in fields.entries) {
      await _writeValue(entry.key, entry.value);
    }
  }

  Future<void> writeConsentSaved(Map<String, dynamic>? payload) async {
    if (payload == null) return;
    final token = payload['axeptio_token']?.toString() ??
        _tokenFromCookies(payload['axeptio_cookies']);
    if (token != null && token.isNotEmpty) {
      await _prefs.setString('AX_CLIENT_TOKEN', token);
      await _prefs.remove('_ax_token');
    }
    if (payload['axeptio_cookies'] != null) {
      await _prefs.setString(
          'axeptio_cookies', payload['axeptio_cookies'].toString());
    }
    if (payload['axeptio_all_vendors'] != null) {
      await _prefs.setString(
          'axeptio_all_vendors', payload['axeptio_all_vendors'].toString());
    }
    if (payload['axeptio_authorized_vendors'] != null) {
      await _prefs.setString('axeptio_authorized_vendors',
          payload['axeptio_authorized_vendors'].toString());
    }
  }

  /// Reads the token the brands widget nests in its cookies payload as
  /// `$$token` instead of sending it as a top level `axeptio_token`.
  String? _tokenFromCookies(dynamic cookies) {
    if (cookies == null) return null;
    if (cookies is Map) return cookies[r'$$token']?.toString();
    try {
      final decoded = jsonDecode(cookies.toString());
      if (decoded is Map) return decoded[r'$$token']?.toString();
    } on FormatException {
      // Not a JSON payload, so there is no token to recover from it.
    }
    return null;
  }

  Future<void> writeCookies(Map<String, dynamic>? payload) async {
    if (payload == null) return;
    for (final entry in payload.entries) {
      await _writeValue(entry.key, entry.value);
    }
  }

  Future<void> writeScope(Map<String, dynamic>? payload) async {
    if (payload == null) return;
    final scope = payload['scope'];
    if (scope != null) {
      await _prefs.setString('widget_scope', scope.toString());
    }
  }

  Future<void> clearAll() async {
    final keys = [
      ...NativeDefaultPreferences.allKeys,
      '_ax_token',
      'widget_scope',
      'vendor_consent_summary',
    ];
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  Map<String, dynamic> getAllData() {
    final result = <String, dynamic>{};
    final keys = [
      ...NativeDefaultPreferences.allKeys,
      '_ax_token',
      'widget_scope',
    ];
    for (final key in keys) {
      final value = _prefs.get(key);
      if (value != null) result[key] = value;
    }
    return result;
  }

  Map<int, bool> getVendorConsents() {
    final bitString = _prefs.getString('IABTCF_VendorConsents') ?? '';
    final result = <int, bool>{};
    for (int i = 0; i < bitString.length; i++) {
      result[i + 1] = bitString[i] == '1';
    }
    return result;
  }

  Future<void> _writeValue(String key, dynamic value) async {
    if (value == null) return;
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else {
      await _prefs.setString(key, value.toString());
    }
  }
}
