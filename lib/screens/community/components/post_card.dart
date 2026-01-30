import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/post.dart';
import 'package:flutter_forager_app/data/models/post_comment.dart';
import 'package:flutter_forager_app/data/repositories/following_repository.dart';
import 'package:flutter_forager_app/data/repositories/post_repository.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';
import 'package:flutter_forager_app/screens/community/community_page.dart';
import 'package:flutter_forager_app/screens/community/components/comment_tile.dart';
import 'package:flutter_forager_app/screens/community/post_detail_screen.dart';
import 'package:flutter_forager_app/data/services/marker_service.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final bool isFavorite;
  final bool isBookmarked;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleBookmark;
  final VoidCallback onDelete;
  final TextEditingController commentController;
  final TextEditingController statusNoteController;
  final Function(String) onAddComment;
  final Function(String, String?) onUpdateStatus;
  final String currentUserEmail;
  final String? username;

  const PostCard({
    super.key,
    required this.post,
    required this.isFavorite,
    required this.isBookmarked,
    required this.onToggleFavorite,
    required this.onToggleBookmark,
    required this.onDelete,
    required this.commentController,
    required this.statusNoteController,
    required this.onAddComment,
    required this.onUpdateStatus,
    required this.currentUserEmail,
    this.username,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late String _selectedStatus;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  List<Map<String, dynamic>> _statusHistory = [];
  String? _markerId;
  bool _isFollowing = false;
  bool _isLoadingFollow = true;
  late final FollowingRepository _followingRepo;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.post.currentStatus;
    _statusHistory = List.from(widget.post.statusHistory);
    _followingRepo = FollowingRepository(firestoreService: FirestoreService());
    _fetchMarkerIdAndRefreshData();
    _checkFollowingStatus();
  }

  Future<void> _checkFollowingStatus() async {
    // Don't check if it's the user's own post
    if (widget.post.userEmail == widget.currentUserEmail) {
      setState(() => _isLoadingFollow = false);
      return;
    }

    try {
      final isFollowing = await _followingRepo.isFollowing(
        widget.currentUserEmail,
        widget.post.userEmail,
      );
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
          _isLoadingFollow = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      if (mounted) {
        setState(() => _isLoadingFollow = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoadingFollow) return;

    setState(() => _isLoadingFollow = true);

    try {
      final newFollowState = await _followingRepo.toggleFollow(
        userId: widget.currentUserEmail,
        targetEmail: widget.post.userEmail,
        targetDisplayName: widget.post.userEmail.split('@')[0],
      );

      if (mounted) {
        setState(() {
          _isFollowing = newFollowState;
          _isLoadingFollow = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newFollowState
                  ? 'Now following @${widget.post.userEmail.split('@')[0]}'
                  : 'Unfollowed @${widget.post.userEmail.split('@')[0]}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      if (mounted) {
        setState(() => _isLoadingFollow = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update follow status: $e')),
        );
      }
    }
  }

  Future<void> _fetchMarkerIdAndRefreshData() async {
    await _fetchMarkerId();
    if (_markerId != null) {
      await _refreshStatusHistory();
    }
  }

  Future<void> _fetchMarkerId() async {
    try {
      // Use root Markers collection (new architecture)
      final markersCollection = FirebaseFirestore.instance.collection('Markers');

      final snapshot = await markersCollection
          .where('name', isEqualTo: widget.post.name)
          .where('type', isEqualTo: widget.post.type)
          .where('markerOwner', isEqualTo: widget.post.originalMarkerOwner)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _markerId = snapshot.docs.first.id;
          });
        }
      } else {
        // Marker may have been deleted - that's okay, just don't show error
        debugPrint('Associated marker not found for post: ${widget.post.name}');
      }
    } catch (e) {
      debugPrint('Error fetching marker: $e');
    }
  }

  void _showCommentDialog() {
    // Create repository instance for streaming comments
    final postRepo = PostRepository(firestoreService: FirestoreService());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
        title: Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: AppTheme.primary, size: 22),
            const SizedBox(width: 8),
            StyledText('Comments', color: AppTheme.primary),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              // Streaming comments from subcollection
              Expanded(
                child: StreamBuilder<List<PostCommentModel>>(
                  stream: postRepo.streamComments(widget.post.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading comments',
                          style: AppTheme.body(color: AppTheme.error),
                        ),
                      );
                    }

                    final comments = snapshot.data ?? [];

                    if (comments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No comments yet',
                              style: AppTheme.body(color: AppTheme.textMedium),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to comment!',
                              style: AppTheme.caption(color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return CommentTile.fromModel(comment: comment);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Comment input field
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: AppTheme.borderRadiusSmall,
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        style: AppTheme.body(size: 14, color: AppTheme.textDark),
                        maxLines: 2,
                        minLines: 1,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send_rounded, color: AppTheme.primary),
                      onPressed: () async {
                        final newComment = widget.commentController.text.trim();
                        if (newComment.isNotEmpty) {
                          await widget.onAddComment(newComment);
                          widget.commentController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: AppTheme.body(color: AppTheme.textMedium),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog() {
    final notesController = TextEditingController();
    String? newStatus = _selectedStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current status: ${_selectedStatus.toUpperCase()}',
                style: AppTheme.body(size: 14, color: AppTheme.textDark),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: AppTheme.borderRadiusSmall,
                  border: Border.all(color: AppTheme.primary),
                ),
                child: DropdownButton<String>(
                  style: AppTheme.body(size: 12, color: AppTheme.textDark),
                  underline: const SizedBox(),
                  value: newStatus,
                  items: [
                    'active',
                    'abundant',
                    'sparse',
                    'out_of_season',
                    'no_longer_available'
                  ]
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: StyledTextMedium(
                              status.replaceAll('_', ' ').toUpperCase(),
                              color: AppTheme.textDark,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      newStatus = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Add notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                style: AppTheme.body(size: 14, color: AppTheme.textDark),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newStatus != null && _markerId != null) {
                  await _updateStatus(newStatus!, notesController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Submit Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshStatusHistory() async {
    if (_markerId == null) return;

    // Use root Markers collection
    final doc = await FirebaseFirestore.instance
        .collection('Markers')
        .doc(_markerId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _statusHistory =
              List<Map<String, dynamic>>.from(data['statusHistory'] ?? []);
          _selectedStatus = data['currentStatus'] ?? 'active';
        });
      }
    }
  }

  Future<void> _updateStatus(String newStatus, String notes) async {
    if (_markerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marker not found')),
      );
      return;
    }

    try {
      final markerService = MarkerService(FirebaseAuth.instance.currentUser!);
      await markerService.updateMarkerStatus(
        markerId: _markerId!,
        newStatus: newStatus,
        notes: notes,
        markerOwnerEmail: widget.post.originalMarkerOwner,
        markerName: widget.post.name,
        markerType: widget.post.type,
      );

      // Update the Posts collection to keep status in sync
      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(widget.post.id)
          .update({
        'currentStatus': newStatus,
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': newStatus,
            'userId': FirebaseAuth.instance.currentUser!.uid,
            'userEmail': FirebaseAuth.instance.currentUser!.email,
            'username': widget.username,
            'timestamp': DateTime.now(),
            if (notes.isNotEmpty) 'notes': notes,
          }
        ]),
      });

      await _refreshStatusHistory();

      if (mounted) {
        setState(() => _selectedStatus = newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                post: widget.post,
                isFavorite: widget.isFavorite,
                isBookmarked: widget.isBookmarked,
                onToggleFavorite: widget.onToggleFavorite,
                onToggleBookmark: widget.onToggleBookmark,
                onDelete: widget.onDelete,
                username: widget.username,
              ),
            ),
          );
        },
        borderRadius: AppTheme.borderRadiusMedium,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: AppTheme.borderRadiusMedium,
            border: Border.all(
              color: AppTheme.textLight.withValues(alpha: 0.15),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel with map preview
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image carousel
                Expanded(
                  child: widget.post.imageUrls.isNotEmpty
                      ? _buildImageCarousel(widget.post.imageUrls)
                      : Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ),
                ),
                // Map preview
                _buildMapPreview(),
              ],
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Row(
                children: [
                  Image.asset(
                    "lib/assets/images/${widget.post.type.toLowerCase()}_marker.png",
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.location_on,
                      size: 24,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.post.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.heading(size: 16, color: AppTheme.textDark),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.post.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(size: 13, color: AppTheme.textMedium),
                ),
              ),
              trailing: _buildCompactStatusBadge(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.favorite,
                          size: 16,
                          color: widget.isFavorite
                              ? AppTheme.accent
                              : AppTheme.textMedium,
                        ),
                        onPressed: widget.onToggleFavorite,
                        color: AppTheme.textMedium,
                      ),
                      StyledText('${widget.post.likeCount}',
                          color: AppTheme.textMedium),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.bookmark_add,
                          size: 16,
                          color: widget.isBookmarked
                              ? AppTheme.secondary
                              : AppTheme.textMedium,
                        ),
                        onPressed: widget.onToggleBookmark,
                        color: AppTheme.textMedium,
                      ),
                      StyledText('${widget.post.bookmarkCount}',
                          color: AppTheme.textMedium),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.comment_outlined, size: 16),
                        onPressed: _showCommentDialog,
                        color: AppTheme.textMedium,
                      ),
                      StyledText('${widget.post.commentCount}',
                          color: AppTheme.textMedium),
                    ],
                  ),
                  if (widget.post.userEmail == widget.currentUserEmail)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: widget.onDelete,
                      color: AppTheme.textMedium,
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: FutureBuilder<String?>(
                future: getLocationWithFlag(
                    widget.post.latitude, widget.post.longitude),
                builder: (context, snapshot) {
                  final location = snapshot.data ?? '';
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          '@${widget.post.userEmail.split('@')[0]}  •  $location  •  ${dateFormat.format(widget.post.postTimestamp)}',
                          style: AppTheme.caption(size: 11, color: AppTheme.textMedium),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Follow button (only show for other users' posts)
                      if (widget.post.userEmail != widget.currentUserEmail)
                        _buildFollowButton(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMapPreview() {
    return Container(
      width: 90,
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
        ),
        border: Border(
          left: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Background gradient - dark blue theme
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.surfaceDark,
                  AppTheme.backgroundDark.withValues(alpha: 0.9),
                  AppTheme.info.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
          // Map icon and coordinates
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 32,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.location_on,
                  size: 20,
                  color: AppTheme.accent,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.post.latitude.toStringAsFixed(2)}°',
                  style: AppTheme.caption(
                    size: 9,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '${widget.post.longitude.toStringAsFixed(2)}°',
                  style: AppTheme.caption(
                    size: 9,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(List<String> imageUrls) {
    return Stack(
      children: [
        SizedBox(
          height: 100,
          child: PageView.builder(
            controller: _pageController,
            itemCount: imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12.0),
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  memCacheHeight: 600,
                  placeholder: (context, url) => Container(
                    color: AppTheme.surfaceLight,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.surfaceLight,
                    child: Icon(Icons.image_not_supported,
                        color: AppTheme.textLight),
                  ),
                ),
              );
            },
          ),
        ),
        if (imageUrls.length > 1)
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build a compact status badge showing last update info
  Widget _buildCompactStatusBadge() {
    final lastUpdate = _statusHistory.isNotEmpty ? _statusHistory.last : null;
    final status = lastUpdate?['status'] ?? widget.post.currentStatus;
    final username = lastUpdate?['username'] ?? '';
    final timestamp = lastUpdate?['timestamp'];

    String dateStr = '';
    if (timestamp != null) {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        date = DateTime.now();
      }
      dateStr = DateFormat('MMM d').format(date);
    }

    return GestureDetector(
      onTap: _showStatusUpdateDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: _getStatusColor(status).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _getStatusColor(status).withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getStatusIcon(status),
              size: 10,
              color: _getStatusColor(status),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                username.isNotEmpty && dateStr.isNotEmpty
                    ? '${status.replaceAll('_', ' ')} • $username $dateStr'
                    : status.replaceAll('_', ' '),
                style: AppTheme.caption(
                  size: 9,
                  color: _getStatusColor(status),
                  weight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.primary;
      case 'abundant':
        return AppTheme.success;
      case 'sparse':
        return AppTheme.secondary;
      case 'out_of_season':
        return AppTheme.textMedium;
      case 'no_longer_available':
        return AppTheme.error;
      default:
        return AppTheme.textMedium;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle_outline;
      case 'abundant':
        return Icons.eco;
      case 'sparse':
        return Icons.remove_circle_outline;
      case 'out_of_season':
        return Icons.schedule;
      case 'no_longer_available':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildFollowButton() {
    if (_isLoadingFollow) {
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primary,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleFollow,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _isFollowing
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primary,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isFollowing ? Icons.check : Icons.person_add_outlined,
              size: 12,
              color: _isFollowing ? AppTheme.primary : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              _isFollowing ? 'Following' : 'Follow',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _isFollowing ? AppTheme.primary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
