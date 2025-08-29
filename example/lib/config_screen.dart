import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:axeptio_sdk/axeptio_sdk.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientIdController = TextEditingController();
  final _versionController = TextEditingController();
  final _tokenController = TextEditingController();
  
  AxeptioService _selectedService = AxeptioService.brands;
  bool _hasUnsavedChanges = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfiguration();
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _versionController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _clientIdController.text = prefs.getString('axeptio_client_id') ?? '5fbfa806a0787d3985c6ee5f';
      _versionController.text = prefs.getString('axeptio_version') ?? 'google cmp partner program sandbox-en-EU';
      _tokenController.text = prefs.getString('axeptio_token') ?? '';
      
      final serviceString = prefs.getString('axeptio_service') ?? 'brands';
      _selectedService = serviceString == 'publishers' 
          ? AxeptioService.publishers 
          : AxeptioService.brands;
      
      _isLoading = false;
    });
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('axeptio_client_id', _clientIdController.text.trim());
    await prefs.setString('axeptio_version', _versionController.text.trim());
    await prefs.setString('axeptio_token', _tokenController.text.trim());
    await prefs.setString('axeptio_service', _selectedService == AxeptioService.publishers ? 'publishers' : 'brands');
    await prefs.setBool('axeptio_config_changed', true);

    setState(() {
      _hasUnsavedChanges = false;
    });

    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuration saved! Please restart the app to apply changes.'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
        backgroundColor: const Color.fromRGBO(247, 209, 94, 1),
        actions: [
          if (_hasUnsavedChanges)
            IconButton(
              onPressed: _saveConfiguration,
              icon: const Icon(Icons.save),
              tooltip: 'Save Configuration',
            ),
        ],
      ),
      body: Container(
        color: const Color.fromRGBO(253, 247, 231, 1),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Restart Required Banner
              if (_hasUnsavedChanges)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Configuration changes require app restart to take effect.',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              // Service Type Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Service Type',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<AxeptioService>(
                        segments: const [
                          ButtonSegment(
                            value: AxeptioService.brands,
                            label: Text('Brands'),
                            icon: Icon(Icons.business),
                          ),
                          ButtonSegment(
                            value: AxeptioService.publishers,
                            label: Text('Publishers (TCF)'),
                            icon: Icon(Icons.web),
                          ),
                        ],
                        selected: {_selectedService},
                        onSelectionChanged: (Set<AxeptioService> newSelection) {
                          setState(() {
                            _selectedService = newSelection.first;
                            _onFieldChanged();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Configuration Fields
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SDK Configuration',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Client ID
                      TextFormField(
                        controller: _clientIdController,
                        decoration: const InputDecoration(
                          labelText: 'Client ID',
                          hintText: 'Enter your Axeptio project ID',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Client ID is required';
                          }
                          return null;
                        },
                        onChanged: (_) => _onFieldChanged(),
                      ),

                      const SizedBox(height: 16),

                      // Version
                      TextFormField(
                        controller: _versionController,
                        decoration: const InputDecoration(
                          labelText: 'Cookies Version',
                          hintText: 'Enter the cookies version',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Version is required';
                          }
                          return null;
                        },
                        onChanged: (_) => _onFieldChanged(),
                      ),

                      const SizedBox(height: 16),

                      // Token (optional)
                      TextFormField(
                        controller: _tokenController,
                        decoration: const InputDecoration(
                          labelText: 'Token (Optional)',
                          hintText: 'Enter custom token if needed',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _onFieldChanged(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _hasUnsavedChanges ? _saveConfiguration : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(247, 209, 94, 1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _hasUnsavedChanges ? 'Save Configuration' : 'No Changes',
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),

              const SizedBox(height: 16),

              // Current Configuration Info
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Configuration',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Service: ${_selectedService == AxeptioService.publishers ? "Publishers (TCF)" : "Brands"}'),
                      Text('Client ID: ${_clientIdController.text.isEmpty ? "Not set" : _clientIdController.text}'),
                      Text('Version: ${_versionController.text.isEmpty ? "Not set" : _versionController.text}'),
                      Text('Token: ${_tokenController.text.isEmpty ? "Not set" : "Set (${_tokenController.text.length} chars)"}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}