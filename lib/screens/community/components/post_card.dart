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
import 'package:flutter_forager_app/screens/profile/user_profile_view_screen.dart';
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

  void _viewUserProfile(String username) {
    // Don't navigate if it's the current user's own post
    if (widget.post.userEmail == widget.currentUserEmail) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileViewScreen(
          userEmail: widget.post.userEmail,
          displayName: username,
        ),
      ),
    );
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
    final username = widget.post.userEmail.split('@')[0];
    final timeAgo = _getTimeAgo(widget.post.postTimestamp);

    // App theme green background
    final cardBg = AppTheme.primaryLight;
    final textPrimary = AppTheme.textWhite;
    final textSecondary = AppTheme.textWhite;

    return InkWell(
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
      child: Container(
        color: cardBg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with profile pic and initial overlay - tappable for profile
            GestureDetector(
              onTap: () => _viewUserProfile(username),
              child: _buildUserAvatar(username),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Username, time, follow button
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _viewUserProfile(username),
                        child: Text(
                          '@$username',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '· $timeAgo',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      // Follow button or delete
                      if (widget.post.userEmail != widget.currentUserEmail)
                        _buildCompactFollowButton()
                      else
                        GestureDetector(
                          onTap: widget.onDelete,
                          child: Icon(
                            Icons.more_horiz,
                            color: textSecondary,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Post title with type icon
                  Row(
                    children: [
                      Image.asset(
                        "lib/assets/images/${widget.post.type.toLowerCase()}_marker.png",
                        width: 18,
                        height: 18,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.eco,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.post.name,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Description
                  if (widget.post.description.isNotEmpty)
                    Text(
                      widget.post.description,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 10),
                  // Image (if exists) with status badge overlay
                  if (widget.post.imageUrls.isNotEmpty)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: widget.post.imageUrls.first,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 180,
                              color: AppTheme.backgroundLight,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 180,
                              color: AppTheme.backgroundLight,
                              child: Icon(Icons.image_not_supported, color: textSecondary),
                            ),
                          ),
                        ),
                        // Status badge in top-right corner
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _buildCompactStatusBadge(),
                        ),
                      ],
                    ),
                  // Show status badge inline if no image
                  if (widget.post.imageUrls.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildCompactStatusBadge(),
                    ),
                  const SizedBox(height: 10),
                  // Location row with coordinates
                  FutureBuilder<String?>(
                    future: getLocationWithFlag(widget.post.latitude, widget.post.longitude),
                    builder: (context, snapshot) {
                      final location = snapshot.data ?? '';
                      final coords = '${widget.post.latitude.toStringAsFixed(3)}°, ${widget.post.longitude.toStringAsFixed(3)}°';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location.isNotEmpty ? '$location · $coords' : coords,
                                style: TextStyle(color: textSecondary, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Action buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Comments
                      _buildActionButton(
                        icon: Icons.chat_bubble_outline,
                        count: widget.post.commentCount,
                        onTap: _showCommentDialog,
                        isActive: false,
                        activeColor: AppTheme.info,
                      ),
                      // Likes
                      _buildActionButton(
                        icon: widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                        count: widget.post.likeCount,
                        onTap: widget.onToggleFavorite,
                        isActive: widget.isFavorite,
                        activeColor: AppTheme.accent,
                      ),
                      // Bookmarks
                      _buildActionButton(
                        icon: widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        count: widget.post.bookmarkCount,
                        onTap: widget.onToggleBookmark,
                        isActive: widget.isBookmarked,
                        activeColor: AppTheme.secondary,
                      ),
                      // Share/Map
                      GestureDetector(
                        onTap: () {
                          // Could navigate to map location
                        },
                        child: Icon(
                          Icons.map_outlined,
                          size: 18,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String username) {
    return FutureBuilder<String?>(
      future: _getUserProfilePic(),
      builder: (context, snapshot) {
        final profilePic = snapshot.data;
        final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            children: [
              // Profile image background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  image: profilePic != null
                      ? DecorationImage(
                          image: AssetImage('lib/assets/images/$profilePic'),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {},
                        )
                      : null,
                ),
              ),
              // Initial overlay (bottom right)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _getUserProfilePic() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.post.userEmail)
          .get();
      if (userDoc.exists) {
        return userDoc.data()?['profilePic'] as String?;
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
    return null;
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
    required bool isActive,
    required Color activeColor,
  }) {
    final textSecondary = AppTheme.textWhite;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive ? activeColor : textSecondary,
          ),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: isActive ? activeColor : textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactFollowButton() {
    if (_isLoadingFollow) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return GestureDetector(
      onTap: _toggleFollow,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _isFollowing ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: _isFollowing
              ? Border.all(color: AppTheme.textWhite, width: 1)
              : null,
        ),
        child: Text(
          _isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            color: _isFollowing ? AppTheme.textWhite : Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  /// Build a compact status badge showing last update info - white card for readability
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

    final statusColor = _getStatusColor(status);

    return GestureDetector(
      onTap: _showStatusUpdateDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                _getStatusIcon(status),
                size: 12,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: AppTheme.caption(
                      size: 10,
                      color: statusColor,
                      weight: FontWeight.w700,
                    ),
                  ),
                  if (username.isNotEmpty || dateStr.isNotEmpty)
                    Text(
                      username.isNotEmpty && dateStr.isNotEmpty
                          ? '$username · $dateStr'
                          : username.isNotEmpty ? username : dateStr,
                      style: AppTheme.caption(
                        size: 8,
                        color: AppTheme.textMedium,
                      ),
                    ),
                ],
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
        return AppTheme.textWhite;
      case 'no_longer_available':
        return AppTheme.error;
      default:
        return AppTheme.textWhite;
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

}
