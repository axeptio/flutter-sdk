import 'package:axeptio_sdk/axeptio_sdk.dart';
import 'package:axeptio_sdk/events/event_listener.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AppColors {
  static const Color axeptioYellow = Color(0xFFF7D05E);
  static const Color axeptioYellowLight = Color(0xFFFDF7E7);
  static const Color axeptioRed = Color(0xFFCD615B);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _sdkEvents = "";
  EventListener cmpListener = EventListener();
  late final WebViewController _webViewController = WebViewController();

  double verticalSpace = 16.0;
  double buttonSize = 50.0;

  @override
  void initState() {
    super.initState();

    AxeptioSdk.addEventListener(cmpListener);
  }

  void _showInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController _textController = TextEditingController();
        return AlertDialog(
          title: const Text('Enter axeptio token'),
          content: TextField(
            controller: _textController,
            decoration: const InputDecoration(hintText: 'axeptio token'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String url = 'https://google-cmp-partner.axept.io/cmp-for-publishers.html';
                String updatedUrl = '';
                String userInput = _textController.text;
                if (userInput.isNotEmpty) {
                  // TODO: set update url AxeptioSdk.appendAxeptioTokenURL(url, userInput);
                } else {
                  updatedUrl = url;
                }

                _webViewController.loadRequest(Uri.parse('https://google-cmp-partner.axept.io/cmp-for-publishers.html'));
                _showWebViewModel();
              },
              child: const Text('Open in browser'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')
            ),
          ]
        );
      }
    );
  }

  void _showWebViewModel() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        content: Container(
          child: WebViewWidget(controller: _webViewController)
        )
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold( 
        backgroundColor: AppColors.axeptioYellowLight,
        appBar: AppBar(
          backgroundColor: AppColors.axeptioYellow,
          title: const Text('Axeptio Flutter Demo'),
        ),
        body: Center(
          child: Container(
            constraints: BoxConstraints.expand(width: MediaQuery.of(context).size.width * 0.9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => (),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.axeptioYellow,
                    minimumSize: Size(double.infinity, buttonSize)
                  ),
                  child: const Text('Consent pop up', style: TextStyle(color: Colors.black))
                ),
                SizedBox(height: verticalSpace),
                ElevatedButton(
                  onPressed: () => (),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.axeptioYellow,
                    minimumSize: Size(double.infinity, buttonSize)
                  ),
                  child: const Text('User Defaults', style: TextStyle(color: Colors.black))
                ),
                SizedBox(height: verticalSpace),
                ElevatedButton(
                  onPressed: () => (),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.axeptioYellow,
                    minimumSize: Size(double.infinity, buttonSize)
                  ),
                  child: const Text('Google ad', style: TextStyle(color: Colors.black))
                ),
                SizedBox(height: verticalSpace),
                ElevatedButton(
                  onPressed: () => (),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.axeptioRed,
                    minimumSize: Size(double.infinity, buttonSize)
                  ),
                  child: const Text('Clear consent', style: TextStyle(color: Colors.black))
                ),
                SizedBox(height: verticalSpace),
                ElevatedButton(
                  onPressed: () => _showInputDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.axeptioYellow,
                    minimumSize: Size(double.infinity, buttonSize)
                  ),
                  child: const Text('Show webview with token', style: TextStyle(color: Colors.black))
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}