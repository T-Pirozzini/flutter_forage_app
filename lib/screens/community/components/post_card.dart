import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/models/post.dart';
import 'package:flutter_forager_app/screens/community/community_page.dart';
import 'package:flutter_forager_app/screens/community/components/comment_tile.dart';
import 'package:flutter_forager_app/screens/forage/services/marker_service.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final String status;
  final List<Map<String, dynamic>> comments;
  final List<Map<String, dynamic>> statusHistory;

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
    this.status = 'active',
    this.comments = const [],
    this.statusHistory = const [],
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
  List<Map<String, dynamic>> _comments = [];
  String? _markerId;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.post.currentStatus;
    _statusHistory = List.from(widget.statusHistory);
    _comments = List.from(widget.comments);
    _fetchMarkerIdAndRefreshData();
  }

  Future<void> _fetchMarkerIdAndRefreshData() async {
    await _fetchMarkerId();
    if (_markerId != null) {
      await _refreshData();
    }
  }

  Future<void> _fetchMarkerId() async {
    try {
      final markersCollection = FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.post.originalMarkerOwner)
          .collection('Markers');

      final snapshot = await markersCollection
          .where('name', isEqualTo: widget.post.name)
          .where('type', isEqualTo: widget.post.type)
          .where('location.latitude', isEqualTo: widget.post.latitude)
          .where('location.longitude', isEqualTo: widget.post.longitude)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _markerId = snapshot.docs.first.id;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Associated marker not found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching marker: $e')),
        );
      }
    }
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
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                color: AppColors.textColor.withValues(alpha: 0.9),
                child: DropdownButton<String>(
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white,
                  ),
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
                              color: Colors.black, // Black font for menu items
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
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textColor,
                ),
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

  Future<void> _refreshData() async {
    await _refreshStatusHistory();
    await _refreshComments();
  }

  Future<void> _refreshStatusHistory() async {
    if (_markerId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.post.originalMarkerOwner)
        .collection('Markers')
        .doc(_markerId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _statusHistory =
            List<Map<String, dynamic>>.from(data['statusHistory'] ?? []);
        _selectedStatus = data['currentStatus'] ?? 'active';
      });
    }
  }

  Future<void> _refreshComments() async {
    if (_markerId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.post.originalMarkerOwner)
        .collection('Markers')
        .doc(_markerId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
      });
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
    final sortedStatusHistory =
        List<Map<String, dynamic>>.from(widget.post.statusHistory)
          ..sort((a, b) {
            final aTimestamp = a['timestamp'] is Timestamp
                ? (a['timestamp'] as Timestamp).toDate()
                : DateTime(0);
            final bTimestamp = b['timestamp'] is Timestamp
                ? (b['timestamp'] as Timestamp).toDate()
                : DateTime(0);
            return bTimestamp.compareTo(aTimestamp);
          });
    final statusUpdate =
        sortedStatusHistory.isNotEmpty ? sortedStatusHistory.first : null;

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
                  Flexible(
                    child: Text(
                      widget.post.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(widget.post.description),
              trailing: GestureDetector(
                onTap: _showStatusUpdateDialog,
                child: _buildStatusChip(widget.post.currentStatus),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (statusUpdate != null) ...[
                    Text(
                      '${statusUpdate['username']?.toString().toUpperCase() ?? 'Unknown user'}: ',
                      maxLines: 1,
                    ),
                    Flexible(
                      child: StyledTextSmall(
                        statusUpdate['notes']?.toString() ?? 'No notes',
                      ),
                    ),
                    const SizedBox(width: 20),
                    StyledTextSmall(
                      statusUpdate['timestamp'] is Timestamp
                          ? dateFormat.format(
                              (statusUpdate['timestamp'] as Timestamp).toDate())
                          : 'No date',
                    ),
                  ],
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
                    future: getLocationWithFlag(
                        widget.post.latitude, widget.post.longitude),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(snapshot.data ?? 'Unknown location');
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
                      fontSize: 10,
                      color: Colors.deepOrange.shade400,
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

  Widget _buildImageCarousel(List<String> imageUrls) {
    return Stack(
      children: [
        SizedBox(
          height: 200,
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
        ),
        if (imageUrls.length > 1)
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
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

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'active':
        chipColor = Colors.blue;
        break;
      case 'abundant':
        chipColor = Colors.green;
        break;
      case 'sparse':
        chipColor = Colors.orange;
        break;
      case 'out_of_season':
        chipColor = Colors.blueGrey;
        break;
      case 'no_longer_available':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
        ),
      ),
      backgroundColor: chipColor,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
