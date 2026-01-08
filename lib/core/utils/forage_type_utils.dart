import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utilities for handling forage types (colors, icons, markers)
///
/// Consolidates type-related logic previously duplicated across:
/// - map_page.dart
/// - forage_locations_page.dart
/// - map_state_provider.dart
class ForageTypeUtils {
  ForageTypeUtils._();

  /// All available forage types
  static const List<String> allTypes = [
    'Berries',
    'Mushrooms',
    'Nuts',
    'Herbs',
    'Trees',
    'Fish',
    'Plants',
    'Other',
  ];

  /// Get color for a forage type
  static Color getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'berries':
        return Colors.red;
      case 'mushrooms':
        return Colors.brown;
      case 'nuts':
        return const Color(0xFFD2691E); // Chocolate
      case 'herbs':
        return Colors.green;
      case 'trees':
        return const Color(0xFF228B22); // Forest green
      case 'fish':
        return Colors.blue;
      case 'plants':
        return Colors.lightGreen;
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

  /// Get default BitmapDescriptor for a forage type
  static BitmapDescriptor getMarkerIcon(String type) {
    return BitmapDescriptor.defaultMarkerWithHue(getMarkerHue(type));
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
        iconData = Icons.eco; // Leaf icon
        break;
      case 'mushrooms':
        iconData = Icons.nature; // Nature icon
        break;
      case 'nuts':
        iconData = Icons.park; // Park icon
        break;
      case 'herbs':
        iconData = Icons.grass; // Grass icon
        break;
      case 'trees':
        iconData = Icons.forest; // Forest icon
        break;
      case 'fish':
        iconData = Icons.waves; // Waves icon
        break;
      case 'plants':
        iconData = Icons.local_florist; // Flower icon
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
