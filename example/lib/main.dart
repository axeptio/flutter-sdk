import 'dart:async';
import 'dart:io';

import 'package:axeptio_sdk/axeptio_sdk.dart';
import 'package:axeptio_sdk_example/preferences.dart';
import 'package:axeptio_sdk_example/webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // MobileAds.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  // InterstitialAd? _interstitialAd;

  final _axeptioSdkPlugin = AxeptioSdk();

  final adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  @override
  void initState() {
    super.initState();
    initSDK();
  }

  /// Loads an interstitial ad.
  // void loadAd() {
  //   InterstitialAd.load(
  //       adUnitId: adUnitId,
  //       request: const AdRequest(),
  //       adLoadCallback: InterstitialAdLoadCallback(
  //         // Called when an ad is successfully received.
  //         onAdLoaded: (ad) {
  //           debugPrint('$ad loaded.');
  //           // Keep a reference to the ad so you can show it later.
  //           _interstitialAd = ad;
  //         },
  //         // Called when an ad request failed.
  //         onAdFailedToLoad: (LoadAdError error) {
  //           debugPrint('InterstitialAd failed to load: $error');
  //         },
  //       ));
  // }

  Future<void> initSDK() async {
    try {
      await _axeptioSdkPlugin.initialize(
        '5fbfa806a0787d3985c6ee5f',
        'google cmp partner program sandbox-en-EU',
        null,
      );

      await _axeptioSdkPlugin.setupUI();

      const EventChannel('axeptio_sdk/events')
          .receiveBroadcastStream()
          .listen((dynamic event) {
        print('Event channel: $event');
      });
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
    return MaterialApp(home: HomePage(axeptioSdk: _axeptioSdkPlugin));
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.axeptioSdk,
  });

  final AxeptioSdk axeptioSdk;

  Future<void> _showMyDialog(BuildContext context) async {
    String userInput = '';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('AlertDialog Title'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Enter axeptio token'),
                TextField(
                  onChanged: (value) {
                    userInput = value;
                  },
                  decoration: const InputDecoration(hintText: 'Axeptio token'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Open on browser'),
              onPressed: () async {
                Navigator.of(context).pop();
                final token = await axeptioSdk.axeptioToken;
                String? url = '';

                if (userInput.isNotEmpty) {
                  url = await axeptioSdk.appendAxeptioTokenURL(
                    "https://google-cmp-partner.axept.io/cmp-for-publishers.html",
                    userInput,
                  );
                } else if (token != null && token.isNotEmpty) {
                  url = await axeptioSdk.appendAxeptioTokenURL(
                    "https://google-cmp-partner.axept.io/cmp-for-publishers.html",
                    token,
                  );
                }

                if (url != null && url.isNotEmpty) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) {
                      return WebViewPage(
                        url: url!,
                      );
                    },
                  );
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return const PreferencesPage();
                  },
                );
              },
              child: const Text(
                'User Defaults',
                style: textStyle,
              ),
            ),
            ElevatedButton(
              style: style,
              onPressed: null,
              child: const Text(
                'Google ad',
                style: textStyle,
              ),
            ),
            ElevatedButton(
              style: clearConsentStyle,
              onPressed: () {
                axeptioSdk.clearConsent();
              },
              child: const Text(
                'Clear consent',
                style: textStyle,
              ),
            ),
            ElevatedButton(
              style: style,
              onPressed: () {
                _showMyDialog(context);
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
