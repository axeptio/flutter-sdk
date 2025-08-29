// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:axeptio_sdk/axeptio_sdk.dart';
import 'package:axeptio_sdk_example/debug_info_dialog.dart';
import 'package:axeptio_sdk_example/preferences_dialog.dart';
import 'package:axeptio_sdk_example/tokendialog.dart';
import 'package:axeptio_sdk_example/config_screen.dart';
import 'package:axeptio_sdk_example/vendor_screen.dart';
import 'package:axeptio_sdk_example/vendor_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  runApp(const MyApp());
}

class SDKConfig {
  // Default fallback values (used when SharedPreferences is empty)
  static const String _defaultClientId = '5fbfa806a0787d3985c6ee5f';
  static const String _defaultVersion = 'google cmp partner program sandbox-en-EU';
  static const AxeptioService _defaultService = AxeptioService.brands;

  // Current configuration (loaded from SharedPreferences)
  static AxeptioService? _currentService;
  static String? _currentClientId;
  static String? _currentVersion;
  static String? _currentToken;
  static bool _isConfigLoaded = false;

  static Future<void> loadConfiguration() async {
    if (_isConfigLoaded) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    _currentClientId = prefs.getString('axeptio_client_id') ?? _defaultClientId;
    _currentVersion = prefs.getString('axeptio_version') ?? _defaultVersion;
    _currentToken = prefs.getString('axeptio_token');
    
    final serviceString = prefs.getString('axeptio_service') ?? 'brands';
    _currentService = serviceString == 'publishers' 
        ? AxeptioService.publishers 
        : AxeptioService.brands;
    
    _isConfigLoaded = true;
    
    print('=== Loaded SDK Configuration ===');
    print('Service: $_currentService');
    print('Client ID: $_currentClientId');
    print('Version: $_currentVersion');
    print('Token: ${_currentToken?.isNotEmpty == true ? "Set (${_currentToken!.length} chars)" : "Not set"}');
    print('================================');
  }

  static AxeptioService get axeptioService => _currentService ?? _defaultService;
  static String get projectId => _currentClientId ?? _defaultClientId;
  static String get version => _currentVersion ?? _defaultVersion;
  static String? get token => _currentToken;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // ignore: unused_field
  String _platformVersion = 'Unknown';
  InterstitialAd? _interstitialAd;
  Function()? _onAdBtnPressed;

  final _axeptioSdkPlugin = AxeptioSdk();

  final adUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';

  /// Loads an interstitial ad.
  void loadAd() {
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          print('$ad loaded.');
          // Keep a reference to the ad so you can show it later.
          setState(() {
            _interstitialAd = ad;
            _onAdBtnPressed = () {
              _interstitialAd?.show();
              loadAd();
            };
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error');
          setState(() {
            _onAdBtnPressed = null;
          });
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    initSDK();
    loadAd();
  }

  Future<void> initSDK() async {
    // Load configuration from SharedPreferences
    await SDKConfig.loadConfiguration();

    try {
      await _axeptioSdkPlugin.initialize(
        SDKConfig.axeptioService,
        SDKConfig.projectId,
        SDKConfig.version,
        SDKConfig.token,
      );

      var listener = AxeptioEventListener();
      listener.onPopupClosedEvent = () {
        // The CMP notice is being hidden
        loadAd();
      };
      listener.onConsentCleared = () {
        // The consent of the user changed
        // Do something
        print('Consent cleared');
      };
      listener.onGoogleConsentModeUpdate = (consents) {
        // The Google Consent V2 status
        // Do something
      };
      _axeptioSdkPlugin.addEventListerner(listener);

      try {
        TrackingStatus status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        // If the system can show an authorization request dialog
        if (status == TrackingStatus.notDetermined) {
          // Request system's tracking authorization dialog
          status = await AppTrackingTransparency.requestTrackingAuthorization();
        }

        if (status == TrackingStatus.denied) {
          await _axeptioSdkPlugin.setUserDeniedTracking();
        } else {
          // Run setupUI if accepted
          await _axeptioSdkPlugin.setupUI();
        }
      } on PlatformException {
        // Run setupUI on android
        await _axeptioSdkPlugin.setupUI();
      }
    } catch (e) {
      print("ERROR $e");
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _axeptioSdkPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(
        axeptioSdk: _axeptioSdkPlugin,
        onAdBtnPressed: _onAdBtnPressed,
        onClearPressed: () {
          loadAd();
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.axeptioSdk,
    required this.onAdBtnPressed,
    required this.onClearPressed,
  });

  final AxeptioSdk axeptioSdk;
  final Function()? onAdBtnPressed;
  final Function() onClearPressed;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isClearing = false;

  Future<void> _clearConsentWithFeedback() async {
    if (_isClearing) return;

    setState(() {
      _isClearing = true;
    });

    try {
      // Clear consent
      widget.axeptioSdk.clearConsent();
      
      // Trigger immediate refresh of vendor data
      VendorDataService.triggerGlobalRefresh();
      
      // Call the original callback
      widget.onClearPressed();

      // Show feedback for 2 seconds
      await Future.delayed(const Duration(seconds: 2));
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color.fromRGBO(253, 247, 231, 1);

    const TextStyle textStyle = TextStyle(fontSize: 18, color: Colors.black);
    final ButtonStyle style = ElevatedButton.styleFrom(
      textStyle: textStyle,
      elevation: 0,
      backgroundColor: const Color.fromRGBO(247, 209, 94, 1),
    );

    final ButtonStyle clearConsentStyle = ElevatedButton.styleFrom(
      textStyle: textStyle,
      elevation: 0,
      backgroundColor: const Color.fromRGBO(205, 97, 91, 1),
    );

    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 0, 0, 1),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        color: backgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              style: style,
              onPressed: () {
                widget.axeptioSdk.showConsentScreen();
              },
              child: const Text('Consent popup', style: textStyle),
            ),
            ElevatedButton(
              style: style,
              onPressed: widget.onAdBtnPressed,
              child: const Text('Google ad', style: textStyle),
            ),
            ElevatedButton(
              style: _isClearing 
                ? ElevatedButton.styleFrom(
                    textStyle: textStyle,
                    elevation: 0,
                    backgroundColor: Colors.green,
                  )
                : clearConsentStyle,
              onPressed: _isClearing ? null : _clearConsentWithFeedback,
              child: Text(
                _isClearing ? '✅ Cleared!' : 'Clear consent',
                style: TextStyle(
                  fontSize: 18,
                  color: _isClearing ? Colors.white : Colors.black,
                ),
              ),
            ),
            ElevatedButton(
              style: style,
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (BuildContext context) =>
                          TokenAppendDialog(axeptioSdk: widget.axeptioSdk),
                );
              },
              child: const Text('Show webview with token', style: textStyle),
            ),
            ElevatedButton(
              style: style,
              onPressed: () async {
                final data = await widget.axeptioSdk.getConsentSavedData();
                if (!context.mounted) return;
                if (data != null) {
                  showPreferences(context: context, data: data);
                } else {
                  print("Could not read event.");
                }
              },
              child: const Text('Consent values', style: textStyle),
            ),
            ElevatedButton(
              style: style,
              onPressed: () async {
                final data = await widget.axeptioSdk.getConsentDebugInfo();
                if (!context.mounted) return;
                if (data != null) {
                  showDebugInfo(context: context, data: data);
                } else {
                  print("Could not read debug info.");
                }
              },
              child: const Text('Consent Debug Info', style: textStyle),
            ),
            ElevatedButton(
              style: style,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConfigScreen(),
                  ),
                );
              },
              child: const Text('Configuration', style: textStyle),
            ),
            ElevatedButton(
              style: style,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VendorScreen(axeptioSdk: widget.axeptioSdk),
                  ),
                );
              },
              child: const Text('TCF Vendor Management', style: textStyle),
            ),
          ],
        ),
      ),
    );
  }

}
