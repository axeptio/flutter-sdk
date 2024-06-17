// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:axeptio_sdk/axeptio_sdk.dart';
import 'package:axeptio_sdk/events/event_listener.dart';
import 'package:axeptio_sdk_example/tokendialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  runApp(const MyApp());
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

  final adUnitId = Platform.isAndroid
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
        ));
  }

  @override
  void initState() {
    super.initState();
    initSDK();
    loadAd();
  }

  Future<void> initSDK() async {
    try {
      await _axeptioSdkPlugin.initialize(
        '5fbfa806a0787d3985c6ee5f',
        'google cmp partner program sandbox-en-EU',
        null,
      );

      var listener = AxeptioEventListener();
      listener.onPopupClosedEvent = () {
        // The CMP notice is being hidden
        loadAd();
      };
      listener.onConsentChanged = () {
        // The consent of the user changed
        // Do something
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
      platformVersion = await _axeptioSdkPlugin.getPlatformVersion() ??
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
            }));
  }
}

class HomePage extends StatelessWidget {
  const HomePage(
      {super.key,
      required this.axeptioSdk,
      required this.onAdBtnPressed,
      required this.onClearPressed});

  final AxeptioSdk axeptioSdk;
  final Function()? onAdBtnPressed;
  final Function() onClearPressed;

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
                axeptioSdk.showConsentScreen();
              },
              child: const Text(
                'Consent popup',
                style: textStyle,
              ),
            ),
            ElevatedButton(
              style: style,
              onPressed: onAdBtnPressed,
              child: const Text(
                'Google ad',
                style: textStyle,
              ),
            ),
            ElevatedButton(
              style: clearConsentStyle,
              onPressed: () {
                axeptioSdk.clearConsent();
                onClearPressed();
              },
              child: const Text(
                'Clear consent',
                style: textStyle,
              ),
            ),
            ElevatedButton(
              style: style,
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) => TokenAppendDialog(
                          axeptioSdk: axeptioSdk,
                        ));
              },
              child: const Text(
                'Show webview with token',
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
