import 'dart:async';
import 'dart:developer' as developer;
import 'package:axeptio_sdk/axeptio_sdk.dart';

/// Production-ready service for managing TCF vendor consent data with GVL integration
/// Provides real-time updates, smart data filtering, and vendor name resolution
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
  final StreamController<GVLStatusData> _gvlStatusController =
      StreamController.broadcast();

  Stream<VendorSummaryData> get summaryStream => _summaryController.stream;
  Stream<VendorDetailsData> get detailsStream => _detailsController.stream;
  Stream<GVLStatusData> get gvlStatusStream => _gvlStatusController.stream;

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
      // Update GVL status first
      await _updateGVLStatus();

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

      // Create detailed data with smart filtering (with async formatting)
      final consentedVendorsFormatted = await _formatVendorList(
        consentedVendors,
        consentedVendors.length,
      );
      final refusedVendorsFormatted = await _formatVendorList(
        refusedVendors,
        refusedVendors.length,
      );
      final allVendorsPreviewFormatted = await _formatAllVendorsPreview(
        vendorConsents,
      );

      final detailsData = VendorDetailsData(
        consentedVendors: consentedVendorsFormatted,
        refusedVendors: refusedVendorsFormatted,
        allVendorsPreview: allVendorsPreviewFormatted,
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

  Future<String> _formatVendorList(List<int> vendors, int totalCount) async {
    if (vendors.isEmpty) return 'None';

    try {
      // Try to get vendor names if GVL is loaded
      final vendorNames = await getVendorNamesForIds(
        vendors.take(maxDisplayVendors).toList(),
      );

      List<String> formattedVendors = [];
      for (int vendorId in vendors.take(maxDisplayVendors)) {
        final name = vendorNames[vendorId];
        if (name != null && name.isNotEmpty) {
          formattedVendors.add('$vendorId ($name)');
        } else {
          formattedVendors.add(vendorId.toString());
        }
      }

      if (vendors.length <= maxDisplayVendors) {
        return formattedVendors.join(', ');
      } else {
        final remaining = totalCount - maxDisplayVendors;
        return '${formattedVendors.join(', ')}\n... and $remaining more';
      }
    } catch (error) {
      // Fallback to ID-only format if name resolution fails
      if (vendors.length <= maxDisplayVendors) {
        return vendors.map((v) => v.toString()).join(', ');
      } else {
        final visible = vendors.take(maxDisplayVendors);
        final remaining = totalCount - maxDisplayVendors;
        return '${visible.join(', ')}\n... and $remaining more';
      }
    }
  }

  Future<String> _formatAllVendorsPreview(Map<int, bool> vendorConsents) async {
    if (vendorConsents.isEmpty) return 'No vendor consent data available';

    final sortedVendors =
        vendorConsents.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    try {
      // Try to get vendor names for preview vendors
      final previewVendors = sortedVendors.take(maxDisplayVendors).toList();
      final vendorIds = previewVendors.map((entry) => entry.key).toList();
      final vendorNames = await getVendorNamesForIds(vendorIds);

      final preview = previewVendors
          .map((entry) {
            final status = entry.value ? '✅' : '❌';
            final name = vendorNames[entry.key];
            if (name != null && name.isNotEmpty) {
              return '${entry.key} ($name): $status';
            } else {
              return '${entry.key}: $status';
            }
          })
          .join('\n');

      if (vendorConsents.length > maxDisplayVendors) {
        final remaining = vendorConsents.length - maxDisplayVendors;
        return '$preview\n... and $remaining more vendors';
      }

      return preview;
    } catch (error) {
      // Fallback to ID-only format
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

      var analysis = '🔍 Enhanced TCF String Analysis with GVL:\n\n';

      // ========== GVL Status Section ==========
      try {
        final isGVLLoaded = await _axeptioSdk.isGVLLoaded();
        final gvlVersion =
            isGVLLoaded ? await _axeptioSdk.getGVLVersion() : null;

        analysis += '🌐 GVL Status:\n';
        analysis += '• GVL Loaded: ${isGVLLoaded ? "✅ Yes" : "❌ No"}\n';
        if (isGVLLoaded && gvlVersion != null) {
          analysis += '• GVL Version: $gvlVersion\n';
        }
        analysis += '\n';
      } catch (error) {
        analysis += '🌐 GVL Status: ⚠️ Error checking GVL status\n\n';
      }

      // ========== Basic TCF Info ==========
      analysis += '📊 Basic TCF Info:\n';
      analysis += '• GDPR Applies: ${gdprApplies ?? "Not set"}\n';
      analysis += '• Policy Version: ${policyVersion ?? "Not set"}\n';
      analysis +=
          '• TC String Length: ${tcfString.toString().length} chars\n\n';

      // ========== Vendor Consents String ==========
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

      // ========== API vs TCF Comparison with GVL Names ==========
      final apiVendorConsents = await _axeptioSdk.getVendorConsents();
      final apiConsentedVendors = await _axeptioSdk.getConsentedVendors();

      analysis += '\n🔗 API vs TCF Comparison:\n';
      analysis += '• API Total Vendors: ${apiVendorConsents.length}\n';
      analysis += '• API Consented Vendors: ${apiConsentedVendors.length}\n';

      // ========== Enhanced Vendor Analysis with Names ==========
      try {
        // Try to get vendor names for enhanced analysis
        final vendorNamesMap = await getVendorNamesForIds(
          apiConsentedVendors.take(10).toList(),
        );

        if (vendorNamesMap.isNotEmpty) {
          analysis += '\n👥 Sample Consented Vendors (with names):\n';
          int count = 0;
          for (final vendorId in apiConsentedVendors.take(10)) {
            final name = vendorNamesMap[vendorId];
            if (name != null && name.isNotEmpty) {
              analysis += '• $vendorId: $name\n';
              count++;
            } else {
              analysis += '• $vendorId: Name not available\n';
            }
          }

          if (apiConsentedVendors.length > 10) {
            analysis +=
                '... and ${apiConsentedVendors.length - 10} more vendors\n';
          }

          // Calculate name resolution rate
          final nameResolutionRate =
              vendorNamesMap.length /
              (apiConsentedVendors.take(10).length) *
              100;
          analysis +=
              '\n📈 Name Resolution Rate: ${nameResolutionRate.toStringAsFixed(1)}% (${vendorNamesMap.length}/10 sample)\n';
        } else {
          analysis +=
              '\n👥 Vendor Names: ⚠️ No vendor names available (GVL may not be loaded)\n';
        }
      } catch (error) {
        analysis +=
            '\n👥 Vendor Names: ⚠️ Error retrieving vendor names: $error\n';
      }

      // ========== GVL vs TCF Data Consistency Check ==========
      try {
        final vendorConsentsWithNames = await getVendorConsentsWithNames();

        if (vendorConsentsWithNames.isNotEmpty) {
          analysis += '\n🔍 GVL vs TCF Consistency:\n';
          analysis +=
              '• GVL Enhanced Data: ${vendorConsentsWithNames.length} vendors with detailed info\n';

          // Check for vendors with purposes data
          final vendorsWithPurposes =
              vendorConsentsWithNames.values
                  .where((v) => v.purposes.isNotEmpty)
                  .length;
          analysis += '• Vendors with Purpose Data: $vendorsWithPurposes\n';

          // Check for vendors with descriptions
          final vendorsWithDescriptions =
              vendorConsentsWithNames.values
                  .where(
                    (v) => v.description != null && v.description!.isNotEmpty,
                  )
                  .length;
          analysis += '• Vendors with Descriptions: $vendorsWithDescriptions\n';

          // Sample vendor details
          final sampleVendor = vendorConsentsWithNames.values.first;
          analysis += '\n📋 Sample Vendor Details:\n';
          analysis += '• ID: ${sampleVendor.id}, Name: ${sampleVendor.name}\n';
          analysis += '• Consented: ${sampleVendor.consented}\n';
          analysis += '• Purposes: ${sampleVendor.purposes.join(", ")}\n';
          analysis += '• Uses Cookies: ${sampleVendor.usesCookies}\n';
        }
      } catch (error) {
        analysis += '\n🔍 GVL Enhanced Data: ⚠️ Error retrieving: $error\n';
      }

      // ========== Debug Info ==========
      analysis += '\n🐛 Debug Info:\n';
      analysis += '• Timestamp: ${DateTime.now()}\n';
      analysis +=
          '• Auto-refresh: ${_refreshTimer?.isActive == true ? "Active" : "Inactive"}\n';

      // ========== Recommendations ==========
      analysis += '\n💡 Recommendations:\n';

      try {
        final isGVLLoaded = await _axeptioSdk.isGVLLoaded();
        if (!isGVLLoaded) {
          analysis +=
              '• Load GVL to enable vendor name resolution and detailed vendor info\n';
          analysis +=
              '• GVL provides vendor descriptions, purposes, and policy URLs\n';
        } else {
          analysis +=
              '• GVL is loaded - vendor names and detailed info should be available\n';
          analysis +=
              '• Use the Vendor Information panel to explore specific vendor details\n';
        }
      } catch (error) {
        analysis += '• Unable to check GVL status for recommendations\n';
      }

      if (apiVendorConsents.length !=
          apiConsentedVendors.length +
              (apiVendorConsents.values
                  .where((consented) => !consented)
                  .length)) {
        analysis +=
            '• Check for potential data inconsistencies in vendor consent tracking\n';
      }

      return analysis;
    } catch (error) {
      return 'Error analyzing TCF strings with GVL integration: $error';
    }
  }

  // ========== GVL Integration Methods ==========

  /// Updates GVL status and emits to stream
  Future<void> _updateGVLStatus() async {
    try {
      final isLoaded = await _axeptioSdk.isGVLLoaded();
      final version = isLoaded ? await _axeptioSdk.getGVLVersion() : null;

      final statusData = GVLStatusData(
        isLoaded: isLoaded,
        version: version,
        lastUpdate: DateTime.now(),
        isLoading: false,
        error: null,
      );

      _gvlStatusController.add(statusData);
    } catch (error) {
      _gvlStatusController.add(
        GVLStatusData(
          isLoaded: false,
          version: null,
          lastUpdate: DateTime.now(),
          isLoading: false,
          error: error.toString(),
        ),
      );
    }
  }

  /// Loads GVL with UI feedback
  Future<bool> loadGVLWithStatus({String? gvlVersion}) async {
    try {
      // Emit loading state
      _gvlStatusController.add(
        GVLStatusData(
          isLoaded: false,
          version: null,
          lastUpdate: DateTime.now(),
          isLoading: true,
          error: null,
        ),
      );

      final success = await _axeptioSdk.loadGVL(gvlVersion: gvlVersion);

      if (success) {
        // Update status after successful load
        await _updateGVLStatus();
        // Trigger data refresh to update vendor names
        _refreshDataWithDelay();
      } else {
        _gvlStatusController.add(
          GVLStatusData(
            isLoaded: false,
            version: null,
            lastUpdate: DateTime.now(),
            isLoading: false,
            error: 'Failed to load GVL',
          ),
        );
      }

      return success;
    } catch (error) {
      _gvlStatusController.add(
        GVLStatusData(
          isLoaded: false,
          version: null,
          lastUpdate: DateTime.now(),
          isLoading: false,
          error: error.toString(),
        ),
      );
      return false;
    }
  }

  /// Unloads GVL
  Future<void> unloadGVL() async {
    try {
      await _axeptioSdk.unloadGVL();
      await _updateGVLStatus();
      // Refresh data to remove vendor names
      _refreshDataWithDelay();
    } catch (error) {
      developer.log(
        'Error unloading GVL',
        name: _logName,
        error: error,
        level: 1000,
      );
    }
  }

  /// Clears GVL cache
  Future<void> clearGVL() async {
    try {
      await _axeptioSdk.clearGVL();
      await _updateGVLStatus();
      // Refresh data to remove vendor names
      _refreshDataWithDelay();
    } catch (error) {
      developer.log(
        'Error clearing GVL',
        name: _logName,
        error: error,
        level: 1000,
      );
    }
  }

  /// Gets vendor name for a single ID
  Future<String?> getVendorName(int vendorId) async {
    try {
      return await _axeptioSdk.getVendorName(vendorId);
    } catch (error) {
      developer.log(
        'Error getting vendor name for ID $vendorId',
        name: _logName,
        error: error,
        level: 1000,
      );
      return null;
    }
  }

  /// Gets vendor names for multiple IDs
  Future<Map<int, String>> getVendorNamesForIds(List<int> vendorIds) async {
    try {
      return await _axeptioSdk.getVendorNames(vendorIds);
    } catch (error) {
      developer.log(
        'Error getting vendor names for IDs $vendorIds',
        name: _logName,
        error: error,
        level: 1000,
      );
      return {};
    }
  }

  /// Gets vendor consents with names
  Future<Map<int, VendorInfo>> getVendorConsentsWithNames() async {
    try {
      return await _axeptioSdk.getVendorConsentsWithNames();
    } catch (error) {
      developer.log(
        'Error getting vendor consents with names',
        name: _logName,
        error: error,
        level: 1000,
      );
      return {};
    }
  }

  /// Tests vendor consent with enhanced information
  Future<VendorTestResult> testVendorWithInfo(int vendorId) async {
    try {
      final isConsented = await _axeptioSdk.isVendorConsented(vendorId);
      final vendorName = await getVendorName(vendorId);

      return VendorTestResult(
        vendorId: vendorId,
        vendorName: vendorName,
        isConsented: isConsented,
        error: null,
      );
    } catch (error) {
      return VendorTestResult(
        vendorId: vendorId,
        vendorName: null,
        isConsented: false,
        error: error.toString(),
      );
    }
  }

  void dispose() {
    stopAutoRefresh();
    _summaryController.close();
    _detailsController.close();
    _gvlStatusController.close();

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

// ========== GVL-Related Data Classes ==========

class GVLStatusData {
  final bool isLoaded;
  final String? version;
  final DateTime lastUpdate;
  final bool isLoading;
  final String? error;

  GVLStatusData({
    required this.isLoaded,
    this.version,
    required this.lastUpdate,
    required this.isLoading,
    this.error,
  });
}

class VendorTestResult {
  final int vendorId;
  final String? vendorName;
  final bool isConsented;
  final String? error;

  VendorTestResult({
    required this.vendorId,
    this.vendorName,
    required this.isConsented,
    this.error,
  });
}
