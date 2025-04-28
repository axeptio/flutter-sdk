import 'dart:io';

import 'package:axeptio_sdk/axeptio_sdk.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> fetchAndShowSharedPreferences(BuildContext context) async {
  final keys = [
    'IABTCF_CmpSdkID',
    'IABTCF_CmpSdkVersion',
    'IABTCF_PolicyVersion',
    'IABTCF_gdprApplies',
    'IABTCF_PublisherCC',
    'IABTCF_PurposeOneTreatment',
    'IABTCF_UseNonStandardTexts',
    'IABTCF_TCString',
    'IABTCF_VendorConsents',
    'IABTCF_VendorLegitimateInterests',
    'IABTCF_PurposeConsents',
    'IABTCF_PurposeLegitimateInterests',
    'IABTCF_SpecialFeaturesOptIns',
    'IABTCF_PublisherRestrictions1',
    'IABTCF_PublisherRestrictions2',
    'IABTCF_PublisherRestrictions3',
    'IABTCF_PublisherRestrictions4',
    'IABTCF_PublisherRestrictions5',
    'IABTCF_PublisherRestrictions6',
    'IABTCF_PublisherRestrictions7',
    'IABTCF_PublisherRestrictions8',
    'IABTCF_PublisherRestrictions9',
    'IABTCF_PublisherRestrictions10',
    'IABTCF_PublisherRestrictions11',
    'IABTCF_PublisherConsent',
    'IABTCF_PublisherLegitimateInterests',
    'IABTCF_PublisherCustomPurposesConsents',
    'IABTCF_PublisherCustomPurposesLegitimateInterests',
    'IABTCF_AddtlConsent',
    'IABTCF_EnableAdvertiserConsentMode',
  ];

  Map<String, dynamic> data = {};

  if (Platform.isAndroid) {
    for (final key in keys) {
      final value = await NativeDefaultPreferences.getDefaultPreference(key);
      if (value != null) {
        data[key] = value;
      }
    }
  } else {
    final sharedPreferences = SharedPreferencesAsync();
    data = await sharedPreferences.getAll();
  }

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Shared Preferences',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...data.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${entry.value}',
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
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
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

class NativeDefaultPreferences {
  static final _axeptioSdkPlugin = AxeptioSdk();

  static Future<dynamic> getDefaultPreference(String key) async {
    try {
      final value = await _axeptioSdkPlugin.getDefaultPreference(key);
      return value;
    } catch (e) {
      // Handle exception...
      return null;
    }
  }
}
