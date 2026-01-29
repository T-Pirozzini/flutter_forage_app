import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/bookmark.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/forage/map_page.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  void _viewOnMap(BookmarkModel bookmark) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapPage(
          initialLocation: LatLng(bookmark.latitude, bookmark.longitude),
        ),
      ),
    );
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
                      child: StyledHeading('Bookmarked Locations'),
                    ),
                    Text(
                      '${bookmarks.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[600],
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
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(12),
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
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.amber.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _viewOnMap(bookmark),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (bookmark.imageUrl != null && bookmark.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: CachedNetworkImage(
                        imageUrl: bookmark.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.photo,
                      size: 30,
                      color: Colors.grey[400],
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
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bookmark.markerDescription,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'by ${bookmark.markerOwner.split('@').first}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('MMM dd').format(bookmark.bookmarkedAt),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
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
                    color: _getTypeColor(bookmark.type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: ImageIcon(
                      AssetImage(
                        'lib/assets/images/${bookmark.type.toLowerCase()}_marker.png',
                      ),
                      size: 24,
                      color: _getTypeColor(bookmark.type),
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

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'berries':
        return Colors.purpleAccent;
      case 'mushrooms':
        return Colors.orangeAccent;
      case 'nuts':
        return Colors.brown;
      case 'herbs':
        return Colors.lightGreen;
      case 'tree':
        return Colors.green;
      case 'fish':
        return Colors.blue;
      default:
        return Colors.deepOrangeAccent;
    }
  }
}
