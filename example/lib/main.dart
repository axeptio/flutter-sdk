import 'package:axeptio_sdk_example/home.dart';
import 'package:flutter/material.dart';

// import 'package:axeptio_sdk/axeptio_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "Axeptio Flutter Demo",
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.axeptioYellowLight),
      useMaterial3: true
    ),
    home: const HomePage(),
  );
}
