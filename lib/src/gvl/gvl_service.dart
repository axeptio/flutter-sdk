import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/vendor_info.dart';

/// Flutter-native Global Vendor List (GVL) service
/// Handles fetching, parsing, and caching of IAB vendor data
class GVLService {
  static const String _baseUrl = 'https://static.axept.io/gvl';
  static const String _vendorListEndpoint = '/vendor-list.json';
  static const String _cacheKeyGvlData = 'gvl_data';
  static const String _cacheKeyGvlVersion = 'gvl_version';
  static const String _cacheKeyGvlTimestamp = 'gvl_timestamp';
  static const Duration _cacheDuration = Duration(days: 7);

  static GVLService? _instance;
  static GVLService get instance => _instance ??= GVLService._();

  GVLService._();

  Map<int, VendorInfo>? _cachedVendors;
  String? _cachedVersion;
  bool _isLoading = false;

  /// Loads GVL data from cache or remote
  Future<bool> loadGVL({String? gvlVersion}) async {
    if (_isLoading) return false;

    _isLoading = true;
    try {
      // Try cache first if no specific version requested
      if (gvlVersion == null && await _loadFromCache()) {
        return true;
      }

      // Fetch from remote
      return await _fetchFromRemote(gvlVersion);
    } catch (error) {
      developer.log('Error loading GVL', error: error, name: 'GVLService');
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// Checks if GVL data is currently loaded
  bool isGVLLoaded() {
    return _cachedVendors != null && _cachedVendors!.isNotEmpty;
  }

  /// Gets the currently loaded GVL version
  String? getGVLVersion() {
    return _cachedVersion;
  }

  /// Gets vendor name by ID
  String? getVendorName(int vendorId) {
    final vendor = _cachedVendors?[vendorId];
    return vendor?.name;
  }

  /// Gets multiple vendor names by IDs
  Map<int, String> getVendorNames(List<int> vendorIds) {
    final result = <int, String>{};
    if (_cachedVendors == null) return result;

    for (final vendorId in vendorIds) {
      final vendor = _cachedVendors![vendorId];
      if (vendor != null && vendor.name.isNotEmpty) {
        result[vendorId] = vendor.name;
      }
    }
    return result;
  }

  /// Gets vendor information by ID
  VendorInfo? getVendorInfo(int vendorId) {
    return _cachedVendors?[vendorId];
  }

  /// Gets all loaded vendors
  Map<int, VendorInfo> getAllVendors() {
    return Map.from(_cachedVendors ?? <int, VendorInfo>{});
  }

  /// Unloads GVL data from memory
  void unloadGVL() {
    _cachedVendors = null;
    _cachedVersion = null;
  }

  /// Clears GVL cache completely
  Future<void> clearGVL() async {
    unloadGVL();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKeyGvlData);
    await prefs.remove(_cacheKeyGvlVersion);
    await prefs.remove(_cacheKeyGvlTimestamp);
  }

  /// Creates vendor consent information with GVL data
  Map<int, VendorInfo> createVendorConsentsWithNames(Map<int, bool> consents) {
    final result = <int, VendorInfo>{};
    if (_cachedVendors == null) return result;

    for (final entry in consents.entries) {
      final vendorId = entry.key;
      final consented = entry.value;
      final cachedVendor = _cachedVendors![vendorId];

      if (cachedVendor != null) {
        // Use cached vendor data with updated consent status
        result[vendorId] = cachedVendor.copyWith(consented: consented);
      } else {
        // Create basic vendor info if not in GVL
        result[vendorId] = VendorInfo(
          id: vendorId,
          name: 'Vendor $vendorId',
          consented: consented,
          purposes: [],
        );
      }
    }
    return result;
  }

  /// Loads data from local cache
  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKeyGvlData);
      final cachedVersion = prefs.getString(_cacheKeyGvlVersion);
      final timestampMs = prefs.getInt(_cacheKeyGvlTimestamp);

      if (cachedData == null || cachedVersion == null || timestampMs == null) {
        return false;
      }

      // Check if cache is expired
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestampMs);
      if (DateTime.now().difference(cacheTime) > _cacheDuration) {
        return false;
      }

      // Parse cached data
      final Map<String, dynamic> gvlData = json.decode(cachedData);
      _cachedVendors = _parseVendorList(gvlData);
      _cachedVersion = cachedVersion;

      developer.log(
          'Loaded ${_cachedVendors?.length ?? 0} vendors from cache (v$_cachedVersion)',
          name: 'GVLService');
      return true;
    } catch (error) {
      developer.log('Error loading from cache',
          error: error, name: 'GVLService');
      return false;
    }
  }

  /// Fetches data from remote GVL API
  Future<bool> _fetchFromRemote(String? specificVersion) async {
    try {
      String url = _baseUrl + _vendorListEndpoint;
      if (specificVersion != null) {
        url = '$_baseUrl/vendor-list-v$specificVersion.json';
      }

      developer.log('Fetching GVL from $url', name: 'GVLService');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Axeptio-Flutter-SDK/2.0.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        developer.log('HTTP ${response.statusCode} - ${response.reasonPhrase}',
            name: 'GVLService');
        return false;
      }

      final Map<String, dynamic> gvlData = json.decode(response.body);
      _cachedVendors = _parseVendorList(gvlData);
      _cachedVersion = gvlData['gvlSpecificationVersion']?.toString() ??
          gvlData['tcfPolicyVersion']?.toString() ??
          'unknown';

      // Cache the data
      await _saveToCache(response.body, _cachedVersion!);

      developer.log(
          'Loaded ${_cachedVendors?.length ?? 0} vendors from remote (v$_cachedVersion)',
          name: 'GVLService');
      return true;
    } catch (error) {
      developer.log('Error fetching from remote',
          error: error, name: 'GVLService');
      return false;
    }
  }

  /// Parses vendor list JSON into VendorInfo objects
  Map<int, VendorInfo> _parseVendorList(Map<String, dynamic> gvlData) {
    final vendors = <int, VendorInfo>{};

    try {
      final vendorsData = gvlData['vendors'] as Map<String, dynamic>?;
      if (vendorsData == null) return vendors;

      for (final entry in vendorsData.entries) {
        final vendorId = int.tryParse(entry.key);
        if (vendorId == null) continue;

        final vendorData = entry.value as Map<String, dynamic>;

        vendors[vendorId] = VendorInfo(
          id: vendorId,
          name: vendorData['name']?.toString() ?? 'Vendor $vendorId',
          consented: false, // Default, will be updated with actual consent
          description: vendorData['description']?.toString(),
          purposes:
              (vendorData['purposes'] as List<dynamic>?)?.cast<int>() ?? [],
          legitimateInterestPurposes:
              (vendorData['legIntPurposes'] as List<dynamic>?)?.cast<int>() ??
                  [],
          specialFeatures:
              (vendorData['specialFeatures'] as List<dynamic>?)?.cast<int>() ??
                  [],
          specialPurposes:
              (vendorData['specialPurposes'] as List<dynamic>?)?.cast<int>() ??
                  [],
          cookieMaxAgeSeconds: vendorData['cookieMaxAgeSeconds'] as int?,
          usesCookies: vendorData['usesCookies'] as bool? ?? false,
          usesNonCookieAccess:
              vendorData['usesNonCookieAccess'] as bool? ?? false,
          policyUrl: vendorData['policyUrl']?.toString(),
        );
      }
    } catch (error) {
      developer.log('Error parsing vendor list',
          error: error, name: 'GVLService');
    }

    return vendors;
  }

  /// Saves data to local cache
  Future<void> _saveToCache(String rawData, String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKeyGvlData, rawData);
      await prefs.setString(_cacheKeyGvlVersion, version);
      await prefs.setInt(
          _cacheKeyGvlTimestamp, DateTime.now().millisecondsSinceEpoch);
    } catch (error) {
      developer.log('Error saving to cache', error: error, name: 'GVLService');
    }
  }
}
