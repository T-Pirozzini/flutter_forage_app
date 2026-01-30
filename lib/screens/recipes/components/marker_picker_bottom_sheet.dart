import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/data/models/marker.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet for selecting a marker to link to an ingredient.
///
/// Shows user's foraged markers with search and type filtering.
/// Returns the selected marker for linking to the ingredient.
class MarkerPickerBottomSheet extends ConsumerStatefulWidget {
  final String? filterByType;
  final Function(MarkerModel) onMarkerSelected;

  const MarkerPickerBottomSheet({
    super.key,
    this.filterByType,
    required this.onMarkerSelected,
  });

  @override
  ConsumerState<MarkerPickerBottomSheet> createState() =>
      _MarkerPickerBottomSheetState();
}

class _MarkerPickerBottomSheetState
    extends ConsumerState<MarkerPickerBottomSheet> {
  String _searchQuery = '';
  String? _selectedType;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.filterByType;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markerRepo = ref.watch(markerRepositoryProvider);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Please sign in'));
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
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

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.eco, color: AppTheme.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Link to Forage Location',
                        style: AppTheme.heading(size: 18, color: AppTheme.textDark),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Privacy note
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: AppTheme.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Only friends can see the linked location',
                        style: AppTheme.caption(size: 12, color: AppTheme.info),
                      ),
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search your locations...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(height: 8),

              // Type filter chips
              if (widget.filterByType == null)
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildTypeChip(null, 'All'),
                      ...ForageTypeUtils.allTypes
                          .map((type) => _buildTypeChip(type, ForageTypeUtils.normalizeType(type))),
                    ],
                  ),
                ),
              const SizedBox(height: 8),

              // Marker list
              Expanded(
                child: StreamBuilder<List<MarkerModel>>(
                  stream: markerRepo.streamByUserId(user.email!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading markers: ${snapshot.error}'),
                      );
                    }

                    var markers = snapshot.data ?? [];

                    // Filter by search query
                    if (_searchQuery.isNotEmpty) {
                      markers = markers
                          .where((m) =>
                              m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              (m.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
                          .toList();
                    }

                    // Filter by type
                    if (_selectedType != null) {
                      markers = markers
                          .where((m) => m.type.toLowerCase() == _selectedType!.toLowerCase())
                          .toList();
                    }

                    if (markers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off_outlined,
                              size: 48,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty || _selectedType != null
                                  ? 'No matching locations found'
                                  : 'No foraged locations yet',
                              style: AppTheme.body(color: AppTheme.textMedium),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: markers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final marker = markers[index];
                        return _buildMarkerTile(marker);
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

  Widget _buildTypeChip(String? type, String label) {
    final isSelected = _selectedType == type;
    final color = type != null ? ForageTypeUtils.getTypeColor(type) : AppTheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : AppTheme.textMedium,
        ),
        backgroundColor: AppTheme.surfaceLight,
        selectedColor: color,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? color : AppTheme.textLight.withValues(alpha: 0.3),
        ),
        onSelected: (selected) {
          setState(() => _selectedType = selected ? type : null);
        },
      ),
    );
  }

  Widget _buildMarkerTile(MarkerModel marker) {
    final color = ForageTypeUtils.getTypeColor(marker.type);

    return InkWell(
      onTap: () {
        widget.onMarkerSelected(marker);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.textLight.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Image.asset(
                  'lib/assets/images/${marker.type.toLowerCase()}_marker.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (context, error, stackTrace) {
                    return ForageTypeUtils.getTypeIcon(marker.type, size: 24);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name and type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    marker.name,
                    style: AppTheme.body(
                      size: 14,
                      color: AppTheme.textDark,
                      weight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ForageTypeUtils.normalizeType(marker.type),
                    style: AppTheme.caption(
                      size: 12,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),

            // Select indicator
            Icon(
              Icons.add_circle_outline,
              color: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
