import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/data/models/bookmark.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/forage_locations/location_detail_screen.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Tab showing user's bookmarked locations from friends/community
class BookmarkedTab extends ConsumerStatefulWidget {
  final String userId;

  const BookmarkedTab({Key? key, required this.userId}) : super(key: key);

  @override
  ConsumerState<BookmarkedTab> createState() => _BookmarkedTabState();
}

class _BookmarkedTabState extends ConsumerState<BookmarkedTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'recent'; // recent, name, owner
  final dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BookmarkModel> _filterAndSortBookmarks(List<BookmarkModel> bookmarks) {
    // Filter by search query
    var filtered = bookmarks.where((b) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return b.markerName.toLowerCase().contains(query) ||
          b.markerDescription.toLowerCase().contains(query) ||
          b.markerOwner.toLowerCase().contains(query) ||
          b.type.toLowerCase().contains(query);
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.markerName.compareTo(b.markerName));
        break;
      case 'owner':
        filtered.sort((a, b) => a.markerOwner.compareTo(b.markerOwner));
        break;
      case 'recent':
      default:
        filtered.sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt));
    }

    return filtered;
  }

  Future<void> _removeBookmark(String bookmarkId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Bookmark'),
        content: const Text('Remove this location from your bookmarks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final bookmarkRepo = ref.read(bookmarkRepositoryProvider);
        await bookmarkRepo.removeBookmark(widget.userId, bookmarkId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bookmark removed')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove: $e')),
          );
        }
      }
    }
  }

  Future<void> _viewBookmarkDetail(BookmarkModel bookmark) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final markerRepo = ref.read(markerRepositoryProvider);

      // First try to find marker by ID
      var marker = await markerRepo.getById(bookmark.markerId);

      // If not found by ID, try to find by owner and coordinates
      // This handles bookmarks created from community posts (postId stored as markerId)
      if (marker == null) {
        marker = await markerRepo.findByOwnerAndCoordinates(
          ownerEmail: bookmark.markerOwner,
          latitude: bookmark.latitude,
          longitude: bookmark.longitude,
        );
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (marker != null) {
        final foundMarker = marker; // Capture non-null for closure
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LocationDetailScreen(marker: foundMarker),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not found. It may have been deleted.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkRepo = ref.watch(bookmarkRepositoryProvider);

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
                    hintText: 'Search bookmarks...',
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
                    value: 'owner',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 18,
                          color: _sortBy == 'owner' ? AppTheme.primary : AppTheme.textMedium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Owner',
                          style: TextStyle(
                            color: _sortBy == 'owner' ? AppTheme.primary : AppTheme.textDark,
                            fontWeight: _sortBy == 'owner' ? FontWeight.w600 : FontWeight.normal,
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

        // Bookmarks list
        Expanded(
          child: StreamBuilder<List<BookmarkModel>>(
            stream: bookmarkRepo.streamBookmarks(widget.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading bookmarks: ${snapshot.error}',
                    style: TextStyle(color: AppTheme.error),
                  ),
                );
              }

              final allBookmarks = snapshot.data ?? [];
              final bookmarks = _filterAndSortBookmarks(allBookmarks);

              if (allBookmarks.isEmpty) {
                return _buildEmptyState();
              }

              if (bookmarks.isEmpty && _searchQuery.isNotEmpty) {
                return _buildNoResultsState();
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: bookmarks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final bookmark = bookmarks[index];
                  return _buildBookmarkCard(bookmark);
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
          Icon(Icons.bookmark_border, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(
            'No bookmarks yet',
            style: AppTheme.heading(size: 18, color: AppTheme.textMedium),
          ),
          const SizedBox(height: 8),
          Text(
            'Bookmark locations from the Explore map\nto save them here',
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

  Widget _buildBookmarkCard(BookmarkModel bookmark) {
    final cardContent = Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
        side: BorderSide(
          color: AppTheme.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: AppTheme.borderRadiusMedium,
        onTap: () => _viewBookmarkDetail(bookmark),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              if (bookmark.imageUrl != null && bookmark.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: AppTheme.borderRadiusSmall,
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: CachedNetworkImage(
                      imageUrl: bookmark.imageUrl!,
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
                    Row(
                      children: [
                        Icon(Icons.bookmark, size: 14, color: AppTheme.secondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            bookmark.markerName,
                            style: AppTheme.heading(size: 14, color: AppTheme.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (bookmark.markerDescription.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        bookmark.markerDescription,
                        style: AppTheme.body(size: 12, color: AppTheme.textMedium),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 12, color: AppTheme.textLight),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            bookmark.markerOwner.split('@').first,
                            style: AppTheme.caption(size: 11, color: AppTheme.textLight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
                    dateFormat.format(bookmark.bookmarkedAt),
                    style: AppTheme.caption(size: 10, color: AppTheme.textLight),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ForageTypeUtils.getTypeColor(bookmark.type).withValues(alpha: 0.2),
                      borderRadius: AppTheme.borderRadiusSmall,
                    ),
                    child: Center(
                      child: ImageIcon(
                        AssetImage('lib/assets/images/${bookmark.type.toLowerCase()}_marker.png'),
                        size: 24,
                        color: ForageTypeUtils.getTypeColor(bookmark.type),
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

    // Wrap with Dismissible for swipe-to-remove
    return Dismissible(
      key: Key(bookmark.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.bookmark_remove, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        await _removeBookmark(bookmark.id);
        return false; // We handle removal ourselves
      },
      child: cardContent,
    );
  }
}
