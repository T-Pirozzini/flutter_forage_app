import 'package:geocoding/geocoding.dart';

/// Service for caching geocoding results to reduce API calls
///
/// Geocoding API calls are expensive - this cache stores results
/// to avoid repeated lookups for the same coordinates.
class GeocodingCache {
  GeocodingCache._();

  /// In-memory cache storing address strings by coordinate key
  static final Map<String, String> _cache = {};

  /// Get a cached address or fetch from geocoding API
  ///
  /// Coordinates are rounded to 4 decimal places (~11m precision)
  /// which is sufficient for display purposes and improves cache hits.
  static Future<String> getAddress(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locality = place.locality ?? '';
        final country = place.country ?? '';
        final address = locality.isNotEmpty && country.isNotEmpty
            ? '$locality, $country'
            : locality.isNotEmpty
                ? locality
                : country.isNotEmpty
                    ? country
                    : '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
        _cache[key] = address.trim();
        return _cache[key]!;
      }
      final fallback = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      _cache[key] = fallback;
      return fallback;
    } catch (_) {
      final fallback = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      _cache[key] = fallback;
      return fallback;
    }
  }

  /// Clear the geocoding cache
  static void clearCache() {
    _cache.clear();
  }

  /// Get the current cache size (for debugging)
  static int get cacheSize => _cache.length;
}
