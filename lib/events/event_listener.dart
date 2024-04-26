import 'package:axeptio_sdk/model/consentsV2.dart';

class EventListener {
  dynamic Function() onPopupClosedEvent = () {};
  dynamic Function() onConsentChanged = () {};
  dynamic Function(ConsentsV2 consents) onGoogleConsentModeUpdate = (consents) {};
}