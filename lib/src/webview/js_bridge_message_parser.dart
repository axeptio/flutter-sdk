import 'dart:convert';
import 'dart:developer' as developer;

/// Represents a parsed message from the JS bridge.
class JsBridgeMessage {
  final String name;
  final Map<String, dynamic>? payload;

  const JsBridgeMessage({required this.name, this.payload});
}

/// Parses raw JSON messages from the WebView JavaScript bridge and validates
/// their schemas.
///
/// Handles the double-decode pattern where payload can be either
/// a JSON string (requiring second decode) or a Map.
///
/// Validation is informational only: schema mismatches are logged via
/// [developer.log] but messages still flow through. For a consent SDK,
/// failing to show consent is worse than processing a slightly malformed
/// message.
class JsBridgeMessageParser {
  /// Optional callback invoked when a schema validation warning is detected.
  /// Useful for testing; defaults to null.
  final void Function(String eventName, String warning)? onValidationWarning;

  JsBridgeMessageParser({this.onValidationWarning});

  /// Parses a raw message string into a [JsBridgeMessage].
  ///
  /// Returns null if the message cannot be parsed or has no event name.
  JsBridgeMessage? parse(String rawMessage) {
    try {
      final decoded = jsonDecode(rawMessage) as Map<String, dynamic>;
      final name = decoded['name'] as String?;
      if (name == null) return null;

      final payloadRaw = decoded['payload'];
      Map<String, dynamic>? payload;

      if (payloadRaw is String && payloadRaw.isNotEmpty) {
        try {
          payload = jsonDecode(payloadRaw) as Map<String, dynamic>?;
        } catch (e) {
          developer.log(
            'Failed to parse payload string for event: $name',
            error: e,
            name: 'JsBridgeMessageParser',
          );
        }
      } else if (payloadRaw is Map) {
        payload = Map<String, dynamic>.from(payloadRaw);
      }

      _validatePayload(name, payload);

      return JsBridgeMessage(name: name, payload: payload);
    } catch (e) {
      developer.log(
        'Failed to parse JS bridge message',
        error: e,
        name: 'JsBridgeMessageParser',
      );
      return null;
    }
  }

  void _validatePayload(String name, Map<String, dynamic>? payload) {
    switch (name) {
      // Events that REQUIRE a payload
      case 'iabtcf':
      case 'consent:saved':
      case 'axeptio:cookies':
      case 'cookies:complete':
      case 'google:consent-mode-v2-update':
        if (payload == null) {
          _warn(name, 'Expected payload but received null');
        }
        break;
      // payload can be null (triggers close), but if present should have
      // subscription/showCmp
      case 'app:cookies:ready':
        if (payload != null &&
            !payload.containsKey('subscription') &&
            !payload.containsKey('showCmp')) {
          _warn(name, 'Payload missing expected fields: subscription, showCmp');
        }
        break;
      // cookies:close has no payload -- no validation needed
      case 'cookies:close':
        break;
      // Unknown events -- don't validate (we don't know their schema)
      default:
        break;
    }

    // Validate specific event fields when payload exists
    if (payload != null) {
      switch (name) {
        case 'google:consent-mode-v2-update':
          final expectedKeys = [
            'analytics_storage',
            'ad_storage',
            'ad_user_data',
            'ad_personalization',
          ];
          final missingKeys =
              expectedKeys.where((k) => !payload.containsKey(k)).toList();
          if (missingKeys.isNotEmpty) {
            _warn(name, 'Missing expected fields: ${missingKeys.join(', ')}');
          }
          break;
      }
    }
  }

  void _warn(String eventName, String warning) {
    developer.log(
      'Schema validation warning for "$eventName": $warning',
      name: 'JsBridgeMessageParser',
    );
    onValidationWarning?.call(eventName, warning);
  }
}
