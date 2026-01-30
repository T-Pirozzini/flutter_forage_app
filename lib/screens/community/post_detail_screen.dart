import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_forager_app/data/models/post.dart';
import 'package:flutter_forager_app/data/models/post_comment.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/services/marker_service.dart';
import 'package:flutter_forager_app/screens/community/components/comment_tile.dart';
import 'package:flutter_forager_app/screens/forage/map_page.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen detail view for a community post
class PostDetailScreen extends ConsumerStatefulWidget {
  final PostModel post;
  final bool isFavorite;
  final bool isBookmarked;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleBookmark;
  final VoidCallback onDelete;
  final String? username;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.isFavorite,
    required this.isBookmarked,
    required this.onToggleFavorite,
    required this.onToggleBookmark,
    required this.onDelete,
    this.username,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final dateFormat = DateFormat('MMM d, yyyy');
  final _commentController = TextEditingController();
  final PageController _pageController = PageController();

  int _currentImageIndex = 0;
  String _selectedStatus = 'active';
  List<Map<String, dynamic>> _statusHistory = [];
  String? _markerId;
  bool _isFavorite = false;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.post.currentStatus;
    _statusHistory = List.from(widget.post.statusHistory);
    _isFavorite = widget.isFavorite;
    _isBookmarked = widget.isBookmarked;
    _fetchMarkerId();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchMarkerId() async {
    try {
      final markersCollection =
          FirebaseFirestore.instance.collection('Markers');
      final snapshot = await markersCollection
          .where('name', isEqualTo: widget.post.name)
          .where('type', isEqualTo: widget.post.type)
          .where('markerOwner', isEqualTo: widget.post.originalMarkerOwner)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && mounted) {
        setState(() {
          _markerId = snapshot.docs.first.id;
        });
        await _refreshStatusHistory();
      }
    } catch (e) {
      debugPrint('Error fetching marker: $e');
    }
  }

  Future<void> _refreshStatusHistory() async {
    if (_markerId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('Markers')
        .doc(_markerId)
        .get();

    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _statusHistory =
            List<Map<String, dynamic>>.from(data['statusHistory'] ?? []);
        _selectedStatus = data['currentStatus'] ?? 'active';
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
      final markerService = MarkerService(currentUser);
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
            'userId': currentUser.uid,
            'userEmail': currentUser.email,
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
                'Current status: ${_selectedStatus.replaceAll('_', ' ').toUpperCase()}',
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
                  isExpanded: true,
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
                            child: Text(
                              status.replaceAll('_', ' ').toUpperCase(),
                              style: AppTheme.body(
                                  size: 14, color: AppTheme.textDark),
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
                if (newStatus != null) {
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

  void _showStatusHistoryDialog() {
    final sortedHistory = List<Map<String, dynamic>>.from(_statusHistory)
      ..sort((a, b) {
        final aTimestamp = a['timestamp'] is Timestamp
            ? (a['timestamp'] as Timestamp).toDate()
            : DateTime(0);
        final bTimestamp = b['timestamp'] is Timestamp
            ? (b['timestamp'] as Timestamp).toDate()
            : DateTime(0);
        return bTimestamp.compareTo(aTimestamp);
      });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.history, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Text('Status History'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: sortedHistory.isEmpty
              ? Center(
                  child: Text(
                    'No status updates yet',
                    style: AppTheme.body(color: AppTheme.textMedium),
                  ),
                )
              : ListView.builder(
                  itemCount: sortedHistory.length,
                  itemBuilder: (context, index) {
                    final entry = sortedHistory[index];
                    final timestamp = entry['timestamp'] is Timestamp
                        ? (entry['timestamp'] as Timestamp).toDate()
                        : DateTime.now();
                    return ListTile(
                      dense: true,
                      leading: _buildStatusIcon(entry['status'] ?? 'active'),
                      title: Text(
                        (entry['status'] ?? 'active')
                            .toString()
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: AppTheme.body(
                            size: 13,
                            color: AppTheme.textDark,
                            weight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (entry['notes'] != null &&
                              entry['notes'].toString().isNotEmpty)
                            Text(
                              entry['notes'].toString(),
                              style:
                                  AppTheme.caption(color: AppTheme.textMedium),
                            ),
                          Text(
                            '${entry['username'] ?? 'Unknown'} • ${dateFormat.format(timestamp)}',
                            style: AppTheme.caption(
                                size: 11, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;
    switch (status.toLowerCase()) {
      case 'abundant':
        icon = Icons.eco;
        color = AppTheme.success;
        break;
      case 'sparse':
        icon = Icons.grass;
        color = AppTheme.secondary;
        break;
      case 'out_of_season':
        icon = Icons.ac_unit;
        color = AppTheme.textMedium;
        break;
      case 'no_longer_available':
        icon = Icons.block;
        color = AppTheme.error;
        break;
      default:
        icon = Icons.check_circle;
        color = AppTheme.primary;
    }
    return Icon(icon, color: color, size: 20);
  }

  Future<void> _addComment(String text) async {
    if (text.isEmpty) return;

    try {
      final postRepo = ref.read(postRepositoryProvider);
      await postRepo.addComment(
        postId: widget.post.id,
        userId: currentUser.uid,
        userEmail: currentUser.email!,
        username: widget.username ?? currentUser.email!.split('@')[0],
        text: text,
      );
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    }
  }

  void _openInMaps() async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${widget.post.latitude},${widget.post.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _navigateToMapLocation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPage(
          initialLocation: LatLng(widget.post.latitude, widget.post.longitude),
          isFullScreen: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.post.userEmail == currentUser.email;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          widget.post.name,
          style: AppTheme.heading(size: 18, color: Colors.white),
        ),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () {
                widget.onDelete();
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            if (widget.post.imageUrls.isNotEmpty) _buildImageCarousel(),

            // Type badge only - status is in Verification Log
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildTypeBadge(),
            ),

            // Map Section
            _buildMapSection(),

            // Poster info
            _buildPosterInfo(),

            // Description
            _buildDescriptionCard(),

            // Status Log Timeline (inline)
            _buildStatusLogSection(),

            // Action buttons
            _buildActionButtons(),

            // Comments Section
            _buildCommentsSection(),

            const SizedBox(height: 100), // Bottom padding for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.post.imageUrls.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: widget.post.imageUrls[index],
                fit: BoxFit.cover,
                width: double.infinity,
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
                  child:
                      Icon(Icons.image_not_supported, color: AppTheme.textLight),
                ),
              );
            },
          ),
        ),
        if (widget.post.imageUrls.length > 1)
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
                '${_currentImageIndex + 1}/${widget.post.imageUrls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: AppTheme.borderRadiusSmall,
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            "lib/assets/images/${widget.post.type.toLowerCase()}_marker.png",
            width: 20,
            height: 20,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.location_on,
              size: 20,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.post.type,
            style: AppTheme.caption(
              size: 13,
              color: AppTheme.primary,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Mini map preview
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: SizedBox(
              height: 150,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target:
                      LatLng(widget.post.latitude, widget.post.longitude),
                  zoom: 14,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('post_location'),
                    position:
                        LatLng(widget.post.latitude, widget.post.longitude),
                  ),
                },
                zoomControlsEnabled: false,
                scrollGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _navigateToMapLocation,
                  icon: Icon(Icons.map, color: AppTheme.primary),
                  label: Text(
                    'View in App',
                    style: AppTheme.caption(color: AppTheme.primary),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: AppTheme.textLight,
                ),
                TextButton.icon(
                  onPressed: _openInMaps,
                  icon: Icon(Icons.open_in_new, color: AppTheme.primary),
                  label: Text(
                    'Open in Maps',
                    style: AppTheme.caption(color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
            child: Text(
              widget.post.userEmail[0].toUpperCase(),
              style: AppTheme.heading(size: 16, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${widget.post.userEmail.split('@')[0]}',
                  style: AppTheme.body(
                    size: 14,
                    color: AppTheme.textDark,
                    weight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Posted ${dateFormat.format(widget.post.postTimestamp)}',
                  style: AppTheme.caption(size: 12, color: AppTheme.textMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    final isOwner = widget.post.userEmail == currentUser.email;
    final hasDescription = widget.post.description.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Description',
                style: AppTheme.caption(
                  size: 12,
                  color: AppTheme.textMedium,
                  weight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isOwner)
                GestureDetector(
                  onTap: _showEditDescriptionDialog,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: AppTheme.caption(
                          size: 12,
                          color: AppTheme.primary,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasDescription)
            Text(
              widget.post.description,
              style: AppTheme.body(size: 14, color: AppTheme.textDark),
            )
          else
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.textLight),
                const SizedBox(width: 8),
                Text(
                  'No description provided',
                  style: AppTheme.body(
                    size: 14,
                    color: AppTheme.textLight,
                    weight: FontWeight.w400,
                  ),
                ),
                if (isOwner) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showEditDescriptionDialog,
                    child: Text(
                      'Add one',
                      style: AppTheme.body(
                        size: 14,
                        color: AppTheme.primary,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  void _showEditDescriptionDialog() {
    final descriptionController = TextEditingController(text: widget.post.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Description'),
        content: TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            hintText: 'Add a description...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          style: AppTheme.body(size: 14, color: AppTheme.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newDescription = descriptionController.text.trim();
              await _updateDescription(newDescription);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDescription(String newDescription) async {
    try {
      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(widget.post.id)
          .update({'description': newDescription});

      // Also update the marker if it exists
      if (_markerId != null) {
        await FirebaseFirestore.instance
            .collection('Markers')
            .doc(_markerId)
            .update({'description': newDescription});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Description updated')),
        );
        // Force rebuild with new description
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating description: $e')),
        );
      }
    }
  }

  Widget _buildStatusLogSection() {
    // Sort status history by timestamp (newest first)
    final sortedHistory = List<Map<String, dynamic>>.from(_statusHistory)
      ..sort((a, b) {
        final aTimestamp = a['timestamp'] is Timestamp
            ? (a['timestamp'] as Timestamp).toDate()
            : (a['timestamp'] is DateTime ? a['timestamp'] as DateTime : DateTime(0));
        final bTimestamp = b['timestamp'] is Timestamp
            ? (b['timestamp'] as Timestamp).toDate()
            : (b['timestamp'] is DateTime ? b['timestamp'] as DateTime : DateTime(0));
        return bTimestamp.compareTo(aTimestamp);
      });

    // Take only the most recent 5 entries for inline display
    final displayHistory = sortedHistory.take(5).toList();

    // Get current status info
    final latestUpdate = sortedHistory.isNotEmpty ? sortedHistory.first : null;
    final currentStatusDate = latestUpdate != null
        ? (latestUpdate['timestamp'] is Timestamp
            ? (latestUpdate['timestamp'] as Timestamp).toDate()
            : (latestUpdate['timestamp'] is DateTime
                ? latestUpdate['timestamp'] as DateTime
                : null))
        : null;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and add button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Verification Log',
                  style: AppTheme.heading(size: 15, color: AppTheme.textDark),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showStatusUpdateDialog,
                  icon: Icon(Icons.add, size: 16, color: AppTheme.primary),
                  label: Text(
                    'Add Update',
                    style: AppTheme.caption(
                      size: 12,
                      color: AppTheme.primary,
                      weight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Current Status header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Text(
                  'Current Status:',
                  style: AppTheme.body(
                    size: 13,
                    color: AppTheme.textMedium,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_selectedStatus),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _selectedStatus.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (currentStatusDate != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('MMM d, yyyy').format(currentStatusDate),
                    style: AppTheme.caption(size: 12, color: AppTheme.textLight),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Status entries as timeline
          if (displayHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 36, color: AppTheme.textLight),
                    const SizedBox(height: 8),
                    Text(
                      'No verification updates yet',
                      style: AppTheme.body(size: 13, color: AppTheme.textMedium),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Help the community by adding a status update!',
                      style: AppTheme.caption(size: 11, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            const SizedBox(height: 12),
            ...displayHistory.asMap().entries.map((entry) {
              final index = entry.key;
              final historyItem = entry.value;
              final isLast = index == displayHistory.length - 1;
              return _buildStatusLogEntry(historyItem, isLast);
            }),
          ],

          // "View all" button if there are more entries
          if (sortedHistory.length > 5)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: TextButton(
                  onPressed: _showStatusHistoryDialog,
                  child: Text(
                    'View all ${sortedHistory.length} updates',
                    style: AppTheme.caption(
                      size: 12,
                      color: AppTheme.primary,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusLogEntry(Map<String, dynamic> entry, bool isLast) {
    final status = entry['status'] ?? 'active';
    final username = entry['username'] ?? 'Unknown';
    final userEmail = entry['userEmail']?.toString() ?? '';
    final notes = entry['notes']?.toString() ?? '';
    final timestamp = entry['timestamp'] is Timestamp
        ? (entry['timestamp'] as Timestamp).toDate()
        : (entry['timestamp'] is DateTime ? entry['timestamp'] as DateTime : DateTime.now());

    final statusColor = _getStatusColor(status);
    final isOwnEntry = userEmail == currentUser.email;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator (dot + line)
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 50,
                  color: AppTheme.textLight.withValues(alpha: 0.3),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Entry content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 16 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.toString().replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('MMM d, h:mm a').format(timestamp),
                        style: AppTheme.caption(size: 10, color: AppTheme.textLight),
                      ),
                      // Delete button for own entries
                      if (isOwnEntry)
                        GestureDetector(
                          onTap: () => _confirmDeleteStatusEntry(entry),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notes,
                      style: AppTheme.body(size: 12, color: AppTheme.textMedium),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    style: AppTheme.caption(size: 11, color: AppTheme.textLight),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStatusEntry(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Status Update'),
        content: const Text('Are you sure you want to delete this status update?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteStatusEntry(entry);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStatusEntry(Map<String, dynamic> entry) async {
    try {
      // Remove from local state
      setState(() {
        _statusHistory.removeWhere((e) =>
            e['userEmail'] == entry['userEmail'] &&
            e['timestamp'].toString() == entry['timestamp'].toString());
      });

      // Remove from Firestore Posts collection
      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(widget.post.id)
          .update({
        'statusHistory': FieldValue.arrayRemove([entry]),
      });

      // Remove from Markers collection if markerId exists
      if (_markerId != null) {
        await FirebaseFirestore.instance
            .collection('Markers')
            .doc(_markerId)
            .update({
          'statusHistory': FieldValue.arrayRemove([entry]),
        });
      }

      // Update current status to the most recent remaining entry
      if (_statusHistory.isNotEmpty) {
        final sortedHistory = List<Map<String, dynamic>>.from(_statusHistory)
          ..sort((a, b) {
            final aTimestamp = a['timestamp'] is Timestamp
                ? (a['timestamp'] as Timestamp).toDate()
                : (a['timestamp'] is DateTime ? a['timestamp'] as DateTime : DateTime(0));
            final bTimestamp = b['timestamp'] is Timestamp
                ? (b['timestamp'] as Timestamp).toDate()
                : (b['timestamp'] is DateTime ? b['timestamp'] as DateTime : DateTime(0));
            return bTimestamp.compareTo(aTimestamp);
          });

        final newCurrentStatus = sortedHistory.first['status'] ?? 'active';
        setState(() => _selectedStatus = newCurrentStatus);

        await FirebaseFirestore.instance
            .collection('Posts')
            .doc(widget.post.id)
            .update({'currentStatus': newCurrentStatus});

        if (_markerId != null) {
          await FirebaseFirestore.instance
              .collection('Markers')
              .doc(_markerId)
              .update({'currentStatus': newCurrentStatus});
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status update deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting status: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'abundant':
        return AppTheme.success;
      case 'sparse':
        return AppTheme.secondary;
      case 'out_of_season':
        return AppTheme.textMedium;
      case 'no_longer_available':
        return AppTheme.error;
      default:
        return AppTheme.primary;
    }
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.favorite,
            label: '${widget.post.likeCount}',
            isActive: _isFavorite,
            activeColor: AppTheme.accent,
            onTap: () {
              setState(() => _isFavorite = !_isFavorite);
              widget.onToggleFavorite();
            },
          ),
          _buildActionButton(
            icon: Icons.bookmark,
            label: '${widget.post.bookmarkCount}',
            isActive: _isBookmarked,
            activeColor: AppTheme.secondary,
            onTap: () {
              setState(() => _isBookmarked = !_isBookmarked);
              widget.onToggleBookmark();
            },
          ),
          _buildActionButton(
            icon: Icons.comment,
            label: '${widget.post.commentCount}',
            isActive: false,
            activeColor: AppTheme.primary,
            onTap: () {
              // Scroll to comments or focus on input
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.borderRadiusMedium,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.1)
              : AppTheme.surfaceLight,
          borderRadius: AppTheme.borderRadiusMedium,
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.3)
                : AppTheme.textLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : AppTheme.textMedium,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.body(
                size: 14,
                color: isActive ? activeColor : AppTheme.textMedium,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    final postRepo = ref.read(postRepositoryProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Comments',
                  style: AppTheme.heading(size: 16, color: AppTheme.textDark),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Streaming comments
          StreamBuilder<List<PostCommentModel>>(
            stream: postRepo.streamComments(widget.post.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                );
              }

              final comments = snapshot.data ?? [];

              if (comments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 40,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No comments yet',
                          style: AppTheme.body(color: AppTheme.textMedium),
                        ),
                        Text(
                          'Be the first to comment!',
                          style: AppTheme.caption(color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return CommentTile.fromModel(comment: comment);
                },
              );
            },
          ),
          const Divider(height: 1),
          // Comment input
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.borderRadiusSmall,
                        borderSide: BorderSide(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
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
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send_rounded, color: AppTheme.primary),
                  onPressed: () {
                    final text = _commentController.text.trim();
                    if (text.isNotEmpty) {
                      _addComment(text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
