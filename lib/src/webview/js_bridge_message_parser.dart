import 'dart:convert';
import 'dart:developer' as developer;

/// Represents a parsed message from the JS bridge.
class JsBridgeMessage {
  final String name;
  final Map<String, dynamic>? payload;

  const JsBridgeMessage({required this.name, this.payload});
}

/// Parses raw JSON messages from the WebView JavaScript bridge.
///
/// Handles the double-decode pattern where payload can be either
/// a JSON string (requiring second decode) or a Map.
class JsBridgeMessageParser {
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
        } catch (_) {
          developer.log(
            'Failed to parse payload string for event: $name',
            name: 'JsBridgeMessageParser',
          );
        }
      } else if (payloadRaw is Map) {
        payload = Map<String, dynamic>.from(payloadRaw);
      }

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
}
