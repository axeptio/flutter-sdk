import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:axeptio_sdk/axeptio_sdk.dart';
import 'vendor_data_service.dart';

/// Production-ready TCF vendor management screen
/// Provides comprehensive testing and analysis tools for vendor consent data
class VendorScreen extends StatefulWidget {
  final AxeptioSdk axeptioSdk;

  const VendorScreen({super.key, required this.axeptioSdk});

  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  static const String _logName = 'VendorScreen';

  late VendorDataService _dataService;
  final _vendorIdController = TextEditingController();
  final _vendorInfoIdController = TextEditingController();
  String _vendorTestResult = 'Enter a vendor ID to test';
  bool _isTestingVendor = false;
  String _tcfAnalysisResult =
      'Tap "Analyze TCF Strings" to compare raw consent data';
  VendorInfo? _selectedVendorInfo;
  bool _isLoadingVendorInfo = false;
  String? _vendorInfoError;

  @override
  void initState() {
    super.initState();
    _dataService = VendorDataService(widget.axeptioSdk);
    _dataService.startAutoRefresh();
  }

  @override
  void dispose() {
    _dataService.dispose();
    _vendorIdController.dispose();
    _vendorInfoIdController.dispose();
    super.dispose();
  }

  Future<void> _testVendor() async {
    final vendorIdText = _vendorIdController.text.trim();
    if (vendorIdText.isEmpty) {
      setState(() {
        _vendorTestResult = 'Please enter a vendor ID';
      });
      return;
    }

    final vendorId = int.tryParse(vendorIdText);
    if (vendorId == null) {
      setState(() {
        _vendorTestResult = 'Invalid vendor ID. Please enter a number.';
      });
      return;
    }

    setState(() {
      _isTestingVendor = true;
    });

    try {
      developer.log(
        'Testing vendor consent for ID: $vendorId',
        name: _logName,
        level: 800, // Info level
      );

      final result = await _dataService.testVendorWithInfo(vendorId);

      setState(() {
        if (result.error != null) {
          _vendorTestResult = 'Error testing vendor $vendorId: ${result.error}';
        } else {
          final consentStatus =
              result.isConsented ? "✅ CONSENTED" : "❌ REFUSED";
          if (result.vendorName != null && result.vendorName!.isNotEmpty) {
            _vendorTestResult =
                'Vendor $vendorId (${result.vendorName}): $consentStatus';
          } else {
            _vendorTestResult = 'Vendor $vendorId: $consentStatus';
          }
        }
        _isTestingVendor = false;
      });
    } catch (error) {
      developer.log(
        'Error testing vendor $vendorId',
        name: _logName,
        error: error,
        level: 1000, // Warning level
      );
      setState(() {
        _vendorTestResult = 'Error testing vendor $vendorId: $error';
        _isTestingVendor = false;
      });
    }

    _vendorIdController.clear();
  }

  Future<void> _analyzeTCFStrings() async {
    setState(() {
      _tcfAnalysisResult = 'Analyzing TCF strings...';
    });

    try {
      developer.log(
        'Starting TCF string analysis',
        name: _logName,
        level: 800, // Info level
      );

      final analysis = await _dataService.analyzeTCFStrings();
      setState(() {
        _tcfAnalysisResult = analysis;
      });
    } catch (error) {
      developer.log(
        'Error analyzing TCF strings',
        name: _logName,
        error: error,
        level: 1000, // Warning level
      );
      setState(() {
        _tcfAnalysisResult = 'Error analyzing TCF strings: $error';
      });
    }
  }

  // ========== GVL Management Actions ==========

  Future<void> _loadGVL() async {
    try {
      developer.log(
        'Loading GVL',
        name: _logName,
        level: 800, // Info level
      );

      final success = await _dataService.loadGVLWithStatus();

      if (success) {
        developer.log(
          'GVL loaded successfully',
          name: _logName,
          level: 800, // Info level
        );
      } else {
        developer.log(
          'Failed to load GVL',
          name: _logName,
          level: 900, // Warning level
        );
      }
    } catch (error) {
      developer.log(
        'Error loading GVL',
        name: _logName,
        error: error,
        level: 1000, // Error level
      );
    }
  }

  Future<void> _unloadGVL() async {
    try {
      developer.log(
        'Unloading GVL',
        name: _logName,
        level: 800, // Info level
      );

      await _dataService.unloadGVL();

      developer.log(
        'GVL unloaded successfully',
        name: _logName,
        level: 800, // Info level
      );
    } catch (error) {
      developer.log(
        'Error unloading GVL',
        name: _logName,
        error: error,
        level: 1000, // Error level
      );
    }
  }

  Future<void> _clearGVL() async {
    try {
      developer.log(
        'Clearing GVL cache',
        name: _logName,
        level: 800, // Info level
      );

      await _dataService.clearGVL();

      developer.log(
        'GVL cache cleared successfully',
        name: _logName,
        level: 800, // Info level
      );
    } catch (error) {
      developer.log(
        'Error clearing GVL cache',
        name: _logName,
        error: error,
        level: 1000, // Error level
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TCF Vendor Management'),
        backgroundColor: const Color.fromRGBO(247, 209, 94, 1),
        elevation: 0,
      ),
      backgroundColor: const Color.fromRGBO(253, 247, 231, 1),
      body: RefreshIndicator(
        onRefresh: () async {
          _dataService.stopAutoRefresh();
          _dataService.startAutoRefresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // GVL Management Dashboard
            _buildGVLManagementDashboard(),

            const SizedBox(height: 16),

            // Summary Dashboard
            _buildSummaryDashboard(),

            const SizedBox(height: 16),

            // Individual Vendor Tester
            _buildVendorTester(),

            const SizedBox(height: 16),

            // Vendor Information Panel
            _buildVendorInfoPanel(),

            const SizedBox(height: 16),

            // TCF Analysis Section
            _buildTCFAnalysisSection(),

            const SizedBox(height: 16),

            // Vendor Data Sections
            _buildVendorDataSections(),

            const SizedBox(height: 16),

            // IABTCF and Axeptio Data
            _buildPreferenceDataSections(),
          ],
        ),
      ),
    );
  }

  Widget _buildGVLManagementDashboard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Global Vendor List (GVL)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<GVLStatusData>(
              stream: _dataService.gvlStatusStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final gvlStatus = snapshot.data!;
                return Column(
                  children: [
                    // Status Row
                    Row(
                      children: [
                        Expanded(child: _buildGVLStatusCard(gvlStatus)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildGVLVersionCard(gvlStatus)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                gvlStatus.isLoading ? null : () => _loadGVL(),
                            icon:
                                gvlStatus.isLoading
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.download),
                            label: Text(
                              gvlStatus.isLoading
                                  ? 'Loading...'
                                  : gvlStatus.isLoaded
                                  ? 'Reload GVL'
                                  : 'Load GVL',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                (!gvlStatus.isLoaded || gvlStatus.isLoading)
                                    ? null
                                    : () => _unloadGVL(),
                            icon: const Icon(Icons.clear),
                            label: const Text('Unload'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                (!gvlStatus.isLoaded || gvlStatus.isLoading)
                                    ? null
                                    : () => _clearGVL(),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Clear Cache'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Error Display
                    if (gvlStatus.error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Error: ${gvlStatus.error}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGVLStatusCard(GVLStatusData gvlStatus) {
    final isLoaded = gvlStatus.isLoaded;
    final color = isLoaded ? Colors.green : Colors.grey;
    final icon = isLoaded ? Icons.check_circle : Icons.radio_button_unchecked;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            'Status',
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isLoaded ? 'LOADED' : 'NOT LOADED',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGVLVersionCard(GVLStatusData gvlStatus) {
    final version = gvlStatus.version ?? 'N/A';
    final color = gvlStatus.isLoaded ? Colors.blue : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            'Version',
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            version,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDashboard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dashboard, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Summary Dashboard',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                StreamBuilder<VendorSummaryData>(
                  stream: _dataService.summaryStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isProcessing) {
                      return const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    return const Icon(Icons.refresh, color: Colors.green);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<VendorSummaryData>(
              stream: _dataService.summaryStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;
                return Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Consented',
                        data.consentedCount.toString(),
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        'Refused',
                        data.refusedCount.toString(),
                        Colors.red,
                        Icons.cancel,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total',
                        data.totalCount.toString(),
                        Colors.blue,
                        Icons.view_list,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            StreamBuilder<VendorDetailsData>(
              stream: _dataService.detailsStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final analysis = snapshot.data!.vendorAnalysis;
                  return Text(
                    'Consent Rate: ${analysis.consentRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          analysis.consentRate > 50
                              ? Colors.green
                              : Colors.orange,
                    ),
                    textAlign: TextAlign.center,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorTester() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.search, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Test Specific Vendor',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vendorIdController,
                    decoration: const InputDecoration(
                      labelText: 'Vendor ID',
                      hintText: 'e.g., 1, 50, 755',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _testVendor(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isTestingVendor ? null : _testVendor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(247, 209, 94, 1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child:
                      _isTestingVendor
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text(
                            'Test',
                            style: TextStyle(color: Colors.black),
                          ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _vendorTestResult,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color:
                      _vendorTestResult.contains('✅')
                          ? Colors.green
                          : _vendorTestResult.contains('❌')
                          ? Colors.red
                          : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorInfoPanel() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Vendor Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Vendor ID Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vendorInfoIdController,
                    decoration: const InputDecoration(
                      labelText: 'Vendor ID for Info',
                      hintText: 'e.g., 755, 50, 123',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _loadVendorInfo(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoadingVendorInfo ? null : _loadVendorInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child:
                      _isLoadingVendorInfo
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Get Info'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Vendor Information Display
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 150, maxHeight: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _buildVendorInfoContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorInfoContent() {
    if (_isLoadingVendorInfo) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Loading vendor information...'),
          ],
        ),
      );
    }

    if (_vendorInfoError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(
              'Error: $_vendorInfoError',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_selectedVendorInfo == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: Colors.grey, size: 48),
            SizedBox(height: 8),
            Text(
              'Enter a vendor ID above to view detailed information',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final vendor = _selectedVendorInfo!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info
          _buildVendorInfoRow('ID:', vendor.id.toString()),
          _buildVendorInfoRow('Name:', vendor.name),
          _buildVendorInfoRow(
            'Consent Status:',
            vendor.consented ? '✅ Consented' : '❌ Refused',
            valueStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: vendor.consented ? Colors.green : Colors.red,
            ),
          ),

          if (vendor.description != null && vendor.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(vendor.description!, style: const TextStyle(fontSize: 11)),
          ],

          // Purposes
          if (vendor.purposes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildVendorInfoRow('Purposes:', vendor.purposes.join(', ')),
          ],

          // Legitimate Interest Purposes
          if (vendor.legitimateInterestPurposes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildVendorInfoRow(
              'Legitimate Interest:',
              vendor.legitimateInterestPurposes.join(', '),
            ),
          ],

          // Special Features
          if (vendor.specialFeatures.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildVendorInfoRow(
              'Special Features:',
              vendor.specialFeatures.join(', '),
            ),
          ],

          // Special Purposes
          if (vendor.specialPurposes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildVendorInfoRow(
              'Special Purposes:',
              vendor.specialPurposes.join(', '),
            ),
          ],

          // Cookie Info
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildVendorInfoRow(
                  'Uses Cookies:',
                  vendor.usesCookies ? 'Yes' : 'No',
                ),
              ),
              Expanded(
                child: _buildVendorInfoRow(
                  'Non-Cookie Access:',
                  vendor.usesNonCookieAccess ? 'Yes' : 'No',
                ),
              ),
            ],
          ),

          if (vendor.cookieMaxAgeSeconds != null) ...[
            const SizedBox(height: 8),
            _buildVendorInfoRow(
              'Cookie Max Age:',
              '${vendor.cookieMaxAgeSeconds} seconds',
            ),
          ],

          // Policy URL
          if (vendor.policyUrl != null && vendor.policyUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildVendorInfoRow('Policy URL:', vendor.policyUrl!),
          ],
        ],
      ),
    );
  }

  Widget _buildVendorInfoRow(
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadVendorInfo() async {
    final vendorIdText = _vendorInfoIdController.text.trim();
    if (vendorIdText.isEmpty) {
      setState(() {
        _vendorInfoError = 'Please enter a vendor ID';
        _selectedVendorInfo = null;
      });
      return;
    }

    final vendorId = int.tryParse(vendorIdText);
    if (vendorId == null) {
      setState(() {
        _vendorInfoError = 'Invalid vendor ID. Please enter a number.';
        _selectedVendorInfo = null;
      });
      return;
    }

    setState(() {
      _isLoadingVendorInfo = true;
      _vendorInfoError = null;
      _selectedVendorInfo = null;
    });

    try {
      developer.log(
        'Loading vendor info for ID: $vendorId',
        name: _logName,
        level: 800, // Info level
      );

      // Try to get vendor info from the enhanced consent data
      final vendorConsentsWithNames =
          await _dataService.getVendorConsentsWithNames();
      final vendorInfo = vendorConsentsWithNames[vendorId];

      if (vendorInfo != null) {
        setState(() {
          _selectedVendorInfo = vendorInfo;
          _isLoadingVendorInfo = false;
          _vendorInfoError = null;
        });
      } else {
        // Fallback: create basic vendor info from available data
        final testResult = await _dataService.testVendorWithInfo(vendorId);
        if (testResult.error == null) {
          final basicVendorInfo = VendorInfo(
            id: vendorId,
            name: testResult.vendorName ?? 'Unknown Vendor',
            consented: testResult.isConsented,
            purposes: [], // Empty as we don't have detailed info
          );

          setState(() {
            _selectedVendorInfo = basicVendorInfo;
            _isLoadingVendorInfo = false;
            _vendorInfoError = null;
          });
        } else {
          setState(() {
            _vendorInfoError =
                'Vendor $vendorId not found or error: ${testResult.error}';
            _isLoadingVendorInfo = false;
          });
        }
      }
    } catch (error) {
      developer.log(
        'Error loading vendor info for ID $vendorId',
        name: _logName,
        error: error,
        level: 1000, // Error level
      );
      setState(() {
        _vendorInfoError = 'Error loading vendor info: $error';
        _isLoadingVendorInfo = false;
      });
    }
  }

  Widget _buildTCFAnalysisSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'TCF String Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _analyzeTCFStrings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Analyze TCF Strings',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _tcfAnalysisResult,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorDataSections() {
    return StreamBuilder<VendorDetailsData>(
      stream: _dataService.detailsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final data = snapshot.data!;

        return Column(
          children: [
            // Consented Vendors
            _buildDataSection(
              'Consented Vendors',
              data.consentedVendors,
              Colors.green,
              Icons.check_circle,
            ),

            const SizedBox(height: 12),

            // Refused Vendors
            _buildDataSection(
              'Refused Vendors',
              data.refusedVendors,
              Colors.red,
              Icons.cancel,
            ),

            const SizedBox(height: 12),

            // All Vendors Preview
            _buildDataSection(
              'All Vendor Consents (Preview)',
              data.allVendorsPreview,
              Colors.blue,
              Icons.view_list,
              height: 200,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreferenceDataSections() {
    return StreamBuilder<VendorDetailsData>(
      stream: _dataService.detailsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;

        return Column(
          children: [
            // IABTCF Data
            if (data.iabtcfData.isNotEmpty)
              _buildPreferenceSection(
                'IABTCF Data',
                data.iabtcfData,
                Colors.purple,
                Icons.security,
              ),

            if (data.iabtcfData.isNotEmpty) const SizedBox(height: 12),

            // Axeptio Data
            if (data.axeptioData.isNotEmpty)
              _buildPreferenceSection(
                'Axeptio Data',
                data.axeptioData,
                Colors.teal,
                Icons.cookie,
              ),
          ],
        );
      },
    );
  }

  Widget _buildDataSection(
    String title,
    String content,
    Color color,
    IconData icon, {
    double? height,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: height ?? 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  content.isEmpty ? 'No data available' : content,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceSection(
    String title,
    Map<String, dynamic> data,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      data.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                              children: [
                                TextSpan(
                                  text: '${entry.key}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: entry.value.toString(),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
