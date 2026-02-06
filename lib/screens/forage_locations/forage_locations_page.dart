import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/models/marker.dart';
import 'package:flutter_forager_app/screens/forage_locations/components/bookmark_section.dart';
import 'package:flutter_forager_app/screens/forage_locations/components/subscribed_collections_section.dart';
import 'package:flutter_forager_app/screens/forage_locations/location_detail_screen.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class ForageLocations extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final bool userLocations;

  const ForageLocations({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userLocations,
  }) : super(key: key);

  @override
  ConsumerState<ForageLocations> createState() => _ForageLocationsState();
}

class _ForageLocationsState extends ConsumerState<ForageLocations> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
  bool _isDeleting = false;

  Future<String> _getLocationAddress(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.locality ?? ''}${place.locality != null && place.country != null ? ', ' : ''}${place.country ?? ''}'
            .trim();
      }
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    } catch (e) {
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }

  Future<bool> _deleteConfirmation() async {
    if (_isDeleting) return false;
    _isDeleting = true;

    bool shouldDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Forage Location'),
          content: const Text(
              'Are you sure you want to delete this forage location?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                _isDeleting = false;
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                _isDeleting = false;
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return shouldDelete;
  }

  Stream<List<MarkerModel>> get _markersStream {
    final markerRepo = ref.read(markerRepositoryProvider);

    // For user locations, get markers by userId
    // For community locations (bookmarked), this would need bookmarked markers
    // Since we don't have bookmark info here, we'll just show user's markers
    return markerRepo.streamByUserId(widget.userId);
  }

  Future<void> _deleteMarker(String markerId) async {
    try {
      final markerRepo = ref.read(markerRepositoryProvider);
      await markerRepo.delete(markerId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete marker: $e')),
        );
      }
    }
  }

  void _showMarkerDetails(MarkerModel marker) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationDetailScreen(marker: marker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      appBar: AppBar(
        title: Text(
          widget.userLocations ? 'My Forage Spots' : 'Community Locations',
          style: AppTheme.title(size: 20, color: AppTheme.textWhite),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<MarkerModel>>(
          stream: _markersStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading markers: ${snapshot.error}',
                  style: TextStyle(color: AppTheme.error),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // For user's own locations, still show bookmarks section
              if (widget.userLocations) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bookmarked locations section
                      const BookmarkSection(),

                      // Subscribed collections section
                      const SubscribedCollectionsSection(),

                      // Empty state for user's locations
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.add_location_alt,
                                size: 64,
                                color: AppTheme.textLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No personal locations yet',
                                style: AppTheme.heading(
                                  size: 18,
                                  color: AppTheme.textMedium,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add markers on the map to save your forage spots',
                                textAlign: TextAlign.center,
                                style: AppTheme.body(
                                  size: 14,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // For friend's locations, show standard empty state
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 64,
                      color: AppTheme.textLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No locations found',
                      style: AppTheme.heading(
                        size: 18,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              );
            }

            final markers = snapshot.data!;

            // Show bookmarks section only when viewing user's own locations
            if (widget.userLocations) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bookmarked locations section
                    const BookmarkSection(),

                    // Subscribed collections section
                    const SubscribedCollectionsSection(),

                    // My Locations header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'My Locations',
                            style: AppTheme.heading(
                              size: 18,
                              color: AppTheme.textWhite,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${markers.length}',
                            style: AppTheme.caption(
                              size: 14,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // User's markers list
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      itemCount: markers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final marker = markers[index];
                        return _buildLocationCard(marker);
                      },
                    ),
                  ],
                ),
              );
            }

            // For non-user locations (friend's locations), just show the list
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ListView.separated(
                itemCount: markers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final marker = markers[index];
                  return _buildLocationCard(marker);
                },
              ),
            );
          },
        ),
    );
  }

  Widget _buildLocationCard(MarkerModel marker) {
    // CRITICAL: Only allow deletion if current user owns this marker
    final isOwner = marker.markerOwner == currentUser.email;
    final typeColor = ForageTypeUtils.getTypeColor(marker.type);

    final cardContent = Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      color: AppTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
        side: BorderSide(
          color: AppTheme.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: AppTheme.borderRadiusMedium,
        onTap: () => _showMarkerDetails(marker),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Optimized image container
              if (marker.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: AppTheme.borderRadiusSmall,
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: CachedNetworkImage(
                      imageUrl: marker.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.surfaceDark,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.surfaceDark,
                        child: Icon(Icons.error, color: AppTheme.textLight),
                      ),
                      fadeInDuration: const Duration(milliseconds: 300),
                      memCacheHeight: 140,
                    ),
                  ),
                )
              else
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: AppTheme.borderRadiusSmall,
                  ),
                  child: Icon(
                    Icons.photo,
                    size: 32,
                    color: AppTheme.textLight,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marker.name,
                      style: AppTheme.heading(
                        size: 14,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (marker.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        marker.description,
                        style: AppTheme.body(
                          size: 12,
                          color: AppTheme.textMedium,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Location coordinates
                    FutureBuilder<String>(
                      future: _getLocationAddress(
                          marker.latitude, marker.longitude),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox();
                        }
                        return Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 12, color: AppTheme.textLight),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                snapshot.data ??
                                    '${marker.latitude.toStringAsFixed(4)}, ${marker.longitude.toStringAsFixed(4)}',
                                style: AppTheme.caption(
                                  size: 11,
                                  color: AppTheme.textLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MMM dd').format(marker.timestamp),
                    style: AppTheme.caption(
                      size: 10,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Type icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.2),
                      borderRadius: AppTheme.borderRadiusSmall,
                    ),
                    child: Center(
                      child: ImageIcon(
                        AssetImage(
                          'lib/assets/images/${marker.type.toLowerCase()}_marker.png',
                        ),
                        size: 24,
                        color: typeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Only wrap with Dismissible if the current user owns this marker
    if (isOwner) {
      return Dismissible(
        key: Key(marker.id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: AppTheme.error,
            borderRadius: AppTheme.borderRadiusMedium,
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          final shouldDelete = await _deleteConfirmation();
          if (shouldDelete) {
            await _deleteMarker(marker.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Forage location deleted')),
              );
            }
          }
          return shouldDelete;
        },
        child: cardContent,
      );
    }

    // Return card without delete functionality for non-owners
    return cardContent;
  }
}
