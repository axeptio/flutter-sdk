import 'package:flutter/material.dart';

enum TCFFields {
  cmpSdkId,
  cmpSdkVersion,
  gdprApplies,
  policyVersion,
  publisherCC,
  publisherConsent,
  publisherCustomPurposesConsents,
  publisherCustomPurposesLegitimateInterests,
  publisherLegitimateInterests,
  publisherRestrictions,
  purposeConsents,
  purposeLegitimateInterests,
  purposeOneTreatment,
  specialFeaturesOptIns,
  tcString,
  useNonStandardTexts,
  vendorConsents,
  vendorLegitimateInterests,
  addtlConsent,
}

extension TCFFieldsExtension on TCFFields {
  String get rawValue {
    switch (this) {
      case TCFFields.cmpSdkId:
        return 'IABTCF_CmpSdkID';
      case TCFFields.cmpSdkVersion:
        return 'IABTCF_CmpSdkVersion';
      case TCFFields.gdprApplies:
        return 'IABTCF_gdprApplies';
      case TCFFields.policyVersion:
        return 'IABCTF_PolicyVersion';
      case TCFFields.publisherCC:
        return 'IABTCF_PublisherCC';
      case TCFFields.publisherConsent:
        return 'IABTCF_PublisherConsent';
      case TCFFields.publisherCustomPurposesConsents:
        return 'IABTCF_PublisherCustomPurposesConsents';
      case TCFFields.publisherCustomPurposesLegitimateInterests:
        return 'IABTCF_PublisherCustomPurposesLegitimateInterests';
      case TCFFields.publisherLegitimateInterests:
        return 'IABTCF_PublisherLegitimateInterests';
      case TCFFields.publisherRestrictions:
        return 'IABTCF_PublisherRestrictions';
      case TCFFields.purposeConsents:
        return 'IABTCF_PurposeConsents';
      case TCFFields.purposeLegitimateInterests:
        return 'IABTCF_PurposeLegitimateInterests';
      case TCFFields.purposeOneTreatment:
        return 'IABTCF_PurposeOneTreatment';
      case TCFFields.specialFeaturesOptIns:
        return 'IABTCF_SpecialFeaturesOptIns';
      case TCFFields.tcString:
        return 'IABTCF_TCString';
      case TCFFields.useNonStandardTexts:
        return 'IABTCF_UseNonStandardTexts';
      case TCFFields.vendorConsents:
        return 'IABTCF_VendorConsents';
      case TCFFields.vendorLegitimateInterests:
        return 'IABTCF_VendorLegitimateInterests';
      case TCFFields.addtlConsent:
        return 'IABTCF_AddtlConsent';
    }
  }
}

class TCFFieldsList extends StatelessWidget {
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
    // List to hold the asynchronous operations
    List<Future<String>> futures = [];

    // Mapping TCFFields to asynchronous operations
    for (var field in TCFFields.values) {
      futures.add(getAsyncRawValue(field));
    }

    // Waiting for all asynchronous operations to complete
    List<String> rawValues = await Future.wait(futures);
    return rawValues;
  }

  Future<String> getAsyncRawValue(TCFFields field) async {
    // Simulated asynchronous value
    return field.rawValue;
  }
}
