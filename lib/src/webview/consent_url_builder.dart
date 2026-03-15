import 'package:axeptio_sdk/src/model/axeptio_service.dart';

class ConsentUrlBuilder {
  static const String _publishersUrl =
      'https://static.axept.io/app-sdk-webview.html';
  static const String _brandsUrl =
      'https://static.axept.io/app-sdk-webview-for-brands.html';

  static Uri build({
    required AxeptioService service,
    required String clientId,
    required String cookiesVersion,
    String? token,
    bool showConsentManager = false,
  }) {
    final base =
        service == AxeptioService.publishers ? _publishersUrl : _brandsUrl;
    final params = <String, String>{
      'clientId': clientId,
      'cookiesVersion': cookiesVersion,
    };
    if (token != null) params['axeptio_token'] = token;
    if (showConsentManager) params['showConsentManager'] = 'true';
    return Uri.parse(base).replace(queryParameters: params);
  }

  static Uri? appendToken(
      String url, String clientId, String cookiesVersion, String? token) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null; // coverage:ignore-line
    final params = Map<String, String>.from(uri.queryParameters);
    params['clientId'] = clientId;
    params['cookiesVersion'] = cookiesVersion;
    if (token != null) {
      params['axeptio_token'] = token;
    } else {
      params.remove('axeptio_token');
    }
    return uri.replace(queryParameters: params);
  }
}
