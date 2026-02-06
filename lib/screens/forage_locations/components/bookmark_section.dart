import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/data/models/bookmark.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/forage_locations/location_detail_screen.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// A widget that displays the user's bookmarked locations.
///
/// This is used in the ForageLocationsPage to show community locations
/// that the user has saved for quick access.
class BookmarkSection extends ConsumerStatefulWidget {
  const BookmarkSection({Key? key}) : super(key: key);

  @override
  ConsumerState<BookmarkSection> createState() => _BookmarkSectionState();
}

class _BookmarkSectionState extends ConsumerState<BookmarkSection> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool _isExpanded = true;

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
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final bookmarkRepo = ref.read(bookmarkRepositoryProvider);
        await bookmarkRepo.removeBookmark(currentUser.email!, bookmarkId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bookmark removed')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove bookmark: $e')),
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
    final bookmarkRepo = ref.read(bookmarkRepositoryProvider);

    return StreamBuilder<List<BookmarkModel>>(
      stream: bookmarkRepo.streamBookmarks(currentUser.email!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final bookmarks = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.bookmark,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bookmarked Locations',
                        style: AppTheme.heading(size: 18, color: AppTheme.textWhite),
                      ),
                    ),
                    Text(
                      '${bookmarks.length}',
                      style: AppTheme.caption(size: 14, color: AppTheme.textLight),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.textLight,
                    ),
                  ],
                ),
              ),
            ),

            // Bookmarks list
            if (_isExpanded)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: bookmarks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final bookmark = bookmarks[index];
                  return _buildBookmarkCard(bookmark);
                },
              ),

            if (_isExpanded) const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildBookmarkCard(BookmarkModel bookmark) {
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
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        await _removeBookmark(bookmark.id);
        return false; // We handle removal ourselves
      },
      child: Card(
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
                      width: 60,
                      height: 60,
                      child: CachedNetworkImage(
                        imageUrl: bookmark.imageUrl!,
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
                      ),
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: AppTheme.borderRadiusSmall,
                    ),
                    child: Icon(
                      Icons.photo,
                      size: 30,
                      color: AppTheme.textLight,
                    ),
                  ),

                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bookmark,
                            size: 16,
                            color: Colors.amber,
                          ),
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
                      const SizedBox(height: 4),
                      Text(
                        bookmark.markerDescription,
                        style: AppTheme.body(size: 12, color: AppTheme.textMedium),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'by ${bookmark.markerOwner.split('@').first}',
                            style: AppTheme.caption(size: 11, color: AppTheme.textLight),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('MMM dd').format(bookmark.bookmarkedAt),
                            style: AppTheme.caption(size: 11, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Type icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ForageTypeUtils.getTypeColor(bookmark.type).withValues(alpha: 0.2),
                    borderRadius: AppTheme.borderRadiusSmall,
                  ),
                  child: Center(
                    child: ImageIcon(
                      AssetImage(
                        'lib/assets/images/${bookmark.type.toLowerCase()}_marker.png',
                      ),
                      size: 24,
                      color: ForageTypeUtils.getTypeColor(bookmark.type),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
