import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_forager_app/data/models/marker.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/forage/map_page.dart';
import 'package:flutter_forager_app/data/services/marker_service.dart';
import 'package:flutter_forager_app/screens/forage_locations/components/status_history_dialog.dart';
import 'package:flutter_forager_app/shared/gamification/gamification_helper.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// Full-screen detail view for a forage location/marker
class LocationDetailScreen extends ConsumerStatefulWidget {
  final MarkerModel marker;

  const LocationDetailScreen({
    super.key,
    required this.marker,
  });

  @override
  ConsumerState<LocationDetailScreen> createState() =>
      _LocationDetailScreenState();
}

class _LocationDetailScreenState extends ConsumerState<LocationDetailScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final picker = ImagePicker();
  final dateFormat = DateFormat('MMM dd, yyyy');

  late List<String> imageUrls;
  late TextEditingController _descriptionController;
  final _commentController = TextEditingController();

  bool _isEditing = false;
  bool _isOwner = false;
  int _currentImageIndex = 0;
  String _ownerUsername = '';
  String _ownerProfilePic = '';
  String _selectedStatus = 'active';
  List<Map<String, dynamic>> _statusHistory = [];
  List<Map<String, dynamic>> _comments = [];
  bool _isBookmarked = false;
  bool _isBookmarkLoading = false;

  @override
  void initState() {
    super.initState();
    imageUrls = List.from(widget.marker.imageUrls);
    _descriptionController =
        TextEditingController(text: widget.marker.description);
    _isOwner = currentUser.email == widget.marker.markerOwner;
    _selectedStatus = widget.marker.currentStatus;
    _statusHistory = List.from(widget.marker.statusHistory);
    _comments = List.from(widget.marker.comments);
    _fetchOwnerUsername();
    _refreshData();
    _checkBookmarkStatus();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkBookmarkStatus() async {
    if (_isOwner) return;

    try {
      final bookmarkRepo = ref.read(bookmarkRepositoryProvider);
      final isBookmarked = await bookmarkRepo.isBookmarked(
        currentUser.email!,
        widget.marker.id,
      );
      if (mounted) {
        setState(() => _isBookmarked = isBookmarked);
      }
    } catch (e) {
      debugPrint('Error checking bookmark status: $e');
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarkLoading) return;

    setState(() => _isBookmarkLoading = true);

    try {
      final bookmarkRepo = ref.read(bookmarkRepositoryProvider);

      if (_isBookmarked) {
        await bookmarkRepo.removeBookmarkByMarkerId(
          currentUser.email!,
          widget.marker.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bookmark removed')),
          );
        }
      } else {
        await bookmarkRepo.addBookmarkFromData(
          userId: currentUser.email!,
          markerId: widget.marker.id,
          markerOwner: widget.marker.markerOwner,
          markerName: widget.marker.name,
          markerDescription: widget.marker.description,
          latitude: widget.marker.latitude,
          longitude: widget.marker.longitude,
          type: widget.marker.type,
          imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location bookmarked!')),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
          _isBookmarkLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBookmarkLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _fetchOwnerUsername() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.marker.markerOwner)
          .get();

      if (userDoc.exists) {
        setState(() {
          _ownerUsername =
              userDoc['username'] ?? widget.marker.markerOwner.split('@').first;
          _ownerProfilePic = userDoc['profilePic'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error fetching username: $e');
      setState(() {
        _ownerUsername = widget.marker.markerOwner.split('@').first;
        _ownerProfilePic = '';
      });
    }
  }

  Future<void> _refreshData() async {
    await _refreshStatusHistory();
    await _refreshComments();
  }

  Future<void> _refreshStatusHistory() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Markers')
          .doc(widget.marker.id)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _statusHistory =
              List<Map<String, dynamic>>.from(data['statusHistory'] ?? []);
          _selectedStatus = data['currentStatus'] ?? 'active';
        });
      }
    } catch (e) {
      debugPrint('Error refreshing status history: $e');
    }
  }

  Future<void> _refreshComments() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Markers')
          .doc(widget.marker.id)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error refreshing comments: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (imageUrls.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum of 3 photos allowed')),
      );
      return;
    }

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      final fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';
      final storageRef =
          FirebaseStorage.instance.ref().child('images/$fileName');
      await storageRef.putFile(File(pickedFile.path));
      final newImageUrl = await storageRef.getDownloadURL();

      setState(() => imageUrls.add(newImageUrl));
      await _updateImagesInFirestore();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  Future<void> _updateImagesInFirestore() async {
    await FirebaseFirestore.instance
        .collection('Markers')
        .doc(widget.marker.id)
        .update({'images': imageUrls});
  }

  Future<void> _updateDescription() async {
    if (_descriptionController.text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('Markers')
        .doc(widget.marker.id)
        .update({'description': _descriptionController.text});

    setState(() => _isEditing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description updated')),
      );
    }
  }

  Future<void> _deleteImage(int index) async {
    if (imageUrls.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one photo is required')),
      );
      return;
    }

    try {
      final imageUrlToDelete = imageUrls[index];
      final uri = Uri.parse(imageUrlToDelete);
      final path = uri.pathSegments.last;
      final ref = FirebaseStorage.instance.ref().child('images/$path');

      await ref.delete();

      setState(() {
        imageUrls.removeAt(index);
        if (_currentImageIndex >= imageUrls.length) {
          _currentImageIndex = imageUrls.length - 1;
        }
      });

      await _updateImagesInFirestore();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete image: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteImage(int index) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Image'),
            content: const Text('Are you sure you want to delete this image?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldDelete) {
      await _deleteImage(index);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final markerService = MarkerService(currentUser);
      await markerService.addComment(
        markerId: widget.marker.id,
        text: _commentController.text.trim(),
        markerOwnerEmail: widget.marker.markerOwner,
        markerName: widget.marker.name,
        markerType: widget.marker.type,
      );

      await _refreshComments();
      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: $e')),
        );
      }
    }
  }

  void _showStatusUpdateDialog(String newStatus) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update to ${_formatStatus(newStatus)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: ${_formatStatus(_selectedStatus)}',
              style: AppTheme.body(size: 14, color: AppTheme.textMedium),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Add notes (optional)',
                border: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
              ),
              maxLines: 3,
              style: AppTheme.body(size: 14),
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
              await _updateStatus(newStatus, notesController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String newStatus, String notes) async {
    try {
      final markerService = MarkerService(currentUser);
      await markerService.updateMarkerStatus(
        markerId: widget.marker.id,
        newStatus: newStatus,
        notes: notes,
        markerOwnerEmail: widget.marker.markerOwner,
        markerName: widget.marker.name,
        markerType: widget.marker.type,
      );

      await _refreshStatusHistory();

      if (mounted) {
        setState(() => _selectedStatus = newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showStatusHistory() {
    final history = _statusHistory.map((map) {
      return MarkerStatusUpdate.fromMap(map);
    }).toList();

    showDialog(
      context: context,
      builder: (context) => StatusHistoryDialog(history: history),
    );
  }

  Future<void> _postToCommunity() async {
    final shouldPost = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadiusMedium,
            ),
            title: Row(
              children: [
                Icon(Icons.campaign, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Text('Share with Community'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your find will be visible to all foragers in the community feed.',
                  style: AppTheme.body(size: 14, color: AppTheme.textMedium),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: AppTheme.borderRadiusSmall,
                    border: Border.all(
                      color: AppTheme.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: AppTheme.success, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Earn 15 points and progress towards badges!',
                          style: AppTheme.caption(
                            size: 12,
                            color: AppTheme.success,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: AppTheme.body(color: AppTheme.textMedium),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldPost) return;

    try {
      final postsCollection = FirebaseFirestore.instance.collection('Posts');

      await postsCollection.add({
        'name': widget.marker.name,
        'description': _descriptionController.text,
        'timestamp': dateFormat.format(widget.marker.timestamp),
        'location': {
          'latitude': widget.marker.latitude,
          'longitude': widget.marker.longitude,
        },
        'type': widget.marker.type,
        'images': imageUrls,
        'userId': currentUser.uid,
        'userEmail': currentUser.email,
        'likeCount': 0,
        'likedBy': [],
        'bookmarkCount': 0,
        'bookmarkedBy': [],
        'commentCount': 0,
        'comments': [], // Legacy array for backward compatibility
        'postTimestamp': FieldValue.serverTimestamp(),
        'originalMarkerOwner': widget.marker.markerOwner,
        'currentStatus': _selectedStatus,
        'statusHistory': _statusHistory,
      });

      // Award points and check for achievements
      await GamificationHelper.awardLocationShared(
        context: context,
        ref: ref,
        userId: currentUser.email!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Shared to community! +15 points'),
              ],
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Future<void> _deleteLocation() async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Location'),
            content: const Text(
                'Are you sure you want to permanently delete this location?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    try {
      for (final imageUrl in imageUrls) {
        try {
          final uri = Uri.parse(imageUrl);
          final path = uri.pathSegments.last;
          final ref = FirebaseStorage.instance.ref().child('images/$path');
          await ref.delete();
        } catch (e) {
          debugPrint('Error deleting image: $e');
        }
      }

      await FirebaseFirestore.instance
          .collection('Markers')
          .doc(widget.marker.id)
          .delete();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'abundant':
        return Icons.eco;
      case 'sparse':
        return Icons.water_drop;
      case 'out_of_season':
        return Icons.hourglass_empty;
      case 'no_longer_available':
        return Icons.not_interested;
      case 'active':
      default:
        return Icons.location_on;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'abundant':
        return AppTheme.success;
      case 'sparse':
        return Colors.orange;
      case 'out_of_season':
        return AppTheme.textMedium;
      case 'no_longer_available':
        return AppTheme.error;
      case 'active':
      default:
        return AppTheme.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = ForageTypeUtils.getTypeColor(widget.marker.type);

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(
          widget.marker.name,
          style: AppTheme.heading(size: 18, color: AppTheme.textWhite),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteLocation,
              tooltip: 'Delete location',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel
            _buildImageCarousel(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type and status header
                  _buildTypeStatusHeader(typeColor),

                  const SizedBox(height: 16),

                  // Owner info
                  _buildOwnerInfo(),

                  const SizedBox(height: 16),

                  // Description
                  _buildDescriptionSection(),

                  const SizedBox(height: 16),

                  // Details card
                  _buildDetailsCard(),

                  const SizedBox(height: 16),

                  // Status update section
                  _buildStatusSection(),

                  const SizedBox(height: 16),

                  // Comments section
                  _buildCommentsSection(),

                  const SizedBox(height: 24),

                  // Action buttons
                  _buildActionButtons(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: imageUrls.isEmpty ? 1 : imageUrls.length,
          options: CarouselOptions(
            height: 250,
            viewportFraction: 1.0,
            enableInfiniteScroll: false,
            onPageChanged: (index, reason) {
              setState(() => _currentImageIndex = index);
            },
          ),
          itemBuilder: (context, index, realIndex) {
            if (imageUrls.isEmpty) {
              return Container(
                color: AppTheme.surfaceLight,
                child: Center(
                  child: Icon(Icons.photo, size: 64, color: AppTheme.textLight),
                ),
              );
            }

            return Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 250,
                  placeholder: (context, url) => Container(
                    color: AppTheme.surfaceLight,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.surfaceLight,
                    child: Icon(Icons.error, color: AppTheme.error),
                  ),
                ),
                if (_isOwner)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _confirmDeleteImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.delete,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (_isOwner)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'addPhoto',
              mini: true,
              backgroundColor: AppTheme.primary,
              onPressed: _pickAndUploadImage,
              child: const Icon(Icons.add_a_photo, color: Colors.white),
            ),
          ),
        if (imageUrls.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: imageUrls.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == entry.key
                        ? AppTheme.primary
                        : Colors.white70,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTypeStatusHeader(Color typeColor) {
    return Row(
      children: [
        // Type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.15),
            borderRadius: AppTheme.borderRadiusSmall,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'lib/assets/images/${widget.marker.type.toLowerCase()}_marker.png',
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.location_on, size: 20, color: typeColor),
              ),
              const SizedBox(width: 6),
              Text(
                widget.marker.type,
                style: AppTheme.caption(
                    size: 13, color: typeColor, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(_selectedStatus).withValues(alpha: 0.15),
            borderRadius: AppTheme.borderRadiusSmall,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(_selectedStatus),
                size: 16,
                color: _getStatusColor(_selectedStatus),
              ),
              const SizedBox(width: 6),
              Text(
                _formatStatus(_selectedStatus),
                style: AppTheme.caption(
                  size: 13,
                  color: _getStatusColor(_selectedStatus),
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
          backgroundImage: _ownerProfilePic.isNotEmpty
              ? AssetImage('lib/assets/images/$_ownerProfilePic')
              : null,
          child: _ownerProfilePic.isEmpty
              ? Icon(Icons.person, size: 20, color: AppTheme.primary)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _ownerUsername.isNotEmpty ? _ownerUsername : 'Loading...',
              style: AppTheme.heading(size: 14, color: AppTheme.textDark),
            ),
            Text(
              'Discovered ${dateFormat.format(widget.marker.timestamp)}',
              style: AppTheme.caption(size: 12, color: AppTheme.textLight),
            ),
          ],
        ),
        const Spacer(),
        if (!_isOwner)
          IconButton(
            onPressed: _isBookmarkLoading ? null : _toggleBookmark,
            icon: _isBookmarkLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.secondary,
                    ),
                  )
                : Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked
                        ? AppTheme.secondary
                        : AppTheme.textMedium,
                  ),
            tooltip: _isBookmarked ? 'Remove bookmark' : 'Bookmark',
          ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Description',
                  style: AppTheme.heading(size: 14, color: AppTheme.textDark),
                ),
                if (_isOwner && !_isEditing)
                  IconButton(
                    icon: Icon(Icons.edit, size: 18, color: AppTheme.primary),
                    onPressed: () => setState(() => _isEditing = true),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isEditing)
              Column(
                children: [
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: AppTheme.body(size: 14, color: AppTheme.textDark),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.borderRadiusSmall,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _isEditing = false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _updateDescription,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              )
            else
              Text(
                _descriptionController.text.isNotEmpty
                    ? _descriptionController.text
                    : 'No description',
                style: AppTheme.body(
                  size: 14,
                  color: _descriptionController.text.isNotEmpty
                      ? AppTheme.textDark
                      : AppTheme.textLight,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Details',
              style: AppTheme.heading(size: 14, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.location_on,
              'Coordinates',
              '${widget.marker.latitude.toStringAsFixed(4)}, ${widget.marker.longitude.toStringAsFixed(4)}',
            ),
            const Divider(height: 16),
            _buildDetailRow(
              Icons.calendar_today,
              'Discovered',
              dateFormat.format(widget.marker.timestamp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.caption(size: 11, color: AppTheme.textLight),
            ),
            Text(
              value,
              style: AppTheme.body(size: 13, color: AppTheme.textDark),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status',
                  style: AppTheme.heading(size: 14, color: AppTheme.textDark),
                ),
                TextButton.icon(
                  onPressed: _showStatusHistory,
                  icon: Icon(Icons.history, size: 16, color: AppTheme.primary),
                  label: Text(
                    'History',
                    style:
                        AppTheme.caption(size: 12, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'abundant', child: Text('Abundant')),
                DropdownMenuItem(value: 'sparse', child: Text('Sparse')),
                DropdownMenuItem(
                    value: 'out_of_season', child: Text('Out of Season')),
                DropdownMenuItem(
                    value: 'no_longer_available',
                    child: Text('No Longer Available')),
              ],
              onChanged: (value) {
                if (value != null && value != _selectedStatus) {
                  _showStatusUpdateDialog(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments (${_comments.length})',
              style: AppTheme.heading(size: 14, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            if (_comments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No comments yet. Be the first!',
                  style: AppTheme.body(size: 13, color: AppTheme.textLight),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _comments.length > 3 ? 3 : _comments.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  final timestamp = comment['timestamp'];
                  final formattedDate = timestamp is Timestamp
                      ? DateFormat('MMM d').format(timestamp.toDate())
                      : '';

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.2),
                        backgroundImage: (comment['profilePic'] != null &&
                                comment['profilePic'].toString().isNotEmpty)
                            ? AssetImage(
                                'lib/assets/images/${comment['profilePic']}')
                            : null,
                        child: (comment['profilePic'] == null ||
                                comment['profilePic'].toString().isEmpty)
                            ? Icon(Icons.person,
                                size: 16, color: AppTheme.primary)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  comment['username'] ?? 'Anonymous',
                                  style: AppTheme.caption(
                                    size: 12,
                                    color: AppTheme.textDark,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formattedDate,
                                  style: AppTheme.caption(
                                    size: 11,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              comment['text']?.toString() ?? '',
                              style: AppTheme.body(
                                  size: 13, color: AppTheme.textMedium),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            if (_comments.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () {
                    // Could expand to show all comments
                  },
                  child: Text(
                    'View all ${_comments.length} comments',
                    style: AppTheme.caption(size: 12, color: AppTheme.primary),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: AppTheme.body(size: 14),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle:
                          AppTheme.body(size: 14, color: AppTheme.textLight),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: Icon(Icons.send, color: AppTheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // View on Map button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.map),
            label: const Text('View on Map'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusMedium,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => MapPage(
                    initialLocation: LatLng(
                      widget.marker.latitude,
                      widget.marker.longitude,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Bookmark button (for non-owners)
        if (!_isOwner)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: _isBookmarkLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.secondary,
                      ),
                    )
                  : Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border),
              label: Text(_isBookmarked ? 'Bookmarked' : 'Bookmark Location'),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    _isBookmarked ? AppTheme.secondary : AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: _isBookmarked ? AppTheme.secondary : AppTheme.primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.borderRadiusMedium,
                ),
              ),
              onPressed: _isBookmarkLoading ? null : _toggleBookmark,
            ),
          ),
        // Share button (for owners)
        if (_isOwner) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Share with Community'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.borderRadiusMedium,
                ),
              ),
              onPressed: _postToCommunity,
            ),
          ),
        ],
      ],
    );
  }
}
