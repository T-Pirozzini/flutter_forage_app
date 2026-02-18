import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Public feedback/feature requests tab with timeline-style cards
class FeedbackTab extends StatefulWidget {
  final String? username;
  final String? userProfilePic;

  const FeedbackTab({
    super.key,
    this.username,
    this.userProfilePic,
  });

  @override
  State<FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends State<FeedbackTab> {
  final _controller = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser!;
  final _dateFormat = DateFormat('MMM d');
  final _timeFormat = DateFormat('h:mm a');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('Feedback').add({
        'userId': _currentUser.uid,
        'userEmail': _currentUser.email!,
        'username': widget.username ?? _currentUser.email!.split('@')[0],
        'profilePic': widget.userProfilePic ?? '',
        'feedback': text,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': <String>[],
        'comments': <Map<String, dynamic>>[],
      });

      _controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryLight.withValues(alpha: 0.15),
      child: Column(
        children: [
          // Compact input at top
          _buildInputSection(),
          // Feedback list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Feedback')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = {
                    ...doc.data() as Map<String, dynamic>,
                    'docId': doc.id,
                  };
                  return _FeedbackCard(
                    data: data,
                    dateFormat: _dateFormat,
                    timeFormat: _timeFormat,
                    currentUsername: widget.username,
                    currentProfilePic: widget.userProfilePic,
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // User avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
            backgroundImage: widget.userProfilePic != null &&
                    widget.userProfilePic!.isNotEmpty
                ? AssetImage('lib/assets/images/${widget.userProfilePic}')
                : null,
            child: widget.userProfilePic == null || widget.userProfilePic!.isEmpty
                ? Icon(Icons.person, size: 18, color: AppTheme.primary)
                : null,
          ),
          const SizedBox(width: 10),
          // Text field
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Suggest a feature or improvement...',
                hintStyle: AppTheme.body(
                  size: 14,
                  color: AppTheme.textLight,
                ),
                filled: true,
                fillColor: AppTheme.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
              style: AppTheme.body(size: 14, color: AppTheme.textDark),
              maxLines: 2,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          // Submit button
          IconButton(
            onPressed: _submitFeedback,
            icon: Icon(Icons.send_rounded, color: AppTheme.primary),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No feature requests yet',
            style: AppTheme.body(color: AppTheme.textMedium),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your ideas!',
            style: AppTheme.caption(color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }
}

/// Timeline-style feedback card
class _FeedbackCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final DateFormat dateFormat;
  final DateFormat timeFormat;
  final String? currentUsername;
  final String? currentProfilePic;

  const _FeedbackCard({
    required this.data,
    required this.dateFormat,
    required this.timeFormat,
    this.currentUsername,
    this.currentProfilePic,
  });

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  final _commentController = TextEditingController();
  bool _isLiked = false;
  int _likeCount = 0;
  bool _showComments = false;

  @override
  void initState() {
    super.initState();
    _updateLikeState();
  }

  @override
  void didUpdateWidget(covariant _FeedbackCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _updateLikeState();
    }
  }

  void _updateLikeState() {
    _likeCount = widget.data['likes'] ?? 0;
    final likedBy = widget.data['likedBy'] as List<dynamic>? ?? [];
    _isLiked = likedBy
        .map((e) => e.toString())
        .contains(FirebaseAuth.instance.currentUser!.uid);
  }

  Future<void> _toggleLike() async {
    final docId = widget.data['docId'] as String;
    final docRef = FirebaseFirestore.instance.collection('Feedback').doc(docId);
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final likedBy = (widget.data['likedBy'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    setState(() {
      if (_isLiked) {
        _likeCount--;
        likedBy.remove(currentUserId);
      } else {
        _likeCount++;
        likedBy.add(currentUserId);
      }
      _isLiked = !_isLiked;
    });

    try {
      await docRef.update({
        'likes': _likeCount,
        'likedBy': likedBy,
      });
    } catch (e) {
      debugPrint('Error updating like: $e');
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final docId = widget.data['docId'] as String;
    final docRef = FirebaseFirestore.instance.collection('Feedback').doc(docId);
    final currentUser = FirebaseAuth.instance.currentUser!;

    final newComment = {
      'userId': currentUser.uid,
      'username': widget.currentUsername ?? currentUser.email!.split('@')[0],
      'comment': text,
      'timestamp': Timestamp.fromDate(DateTime.now()),
      'profilePic': widget.currentProfilePic ?? '',
    };

    _commentController.clear();

    try {
      await docRef.update({
        'comments': FieldValue.arrayUnion([newComment]),
      });
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.data['username'] ??
        widget.data['userEmail']?.split('@')[0] ??
        'Anonymous';
    final profilePic = widget.data['profilePic'] ?? '';
    final timestamp = widget.data['timestamp'] as Timestamp?;
    final feedback = widget.data['feedback'] ?? '';
    final comments =
        List<Map<String, dynamic>>.from(widget.data['comments'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.surfaceLight,
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 100,
                color: AppTheme.primary.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Card content
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusMedium,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Avatar, username, time
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppTheme.primary.withValues(alpha: 0.2),
                          backgroundImage: profilePic.isNotEmpty
                              ? AssetImage('lib/assets/images/$profilePic')
                              : null,
                          child: profilePic.isEmpty
                              ? Icon(Icons.person,
                                  size: 16, color: AppTheme.primary)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '@$username',
                                style: AppTheme.body(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              if (timestamp != null)
                                Text(
                                  '${widget.dateFormat.format(timestamp.toDate())} at ${widget.timeFormat.format(timestamp.toDate())}',
                                  style: AppTheme.caption(
                                    size: 11,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Feedback content
                    Text(
                      feedback,
                      style: AppTheme.body(
                        size: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Actions: Like, Comment
                    Row(
                      children: [
                        // Like button
                        InkWell(
                          onTap: _toggleLike,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _isLiked
                                  ? AppTheme.error.withValues(alpha: 0.1)
                                  : AppTheme.backgroundLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 16,
                                  color: _isLiked
                                      ? AppTheme.error
                                      : AppTheme.textMedium,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$_likeCount',
                                  style: AppTheme.caption(
                                    size: 12,
                                    color: _isLiked
                                        ? AppTheme.error
                                        : AppTheme.textMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Comment button
                        InkWell(
                          onTap: () =>
                              setState(() => _showComments = !_showComments),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 16,
                                  color: AppTheme.textMedium,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${comments.length}',
                                  style: AppTheme.caption(
                                    size: 12,
                                    color: AppTheme.textMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Comments section (collapsible)
                    if (_showComments) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      // Existing comments
                      ...comments.map((comment) => _buildComment(comment)),
                      // Add comment input
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: AppTheme.caption(
                                  color: AppTheme.textLight,
                                ),
                                filled: true,
                                fillColor: AppTheme.backgroundLight,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                              ),
                              style: AppTheme.caption(color: AppTheme.textDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addComment,
                            icon: Icon(Icons.send, size: 18),
                            color: AppTheme.primary,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment(Map<String, dynamic> comment) {
    final username = comment['username'] ?? 'Anonymous';
    final profilePic = comment['profilePic'] ?? '';
    final text = comment['comment'] ?? '';
    final timestamp = comment['timestamp'] as Timestamp?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
            backgroundImage: profilePic.isNotEmpty
                ? AssetImage('lib/assets/images/$profilePic')
                : null,
            child: profilePic.isEmpty
                ? Icon(Icons.person, size: 12, color: AppTheme.primary)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '@$username',
                      style: AppTheme.caption(
                        size: 11,
                        weight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (timestamp != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        widget.dateFormat.format(timestamp.toDate()),
                        style: AppTheme.caption(
                          size: 10,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: AppTheme.caption(
                    size: 12,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
