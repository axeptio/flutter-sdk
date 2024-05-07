import 'package:axeptio_sdk_example/tcffields.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: fetchRawValues(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return ListView(
            children: snapshot.data!
                .map(
                  (field) => ListTile(
                    title: Text(field),
                  ),
                )
                .toList(),
          );
        }
      },
    );
  }

  Future<List<String>> fetchRawValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return TCFFields.values
        .compactMap((field) => prefs.getString(field.rawValue));
  }
}

extension IterableExtension<T> on Iterable<T> {
  List<R> compactMap<R>(R? Function(T) transform) {
    return map(transform)
        .where((element) => element != null)
        .toList()
        .cast<R>();
  }
}
