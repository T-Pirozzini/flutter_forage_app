/// Information about location sharing between users.
///
/// Used to display how many locations a friend is sharing
/// and how many are hidden based on visibility settings.
class LocationSharingInfo {
  /// Total number of markers the friend has
  final int totalLocations;

  /// Number of markers shared with the viewer (public + friends + specific includes viewer)
  final int sharedWithViewer;

  /// Number of markers hidden from the viewer (private + specific excludes viewer)
  final int hiddenFromViewer;

  const LocationSharingInfo({
    required this.totalLocations,
    required this.sharedWithViewer,
    required this.hiddenFromViewer,
  });

  /// Creates an empty sharing info (no locations)
  const LocationSharingInfo.empty()
      : totalLocations = 0,
        sharedWithViewer = 0,
        hiddenFromViewer = 0;

  /// Display text for the sharing info
  /// e.g., "Sharing 8 locations (3 hidden from you)"
  String get displayText {
    if (totalLocations == 0) {
      return 'No locations yet';
    }

    final sharedText = sharedWithViewer == 1
        ? 'Sharing 1 location'
        : 'Sharing $sharedWithViewer locations';

    if (hiddenFromViewer == 0) {
      return sharedText;
    }

    final hiddenText =
        hiddenFromViewer == 1 ? '1 hidden from you' : '$hiddenFromViewer hidden from you';

    return '$sharedText ($hiddenText)';
  }

  /// Short display text for compact cards
  /// e.g., "8 locations (3 hidden)"
  String get shortDisplayText {
    if (totalLocations == 0) {
      return 'No locations';
    }

    final locText = totalLocations == 1 ? '1 location' : '$totalLocations locations';

    if (hiddenFromViewer == 0) {
      return locText;
    }

    return '$sharedWithViewer visible, $hiddenFromViewer hidden';
  }

  /// Whether there are any shared locations
  bool get hasSharedLocations => sharedWithViewer > 0;

  /// Whether any locations are hidden from the viewer
  bool get hasHiddenLocations => hiddenFromViewer > 0;

  @override
  String toString() {
    return 'LocationSharingInfo(total: $totalLocations, shared: $sharedWithViewer, hidden: $hiddenFromViewer)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationSharingInfo &&
          runtimeType == other.runtimeType &&
          totalLocations == other.totalLocations &&
          sharedWithViewer == other.sharedWithViewer &&
          hiddenFromViewer == other.hiddenFromViewer;

  @override
  int get hashCode =>
      totalLocations.hashCode ^ sharedWithViewer.hashCode ^ hiddenFromViewer.hashCode;
}
