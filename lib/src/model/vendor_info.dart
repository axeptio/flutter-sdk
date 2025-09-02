/// Represents comprehensive information about a TCF vendor.
///
/// This class encapsulates all relevant information about a vendor from the
/// Global Vendor List (GVL), including consent status and vendor details.
class VendorInfo {
  /// The unique vendor ID as defined in the IAB Global Vendor List.
  final int id;

  /// The human-readable name of the vendor.
  final String name;

  /// Whether the user has consented to this vendor's data processing.
  final bool consented;

  /// Optional description of the vendor's data processing activities.
  final String? description;

  /// List of purpose IDs that this vendor processes data for.
  final List<int> purposes;

  /// Optional list of legitimate interest purpose IDs.
  final List<int> legitimateInterestPurposes;

  /// Optional list of special features this vendor uses.
  final List<int> specialFeatures;

  /// Optional list of special purposes this vendor processes data for.
  final List<int> specialPurposes;

  /// Maximum age of cookies in seconds, if the vendor uses cookies.
  final int? cookieMaxAgeSeconds;

  /// Whether this vendor uses cookies for data storage.
  final bool usesCookies;

  /// Whether this vendor uses non-cookie methods for data storage.
  final bool usesNonCookieAccess;

  /// Privacy policy URL for this vendor.
  final String? policyUrl;

  /// Creates a new [VendorInfo] instance.
  const VendorInfo({
    required this.id,
    required this.name,
    required this.consented,
    this.description,
    required this.purposes,
    this.legitimateInterestPurposes = const [],
    this.specialFeatures = const [],
    this.specialPurposes = const [],
    this.cookieMaxAgeSeconds,
    this.usesCookies = false,
    this.usesNonCookieAccess = false,
    this.policyUrl,
  });

  /// Creates a [VendorInfo] instance from a JSON map.
  ///
  /// The [json] parameter should contain vendor data from the GVL API
  /// and the [consented] parameter indicates the user's consent status.
  factory VendorInfo.fromJson(Map<String, dynamic> json, bool consented) {
    return VendorInfo(
      id: json['id'] is num ? (json['id'] as num).toInt() : json['id'] as int,
      name: json['name'] as String,
      consented: consented,
      description: json['description'] as String?,
      purposes: (json['purposes'] as List<dynamic>?)?.cast<int>() ?? [],
      legitimateInterestPurposes:
          (json['legIntPurposes'] as List<dynamic>?)?.cast<int>() ?? [],
      specialFeatures:
          (json['specialFeatures'] as List<dynamic>?)?.cast<int>() ?? [],
      specialPurposes:
          (json['specialPurposes'] as List<dynamic>?)?.cast<int>() ?? [],
      cookieMaxAgeSeconds: json['cookieMaxAgeSeconds'] as int?,
      usesCookies: json['usesCookies'] as bool? ?? false,
      usesNonCookieAccess: json['usesNonCookieAccess'] as bool? ?? false,
      policyUrl: json['policyUrl'] as String?,
    );
  }

  /// Converts this [VendorInfo] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'consented': consented,
      'description': description,
      'purposes': purposes,
      'legIntPurposes': legitimateInterestPurposes,
      'specialFeatures': specialFeatures,
      'specialPurposes': specialPurposes,
      'cookieMaxAgeSeconds': cookieMaxAgeSeconds,
      'usesCookies': usesCookies,
      'usesNonCookieAccess': usesNonCookieAccess,
      'policyUrl': policyUrl,
    };
  }

  /// Returns a copy of this [VendorInfo] with the given fields replaced.
  VendorInfo copyWith({
    int? id,
    String? name,
    bool? consented,
    String? description,
    List<int>? purposes,
    List<int>? legitimateInterestPurposes,
    List<int>? specialFeatures,
    List<int>? specialPurposes,
    int? cookieMaxAgeSeconds,
    bool? usesCookies,
    bool? usesNonCookieAccess,
    String? policyUrl,
  }) {
    return VendorInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      consented: consented ?? this.consented,
      description: description ?? this.description,
      purposes: purposes ?? this.purposes,
      legitimateInterestPurposes:
          legitimateInterestPurposes ?? this.legitimateInterestPurposes,
      specialFeatures: specialFeatures ?? this.specialFeatures,
      specialPurposes: specialPurposes ?? this.specialPurposes,
      cookieMaxAgeSeconds: cookieMaxAgeSeconds ?? this.cookieMaxAgeSeconds,
      usesCookies: usesCookies ?? this.usesCookies,
      usesNonCookieAccess: usesNonCookieAccess ?? this.usesNonCookieAccess,
      policyUrl: policyUrl ?? this.policyUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          consented == other.consented &&
          description == other.description &&
          purposes.toString() == other.purposes.toString() &&
          legitimateInterestPurposes.toString() ==
              other.legitimateInterestPurposes.toString() &&
          specialFeatures.toString() == other.specialFeatures.toString() &&
          specialPurposes.toString() == other.specialPurposes.toString() &&
          cookieMaxAgeSeconds == other.cookieMaxAgeSeconds &&
          usesCookies == other.usesCookies &&
          usesNonCookieAccess == other.usesNonCookieAccess &&
          policyUrl == other.policyUrl;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      consented.hashCode ^
      description.hashCode ^
      purposes.hashCode ^
      legitimateInterestPurposes.hashCode ^
      specialFeatures.hashCode ^
      specialPurposes.hashCode ^
      cookieMaxAgeSeconds.hashCode ^
      usesCookies.hashCode ^
      usesNonCookieAccess.hashCode ^
      policyUrl.hashCode;

  @override
  String toString() {
    return 'VendorInfo{id: $id, name: $name, consented: $consented, '
        'purposes: $purposes, description: $description}';
  }
}