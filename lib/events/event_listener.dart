import 'package:axeptio_sdk/model/consents_v2.dart';

class AxeptioEventListener {
  dynamic Function() onPopupClosedEvent = () {};
  dynamic Function() onConsentChanged = () {};
  dynamic Function(ConsentsV2 consents) onGoogleConsentModeUpdate =
      (consents) {};
}
