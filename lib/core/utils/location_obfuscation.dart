import 'dart:math';
import 'package:flutter_forager_app/data/models/marker.dart';

/// Simple class to hold obfuscated coordinates.
class ObfuscatedCoordinates {
  final double latitude;
  final double longitude;

  const ObfuscatedCoordinates({
    required this.latitude,
    required this.longitude,
  });
}

/// Utility for obfuscating location coordinates for privacy.
///
/// Used to hide precise locations from regular friends while
/// allowing close friends to see exact coordinates.
class LocationObfuscation {
  /// Default obfuscation radius in meters (~500m for approximate area)
  static const double defaultRadiusMeters = 500.0;

  /// Earth's radius in meters
  static const double earthRadiusMeters = 6371000.0;

  /// Random number generator with secure seed
  static final Random _random = Random();

  /// Obfuscate a single coordinate pair by randomizing within a radius.
  ///
  /// Returns a new lat/lng pair within [radiusMeters] of the original location.
  /// The randomization is deterministic based on the marker ID to ensure
  /// consistent obfuscation for the same marker.
  static ObfuscatedCoordinates obfuscateCoordinates({
    required double latitude,
    required double longitude,
    required String markerId,
    double radiusMeters = defaultRadiusMeters,
  }) {
    // Use marker ID to seed random for consistent obfuscation
    final seed = markerId.hashCode;
    final seededRandom = Random(seed);

    // Generate random distance and bearing
    final distance = seededRandom.nextDouble() * radiusMeters;
    final bearing = seededRandom.nextDouble() * 2 * pi;

    // Convert distance to radians
    final distanceRadians = distance / earthRadiusMeters;

    // Convert latitude/longitude to radians
    final lat1 = latitude * pi / 180;
    final lng1 = longitude * pi / 180;

    // Calculate new latitude
    final lat2 = asin(
      sin(lat1) * cos(distanceRadians) +
          cos(lat1) * sin(distanceRadians) * cos(bearing),
    );

    // Calculate new longitude
    final lng2 = lng1 +
        atan2(
          sin(bearing) * sin(distanceRadians) * cos(lat1),
          cos(distanceRadians) - sin(lat1) * sin(lat2),
        );

    // Convert back to degrees
    return ObfuscatedCoordinates(
      latitude: lat2 * 180 / pi,
      longitude: lng2 * 180 / pi,
    );
  }

  /// Obfuscate a marker's location and mark it as obfuscated.
  ///
  /// Returns a new MarkerModel with randomized coordinates within the
  /// specified radius and [isLocationObfuscated] set to true.
  static MarkerModel obfuscateMarker(
    MarkerModel marker, {
    double radiusMeters = defaultRadiusMeters,
  }) {
    final obfuscated = obfuscateCoordinates(
      latitude: marker.latitude,
      longitude: marker.longitude,
      markerId: marker.id,
      radiusMeters: radiusMeters,
    );

    return marker.copyWith(
      latitude: obfuscated.latitude,
      longitude: obfuscated.longitude,
      isLocationObfuscated: true,
    );
  }

  /// Obfuscate a list of markers based on viewer's relationship to owners.
  ///
  /// [markers] - List of markers to process
  /// [viewerEmail] - Email of the user viewing the markers
  /// [closeFriendEmails] - Set of emails that are the viewer's close friends
  ///
  /// Returns markers with obfuscated locations for non-close friends.
  /// The viewer's own markers and close friends' markers remain precise.
  static List<MarkerModel> obfuscateMarkersForViewer({
    required List<MarkerModel> markers,
    required String viewerEmail,
    required Set<String> closeFriendEmails,
    double radiusMeters = defaultRadiusMeters,
  }) {
    return markers.map((marker) {
      // Don't obfuscate viewer's own markers
      if (marker.markerOwner == viewerEmail) {
        return marker;
      }

      // Don't obfuscate close friends' markers
      if (closeFriendEmails.contains(marker.markerOwner)) {
        return marker;
      }

      // Obfuscate markers from regular friends and others
      return obfuscateMarker(marker, radiusMeters: radiusMeters);
    }).toList();
  }

  /// Check if a user should see precise location for a marker.
  ///
  /// Returns true if:
  /// - The viewer owns the marker
  /// - The marker owner is a close friend of the viewer
  static bool shouldShowPreciseLocation({
    required String markerOwner,
    required String viewerEmail,
    required Set<String> closeFriendEmails,
  }) {
    if (markerOwner == viewerEmail) return true;
    if (closeFriendEmails.contains(markerOwner)) return true;
    return false;
  }

  /// Get location precision label for UI display.
  ///
  /// Returns "Precise location" for close friends/owner,
  /// "Approximate area (~500m)" for regular friends.
  static String getLocationPrecisionLabel({
    required bool isObfuscated,
  }) {
    return isObfuscated ? 'Approximate area (~500m)' : 'Precise location';
  }
}
