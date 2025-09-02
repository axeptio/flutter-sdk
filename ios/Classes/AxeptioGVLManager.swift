import Foundation

/// Manages the Global Vendor List (GVL) data for the Axeptio SDK.
/// Handles downloading, caching, and retrieving vendor information.
class AxeptioGVLManager {
  static let shared = AxeptioGVLManager()
  
  private let gvlUrl = "https://vendor-list.consensu.org/v3/vendor-list.json"
  private let cacheKey = "axeptio_gvl_cache"
  private let cacheVersionKey = "axeptio_gvl_version"
  private let cacheTimestampKey = "axeptio_gvl_timestamp"
  private let cacheTTLDays = 7
  
  private var cachedGVL: [String: Any]?
  private var cachedVendors: [String: [String: Any]]?
  
  private init() {
    loadCachedGVL()
  }
  
  // MARK: - Public Methods
  
  /// Loads the GVL from the server or cache
  func loadGVL(version: String? = nil, completion: @escaping (Bool) -> Void) {
    // Check if we have valid cached data first
    if let cached = cachedGVL, isCacheValid() {
      completion(true)
      return
    }
    
    downloadGVL(version: version, completion: completion)
  }
  
  /// Unloads the GVL from memory but keeps cache
  func unloadGVL() {
    cachedGVL = nil
    cachedVendors = nil
  }
  
  /// Clears all GVL data from cache and memory
  func clearGVL() {
    cachedGVL = nil
    cachedVendors = nil
    UserDefaults.standard.removeObject(forKey: cacheKey)
    UserDefaults.standard.removeObject(forKey: cacheVersionKey)
    UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
  }
  
  /// Gets the name of a vendor by ID
  func getVendorName(_ vendorId: Int) -> String? {
    guard let vendors = getVendors() else { return nil }
    return vendors[String(vendorId)]?["name"] as? String
  }
  
  /// Gets names for multiple vendor IDs
  func getVendorNames(_ vendorIds: [Int]) -> [String: String] {
    var result: [String: String] = [:]
    guard let vendors = getVendors() else { return result }
    
    for vendorId in vendorIds {
      let vendorKey = String(vendorId)
      if let name = vendors[vendorKey]?["name"] as? String {
        result[vendorKey] = name
      }
    }
    
    return result
  }
  
  /// Gets comprehensive vendor information
  func getVendorInfo(_ vendorId: Int) -> [String: Any]? {
    guard let vendors = getVendors() else { return nil }
    return vendors[String(vendorId)]
  }
  
  /// Checks if GVL is loaded in memory
  func isGVLLoaded() -> Bool {
    return cachedGVL != nil
  }
  
  /// Gets the current GVL version
  func getGVLVersion() -> String? {
    return UserDefaults.standard.string(forKey: cacheVersionKey)
  }
  
  // MARK: - Private Methods
  
  private func downloadGVL(version: String?, completion: @escaping (Bool) -> Void) {
    var urlString = gvlUrl
    if let version = version {
      urlString += "?version=\(version)"
    }
    
    guard let url = URL(string: urlString) else {
      completion(false)
      return
    }
    
    let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
      guard let self = self,
            let data = data,
            error == nil,
            let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200 else {
        completion(false)
        return
      }
      
      do {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
          completion(false)
          return
        }
        
        self.processAndCacheGVL(json)
        completion(true)
      } catch {
        print("AxeptioGVLManager: Error parsing GVL JSON: \(error)")
        completion(false)
      }
    }
    
    task.resume()
  }
  
  private func processAndCacheGVL(_ gvl: [String: Any]) {
    cachedGVL = gvl
    
    // Extract and cache vendor information
    if let vendors = gvl["vendors"] as? [String: [String: Any]] {
      cachedVendors = vendors
    }
    
    // Cache to UserDefaults
    if let data = try? JSONSerialization.data(withJSONObject: gvl) {
      UserDefaults.standard.set(data, forKey: cacheKey)
    }
    
    // Cache version and timestamp
    if let version = gvl["vendorListVersion"] as? Int {
      UserDefaults.standard.set(String(version), forKey: cacheVersionKey)
    }
    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
  }
  
  private func loadCachedGVL() {
    guard let data = UserDefaults.standard.data(forKey: cacheKey),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return
    }
    
    if isCacheValid() {
      cachedGVL = json
      if let vendors = json["vendors"] as? [String: [String: Any]] {
        cachedVendors = vendors
      }
    } else {
      // Cache expired, clear it
      clearGVL()
    }
  }
  
  private func isCacheValid() -> Bool {
    let timestamp = UserDefaults.standard.double(forKey: cacheTimestampKey)
    guard timestamp > 0 else { return false }
    
    let cacheDate = Date(timeIntervalSince1970: timestamp)
    let expirationDate = Calendar.current.date(byAdding: .day, value: cacheTTLDays, to: cacheDate) ?? cacheDate
    
    return Date() < expirationDate
  }
  
  private func getVendors() -> [String: [String: Any]]? {
    if cachedVendors != nil {
      return cachedVendors
    }
    
    guard let gvl = cachedGVL,
          let vendors = gvl["vendors"] as? [String: [String: Any]] else {
      return nil
    }
    
    cachedVendors = vendors
    return vendors
  }
}