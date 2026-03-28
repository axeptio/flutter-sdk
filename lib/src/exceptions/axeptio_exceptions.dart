/// Base exception for the Axeptio SDK.
class AxeptioException implements Exception {
  final String message;
  final Object? cause;

  const AxeptioException(this.message, {this.cause});

  @override
  String toString() => 'AxeptioException: $message';
}

/// Thrown when SDK methods are called before [AxeptioSdk.initialize].
class AxeptioNotInitializedException extends AxeptioException {
  const AxeptioNotInitializedException(
      [super.message = 'SDK not initialized. Call initialize() first.']);

  @override
  String toString() => 'AxeptioNotInitializedException: $message';
}

/// Thrown when consent data operations fail.
class AxeptioConsentException extends AxeptioException {
  const AxeptioConsentException(super.message, {super.cause});

  @override
  String toString() => 'AxeptioConsentException: $message';
}

/// Thrown when network operations fail (GVL fetch, WebView load).
class AxeptioNetworkException extends AxeptioException {
  final int? statusCode;

  const AxeptioNetworkException(super.message, {this.statusCode, super.cause});

  @override
  String toString() =>
      'AxeptioNetworkException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// Thrown when SharedPreferences operations fail.
class AxeptioStorageException extends AxeptioException {
  const AxeptioStorageException(super.message, {super.cause});

  @override
  String toString() => 'AxeptioStorageException: $message';
}
