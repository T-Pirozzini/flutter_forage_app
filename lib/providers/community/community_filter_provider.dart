import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum representing the available community post filters
enum CommunityFilter {
  all,       // Show all posts
  recent,    // Sort by most recent
  friends,   // Show only friends' posts
  following, // Show only followed users' posts
  nearby,    // Show posts within a radius
}

/// Extension to provide display names for filters
extension CommunityFilterExtension on CommunityFilter {
  String get displayName {
    switch (this) {
      case CommunityFilter.all:
        return 'All';
      case CommunityFilter.recent:
        return 'Recent';
      case CommunityFilter.friends:
        return 'Friends';
      case CommunityFilter.following:
        return 'Following';
      case CommunityFilter.nearby:
        return 'Nearby';
    }
  }

  String get description {
    switch (this) {
      case CommunityFilter.all:
        return 'Show all community posts';
      case CommunityFilter.recent:
        return 'Most recent posts first';
      case CommunityFilter.friends:
        return 'Posts from your friends';
      case CommunityFilter.following:
        return 'Posts from users you follow';
      case CommunityFilter.nearby:
        return 'Posts near your location';
    }
  }
}

/// Provider for the current community filter selection
final communityFilterProvider = StateProvider<CommunityFilter>((ref) {
  return CommunityFilter.all;
});

/// Provider for the nearby filter radius (in kilometers)
final communityRadiusProvider = StateProvider<double>((ref) {
  return 50.0; // Default 50km radius
});

/// Provider for search query within the community
final communitySearchQueryProvider = StateProvider<String>((ref) {
  return '';
});
