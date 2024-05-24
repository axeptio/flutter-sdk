import 'package:axeptio_sdk/axeptio_sdk.dart';
import 'package:axeptio_sdk_example/webview.dart';
import 'package:flutter/material.dart';

class TokenAppendDialog extends StatelessWidget {
  final AxeptioSdk axeptioSdk;

  const TokenAppendDialog({super.key, required this.axeptioSdk});

  @override
  Widget build(BuildContext context) {
    String userInput = '';

    return AlertDialog(
      backgroundColor: const Color.fromRGBO(253, 247, 231, 1),
      title: const Text('Enter axeptio token'),
      content: SingleChildScrollView(
        child: TextField(
          onChanged: (value) {
            userInput = value;
          },
          cursorColor: Colors.black,
          decoration: const InputDecoration(
            hintText: 'Axeptio token',
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            focusColor: Colors.black,
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
          ),
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
              url =
                  "https://google-cmp-partner.axept.io/cmp-for-publishers.html";
            }

            if (url != null && url.isNotEmpty) {
              showDialog(
                // ignore: use_build_context_synchronously
                context: context,
                barrierLabel: "Close",
                barrierColor: Colors.black,
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
          style: TextButton.styleFrom(
            foregroundColor: const Color.fromRGBO(205, 97, 91, 1),
          ),
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
