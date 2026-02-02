import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/data/models/marker.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/forage_locations/location_detail_screen.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

/// Tab showing user's own markers with search, sort, and delete functionality
class MyLocationsTab extends ConsumerStatefulWidget {
  final String userId;

  const MyLocationsTab({Key? key, required this.userId}) : super(key: key);

  @override
  ConsumerState<MyLocationsTab> createState() => _MyLocationsTabState();
}

class _MyLocationsTabState extends ConsumerState<MyLocationsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'recent'; // recent, name, type
  bool _isDeleting = false;
  final dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  List<MarkerModel> _filterAndSortMarkers(List<MarkerModel> markers) {
    // Filter by search query
    var filtered = markers.where((m) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return m.name.toLowerCase().contains(query) ||
          m.description.toLowerCase().contains(query) ||
          m.type.toLowerCase().contains(query);
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'type':
        filtered.sort((a, b) => a.type.compareTo(b.type));
        break;
      case 'recent':
      default:
        filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    return filtered;
  }

  Future<bool> _deleteConfirmation() async {
    if (_isDeleting) return false;
    _isDeleting = true;

    bool shouldDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Location'),
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
                  style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
    return shouldDelete;
  }

  Future<void> _deleteMarker(String markerId) async {
    try {
      final markerRepo = ref.read(markerRepositoryProvider);
      await markerRepo.delete(markerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
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
    final markerRepo = ref.watch(markerRepositoryProvider);

    return Column(
      children: [
        // Search and Sort Bar
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.surfaceLight,
          child: Row(
            children: [
              // Search field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search locations...',
                    hintStyle: AppTheme.caption(size: 13, color: AppTheme.textLight),
                    prefixIcon: Icon(Icons.search, color: AppTheme.textLight, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: AppTheme.textLight, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusSmall,
                      borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusSmall,
                      borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusSmall,
                      borderSide: BorderSide(color: AppTheme.primary),
                    ),
                  ),
                  style: AppTheme.body(size: 13),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 8),
              // Sort dropdown
              PopupMenuButton<String>(
                icon: Icon(Icons.sort, color: AppTheme.primary),
                tooltip: 'Sort by',
                onSelected: (value) => setState(() => _sortBy = value),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'recent',
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: _sortBy == 'recent' ? AppTheme.primary : AppTheme.textMedium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recent',
                          style: TextStyle(
                            color: _sortBy == 'recent' ? AppTheme.primary : AppTheme.textDark,
                            fontWeight: _sortBy == 'recent' ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'name',
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort_by_alpha,
                          size: 18,
                          color: _sortBy == 'name' ? AppTheme.primary : AppTheme.textMedium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Name',
                          style: TextStyle(
                            color: _sortBy == 'name' ? AppTheme.primary : AppTheme.textDark,
                            fontWeight: _sortBy == 'name' ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'type',
                    child: Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 18,
                          color: _sortBy == 'type' ? AppTheme.primary : AppTheme.textMedium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Type',
                          style: TextStyle(
                            color: _sortBy == 'type' ? AppTheme.primary : AppTheme.textDark,
                            fontWeight: _sortBy == 'type' ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Locations list
        Expanded(
          child: StreamBuilder<List<MarkerModel>>(
            stream: markerRepo.streamByUserId(widget.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading locations: ${snapshot.error}',
                    style: TextStyle(color: AppTheme.error),
                  ),
                );
              }

              final allMarkers = snapshot.data ?? [];
              final markers = _filterAndSortMarkers(allMarkers);

              if (allMarkers.isEmpty) {
                return _buildEmptyState();
              }

              if (markers.isEmpty && _searchQuery.isNotEmpty) {
                return _buildNoResultsState();
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: markers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final marker = markers[index];
                  return _buildLocationCard(marker);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_location_alt, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(
            'No locations yet',
            style: AppTheme.heading(size: 18, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 8),
          Text(
            'Add markers on the Explore map\nto save your forage spots',
            textAlign: TextAlign.center,
            style: AppTheme.body(size: 14, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: AppTheme.heading(size: 16, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: AppTheme.body(size: 14, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(MarkerModel marker) {
    final cardContent = Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: InkWell(
        borderRadius: AppTheme.borderRadiusMedium,
        onTap: () => _showMarkerDetails(marker),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
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
                        color: AppTheme.surfaceLight,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.surfaceLight,
                        child: Icon(Icons.error, color: AppTheme.textLight),
                      ),
                      memCacheHeight: 140,
                    ),
                  ),
                )
              else
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: AppTheme.borderRadiusSmall,
                  ),
                  child: Icon(Icons.photo, size: 32, color: AppTheme.textLight),
                ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marker.name,
                      style: AppTheme.heading(size: 14, color: AppTheme.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (marker.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        marker.description,
                        style: AppTheme.body(size: 12, color: AppTheme.textMedium),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    FutureBuilder<String>(
                      future: _getLocationAddress(marker.latitude, marker.longitude),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'Loading...',
                          style: AppTheme.caption(size: 11, color: AppTheme.textLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Type icon and date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateFormat.format(marker.timestamp),
                    style: AppTheme.caption(size: 10, color: AppTheme.textLight),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ForageTypeUtils.getTypeColor(marker.type).withValues(alpha: 0.2),
                      borderRadius: AppTheme.borderRadiusSmall,
                    ),
                    child: Center(
                      child: ImageIcon(
                        AssetImage('lib/assets/images/${marker.type.toLowerCase()}_marker.png'),
                        size: 24,
                        color: ForageTypeUtils.getTypeColor(marker.type),
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

    // Wrap with Dismissible for swipe-to-delete
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
        }
        return shouldDelete;
      },
      child: cardContent,
    );
  }
}
