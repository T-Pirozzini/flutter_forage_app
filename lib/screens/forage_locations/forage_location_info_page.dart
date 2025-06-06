import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/models/marker.dart';
import 'package:flutter_forager_app/screens/forage/map_page.dart';
import 'package:flutter_forager_app/screens/forage/services/marker_service.dart';
import 'package:flutter_forager_app/screens/forage_locations/components/status_history_dialog.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ForageLocationInfo extends StatefulWidget {
  final String name;
  final String description;
  final List<String> imageUrls;
  final double lat;
  final double lng;
  final String timestamp;
  final String type;
  final String markerOwner;
  final String markerId;
  final String status;
  final List<Map<String, dynamic>> comments;
  final List<Map<String, dynamic>> statusHistory;

  const ForageLocationInfo({
    super.key,
    required this.name,
    required this.description,
    required this.lat,
    required this.lng,
    required this.imageUrls,
    required this.timestamp,
    required this.type,
    required this.markerOwner,
    required this.markerId,
    this.status = 'active',
    this.comments = const [],
    this.statusHistory = const [],
  });

  @override
  State<ForageLocationInfo> createState() => _ForageLocationInfoState();
}

class _ForageLocationInfoState extends State<ForageLocationInfo> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final picker = ImagePicker();
  late List<String> imageUrls;
  late TextEditingController _descriptionController;
  bool _isEditing = false;
  bool _isOwner = false;
  int _currentImageIndex = 0;
  String _ownerUsername = '';
  final _commentController = TextEditingController();
  String _selectedStatus = 'active';
  List<Map<String, dynamic>> _statusHistory = [];
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    imageUrls = List.from(widget.imageUrls);
    _descriptionController = TextEditingController(text: widget.description);
    _isOwner = currentUser.email == widget.markerOwner;
    _fetchOwnerUsername();
    _selectedStatus = widget.status;
    _statusHistory = List.from(widget.statusHistory);
    _comments = List.from(widget.comments);
    _refreshData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Add this new method
  Future<void> _fetchOwnerUsername() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.markerOwner)
          .get();

      if (userDoc.exists) {
        setState(() {
          _ownerUsername = userDoc['username'] ?? widget.markerOwner;
        });
      }
    } catch (e) {
      debugPrint('Error fetching username: $e');
      setState(() {
        _ownerUsername = widget.markerOwner;
      });
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

      setState(() {
        imageUrls.add(newImageUrl);
      });

      await _updateImagesInFirestore();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

  Future<void> _updateImagesInFirestore() async {
    final markersCollection = FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.markerOwner)
        .collection('Markers');

    await markersCollection
        .where('name', isEqualTo: widget.name)
        .where('type', isEqualTo: widget.type)
        .get()
        .then((snapshot) {
      for (final doc in snapshot.docs) {
        doc.reference.update({'images': imageUrls});
      }
    });
  }

  Future<void> _updateDescription() async {
    if (_descriptionController.text.isEmpty) return;

    final markersCollection = FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.markerOwner)
        .collection('Markers');

    await markersCollection
        .where('name', isEqualTo: widget.name)
        .where('type', isEqualTo: widget.type)
        .get()
        .then((snapshot) {
      for (final doc in snapshot.docs) {
        doc.reference.update({'description': _descriptionController.text});
      }
    });

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Description updated')),
    );
  }

  Future<void> _deleteImage(int index) async {
    if (imageUrls.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one photo is required')),
      );
      return;
    }

    try {
      // Get the image URL to delete
      final imageUrlToDelete = imageUrls[index];

      // Extract the path from the Firebase Storage URL
      final uri = Uri.parse(imageUrlToDelete);
      final path = uri.pathSegments.last;
      final ref = FirebaseStorage.instance.ref().child('images/$path');

      // Delete from Storage
      await ref.delete();

      // Remove from local list and update Firestore
      setState(() {
        imageUrls.removeAt(index);
        if (_currentImageIndex >= imageUrls.length) {
          _currentImageIndex = imageUrls.length - 1;
        }
      });

      await _updateImagesInFirestore();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete image: $e')),
      );
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
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldDelete) {
      await _deleteImage(index);
    }
  }

  Future<void> _postToCommunity() async {
    // First confirm with user
    final shouldPost = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Share with Community'),
            content: const Text(
                'This will make your location visible to all users. Continue?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Share'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldPost) return;

    try {
      final postsCollection = FirebaseFirestore.instance.collection('Posts');
      final currentUser = FirebaseAuth.instance.currentUser!;

      // Create the post document
      await postsCollection.add({
        'name': widget.name,
        'description': _descriptionController.text,
        'timestamp': widget.timestamp,
        'location': {
          'latitude': widget.lat,
          'longitude': widget.lng,
        },
        'type': widget.type,
        'images': imageUrls,
        'userId': currentUser.uid,
        'userEmail': currentUser.email,
        'likeCount': 0,
        'likedBy': [],
        'bookmarkCount': 0,
        'bookmarkedBy': [],
        'commentCount': 0,
        'postTimestamp': FieldValue.serverTimestamp(),
        'originalMarkerOwner': widget.markerOwner,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location shared with community!')),
        );
        Navigator.of(context).pop(); // Close the dialog
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share location: $e')),
        );
      }
    }
  }

  Future<void> _deleteLocation() async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Location'),
            content:
                const Text('Are you sure you want to delete this location?'),
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

    if (!shouldDelete) return;

    try {
      // First delete all images from storage
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

      // Then delete the document
      final markersCollection = FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.markerOwner)
          .collection('Markers');

      await markersCollection
          .where('name', isEqualTo: widget.name)
          .where('type', isEqualTo: widget.type)
          .get()
          .then((snapshot) async {
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete location: $e')),
        );
      }
    }
  }

  void _showStatusUpdateDialog(String newStatus) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Status to ${newStatus.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current status: ${_selectedStatus.toUpperCase()}'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Add notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
            child: const Text('Submit Update'),
          ),
        ],
      ),
    );
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

  Future<void> _refreshData() async {
    await _refreshStatusHistory();
    await _refreshComments();
  }

  Future<void> _refreshStatusHistory() async {
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.markerOwner)
        .collection('Markers')
        .doc(widget.markerId)
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
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.markerOwner)
        .collection('Markers')
        .doc(widget.markerId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
      });
    }
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final markerService = MarkerService(FirebaseAuth.instance.currentUser!);
      await markerService.addComment(
        markerId: widget.markerId,
        text: _commentController.text.trim(),
        markerOwnerEmail: widget.markerOwner,
      );

      await _refreshComments();
      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added successfully')),
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

  Future<void> _updateStatus(String newStatus, String notes) async {
    try {
      final markerService = MarkerService(FirebaseAuth.instance.currentUser!);
      await markerService.updateMarkerStatus(
        markerId: widget.markerId,
        newStatus: newStatus,
        notes: notes,
        markerOwnerEmail: widget.markerOwner,
      );

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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and type
              Row(
                children: [
                  Image.asset(
                    'lib/assets/images/${widget.type.toLowerCase()}_marker.png',
                    width: 36,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StyledHeading(
                          widget.name,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(_selectedStatus),
                            size: 20,
                            color: _getStatusColor(_selectedStatus),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedStatus.replaceAll('_', ' ').toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(_selectedStatus),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_isOwner)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _deleteLocation,
                      color: Colors.red,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Image Carousel
              _buildImageCarousel(),

              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StyledTitle('Current Status'),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'active', child: Text('Active')),
                            DropdownMenuItem(
                                value: 'ripe', child: Text('Ripe')),
                            DropdownMenuItem(
                                value: 'stale', child: Text('Stale')),
                            DropdownMenuItem(
                                value: 'not_found', child: Text('Not Found')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _showStatusUpdateDialog(value);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.history),
                        onPressed: _showStatusHistory,
                        tooltip: 'View status history',
                      ),
                    ],
                  ),
                ],
              ),

              // Comments section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const StyledTitle('Comments'),
                  const SizedBox(height: 8),
                  if (_comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No comments yet',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final timestamp = comment['timestamp'];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment['username'] ??
                                          comment['userEmail'] ??
                                          'Anonymous',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      timestamp is Timestamp
                                          ? DateFormat('MMM d, h:mm a')
                                              .format(timestamp.toDate())
                                          : 'Just now',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(comment['text']?.toString() ?? ''),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
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
                        onPressed: _addComment,
                      ),
                    ],
                  ),
                ],
              ),

              // Description Section
              _buildDescriptionSection(),

              const SizedBox(height: 16),

              // Details Section
              _buildDetailsSection(isDarkMode),

              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(),

              const SizedBox(height: 16),

              // close button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    child: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: imageUrls.length,
          options: CarouselOptions(
            height: 200,
            viewportFraction: 1.0,
            enableInfiniteScroll: false,
            onPageChanged: (index, reason) {
              setState(() => _currentImageIndex = index);
            },
          ),
          itemBuilder: (context, index, realIndex) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
                if (_isOwner)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _confirmDeleteImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 20,
                        ),
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
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _pickAndUploadImage,
              child: const Icon(Icons.add_a_photo, color: Colors.deepOrange),
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
                        ? Colors.deepOrange
                        : Colors.grey,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StyledTitle(
              'Description',
            ),
            if (_isOwner && !_isEditing)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => setState(() => _isEditing = true),
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
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
                    child: const StyledText('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _updateDescription,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                    ),
                    child: const StyledText('Save'),
                  ),
                ],
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: StyledHeadingSmall(
              _descriptionController.text,
            ),
          ),
      ],
    );
  }

  Widget _buildDetailsSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Coordinates
          _buildDetailRow(
            icon: Icons.location_on,
            label: 'Coordinates',
            value:
                '${widget.lat.toStringAsFixed(0)}, ${widget.lng.toStringAsFixed(0)}',
          ),
          const Divider(height: 16),

          // Discovered Date
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Discovered',
            value: widget.timestamp,
          ),
          const Divider(height: 16),

          // Owner
          _buildDetailRow(
            icon: Icons.person,
            label: 'Owner',
            value: _ownerUsername.isNotEmpty ? _ownerUsername : 'Loading...',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.deepOrange),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StyledHeadingSmall(
              label,
            ),
            const SizedBox(height: 4),
            StyledHeadingSmall(
              value,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.map),
            label: const Text('View on Map'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MapPage(
                    initialLocation: LatLng(widget.lat, widget.lng),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        if (_isOwner)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Share with Community'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.deepOrange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _postToCommunity,
            ),
          ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'ripe':
        return Icons.check_circle;
      case 'stale':
        return Icons.warning;
      case 'not_found':
        return Icons.error_outline;
      case 'active':
      default:
        return Icons.location_on;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ripe':
        return Colors.green;
      case 'stale':
        return Colors.orange;
      case 'not_found':
        return Colors.red;
      case 'active':
      default:
        return Colors.blue;
    }
  }
}
