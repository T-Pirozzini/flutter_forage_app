import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/models/post.dart';
import 'package:flutter_forager_app/screens/community/community_page.dart';
import 'package:flutter_forager_app/screens/community/components/comment_tile.dart';
import 'package:flutter_forager_app/screens/community/components/status_update_tile.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart';
import 'package:intl/intl.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final bool isFavorite;
  final bool isBookmarked;
  final VoidCallback onToggleExpand;
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
    required this.onToggleExpand,
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
  bool _showStatusHistory = false;
  bool _showComments = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.post.currentStatus;
  }

  void _showCommentDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: StyledText('Comments', color: AppColors.secondaryColor),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.post.comments.isNotEmpty)
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: widget.post.comments.length,
                        itemBuilder: (context, index) {
                          final comment = widget.post.comments[index];
                          return CommentTile(comment: comment);
                        },
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('No comments yet'),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: widget.commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(
                          color: AppColors.textColor.withOpacity(0.6)),
                      filled: true,
                      fillColor: AppColors.primaryAccent.withOpacity(0.3),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          final newComment = widget.commentController.text;
                          if (newComment.isNotEmpty) {
                            await widget.onAddComment(newComment);
                            widget.commentController.clear();
                            if (mounted) {
                              // Check if the widget is still mounted
                              setState(() {});
                            }
                          }
                        },
                      ),
                    ),
                    style: TextStyle(color: AppColors.textColor),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: StyledText('Close', color: AppColors.secondaryColor),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: StyledText('Update Status', color: AppColors.secondaryColor),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                        value: 'harvested', child: Text('Harvested')),
                    DropdownMenuItem(
                        value: 'depleted', child: Text('Depleted')),
                    DropdownMenuItem(
                        value: 'verified', child: Text('Verified')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Status',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: widget.statusNoteController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Notes (optional)',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await widget.onUpdateStatus(
                    _selectedStatus,
                    widget.statusNoteController.text,
                  );
                  setState(() {
                    widget.post.currentStatus = _selectedStatus;
                    widget.post.statusHistory.add({
                      'status': _selectedStatus,
                      'note': widget.statusNoteController.text,
                      'timestamp': Timestamp.now(),
                      'updatedBy': widget.currentUserEmail,
                    });
                  });
                  widget.statusNoteController.clear();
                  Navigator.pop(context);
                },
                child: StyledText('Submit', color: AppColors.secondaryColor),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: StyledText('Cancel', color: AppColors.secondaryColor),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color: Colors.deepOrange.shade200,
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.post.imageUrls.isNotEmpty)
              _buildImageCarousel(widget.post.imageUrls),
            ListTile(
              title: Row(
                children: [
                  Image.asset(
                    "lib/assets/images/${widget.post.type.toLowerCase()}.png",
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.post.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text(widget.post.description),
                  const SizedBox(height: 5),
                  _buildStatusChip(widget.post.currentStatus),
                ],
              ),
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
                          size: 18,
                          color: widget.isFavorite
                              ? AppColors.secondaryColor
                              : AppColors.primaryAccent.withOpacity(0.7),
                        ),
                        onPressed: widget.onToggleFavorite,
                        color: AppColors.primaryAccent.withOpacity(0.7),
                      ),
                      StyledText('${widget.post.likeCount}',
                          color: AppColors.primaryAccent.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.bookmark_add,
                          size: 18,
                          color: widget.isBookmarked
                              ? AppColors.secondaryColor
                              : AppColors.primaryAccent.withOpacity(0.7),
                        ),
                        onPressed: widget.onToggleBookmark,
                        color: AppColors.primaryAccent.withOpacity(0.7),
                      ),
                      StyledText('${widget.post.bookmarkCount}',
                          color: AppColors.primaryAccent.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.comment_outlined, size: 18),
                        onPressed: _showCommentDialog,
                        color: AppColors.primaryAccent.withOpacity(0.7),
                      ),
                      StyledText('${widget.post.commentCount}',
                          color: AppColors.primaryAccent.withOpacity(0.7)),
                    ],
                  ),
                  if (widget.post.userEmail == widget.currentUserEmail)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: widget.onDelete,
                      color: AppColors.primaryAccent.withOpacity(0.7),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 5),
                      Text(widget.post.userEmail.split('@')[0]),
                    ],
                  ),
                  FutureBuilder<String?>(
                    future: getAreaFromCoordinates(
                        widget.post.latitude, widget.post.longitude),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(snapshot.data ?? '');
                      } else if (snapshot.hasError) {
                        return const SizedBox.shrink();
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                  Text(
                    dateFormat.format(widget.post.postTimestamp),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.deepOrange.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (_isExpanded) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status History',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _showStatusHistory
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                          onPressed: () {
                            setState(() {
                              _showStatusHistory = !_showStatusHistory;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_showStatusHistory)
                      ...widget.post.statusHistory.reversed.map((update) {
                        final timestamp = update['timestamp'] as Timestamp?;
                        return StatusUpdateTile(
                            update: update, timestamp: timestamp);
                      }).toList(),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: _showStatusDialog,
                      color: AppColors.textColor.withOpacity(0.7),
                    ),
                    StyledText('Update Status',
                        color: AppColors.textColor.withOpacity(0.7)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> imageUrls) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12.0),
              topRight: Radius.circular(12.0),
            ),
            child: CachedNetworkImage(
              imageUrl: imageUrls[index],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.error),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status) {
      case 'active':
        chipColor = Colors.green;
        break;
      case 'harvested':
        chipColor = Colors.orange;
        break;
      case 'depleted':
        chipColor = Colors.red;
        break;
      case 'verified':
        chipColor = Colors.blue;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: chipColor,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
