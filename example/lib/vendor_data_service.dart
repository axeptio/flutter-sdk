import 'dart:async';
import 'dart:developer' as developer;
import 'package:axeptio_sdk/axeptio_sdk.dart';

/// Production-ready service for managing TCF vendor consent data
/// Provides real-time updates and smart data filtering for UI consumption
class VendorDataService {
  static const int maxDisplayVendors = 30;
  static const Duration refreshInterval = Duration(seconds: 3);
  static const String _logName = 'VendorDataService';

  // Static callback for external refresh triggers (e.g., consent clearing)
  static VendorDataService? _activeInstance;

  final AxeptioSdk _axeptioSdk;
  Timer? _refreshTimer;
  Timer? _processingDelayTimer;
  bool _isProcessing = false;

  // Stream controllers for real-time updates
  final StreamController<VendorSummaryData> _summaryController =
      StreamController.broadcast();
  final StreamController<VendorDetailsData> _detailsController =
      StreamController.broadcast();

  Stream<VendorSummaryData> get summaryStream => _summaryController.stream;
  Stream<VendorDetailsData> get detailsStream => _detailsController.stream;

  VendorDataService(this._axeptioSdk) {
    _activeInstance = this;
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      refreshInterval,
      (_) => _refreshDataWithDelay(),
    );
    // Initial refresh
    _refreshDataWithDelay();
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _processingDelayTimer?.cancel();
  }

  /// Forces an immediate refresh of vendor data (bypasses normal delay)
  /// Useful when external actions require immediate UI updates (e.g., consent clearing)
  void forceRefresh() {
    _processingDelayTimer?.cancel();
    _isProcessing = true;

    // Immediate refresh without delay for external triggers
    Future.delayed(const Duration(milliseconds: 100), () {
      _isProcessing = false;
      _refreshData();
    });
  }

  void _refreshDataWithDelay() {
    _processingDelayTimer?.cancel();
    _isProcessing = true;

    // Add delay to allow consent processing to complete
    _processingDelayTimer = Timer(const Duration(milliseconds: 500), () {
      _isProcessing = false;
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    try {
      // Get vendor consent data
      final vendorConsents = await _axeptioSdk.getVendorConsents();
      final consentedVendors = await _axeptioSdk.getConsentedVendors();
      final refusedVendors = await _axeptioSdk.getRefusedVendors();

      // Get preference data
      final consentData = await _axeptioSdk.getConsentSavedData();
      final debugData = await _axeptioSdk.getConsentDebugInfo();

      // Create summary data
      final summaryData = VendorSummaryData(
        consentedCount: consentedVendors.length,
        refusedCount: refusedVendors.length,
        totalCount: vendorConsents.length,
        isProcessing: _isProcessing,
      );

      // Create detailed data with smart filtering
      final detailsData = VendorDetailsData(
        consentedVendors: _formatVendorList(
          consentedVendors,
          consentedVendors.length,
        ),
        refusedVendors: _formatVendorList(
          refusedVendors,
          refusedVendors.length,
        ),
        allVendorsPreview: _formatAllVendorsPreview(vendorConsents),
        iabtcfData: _extractIABTCFData(consentData ?? {}),
        axeptioData: _extractAxeptioData(consentData ?? {}),
        debugData: debugData ?? {},
        vendorAnalysis: _analyzeVendorData(
          vendorConsents,
          consentedVendors,
          refusedVendors,
        ),
      );

      // Emit updates
      _summaryController.add(summaryData);
      _detailsController.add(detailsData);

      // Log vendor analysis for debugging
      _logVendorAnalysis(vendorConsents, consentedVendors, refusedVendors);
    } catch (error) {
      developer.log(
        'Error refreshing vendor data',
        name: _logName,
        error: error,
        level: 1000, // Warning level
      );
    }
  }

  String _formatVendorList(List<int> vendors, int totalCount) {
    if (vendors.isEmpty) return 'None';

    if (vendors.length <= maxDisplayVendors) {
      return vendors.map((v) => v.toString()).join(', ');
    } else {
      final visible = vendors.take(maxDisplayVendors);
      final remaining = totalCount - maxDisplayVendors;
      return '${visible.join(', ')}\n... and $remaining more';
    }
  }

  String _formatAllVendorsPreview(Map<int, bool> vendorConsents) {
    if (vendorConsents.isEmpty) return 'No vendor consent data available';

    final sortedVendors =
        vendorConsents.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    final preview = sortedVendors
        .take(maxDisplayVendors)
        .map((entry) {
          final status = entry.value ? '✅' : '❌';
          return '${entry.key}: $status';
        })
        .join('\n');

    if (vendorConsents.length > maxDisplayVendors) {
      final remaining = vendorConsents.length - maxDisplayVendors;
      return '$preview\n... and $remaining more vendors';
    }

    return preview;
  }

  Map<String, dynamic> _extractIABTCFData(Map<String, dynamic> allData) {
    final iabtcfData = <String, dynamic>{};
    for (final entry in allData.entries) {
      if (entry.key.startsWith('IABTCF_')) {
        iabtcfData[entry.key] = entry.value;
      }
    }
    return iabtcfData;
  }

  Map<String, dynamic> _extractAxeptioData(Map<String, dynamic> allData) {
    final axeptioData = <String, dynamic>{};
    for (final entry in allData.entries) {
      if (entry.key.startsWith('axeptio_') || entry.key.startsWith('AX_')) {
        axeptioData[entry.key] = entry.value;
      }
    }
    return axeptioData;
  }

  VendorAnalysisData _analyzeVendorData(
    Map<int, bool> allVendors,
    List<int> consentedVendors,
    List<int> refusedVendors,
  ) {
    final allVendorIds = allVendors.keys.toSet();
    final consentedSet = consentedVendors.toSet();
    final refusedSet = refusedVendors.toSet();

    // Find discrepancies
    final inAllButNotInLists = allVendorIds
        .difference(consentedSet)
        .difference(refusedSet);

    final inConsentedButNotInAll = consentedSet.difference(allVendorIds);
    final inRefusedButNotInAll = refusedSet.difference(allVendorIds);

    // Calculate consent rate
    final consentRate =
        allVendors.isNotEmpty
            ? (consentedVendors.length / allVendors.length * 100)
            : 0.0;

    // Get vendor ID ranges
    VendorRangeData? rangeData;
    if (allVendorIds.isNotEmpty) {
      final sortedIds = allVendorIds.toList()..sort();
      rangeData = VendorRangeData(
        minId: sortedIds.first,
        maxId: sortedIds.last,
        totalSpan: sortedIds.last - sortedIds.first + 1,
        actualCount: sortedIds.length,
      );
    }

    return VendorAnalysisData(
      consentRate: consentRate,
      discrepancies: VendorDiscrepancies(
        inAllButNotInLists: inAllButNotInLists.toList()..sort(),
        inConsentedButNotInAll: inConsentedButNotInAll.toList()..sort(),
        inRefusedButNotInAll: inRefusedButNotInAll.toList()..sort(),
      ),
      rangeData: rangeData,
      hasDiscrepancies:
          inAllButNotInLists.isNotEmpty ||
          inConsentedButNotInAll.isNotEmpty ||
          inRefusedButNotInAll.isNotEmpty,
    );
  }

  void _logVendorAnalysis(
    Map<int, bool> allVendors,
    List<int> consentedVendors,
    List<int> refusedVendors,
  ) {
    final timestamp = DateTime.now().toIso8601String().substring(0, 19);
    developer.log(
      'VendorAnalysis [$timestamp] Processing: ${_isProcessing ? "PROCESSING" : "STABLE"} '
      'Total: ${allVendors.length}, Consented: ${consentedVendors.length}, Refused: ${refusedVendors.length}',
      name: _logName,
      level: 800, // Info level
    );

    // Check for the 25vs24 issue mentioned in iOS sample
    if (allVendors.length == 24 || consentedVendors.length == 24) {
      developer.log(
        'POTENTIAL 25vs24 ISSUE DETECTED',
        name: _logName,
        level: 900, // Warning level
      );
    }
  }

  Future<bool> testVendorConsent(int vendorId) async {
    try {
      return await _axeptioSdk.isVendorConsented(vendorId);
    } catch (error) {
      developer.log(
        'Error testing vendor $vendorId',
        name: _logName,
        error: error,
        level: 1000, // Warning level
      );
      return false;
    }
  }

  Future<String> analyzeTCFStrings() async {
    try {
      final consentData = await _axeptioSdk.getConsentSavedData() ?? {};

      final tcfString = consentData['IABTCF_TCString'] ?? 'Not found';
      final vendorConsents =
          consentData['IABTCF_VendorConsents'] ?? 'Not found';
      final gdprApplies = consentData['IABTCF_gdprApplies'];
      final policyVersion = consentData['IABTCF_PolicyVersion'];

      var analysis = '🔍 TCF String Analysis:\n\n';
      analysis += '📊 Basic Info:\n';
      analysis += '• GDPR Applies: ${gdprApplies ?? "Not set"}\n';
      analysis += '• Policy Version: ${policyVersion ?? "Not set"}\n';
      analysis +=
          '• TC String Length: ${tcfString.toString().length} chars\n\n';

      analysis += '🏪 Vendor Consents String:\n';
      if (vendorConsents != 'Not found') {
        final vcString = vendorConsents.toString();
        analysis += '• Length: ${vcString.length} chars\n';
        analysis +=
            '• First 50 chars: ${vcString.length > 50 ? vcString.substring(0, 50) : vcString}...\n';

        // Count set bits for binary strings
        if (vcString.contains('1') || vcString.contains('0')) {
          final setBits = vcString.split('').where((c) => c == '1').length;
          analysis += '• Set bits (consented): $setBits\n';
        }
      } else {
        analysis += '• ⚠️ IABTCF_VendorConsents not found!\n';
      }

      // Compare with API results
      final apiVendorConsents = await _axeptioSdk.getVendorConsents();
      final apiConsentedVendors = await _axeptioSdk.getConsentedVendors();

      analysis += '\n🔗 API vs TCF Comparison:\n';
      analysis += '• API Total Vendors: ${apiVendorConsents.length}\n';
      analysis += '• API Consented Vendors: ${apiConsentedVendors.length}\n';

      analysis += '\n🐛 Debug Info:\n';
      analysis += '• Timestamp: ${DateTime.now()}\n';
      analysis +=
          '• Auto-refresh: ${_refreshTimer?.isActive == true ? "Active" : "Inactive"}\n';

      return analysis;
    } catch (error) {
      return 'Error analyzing TCF strings: $error';
    }
  }

  void dispose() {
    stopAutoRefresh();
    _summaryController.close();
    _detailsController.close();

    // Clear active instance if this is the current one
    if (_activeInstance == this) {
      _activeInstance = null;
    }
  }

  /// Triggers immediate refresh on the currently active VendorDataService instance
  /// Used by external components (e.g., Clear Consent button) to force UI updates
  static void triggerGlobalRefresh() {
    _activeInstance?.forceRefresh();
  }
}

// Data classes
class VendorSummaryData {
  final int consentedCount;
  final int refusedCount;
  final int totalCount;
  final bool isProcessing;

  VendorSummaryData({
    required this.consentedCount,
    required this.refusedCount,
    required this.totalCount,
    required this.isProcessing,
  });
}

class VendorDetailsData {
  final String consentedVendors;
  final String refusedVendors;
  final String allVendorsPreview;
  final Map<String, dynamic> iabtcfData;
  final Map<String, dynamic> axeptioData;
  final Map<String, dynamic> debugData;
  final VendorAnalysisData vendorAnalysis;

  VendorDetailsData({
    required this.consentedVendors,
    required this.refusedVendors,
    required this.allVendorsPreview,
    required this.iabtcfData,
    required this.axeptioData,
    required this.debugData,
    required this.vendorAnalysis,
  });
}

class VendorAnalysisData {
  final double consentRate;
  final VendorDiscrepancies discrepancies;
  final VendorRangeData? rangeData;
  final bool hasDiscrepancies;

  VendorAnalysisData({
    required this.consentRate,
    required this.discrepancies,
    this.rangeData,
    required this.hasDiscrepancies,
  });
}

class VendorDiscrepancies {
  final List<int> inAllButNotInLists;
  final List<int> inConsentedButNotInAll;
  final List<int> inRefusedButNotInAll;

  VendorDiscrepancies({
    required this.inAllButNotInLists,
    required this.inConsentedButNotInAll,
    required this.inRefusedButNotInAll,
  });
}

class VendorRangeData {
  final int minId;
  final int maxId;
  final int totalSpan;
  final int actualCount;

  VendorRangeData({
    required this.minId,
    required this.maxId,
    required this.totalSpan,
    required this.actualCount,
  });
}
