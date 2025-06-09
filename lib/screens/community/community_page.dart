import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/components/screen_heading.dart';
import 'package:flutter_forager_app/models/marker.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  String? username;
  final Map<String, bool> _expandedPosts = {};
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, TextEditingController> _statusNoteControllers = {};
  final Map<String, String> _selectedStatus = {};

  @override
  void initState() {
    super.initState();
    fetchUsername();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    for (var controller in _statusNoteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> fetchUsername() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.email)
        .get();

    if (userDoc.exists) {
      setState(() {
        username = userDoc.data()?['username'];
      });
    }
  }

  void toggleExpand(String postId) {
    setState(() {
      _expandedPosts[postId] = !(_expandedPosts[postId] ?? false);
    });
  }

  Future<void> addComment(String postId) async {
    final comment = _commentControllers[postId]?.text.trim();
    if (comment == null || comment.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('Posts').doc(postId).update({
        'comments': FieldValue.arrayUnion([
          {
            'userId': currentUser.uid,
            'userEmail': currentUser.email!,
            'text': comment,
            'timestamp': FieldValue.serverTimestamp(),
            'username': username,
          }
        ]),
        'commentCount': FieldValue.increment(1),
      });
      _commentControllers[postId]?.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $e')),
      );
    }
  }

  Future<void> updateStatus(String postId) async {
    final status = _selectedStatus[postId];
    final notes = _statusNoteControllers[postId]?.text.trim();

    if (status == null) return;

    final statusUpdate = {
      'status': status,
      'userId': currentUser.uid,
      'userEmail': currentUser.email!,
      'username': username,
      'timestamp': FieldValue.serverTimestamp(),
      if (notes?.isNotEmpty == true) 'notes': notes,
    };

    try {
      await FirebaseFirestore.instance.collection('Posts').doc(postId).update({
        'currentStatus': status,
        'statusHistory': FieldValue.arrayUnion([statusUpdate]),
      });

      _statusNoteControllers[postId]?.clear();
      _selectedStatus[postId] = 'active'; // Reset to default status

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> toggleFavorite(
      String postId, bool isFavorite, int likeCount) async {
    try {
      if (isFavorite) {
        await FirebaseFirestore.instance
            .collection('Posts')
            .doc(postId)
            .update({
          'likeCount': likeCount - 1,
          'likedBy': FieldValue.arrayRemove([currentUser.email]),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('Posts')
            .doc(postId)
            .update({
          'likeCount': likeCount + 1,
          'likedBy': FieldValue.arrayUnion([currentUser.email]),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update like: $e')),
      );
    }
  }

  Future<void> toggleBookmark(
      String postId, bool isBookmarked, int bookmarkCount) async {
    try {
      if (isBookmarked) {
        await FirebaseFirestore.instance
            .collection('Posts')
            .doc(postId)
            .update({
          'bookmarkCount': bookmarkCount - 1,
          'bookmarkedBy': FieldValue.arrayRemove([currentUser.email]),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('Posts')
            .doc(postId)
            .update({
          'bookmarkCount': bookmarkCount + 1,
          'bookmarkedBy': FieldValue.arrayUnion([currentUser.email]),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update bookmark: $e')),
      );
    }
  }

  Future<void> deletePost(String postId, String postOwner) async {
    if (postOwner != currentUser.email) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own posts')),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Post'),
            content: const Text('Are you sure you want to delete this post?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldDelete) {
      try {
        await FirebaseFirestore.instance
            .collection('Posts')
            .doc(postId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ScreenHeading(title: 'Community'),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            color: AppColors.titleBarColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StyledText("Care to share your secret spots with us?"),
                ),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StyledText(
                      'Like and/or bookmark forage locations and go explore!'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Posts')
                  .orderBy('postTimestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No posts yet. Be the first to share!'));
                }

                final posts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final postId = post.id;
                    final postData = post.data() as Map<String, dynamic>;
                    final isExpanded = _expandedPosts[postId] ?? false;

                    // Initialize controllers if they don't exist
                    _commentControllers.putIfAbsent(
                        postId, () => TextEditingController());
                    _statusNoteControllers.putIfAbsent(
                        postId, () => TextEditingController());
                    _selectedStatus.putIfAbsent(
                        postId, () => postData['currentStatus'] ?? 'active');

                    final likeCount = postData['likeCount'] ?? 0;
                    final bookmarkCount = postData['bookmarkCount'] ?? 0;
                    final commentCount = postData['commentCount'] ?? 0;
                    final isFavorite =
                        (postData['likedBy'] ?? []).contains(currentUser.email);
                    final isBookmarked = (postData['bookmarkedBy'] ?? [])
                        .contains(currentUser.email);
                    final comments = List<Map<String, dynamic>>.from(
                        postData['comments'] ?? []);
                    final statusHistory = List<Map<String, dynamic>>.from(
                        postData['statusHistory'] ?? []);

                    return PostCard(
                      postId: postId,
                      name: postData['name'] ?? '',
                      description: postData['description'] ?? '',
                      imageUrls: postData['imageUrl'] != null
                          ? [postData['imageUrl']]
                          : [],
                      type: postData['type'] ?? 'plant',
                      timestamp: postData['timestamp'] ?? '',
                      postOwner: postData['user'] ?? '',
                      likeCount: likeCount,
                      bookmarkCount: bookmarkCount,
                      commentCount: commentCount,
                      isFavorite: isFavorite,
                      isBookmarked: isBookmarked,
                      isExpanded: isExpanded,
                      latitude: postData['latitude'] ?? 0.0,
                      longitude: postData['longitude'] ?? 0.0,
                      comments: comments,
                      statusHistory: statusHistory,
                      currentStatus: postData['currentStatus'] ?? 'active',
                      onToggleExpand: () => toggleExpand(postId),
                      onToggleFavorite: () =>
                          toggleFavorite(postId, isFavorite, likeCount),
                      onToggleBookmark: () =>
                          toggleBookmark(postId, isBookmarked, bookmarkCount),
                      onDelete: () =>
                          deletePost(postId, postData['user'] ?? ''),
                      commentController: _commentControllers[postId]!,
                      statusNoteController: _statusNoteControllers[postId]!,
                      selectedStatus: _selectedStatus[postId]!,
                      onStatusChanged: (value) {
                        setState(() {
                          _selectedStatus[postId] = value;
                        });
                      },
                      onAddComment: () => addComment(postId),
                      onUpdateStatus: () => updateStatus(postId),
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
}

class PostCard extends StatelessWidget {
  final String postId;
  final String name;
  final String description;
  final List<String> imageUrls;
  final String type;
  final String timestamp;
  final String postOwner;
  final int likeCount;
  final int bookmarkCount;
  final int commentCount;
  final bool isFavorite;
  final bool isBookmarked;
  final bool isExpanded;
  final double latitude;
  final double longitude;
  final List<Map<String, dynamic>> comments;
  final List<Map<String, dynamic>> statusHistory;
  final String currentStatus;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleBookmark;
  final VoidCallback onDelete;
  final TextEditingController commentController;
  final TextEditingController statusNoteController;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onAddComment;
  final VoidCallback onUpdateStatus;

  const PostCard({
    super.key,
    required this.postId,
    required this.name,
    required this.description,
    required this.imageUrls,
    required this.type,
    required this.timestamp,
    required this.postOwner,
    required this.likeCount,
    required this.bookmarkCount,
    required this.commentCount,
    required this.isFavorite,
    required this.isBookmarked,
    required this.isExpanded,
    required this.latitude,
    required this.longitude,
    required this.comments,
    required this.statusHistory,
    required this.currentStatus,
    required this.onToggleExpand,
    required this.onToggleFavorite,
    required this.onToggleBookmark,
    required this.onDelete,
    required this.commentController,
    required this.statusNoteController,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onAddComment,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final currentUser = FirebaseAuth.instance.currentUser!;

    DateTime? _parseDate(String dateString) {
      try {
        // Try parsing as ISO 8601 (Firestore timestamp string)
        if (dateString.contains('-') && dateString.contains(':')) {
          return DateTime.parse(dateString);
        }

        // Try parsing as formatted date (e.g., "Dec 11, 2023 15:50")
        final formats = [
          DateFormat('MMM d, yyyy HH:mm'), // Dec 11, 2023 15:50
          DateFormat('MMM d, yyyy'), // Dec 11, 2023
          DateFormat('yyyy-MM-dd'), // 2023-12-11
        ];

        for (final format in formats) {
          try {
            return format.parse(dateString);
          } catch (e) {
            continue;
          }
        }

        // If all parsing fails, return null
        return null;
      } catch (e) {
        return null;
      }
    }

    String _formatDate(String dateString) {
      final date = _parseDate(dateString);
      if (date == null)
        return dateString; // Fallback to original string if parsing fails

      return DateFormat('MMM d, yyyy').format(date);
    }

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
            // Image Carousel
            if (imageUrls.isNotEmpty) _buildImageCarousel(imageUrls),

            // Post Header
            ListTile(
              title: Row(
                children: [
                  Image.asset(
                    "lib/assets/images/${type.toLowerCase()}.png",
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    name,
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
                  Text(description),
                  const SizedBox(height: 5),
                  _buildStatusChip(currentStatus),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
                onPressed: onToggleExpand,
              ),
            ),

            // Action Buttons
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
                          color: isFavorite ? Colors.red : null,
                        ),
                        onPressed: onToggleFavorite,
                      ),
                      Text('$likeCount'),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.bookmark_add,
                          color: isBookmarked ? Colors.blue : null,
                        ),
                        onPressed: onToggleBookmark,
                      ),
                      Text('$bookmarkCount'),
                      IconButton(
                        icon: const Icon(Icons.comment),
                        onPressed: onToggleExpand,
                      ),
                      Text('$commentCount'),
                    ],
                  ),
                  if (postOwner == currentUser.email)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: onDelete,
                    ),
                ],
              ),
            ),

            // Post Footer (always visible)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 5),
                      Text(postOwner.split('@')[0]),
                    ],
                  ),
                  FutureBuilder<String?>(
                    future: getAreaFromCoordinates(latitude, longitude),
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
                    _formatDate(timestamp),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.deepOrange.shade400,
                    ),
                  ),
                ],
              ),
            ),

            // Expanded Content
            if (isExpanded) ...[
              const Divider(),

              // Status Update Section
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      items: const [
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'harvested',
                          child: Text('Harvested'),
                        ),
                        DropdownMenuItem(
                          value: 'depleted',
                          child: Text('Depleted'),
                        ),
                        DropdownMenuItem(
                          value: 'verified',
                          child: Text('Verified'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          onStatusChanged(value);
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Status',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: statusNoteController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Notes (optional)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: onUpdateStatus,
                        child: const Text('Update'),
                      ),
                    ),
                  ],
                ),
              ),

              // Status History
              if (statusHistory.isNotEmpty) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status History',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...statusHistory.reversed.map((update) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${update['username'] ?? update['userEmail']?.split('@')[0] ?? 'User'} '
                                    'marked as ${update['status']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    timeFormat.format(
                                        (update['timestamp'] as Timestamp)
                                            .toDate()),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              if (update['notes'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(update['notes']!),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],

              // Comments Section
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No comments yet',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(
                          maxHeight: 200, // Shows about 3 comments
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Scrollbar(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              final timestamp =
                                  comment['timestamp'] as Timestamp?;

                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).hoverColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Colors.deepOrange
                                                .withOpacity(0.2),
                                            child: const Icon(Icons.person,
                                                size: 20,
                                                color: Colors.deepOrange),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              comment['username'] ??
                                                  comment['userEmail']
                                                      ?.split('@')[0] ??
                                                  'Anonymous',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepOrange,
                                              ),
                                            ),
                                          ),
                                          if (timestamp != null)
                                            Text(
                                              timeFormat
                                                  .format(timestamp.toDate()),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        comment['text']?.toString() ?? '',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          color: Colors.deepOrange,
                          onPressed: onAddComment,
                        ),
                      ],
                    ),
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

Future<String?> getAreaFromCoordinates(
    double latitude, double longitude) async {
  try {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(latitude, longitude);

    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks[0];
      return placemark.locality ??
          placemark.subLocality ??
          placemark.administrativeArea;
    }
  } catch (e) {
    print('Error: $e');
  }
  return null;
}
