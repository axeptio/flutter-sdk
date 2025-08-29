import 'package:flutter/material.dart';

Future<void> showPreferences({
  required BuildContext context,
  required Map<String, dynamic> data,
}) async {
  // Filter to only show IABTCF_ and Axeptio-related values
  final filteredData = <String, dynamic>{};
  for (final entry in data.entries) {
    if (entry.key.startsWith('IABTCF_') ||
        entry.key.startsWith('axeptio_') ||
        entry.key.startsWith('AX_')) {
      filteredData[entry.key] = entry.value;
    }
  }
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Consent Values',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              tooltip: 'Close',
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (filteredData.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No IABTCF or Axeptio consent values found.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...(filteredData.entries.toList()
                      ..sort((a, b) => a.key.compareTo(b.key)))
                    .map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SelectableText(
                              '${entry.value}',
                              style: const TextStyle(
                                color: Colors.black87,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Divider(),
                          ],
                        ),
                      );
                    }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
