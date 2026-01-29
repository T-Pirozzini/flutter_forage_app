import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/data/models/marker.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/services/geocoding_cache.dart';
import 'package:flutter_forager_app/providers/map/map_state_provider.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Enhanced bottom sheet for browsing and navigating to saved markers
///
/// Features:
/// - Search by name/description
/// - Sort by distance, date, or name
/// - Distance indicator for each marker
/// - Type icons and color coding
class LocationsBottomSheet extends ConsumerStatefulWidget {
  final Function(LatLng, String markerType) onLocationSelected;

  const LocationsBottomSheet({
    super.key,
    required this.onLocationSelected,
  });

  @override
  ConsumerState<LocationsBottomSheet> createState() =>
      _LocationsBottomSheetState();
}

class _LocationsBottomSheetState extends ConsumerState<LocationsBottomSheet> {
  String _searchQuery = '';
  String _sortBy = 'distance'; // 'distance', 'date', 'name'
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use effective location (spoof if set, else real GPS) for distance calculations
    final effectiveLocation = ref.watch(effectiveLocationProvider);
    final markerRepo = ref.watch(markerRepositoryProvider);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Please sign in'));
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header with title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'My Locations',
                      style:
                          AppTheme.heading(size: 18, color: AppTheme.textDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search markers...',
                    hintStyle: AppTheme.body(color: AppTheme.textLight),
                    prefixIcon: Icon(Icons.search, color: AppTheme.textMedium),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: AppTheme.textMedium),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.backgroundLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(height: 12),

              // Sort options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('Sort by:',
                        style: AppTheme.caption(color: AppTheme.textMedium)),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'Nearest',
                      isSelected: _sortBy == 'distance',
                      onTap: () => setState(() => _sortBy = 'distance'),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'Recent',
                      isSelected: _sortBy == 'date',
                      onTap: () => setState(() => _sortBy = 'date'),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'Name',
                      isSelected: _sortBy == 'name',
                      onTap: () => setState(() => _sortBy = 'name'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Divider
              Divider(color: AppTheme.backgroundLight, height: 1),

              // Marker list
              Expanded(
                child: StreamBuilder<List<MarkerModel>>(
                  stream: markerRepo.streamByUserId(user.email!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_off,
                                size: 48, color: AppTheme.textLight),
                            const SizedBox(height: 12),
                            Text(
                              'No markers yet',
                              style: AppTheme.body(color: AppTheme.textMedium),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap + to add your first foraging spot!',
                              style:
                                  AppTheme.caption(color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      );
                    }

                    var markers = snapshot.data!;

                    // Apply search filter
                    if (_searchQuery.isNotEmpty) {
                      final query = _searchQuery.toLowerCase();
                      markers = markers
                          .where((m) =>
                              m.name.toLowerCase().contains(query) ||
                              m.description.toLowerCase().contains(query) ||
                              m.type.toLowerCase().contains(query))
                          .toList();
                    }

                    // Apply sorting
                    if (_sortBy == 'distance' && effectiveLocation != null) {
                      markers.sort((a, b) {
                        final distA = _calculateDistance(effectiveLocation, a);
                        final distB = _calculateDistance(effectiveLocation, b);
                        return distA.compareTo(distB);
                      });
                    } else if (_sortBy == 'date') {
                      markers
                          .sort((a, b) => b.timestamp.compareTo(a.timestamp));
                    } else if (_sortBy == 'name') {
                      markers.sort((a, b) =>
                          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                    }

                    if (markers.isEmpty) {
                      return Center(
                        child: Text(
                          'No markers match "$_searchQuery"',
                          style: AppTheme.body(color: AppTheme.textMedium),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: markers.length,
                      itemBuilder: (context, index) {
                        final marker = markers[index];
                        final distance = effectiveLocation != null
                            ? _calculateDistance(effectiveLocation, marker)
                            : null;

                        return _MarkerTile(
                          marker: marker,
                          distance: distance,
                          onTap: () {
                            widget.onLocationSelected(
                              LatLng(marker.latitude, marker.longitude),
                              marker.type,
                            );
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _calculateDistance(LatLng pos, MarkerModel marker) {
    return Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      marker.latitude,
      marker.longitude,
    );
  }
}

/// Sort option chip
class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textMedium,
          ),
        ),
      ),
    );
  }
}

/// Individual marker tile in the list
class _MarkerTile extends StatelessWidget {
  final MarkerModel marker;
  final double? distance;
  final VoidCallback onTap;

  const _MarkerTile({
    required this.marker,
    this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = ForageTypeUtils.getTypeColor(marker.type);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: typeColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Image.asset(
            'lib/assets/images/${_getAssetName(marker.type)}_marker.png',
            width: 28,
            height: 28,
            color: typeColor,
            errorBuilder: (_, __, ___) => Icon(
              Icons.place,
              color: typeColor,
              size: 28,
            ),
          ),
        ),
      ),
      title: Text(
        marker.name.isEmpty ? 'Unnamed Location' : marker.name,
        style: AppTheme.title(size: 14, weight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (marker.description.isNotEmpty)
            Text(
              marker.description,
              style: AppTheme.caption(color: AppTheme.textMedium),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 2),
          FutureBuilder<String>(
            future:
                GeocodingCache.getAddress(marker.latitude, marker.longitude),
            builder: (context, snapshot) => Text(
              snapshot.data ?? 'Loading...',
              style: AppTheme.caption(size: 11, color: AppTheme.textLight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: distance != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDistance(distance!),
                style: AppTheme.caption(
                  size: 11,
                  color: AppTheme.primary,
                  weight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  String _getAssetName(String type) {
    switch (type.toLowerCase()) {
      case 'mushrooms':
      case 'mushroom':
        return 'mushroom';
      case 'trees':
      case 'tree':
        return 'tree';
      case 'plants':
      case 'plant':
        return 'plant';
      case 'herbs':
      case 'herb':
        return 'plant';
      case 'berries':
      case 'berry':
        return 'berries';
      case 'nuts':
      case 'nut':
        return 'nuts';
      default:
        return type.toLowerCase();
    }
  }
}
