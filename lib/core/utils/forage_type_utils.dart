import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_forager_app/data/services/marker_icon_service.dart';

/// Utilities for handling forage types (colors, icons, markers)
///
/// Consolidates type-related logic previously duplicated across:
/// - map_page.dart
/// - forage_locations_page.dart
/// - map_state_provider.dart
class ForageTypeUtils {
  ForageTypeUtils._();

  /// All available forage types (lowercase to match saved marker types)
  static const List<String> allTypes = [
    'berries',
    'mushroom',
    'nuts',
    'herbs',
    'tree',
    'fish',
    'plant',
    'shellfish',
    'other',
  ];

  /// Get color for a forage type (handles both singular and plural forms)
  static Color getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'berries':
      case 'berry':
        return Colors.red;
      case 'mushrooms':
      case 'mushroom':
        return Colors.brown;
      case 'nuts':
      case 'nut':
        return const Color(0xFFD2691E); // Chocolate
      case 'herbs':
      case 'herb':
        return Colors.green;
      case 'trees':
      case 'tree':
        return const Color(0xFF228B22); // Forest green
      case 'fish':
        return Colors.blue;
      case 'plants':
      case 'plant':
        return Colors.lightGreen;
      case 'shellfish':
        return const Color(0xFFE91E63); // Pink
      case 'other':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Get Material color swatch for a forage type
  static MaterialColor getTypeMaterialColor(String type) {
    final color = getTypeColor(type);
    return MaterialColor(color.value, {
      50: color.withOpacity(0.1),
      100: color.withOpacity(0.2),
      200: color.withOpacity(0.3),
      300: color.withOpacity(0.4),
      400: color.withOpacity(0.5),
      500: color.withOpacity(0.6),
      600: color.withOpacity(0.7),
      700: color.withOpacity(0.8),
      800: color.withOpacity(0.9),
      900: color,
    });
  }

  /// Get marker icon hue for Google Maps
  static double getMarkerHue(String type) {
    final color = getTypeColor(type);
    final hsl = HSLColor.fromColor(color);
    return hsl.hue;
  }

  /// Get BitmapDescriptor for a forage type (uses custom PNG icons)
  ///
  /// Delegates to MarkerIconService which preloads PNG icons at startup.
  /// Falls back to hue-based colored pins if service not initialized.
  static BitmapDescriptor getMarkerIcon(String type) {
    return MarkerIconService.getIcon(type);
  }

  /// Preload all marker icons into cache
  /// Call this during app initialization for faster map loading
  /// Note: Now handled by MarkerIconService.initialize() in main.dart
  static Future<void> preloadMarkerIcons() async {
    await MarkerIconService.initialize();
  }

  /// Clear the icon cache (useful for memory management)
  static void clearIconCache() {
    MarkerIconService.clearCache();
  }

  /// Get a lighter shade of the type color for backgrounds
  static Color getTypeColorLight(String type) {
    return getTypeColor(type).withOpacity(0.2);
  }

  /// Get an icon widget for a forage type (for use in lists)
  static Widget getTypeIcon(String type, {double size = 24}) {
    IconData iconData;
    switch (type.toLowerCase()) {
      case 'berries':
      case 'berry':
        iconData = Icons.eco; // Leaf icon
        break;
      case 'mushrooms':
      case 'mushroom':
        iconData = Icons.nature; // Nature icon
        break;
      case 'nuts':
      case 'nut':
        iconData = Icons.park; // Park icon
        break;
      case 'herbs':
      case 'herb':
        iconData = Icons.grass; // Grass icon
        break;
      case 'trees':
      case 'tree':
        iconData = Icons.forest; // Forest icon
        break;
      case 'fish':
        iconData = Icons.waves; // Waves icon
        break;
      case 'plants':
      case 'plant':
        iconData = Icons.local_florist; // Flower icon
        break;
      case 'shellfish':
        iconData = Icons.water; // Water icon for shellfish
        break;
      default:
        iconData = Icons.place; // Default location icon
    }

    return Icon(
      iconData,
      color: getTypeColor(type),
      size: size,
    );
  }

  /// Check if a type string is valid
  static bool isValidType(String type) {
    return allTypes.any((t) => t.toLowerCase() == type.toLowerCase());
  }

  /// Normalize type string (capitalize first letter)
  static String normalizeType(String type) {
    if (type.isEmpty) return 'Other';
    return type[0].toUpperCase() + type.substring(1).toLowerCase();
  }
}
