import 'package:flutter_test/flutter_test.dart';
import 'package:axeptio_sdk/src/channel/axeptio_sdk_platform_interface.dart';
import 'package:axeptio_sdk/src/channel/axeptio_sdk_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AxeptioSdkPlatform', () {
    test('default instance is MethodChannelAxeptioSdk', () {
      expect(AxeptioSdkPlatform.instance, isInstanceOf<MethodChannelAxeptioSdk>());
    });

    test('instance getter returns non-null platform', () {
      expect(AxeptioSdkPlatform.instance, isNotNull);
    });
  });
}