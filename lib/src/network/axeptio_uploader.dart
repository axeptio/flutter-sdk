import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AxeptioUploader {
  static const String host = 'api.axept.io';
  static const String pendingProofKey = 'axeptio_pending_consent_proof';
  static const String eventQueueKey = 'axeptio_analytics_queue';
  static const int batchSize = 20;
  static const int maxQueuedEvents = 1000;
  static const Duration requestTimeout = Duration(seconds: 30);

  final SharedPreferences _prefs;
  final http.Client _client;
  final Duration proofRetryInterval;
  final Duration flushInterval;

  Timer? _proofTimer;
  Timer? _flushTimer;
  int _proofGeneration = 0;
  bool _flushing = false;

  AxeptioUploader(
    this._prefs,
    this._client, {
    this.proofRetryInterval = const Duration(seconds: 300),
    this.flushInterval = const Duration(seconds: 60),
  });

  bool get hasPendingConsentProof => _prefs.getString(pendingProofKey) != null;

  List<String> get queuedEvents =>
      _prefs.getStringList(eventQueueKey) ?? const [];

  Future<void> start() async {
    if (hasPendingConsentProof) {
      await _uploadProof(++_proofGeneration);
    }
    await flushEvents();
  }

  void dispose() {
    _proofTimer?.cancel();
    _proofTimer = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    _proofGeneration++;
  }

  Future<void> sendConsentProof(
      String clientId, Map<String, dynamic>? payload) async {
    final identifier = _configIdentifier(payload);
    if (identifier == null) return;
    final record = jsonEncode({
      'clientId': clientId,
      'identifier': identifier,
      'payload': payload,
    });
    await _prefs.setString(pendingProofKey, record);
    await _uploadProof(++_proofGeneration);
  }

  Future<void> cancelConsentProof() async {
    _proofGeneration++;
    _proofTimer?.cancel();
    _proofTimer = null;
    await _prefs.remove(pendingProofKey);
  }

  Future<void> enqueueEvent(Map<String, dynamic>? event) async {
    if (event == null) return;
    final queue = [...queuedEvents, jsonEncode(event)];
    final overflow = queue.length - maxQueuedEvents;
    await _prefs.setStringList(
        eventQueueKey, overflow > 0 ? queue.sublist(overflow) : queue);
    _scheduleFlush();
  }

  void _scheduleFlush() {
    _flushTimer ??= Timer(flushInterval, () {
      _flushTimer = null;
      unawaited(flushEvents());
    });
  }

  Future<void> flushEvents() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final queue = queuedEvents;
      for (var i = 0; i < queue.length; i += batchSize) {
        final batch = queue.sublist(i, min(i + batchSize, queue.length));
        final sent = await _post(
          ['v1', 'analytics', 'evts'],
          batch.map(jsonDecode).toList(),
        );
        if (!sent) break;
        await _removeEvents(batch);
      }
    } finally {
      _flushing = false;
    }
    if (queuedEvents.isNotEmpty) _scheduleFlush();
  }

  Future<void> _removeEvents(List<String> batch) async {
    final remaining = [...queuedEvents];
    for (final event in batch) {
      remaining.remove(event);
    }
    if (remaining.isEmpty) {
      await _prefs.remove(eventQueueKey);
    } else {
      await _prefs.setStringList(eventQueueKey, remaining);
    }
  }

  Future<void> _uploadProof(int generation) async {
    _proofTimer?.cancel();
    _proofTimer = null;
    final raw = _prefs.getString(pendingProofKey);
    if (raw == null) return;
    final proof = jsonDecode(raw) as Map<String, dynamic>;
    final sent = await _post(
      [
        'v1',
        'app',
        'consents',
        proof['clientId'].toString(),
        'cookies',
        proof['identifier'].toString(),
      ],
      proof['payload'],
    );
    if (generation != _proofGeneration) return;
    if (sent) {
      await _prefs.remove(pendingProofKey);
    } else {
      _proofTimer = Timer(proofRetryInterval, () {
        _proofTimer = null;
        unawaited(_uploadProof(generation));
      });
    }
  }

  Future<bool> _post(List<String> pathSegments, Object? body) async {
    try {
      final request = _client.post(
        Uri(scheme: 'https', host: host, pathSegments: pathSegments),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': _userAgent,
        },
        body: jsonEncode(body),
      );
      final response = await request.timeout(requestTimeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      developer.log(
        'Upload failed: ${pathSegments.join('/')}',
        error: e,
        name: 'AxeptioUploader',
      );
      return false;
    }
  }

  static String get _userAgent =>
      'AxeptioFlutterSDK (${Platform.operatingSystem}; '
      '${Platform.operatingSystemVersion})';

  static String? _configIdentifier(Map<String, dynamic>? payload) {
    final preferences = payload?['preferences'];
    if (preferences is! Map) return null;
    final config = preferences['config'];
    if (config is! Map) return null;
    final identifier = config['identifier'];
    if (identifier == null || identifier.toString().isEmpty) return null;
    return identifier.toString();
  }
}
