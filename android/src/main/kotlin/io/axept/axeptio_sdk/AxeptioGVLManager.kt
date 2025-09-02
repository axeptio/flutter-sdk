package io.axept.axeptio_sdk

import android.content.Context
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import kotlin.collections.HashMap

/**
 * Manages the Global Vendor List (GVL) data for the Axeptio SDK.
 * Handles downloading, caching, and retrieving vendor information.
 */
object AxeptioGVLManager {
    private const val GVL_URL = "https://vendor-list.consensu.org/v3/vendor-list.json"
    private const val PREFS_NAME = "axeptio_gvl_prefs"
    private const val CACHE_KEY = "axeptio_gvl_cache"
    private const val CACHE_VERSION_KEY = "axeptio_gvl_version"
    private const val CACHE_TIMESTAMP_KEY = "axeptio_gvl_timestamp"
    private const val CACHE_TTL_DAYS = 7
    
    private var context: Context? = null
    private var cachedGVL: JSONObject? = null
    private var cachedVendors: JSONObject? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    
    fun initialize(context: Context) {
        this.context = context
        loadCachedGVL()
    }
    
    // MARK: - Public Methods
    
    /**
     * Loads the GVL from the server or cache
     */
    fun loadGVL(version: String? = null, callback: (Boolean) -> Unit) {
        // Check if we have valid cached data first
        if (cachedGVL != null && isCacheValid()) {
            callback(true)
            return
        }
        
        downloadGVL(version, callback)
    }
    
    /**
     * Unloads the GVL from memory but keeps cache
     */
    fun unloadGVL() {
        cachedGVL = null
        cachedVendors = null
    }
    
    /**
     * Clears all GVL data from cache and memory
     */
    fun clearGVL() {
        cachedGVL = null
        cachedVendors = null
        
        context?.let { ctx ->
            val prefs = ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .remove(CACHE_KEY)
                .remove(CACHE_VERSION_KEY)
                .remove(CACHE_TIMESTAMP_KEY)
                .apply()
        }
    }
    
    /**
     * Gets the name of a vendor by ID
     */
    fun getVendorName(vendorId: Int): String? {
        val vendors = getVendors() ?: return null
        return vendors.optJSONObject(vendorId.toString())?.optString("name")
    }
    
    /**
     * Gets names for multiple vendor IDs
     */
    fun getVendorNames(vendorIds: List<Int>): Map<String, String> {
        val result = mutableMapOf<String, String>()
        val vendors = getVendors() ?: return result
        
        for (vendorId in vendorIds) {
            val vendorKey = vendorId.toString()
            val name = vendors.optJSONObject(vendorKey)?.optString("name")
            if (name != null) {
                result[vendorKey] = name
            }
        }
        
        return result
    }
    
    /**
     * Gets comprehensive vendor information
     */
    fun getVendorInfo(vendorId: Int): Map<String, Any>? {
        val vendors = getVendors() ?: return null
        val vendorJson = vendors.optJSONObject(vendorId.toString()) ?: return null
        
        return try {
            val vendorMap = mutableMapOf<String, Any>()
            vendorMap["id"] = vendorId
            vendorMap["name"] = vendorJson.optString("name", "Vendor $vendorId")
            
            // Parse purposes array
            val purposesArray = vendorJson.optJSONArray("purposes")
            val purposes = mutableListOf<Int>()
            if (purposesArray != null) {
                for (i in 0 until purposesArray.length()) {
                    purposes.add(purposesArray.getInt(i))
                }
            }
            vendorMap["purposes"] = purposes
            
            // Parse legitimate interest purposes
            val legIntPurposesArray = vendorJson.optJSONArray("legIntPurposes")
            val legIntPurposes = mutableListOf<Int>()
            if (legIntPurposesArray != null) {
                for (i in 0 until legIntPurposesArray.length()) {
                    legIntPurposes.add(legIntPurposesArray.getInt(i))
                }
            }
            vendorMap["legIntPurposes"] = legIntPurposes
            
            // Parse special features
            val specialFeaturesArray = vendorJson.optJSONArray("specialFeatures")
            val specialFeatures = mutableListOf<Int>()
            if (specialFeaturesArray != null) {
                for (i in 0 until specialFeaturesArray.length()) {
                    specialFeatures.add(specialFeaturesArray.getInt(i))
                }
            }
            vendorMap["specialFeatures"] = specialFeatures
            
            // Parse special purposes
            val specialPurposesArray = vendorJson.optJSONArray("specialPurposes")
            val specialPurposes = mutableListOf<Int>()
            if (specialPurposesArray != null) {
                for (i in 0 until specialPurposesArray.length()) {
                    specialPurposes.add(specialPurposesArray.getInt(i))
                }
            }
            vendorMap["specialPurposes"] = specialPurposes
            
            // Other vendor properties
            vendorMap["description"] = vendorJson.optString("description")
            vendorMap["cookieMaxAgeSeconds"] = vendorJson.optInt("cookieMaxAgeSeconds", 0)
            vendorMap["usesCookies"] = vendorJson.optBoolean("usesCookies", false)
            vendorMap["usesNonCookieAccess"] = vendorJson.optBoolean("usesNonCookieAccess", false)
            vendorMap["policyUrl"] = vendorJson.optString("policyUrl")
            
            vendorMap
        } catch (e: Exception) {
            println("AxeptioGVLManager: Error parsing vendor info for ID $vendorId: ${e.message}")
            null
        }
    }
    
    /**
     * Checks if GVL is loaded in memory
     */
    fun isGVLLoaded(): Boolean {
        return cachedGVL != null
    }
    
    /**
     * Gets the current GVL version
     */
    fun getGVLVersion(): String? {
        return context?.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            ?.getString(CACHE_VERSION_KEY, null)
    }
    
    // MARK: - Private Methods
    
    private fun downloadGVL(version: String?, callback: (Boolean) -> Unit) {
        executor.execute {
            try {
                var urlString = GVL_URL
                if (version != null) {
                    urlString += "?version=$version"
                }
                
                val url = URL(urlString)
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.connectTimeout = 30000
                connection.readTimeout = 30000
                
                val responseCode = connection.responseCode
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    val reader = BufferedReader(InputStreamReader(connection.inputStream))
                    val response = StringBuilder()
                    var line: String?
                    
                    while (reader.readLine().also { line = it } != null) {
                        response.append(line)
                    }
                    reader.close()
                    
                    val gvlJson = JSONObject(response.toString())
                    processAndCacheGVL(gvlJson)
                    
                    mainHandler.post { callback(true) }
                } else {
                    println("AxeptioGVLManager: HTTP error $responseCode when downloading GVL")
                    mainHandler.post { callback(false) }
                }
                
                connection.disconnect()
            } catch (e: Exception) {
                println("AxeptioGVLManager: Error downloading GVL: ${e.message}")
                mainHandler.post { callback(false) }
            }
        }
    }
    
    private fun processAndCacheGVL(gvl: JSONObject) {
        cachedGVL = gvl
        
        // Extract and cache vendor information
        cachedVendors = gvl.optJSONObject("vendors")
        
        // Cache to SharedPreferences
        context?.let { ctx ->
            val prefs = ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putString(CACHE_KEY, gvl.toString())
                .putString(CACHE_VERSION_KEY, gvl.optInt("vendorListVersion").toString())
                .putLong(CACHE_TIMESTAMP_KEY, System.currentTimeMillis())
                .apply()
        }
    }
    
    private fun loadCachedGVL() {
        context?.let { ctx ->
            val prefs = ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val cachedData = prefs.getString(CACHE_KEY, null)
            
            if (cachedData != null && isCacheValid()) {
                try {
                    cachedGVL = JSONObject(cachedData)
                    cachedVendors = cachedGVL?.optJSONObject("vendors")
                } catch (e: Exception) {
                    println("AxeptioGVLManager: Error parsing cached GVL: ${e.message}")
                    clearGVL()
                }
            } else if (cachedData != null) {
                // Cache expired, clear it
                clearGVL()
            }
        }
    }
    
    private fun isCacheValid(): Boolean {
        context?.let { ctx ->
            val prefs = ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val timestamp = prefs.getLong(CACHE_TIMESTAMP_KEY, 0)
            
            if (timestamp == 0L) return false
            
            val now = System.currentTimeMillis()
            val cacheTTLMillis = CACHE_TTL_DAYS * 24 * 60 * 60 * 1000L
            
            return (now - timestamp) < cacheTTLMillis
        }
        
        return false
    }
    
    private fun getVendors(): JSONObject? {
        if (cachedVendors != null) {
            return cachedVendors
        }
        
        val gvl = cachedGVL ?: return null
        val vendors = gvl.optJSONObject("vendors") ?: return null
        
        cachedVendors = vendors
        return vendors
    }
}