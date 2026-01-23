import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_result.dart';
import '../constants/app_constants.dart';

/// Service for caching scan results to improve performance
///
/// Caches successful scan results by barcode/product name
/// to avoid redundant AI API calls for identical products.
///
/// Cache entries expire after 24 hours by default.
class CacheService {
  static const String _cacheKeyPrefix = 'scan_cache_';
  static const String _timestampSuffix = '_timestamp';

  /// Gets a cached scan result by barcode
  ///
  /// Returns null if:
  /// - No cache entry exists
  /// - Cache entry is expired
  /// - Cache entry is invalid
  Future<ScanResult?> getCachedResultByBarcode(String barcode) async {
    if (barcode.isEmpty) return null;

    final cacheKey = _generateCacheKey(barcode: barcode);
    return await _getCachedResult(cacheKey);
  }

  /// Gets a cached scan result by product name and condition
  ///
  /// Returns null if:
  /// - No cache entry exists
  /// - Cache entry is expired
  /// - Cache entry is invalid
  Future<ScanResult?> getCachedResultByProduct({
    required String productName,
    required String condition,
  }) async {
    if (productName.isEmpty) return null;

    final cacheKey = _generateCacheKey(
      productName: productName,
      condition: condition,
    );
    return await _getCachedResult(cacheKey);
  }

  /// Caches a scan result by barcode
  Future<void> cacheResultByBarcode({
    required String barcode,
    required ScanResult result,
  }) async {
    if (barcode.isEmpty) return;

    final cacheKey = _generateCacheKey(barcode: barcode);
    await _cacheResult(cacheKey, result);
  }

  /// Caches a scan result by product name and condition
  Future<void> cacheResultByProduct({
    required String productName,
    required String condition,
    required ScanResult result,
  }) async {
    if (productName.isEmpty) return;

    final cacheKey = _generateCacheKey(
      productName: productName,
      condition: condition,
    );
    await _cacheResult(cacheKey, result);
  }

  /// Clears all cached scan results
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_cacheKeyPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  /// Clears expired cache entries
  Future<void> clearExpiredCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final now = DateTime.now();

    for (final key in keys) {
      if (key.startsWith(_cacheKeyPrefix) && key.endsWith(_timestampSuffix)) {
        final timestamp = prefs.getInt(key);
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final age = now.difference(cacheTime);

          if (age > Durations.cacheDuration) {
            // Remove both timestamp and cached data
            final dataKey = key.replaceAll(_timestampSuffix, '');
            await prefs.remove(key);
            await prefs.remove(dataKey);
          }
        }
      }
    }
  }

  /// Gets cache statistics
  Future<CacheStatistics> getStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    int totalEntries = 0;
    int expiredEntries = 0;
    int validEntries = 0;
    final now = DateTime.now();

    for (final key in keys) {
      if (key.startsWith(_cacheKeyPrefix) && key.endsWith(_timestampSuffix)) {
        totalEntries++;
        final timestamp = prefs.getInt(key);

        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final age = now.difference(cacheTime);

          if (age > Durations.cacheDuration) {
            expiredEntries++;
          } else {
            validEntries++;
          }
        }
      }
    }

    return CacheStatistics(
      totalEntries: totalEntries,
      validEntries: validEntries,
      expiredEntries: expiredEntries,
    );
  }

  // Private helper methods

  String _generateCacheKey({
    String? barcode,
    String? productName,
    String? condition,
  }) {
    if (barcode != null && barcode.isNotEmpty) {
      return '$_cacheKeyPrefix${barcode.toLowerCase()}';
    }

    if (productName != null && productName.isNotEmpty) {
      final normalizedName = productName.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      final conditionSuffix = condition != null ? '_${condition.toLowerCase()}' : '';
      return '$_cacheKeyPrefix$normalizedName$conditionSuffix';
    }

    throw ArgumentError('Either barcode or productName must be provided');
  }

  Future<ScanResult?> _getCachedResult(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if cache entry exists
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson == null) return null;

      // Check if cache is expired
      final timestamp = prefs.getInt('$cacheKey$_timestampSuffix');
      if (timestamp == null) return null;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(cacheTime);

      if (age > Durations.cacheDuration) {
        // Cache expired, remove it
        await prefs.remove(cacheKey);
        await prefs.remove('$cacheKey$_timestampSuffix');
        return null;
      }

      // Parse and return cached result
      final json = jsonDecode(cachedJson) as Map<String, dynamic>;
      return ScanResult.fromJson(json);
    } catch (e) {
      // If any error occurs, return null (cache miss)
      return null;
    }
  }

  Future<void> _cacheResult(String cacheKey, ScanResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Serialize scan result to JSON
      final json = result.toJson();
      final jsonString = jsonEncode(json);

      // Store cached result
      await prefs.setString(cacheKey, jsonString);

      // Store timestamp
      await prefs.setInt(
        '$cacheKey$_timestampSuffix',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Silently fail if caching fails (not critical)
      // Could log error here if logging service is available
    }
  }
}

/// Cache statistics for monitoring
class CacheStatistics {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;

  CacheStatistics({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
  });

  double get hitRate {
    if (totalEntries == 0) return 0.0;
    return validEntries / totalEntries;
  }

  @override
  String toString() {
    return 'CacheStatistics(total: $totalEntries, valid: $validEntries, expired: $expiredEntries, hit rate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}
