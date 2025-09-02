import 'package:axeptio_sdk/axeptio_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAxeptioSdkPlatform
    with MockPlatformInterfaceMixin
    implements AxeptioSdkPlatform {
  // Mock state
  bool _isInitialized = false;
  AxeptioService? _currentService;
  String? _currentToken;
  final List<AxeptioEventListener> _listeners = [];
  bool _userDeniedTracking = false;

  // Mock data
  final Map<String, dynamic> _mockConsentData = {
    'axeptio_cookies': '{"analytics": true, "ads": false}',
    'IABTCF_TCString': 'CPXxRfAPXxRfAAfKABENATEIAAIAAAAAAAAAAAAA',
    'IABTCF_gdprApplies': '1',
    'IABTCF_CmpSdkID': '42',
    'AX_CLIENT_TOKEN': 'mock-client-token-123',
  };

  final Map<String, dynamic> _mockDebugInfo = {
    'sdk_version': '2.0.16',
    'client_id': 'test-client-id',
    'service_type': 'brands',
    'initialization_time': '2025-01-01T00:00:00Z',
  };

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> appendAxeptioTokenURL(String url, String token) async {
    if (!_isInitialized) {
      throw PlatformException(
          code: 'NOT_INITIALIZED', message: 'SDK not initialized');
    }
    return '$url?axeptio_token=$token';
  }

  @override
  Future<void> clearConsent() async {
    if (!_isInitialized) {
      throw PlatformException(
          code: 'NOT_INITIALIZED', message: 'SDK not initialized');
    }
    _mockConsentData.clear();
    // Trigger event listeners
    for (final listener in _listeners) {
      listener.onConsentCleared.call();
    }
  }

  @override
  Future<String?> get axeptioToken async {
    if (!_isInitialized) return null;
    return _currentToken ?? _mockConsentData['AX_CLIENT_TOKEN'] as String?;
  }

  @override
  Future<void> initialize(AxeptioService service, String clientId,
      String cookiesVersion, String? token) async {
    if (clientId.isEmpty) {
      throw PlatformException(
          code: 'INVALID_CLIENT_ID', message: 'Client ID cannot be empty');
    }
    _isInitialized = true;
    _currentService = service;
    _currentToken = token;

    // Update mock debug info
    _mockDebugInfo['client_id'] = clientId;
    _mockDebugInfo['service_type'] =
        service == AxeptioService.brands ? 'brands' : 'publishers';
    if (token != null) {
      _mockConsentData['AX_CLIENT_TOKEN'] = token;
    }
  }

  @override
  Future<void> setUserDeniedTracking() async {
    if (!_isInitialized) {
      throw PlatformException(
          code: 'NOT_INITIALIZED', message: 'SDK not initialized');
    }
    _userDeniedTracking = true;
    _mockConsentData['user_denied_tracking'] = 'true';
  }

  @override
  Future<void> setupUI() async {
    if (!_isInitialized) {
      throw PlatformException(
          code: 'NOT_INITIALIZED', message: 'SDK not initialized');
    }
    if (_userDeniedTracking) return; // UI not shown if tracking denied
    // Simulate UI setup
  }

  @override
  Future<void> showConsentScreen() async {
    if (!_isInitialized) {
      throw PlatformException(
          code: 'NOT_INITIALIZED', message: 'SDK not initialized');
    }
    // Simulate showing consent screen and closing it
    await Future.delayed(const Duration(milliseconds: 100));
    for (final listener in _listeners) {
      listener.onPopupClosedEvent.call();
    }
  }

  @override
  addEventListener(AxeptioEventListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  @override
  removeEventListener(AxeptioEventListener listener) {
    _listeners.remove(listener);
  }

  @override
  Future<Map<String, dynamic>?> getConsentSavedData(
      {String? preferenceKey}) async {
    if (!_isInitialized) return null;

    if (preferenceKey != null) {
      final value = _mockConsentData[preferenceKey];
      return value != null ? {preferenceKey: value} : null;
    }
    return Map<String, dynamic>.from(_mockConsentData);
  }

  @override
  Future<Map<String, dynamic>?> getConsentDebugInfo(
      {String? preferenceKey}) async {
    if (!_isInitialized) return null;

    if (preferenceKey != null) {
      final value = _mockDebugInfo[preferenceKey];
      return value != null ? {preferenceKey: value} : null;
    }
    return Map<String, dynamic>.from(_mockDebugInfo);
  }

  @override
  Future<Map<int, bool>> getVendorConsents() async {
    if (!_isInitialized) return {};
    return {1: true, 2: false, 50: true, 100: false, 755: true};
  }

  @override
  Future<List<int>> getConsentedVendors() async {
    if (!_isInitialized) return [];
    return [1, 50, 755];
  }

  @override
  Future<List<int>> getRefusedVendors() async {
    if (!_isInitialized) return [];
    return [2, 100];
  }

  @override
  Future<bool> isVendorConsented(int vendorId) async {
    if (!_isInitialized) return false;
    final consents = await getVendorConsents();
    return consents[vendorId] ?? false;
  }

  // Helper methods for testing
  void reset() {
    _isInitialized = false;
    _currentService = null;
    _currentToken = null;
    _listeners.clear();
    _userDeniedTracking = false;
  }

  bool get isInitialized => _isInitialized;
  AxeptioService? get currentService => _currentService;
  List<AxeptioEventListener> get listeners => List.unmodifiable(_listeners);

  // GVL Mock Methods
  @override
  Future<bool> loadGVL({String? gvlVersion}) async {
    return true; // Mock success
  }

  @override
  Future<void> unloadGVL() async {
    // Mock implementation
  }

  @override
  Future<void> clearGVL() async {
    // Mock implementation
  }

  @override
  Future<String?> getVendorName(int vendorId) async {
    // Mock vendor names
    final mockNames = {
      1: 'Google',
      2: 'Facebook', 
      755: 'Microsoft',
      5175: 'Apple',
      8690: 'Amazon'
    };
    return mockNames[vendorId];
  }

  @override
  Future<Map<int, String>> getVendorNames(List<int> vendorIds) async {
    final mockNames = {
      1: 'Google',
      2: 'Facebook',
      755: 'Microsoft',
      5175: 'Apple',
      8690: 'Amazon'
    };
    
    final result = <int, String>{};
    for (final id in vendorIds) {
      final name = mockNames[id];
      if (name != null) {
        result[id] = name;
      }
    }
    return result;
  }

  @override
  Future<Map<int, VendorInfo>> getVendorConsentsWithNames() async {
    final mockVendorConsents = await getVendorConsents();
    final result = <int, VendorInfo>{};
    
    for (final entry in mockVendorConsents.entries) {
      final vendorName = await getVendorName(entry.key);
      result[entry.key] = VendorInfo(
        id: entry.key,
        name: vendorName ?? 'Vendor ${entry.key}',
        consented: entry.value,
        purposes: [1, 2, 3],
      );
    }
    
    return result;
  }

  @override
  Future<bool> isGVLLoaded() async {
    return true; // Mock loaded state
  }

  @override
  Future<String?> getGVLVersion() async {
    return '123'; // Mock version
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final AxeptioSdkPlatform initialPlatform = AxeptioSdkPlatform.instance;

  group('Platform Interface', () {
    test('$MethodChannelAxeptioSdk is the default instance', () {
      expect(initialPlatform, isInstanceOf<MethodChannelAxeptioSdk>());
    });

    test('getPlatformVersion', () async {
      AxeptioSdk axeptioSdkPlugin = AxeptioSdk();
      MockAxeptioSdkPlatform fakePlatform = MockAxeptioSdkPlatform();
      AxeptioSdkPlatform.instance = fakePlatform;

      expect(await axeptioSdkPlugin.getPlatformVersion(), '42');
    });
  });

  group('SDK Initialization', () {
    late AxeptioSdk sdk;
    late MockAxeptioSdkPlatform mockPlatform;

    setUp(() {
      sdk = AxeptioSdk();
      mockPlatform = MockAxeptioSdkPlatform();
      AxeptioSdkPlatform.instance = mockPlatform;
      mockPlatform.reset();
    });

    test('initialize with brands service', () async {
      await sdk.initialize(
        AxeptioService.brands,
        'test-client-id',
        'v1.0.0',
        null,
      );

      expect(mockPlatform.isInitialized, isTrue);
      expect(mockPlatform.currentService, equals(AxeptioService.brands));
    });

    test('initialize with publishers service', () async {
      await sdk.initialize(
        AxeptioService.publishers,
        'test-client-id',
        'v1.0.0',
        'custom-token',
      );

      expect(mockPlatform.isInitialized, isTrue);
      expect(mockPlatform.currentService, equals(AxeptioService.publishers));
    });

    test('initialize with empty client ID throws error', () async {
      expect(
        () => sdk.initialize(AxeptioService.brands, '', 'v1.0.0', null),
        throwsA(isA<PlatformException>()),
      );
    });

    test('methods fail when not initialized', () async {
      expect(
        () => sdk.setupUI(),
        throwsA(isA<PlatformException>()),
      );

      expect(
        () => sdk.showConsentScreen(),
        throwsA(isA<PlatformException>()),
      );

      expect(
        () => sdk.clearConsent(),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('UI and Consent Management', () {
    late AxeptioSdk sdk;
    late MockAxeptioSdkPlatform mockPlatform;

    setUp(() async {
      sdk = AxeptioSdk();
      mockPlatform = MockAxeptioSdkPlatform();
      AxeptioSdkPlatform.instance = mockPlatform;
      mockPlatform.reset();

      // Initialize SDK for UI tests
      await sdk.initialize(
          AxeptioService.brands, 'test-client', 'v1.0.0', null);
    });

    test('setupUI works after initialization', () async {
      await expectLater(sdk.setupUI(), completes);
    });

    test('showConsentScreen works and triggers events', () async {
      bool popupClosed = false;
      final listener = AxeptioEventListener();
      listener.onPopupClosedEvent = () {
        popupClosed = true;
      };

      sdk.addEventListerner(listener);
      await sdk.showConsentScreen();

      expect(popupClosed, isTrue);
    });

    test('clearConsent works and triggers events', () async {
      bool consentCleared = false;
      final listener = AxeptioEventListener();
      listener.onConsentCleared = () {
        consentCleared = true;
      };

      sdk.addEventListerner(listener);
      await sdk.clearConsent();

      expect(consentCleared, isTrue);
    });

    test('setUserDeniedTracking works', () async {
      await expectLater(sdk.setUserDeniedTracking(), completes);
    });
  });

  group('Token Management', () {
    late AxeptioSdk sdk;
    late MockAxeptioSdkPlatform mockPlatform;

    setUp(() async {
      sdk = AxeptioSdk();
      mockPlatform = MockAxeptioSdkPlatform();
      AxeptioSdkPlatform.instance = mockPlatform;
      mockPlatform.reset();

      await sdk.initialize(
          AxeptioService.brands, 'test-client', 'v1.0.0', 'test-token');
    });

    test('axeptioToken returns token', () async {
      final token = await sdk.axeptioToken;
      expect(token, equals('test-token'));
    });

    test('appendAxeptioTokenURL works', () async {
      final url =
          await sdk.appendAxeptioTokenURL('https://example.com', 'token123');
      expect(url, equals('https://example.com?axeptio_token=token123'));
    });

    test('appendAxeptioTokenURL fails when not initialized', () async {
      mockPlatform.reset();
      expect(
        () => sdk.appendAxeptioTokenURL('https://example.com', 'token123'),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('Data Retrieval', () {
    late AxeptioSdk sdk;
    late MockAxeptioSdkPlatform mockPlatform;

    setUp(() async {
      sdk = AxeptioSdk();
      mockPlatform = MockAxeptioSdkPlatform();
      AxeptioSdkPlatform.instance = mockPlatform;
      mockPlatform.reset();

      await sdk.initialize(
          AxeptioService.brands, 'test-client', 'v1.0.0', null);
    });

    test('getConsentSavedData returns all data when no key specified',
        () async {
      final data = await sdk.getConsentSavedData();
      expect(data, isNotNull);
      expect(data!.containsKey('axeptio_cookies'), isTrue);
      expect(data.containsKey('IABTCF_TCString'), isTrue);
    });

    test('getConsentSavedData returns specific data when key specified',
        () async {
      final data =
          await sdk.getConsentSavedData(preferenceKey: 'axeptio_cookies');
      expect(data, isNotNull);
      expect(data!['axeptio_cookies'],
          equals('{"analytics": true, "ads": false}'));
    });

    test('getConsentDebugInfo returns debug information', () async {
      final data = await sdk.getConsentDebugInfo();
      expect(data, isNotNull);
      expect(data!.containsKey('sdk_version'), isTrue);
      expect(data['sdk_version'], equals('2.0.16'));
    });

    test('data methods return null when not initialized', () async {
      mockPlatform.reset();

      final consentData = await sdk.getConsentSavedData();
      expect(consentData, isNull);

      final debugData = await sdk.getConsentDebugInfo();
      expect(debugData, isNull);
    });
  });

  group('Event Listener Management', () {
    late AxeptioSdk sdk;
    late MockAxeptioSdkPlatform mockPlatform;

    setUp(() {
      sdk = AxeptioSdk();
      mockPlatform = MockAxeptioSdkPlatform();
      AxeptioSdkPlatform.instance = mockPlatform;
      mockPlatform.reset();
    });

    test('add and remove event listeners', () {
      final listener1 = AxeptioEventListener();
      final listener2 = AxeptioEventListener();

      // Add listeners
      sdk.addEventListerner(listener1);
      sdk.addEventListerner(listener2);
      expect(mockPlatform.listeners.length, equals(2));

      // Remove listener
      sdk.removeEventListener(listener1);
      expect(mockPlatform.listeners.length, equals(1));
      expect(mockPlatform.listeners.contains(listener2), isTrue);
    });

    test('adding same listener twice only adds once', () {
      final listener = AxeptioEventListener();

      sdk.addEventListerner(listener);
      sdk.addEventListerner(listener);

      expect(mockPlatform.listeners.length, equals(1));
    });
  });

  group('GVL Integration', () {
    late AxeptioSdk sdk;
    late MockAxeptioSdkPlatform mockPlatform;

    setUp(() async {
      sdk = AxeptioSdk();
      mockPlatform = MockAxeptioSdkPlatform();
      AxeptioSdkPlatform.instance = mockPlatform;
      mockPlatform.reset();

      // Initialize SDK for GVL tests
      await sdk.initialize(
          AxeptioService.publishers, 'test-client', 'v1.0.0', null);
    });

    group('GVL Loading', () {
      test('loadGVL succeeds with default version', () async {
        final result = await sdk.loadGVL();
        expect(result, isTrue);
      });

      test('loadGVL succeeds with specific version', () async {
        final result = await sdk.loadGVL(gvlVersion: '123');
        expect(result, isTrue);
      });

      test('isGVLLoaded returns correct status', () async {
        final isLoaded = await sdk.isGVLLoaded();
        expect(isLoaded, isTrue);
      });

      test('getGVLVersion returns version string', () async {
        final version = await sdk.getGVLVersion();
        expect(version, equals('123'));
      });

      test('unloadGVL completes successfully', () async {
        await expectLater(sdk.unloadGVL(), completes);
      });

      test('clearGVL completes successfully', () async {
        await expectLater(sdk.clearGVL(), completes);
      });
    });

    group('Vendor Name Resolution', () {
      test('getVendorName returns vendor name for known ID', () async {
        final vendorName = await sdk.getVendorName(1);
        expect(vendorName, equals('Google'));
      });

      test('getVendorName returns null for unknown ID', () async {
        final vendorName = await sdk.getVendorName(9999);
        expect(vendorName, isNull);
      });

      test('getVendorNames returns map for multiple IDs', () async {
        final vendorNames = await sdk.getVendorNames([1, 2, 755]);
        expect(vendorNames, isA<Map<int, String>>());
        expect(vendorNames[1], equals('Google'));
        expect(vendorNames[2], equals('Facebook'));
        expect(vendorNames[755], equals('Microsoft'));
      });

      test('getVendorNames handles empty list', () async {
        final vendorNames = await sdk.getVendorNames([]);
        expect(vendorNames, isEmpty);
      });

      test('getVendorNames filters unknown IDs', () async {
        final vendorNames = await sdk.getVendorNames([1, 9999, 755]);
        expect(vendorNames.length, equals(2));
        expect(vendorNames.containsKey(9999), isFalse);
        expect(vendorNames[1], equals('Google'));
        expect(vendorNames[755], equals('Microsoft'));
      });
    });

    group('Vendor Consents with Names', () {
      test('getVendorConsentsWithNames returns enhanced consent data', () async {
        final vendorConsentsWithNames = await sdk.getVendorConsentsWithNames();
        expect(vendorConsentsWithNames, isA<Map<int, VendorInfo>>());
        expect(vendorConsentsWithNames.isNotEmpty, isTrue);
      });

      test('getVendorConsentsWithNames includes consent status', () async {
        final vendorConsentsWithNames = await sdk.getVendorConsentsWithNames();
        
        for (final entry in vendorConsentsWithNames.entries) {
          final vendorInfo = entry.value;
          expect(vendorInfo.id, equals(entry.key));
          expect(vendorInfo.name, isNotEmpty);
          expect(vendorInfo.consented, isA<bool>());
          expect(vendorInfo.purposes, isA<List<int>>());
        }
      });

      test('getVendorConsentsWithNames includes vendor names', () async {
        final vendorConsentsWithNames = await sdk.getVendorConsentsWithNames();
        
        // Check specific vendors we know exist
        if (vendorConsentsWithNames.containsKey(1)) {
          expect(vendorConsentsWithNames[1]!.name, equals('Google'));
        }
        if (vendorConsentsWithNames.containsKey(755)) {
          expect(vendorConsentsWithNames[755]!.name, equals('Microsoft'));
        }
      });

      test('getVendorConsentsWithNames provides fallback names for unknown vendors', () async {
        final vendorConsentsWithNames = await sdk.getVendorConsentsWithNames();
        
        for (final entry in vendorConsentsWithNames.entries) {
          final vendorInfo = entry.value;
          // Should never be null or empty
          expect(vendorInfo.name, isNotEmpty);
          // If no name found, should fallback to "Vendor {id}"
          if (!vendorInfo.name.contains('Google') && 
              !vendorInfo.name.contains('Facebook') && 
              !vendorInfo.name.contains('Microsoft')) {
            expect(vendorInfo.name, contains('Vendor'));
            expect(vendorInfo.name, contains(vendorInfo.id.toString()));
          }
        }
      });
    });

    group('GVL Error Handling', () {
      test('GVL methods work without initialization', () async {
        mockPlatform.reset(); // Reset to uninitialized state
        
        // These methods should still work as they don't require SDK initialization
        await expectLater(sdk.loadGVL(), completes);
        await expectLater(sdk.getVendorName(1), completes);
        await expectLater(sdk.getVendorNames([1, 2]), completes);
        await expectLater(sdk.unloadGVL(), completes);
        await expectLater(sdk.clearGVL(), completes);
      });
    });

    group('Integration with Existing Vendor Methods', () {
      test('GVL enhances existing vendor consent data', () async {
        // Get standard vendor consents
        final vendorConsents = await sdk.getVendorConsents();
        expect(vendorConsents, isA<Map<int, bool>>());

        // Get enhanced vendor consents with names
        final vendorConsentsWithNames = await sdk.getVendorConsentsWithNames();
        expect(vendorConsentsWithNames, isA<Map<int, VendorInfo>>());

        // Both should have same vendor IDs
        expect(vendorConsentsWithNames.keys.toSet(), equals(vendorConsents.keys.toSet()));

        // Consent status should match
        for (final vendorId in vendorConsents.keys) {
          expect(vendorConsentsWithNames[vendorId]!.consented, 
                 equals(vendorConsents[vendorId]));
        }
      });

      test('GVL data is consistent with isVendorConsented', () async {
        final vendorConsentsWithNames = await sdk.getVendorConsentsWithNames();

        for (final entry in vendorConsentsWithNames.entries) {
          final vendorId = entry.key;
          final vendorInfo = entry.value;
          
          final isConsented = await sdk.isVendorConsented(vendorId);
          expect(vendorInfo.consented, equals(isConsented));
        }
      });

      test('GVL data is consistent with consented/refused vendor lists', () async {
        final consentedVendors = await sdk.getConsentedVendors();
        final refusedVendors = await sdk.getRefusedVendors();
        final vendorConsentsWithNames = await sdk.getVendorConsentsWithNames();

        // Check consented vendors
        for (final vendorId in consentedVendors) {
          expect(vendorConsentsWithNames[vendorId]?.consented, isTrue);
        }

        // Check refused vendors
        for (final vendorId in refusedVendors) {
          expect(vendorConsentsWithNames[vendorId]?.consented, isFalse);
        }
      });
    });
  });
}
