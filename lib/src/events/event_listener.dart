import 'package:axeptio_sdk/src/exceptions/axeptio_exceptions.dart';
import 'package:axeptio_sdk/src/model/consents_v2.dart';

class AxeptioEventListener {
  dynamic Function() onPopupClosedEvent = () {};
  dynamic Function() onConsentCleared = () {};
  dynamic Function(ConsentsV2 consents) onGoogleConsentModeUpdate =
      (consents) {};
  void Function(AxeptioException error) onError = (_) {};
}
