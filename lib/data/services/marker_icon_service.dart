import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/data/models/custom_marker_type.dart';
import 'package:flutter_forager_app/data/services/emoji_marker_service.dart';

/// Service for loading and caching custom PNG marker icons
///
/// Preloads all marker icons at app startup for instant access.
/// Falls back to colored hue-based pins if PNG loading fails.
class MarkerIconService {
  MarkerIconService._();

  static final Map<String, BitmapDescriptor> _iconCache = {};
  static bool _isInitialized = false;

  /// Marker size in pixels (smaller = better visibility when zoomed out)
  static const double _markerSize = 56.0;

  /// Maps forage type names to asset file names
  /// Handles naming inconsistencies (singular/plural)
  static String _getAssetFileName(String type) {
    switch (type.toLowerCase()) {
      case 'berries':
      case 'berry':
        return 'berries_marker.png';
      case 'mushrooms':
      case 'mushroom':
        return 'mushroom_marker.png';
      case 'nuts':
      case 'nut':
        return 'nuts_marker.png';
      case 'herbs':
      case 'herb':
        return 'plant_marker.png'; // No herbs icon, use plant as fallback
      case 'trees':
      case 'tree':
        return 'tree_marker.png';
      case 'fish':
        return 'fish_marker.png';
      case 'plants':
      case 'plant':
        return 'plant_marker.png';
      case 'shellfish':
        return 'shellfish_marker.png';
      case 'other':
        return 'other_marker.png';
      default:
        return 'other_marker.png';
    }
  }

  /// Preload all marker icons at app startup
  ///
  /// Call this in main() before runApp() for best performance.
  /// Icons are cached as BitmapDescriptor objects for instant access.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    for (final type in ForageTypeUtils.allTypes) {
      try {
        final icon = await _loadIconFromAsset(type);
        _iconCache[type.toLowerCase()] = icon;
      } catch (e) {
        debugPrint('Failed to load marker icon for $type: $e');
        // Fallback to hue-based colored pin
        _iconCache[type.toLowerCase()] = BitmapDescriptor.defaultMarkerWithHue(
          ForageTypeUtils.getMarkerHue(type),
        );
      }
    }

    _isInitialized = true;
    debugPrint('MarkerIconService initialized with ${_iconCache.length} icons');
  }

  /// Load a PNG icon from assets and convert to BitmapDescriptor
  static Future<BitmapDescriptor> _loadIconFromAsset(String type) async {
    final fileName = _getAssetFileName(type);
    final assetPath = 'lib/assets/images/$fileName';

    final ByteData byteData = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetWidth: _markerSize.toInt(),
      targetHeight: _markerSize.toInt(),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? imageByteData = await frameInfo.image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (imageByteData == null) {
      throw Exception('Failed to convert image to bytes');
    }

    final Uint8List markerBytes = imageByteData.buffer.asUint8List();
    return BitmapDescriptor.bytes(markerBytes);
  }

  /// Get cached icon for a forage type
  ///
  /// Handles both built-in types (PNG icons) and custom types (emoji markers).
  /// Returns colored hue-based pin if icons not initialized or type not found.
  static BitmapDescriptor getIcon(String type) {
    // Check if this is a custom emoji type
    if (CustomMarkerType.isCustomType(type)) {
      final emoji = CustomMarkerType.getEmojiFromType(type);
      if (emoji != null && _iconCache.containsKey('emoji_$emoji')) {
        return _iconCache['emoji_$emoji']!;
      }
      // Return default marker if emoji not cached yet
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }

    final key = type.toLowerCase();

    if (_iconCache.containsKey(key)) {
      return _iconCache[key]!;
    }

    // Fallback if not initialized or type not in cache
    return BitmapDescriptor.defaultMarkerWithHue(
      ForageTypeUtils.getMarkerHue(type),
    );
  }

  /// Get or create an emoji marker icon (async)
  ///
  /// Creates the emoji marker on first access and caches it for future use.
  static Future<BitmapDescriptor> getEmojiIcon(String emoji) async {
    final cacheKey = 'emoji_$emoji';

    if (_iconCache.containsKey(cacheKey)) {
      return _iconCache[cacheKey]!;
    }

    try {
      final icon = await EmojiMarkerService.getEmojiMarker(emoji);
      _iconCache[cacheKey] = icon;
      return icon;
    } catch (e) {
      debugPrint('Failed to create emoji marker for $emoji: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  /// Preload emoji markers for a list of custom types
  static Future<void> preloadEmojiMarkers(List<CustomMarkerType> customTypes) async {
    for (final customType in customTypes) {
      await getEmojiIcon(customType.emoji);
    }
  }

  /// Check if icons have been initialized
  static bool get isInitialized => _isInitialized;

  /// Clear the icon cache (useful for memory management or hot reload)
  static void clearCache() {
    _iconCache.clear();
    _isInitialized = false;
  }
}
