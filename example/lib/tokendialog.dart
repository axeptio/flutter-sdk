import 'package:axeptio_sdk/axeptio_sdk.dart';
import 'package:axeptio_sdk_example/webview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TokenAppendDialog extends StatelessWidget {

  final AxeptioSdk axeptioSdk;

  const TokenAppendDialog({super.key, required this.axeptioSdk});

  @override
  Widget build(BuildContext context) {
    String userInput = '';

    return AlertDialog(
      title: const Text('Enter axeptio token'),
      content: SingleChildScrollView(
        child: TextField(
          onChanged: (value) {
            userInput = value;
          },
          decoration: const InputDecoration(hintText: 'Axeptio token'),
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
            } else {
              url = "https://google-cmp-partner.axept.io/cmp-for-publishers.html";
            }

            if (url != null && url.isNotEmpty) {
              showDialog(
                context: context,
                barrierLabel: "Close",
                barrierColor: Colors.amber,
                barrierDismissible: true,
                // isScrollControlled: false,
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
  }
}
