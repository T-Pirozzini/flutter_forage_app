import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/models/marker.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_location_info_page.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ForageLocations extends StatefulWidget {
  final String userId;
  final String userName;
  final bool userLocations;

  const ForageLocations({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userLocations,
  }) : super(key: key);

  @override
  State<ForageLocations> createState() => _ForageLocationsState();
}

class _ForageLocationsState extends State<ForageLocations> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
  bool _isDeleting = false;

  Future<String> _getLocationAddress(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.locality ?? ''}${place.locality != null && place.country != null ? ', ' : ''}${place.country ?? ''}'
            .trim();
      }
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    } catch (e) {
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }

  Future<bool> _deleteConfirmation() async {
    if (_isDeleting) return false;
    _isDeleting = true;

    bool shouldDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Forage Location'),
          content: const Text(
              'Are you sure you want to delete this forage location?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                _isDeleting = false;
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                _isDeleting = false;
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return shouldDelete;
  }

  Stream<QuerySnapshot> get _markersStream {
    final collection = FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userId)
        .collection('Markers');

    return widget.userLocations
        ? collection.where('markerOwner', isEqualTo: widget.userId).snapshots()
        : collection
            .where('markerOwner', isNotEqualTo: widget.userId)
            .snapshots();
  }

  Future<void> _deleteMarker(String markerId) async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userId)
        .collection('Markers')
        .doc(markerId)
        .delete();
  }

  void _showMarkerDetails(MarkerModel marker) {
    showDialog(
      context: context,
      builder: (context) => ForageLocationInfo(
        name: marker.name,
        description: marker.description,
        type: marker.type,
        lat: marker.latitude,
        lng: marker.longitude,
        timestamp: dateFormat.format(marker.timestamp),
        imageUrls: marker.imageUrls,
        markerOwner: marker.markerOwner,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: StyledHeading(
              widget.userLocations ? 'My Forage Spots' : 'Community Locations',
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColors.secondaryColor,
          elevation: 0,
          shape: const RoundedRectangleBorder(),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _markersStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.deepOrangeAccent),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No locations found',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (!widget.userLocations)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Bookmark community locations to see them here',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }

            final markers = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final location = data['location'] as Map<String, dynamic>;

              List<String> images = [];
              if (data['images'] != null) {
                images = List<String>.from(data['images'] as List);
              } else if (data['image'] != null) {
                images = [data['image'] as String];
              }
              return MarkerModel(
                id: doc.id,
                name: data['name'] ?? '',
                description: data['description'] ?? '',
                type: data['type'] ?? '',
                imageUrls: images,
                markerOwner: data['markerOwner'] ?? '',
                timestamp: data['timestamp'] != null
                    ? (data['timestamp'] as Timestamp).toDate()
                    : DateTime.now(),
                latitude: (location['latitude'] as num).toDouble(),
                longitude: (location['longitude'] as num).toDouble(),
              );
            }).toList();

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ListView.separated(
                itemCount: markers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final marker = markers[index];
                  return _buildLocationCard(marker);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationCard(MarkerModel marker) {
    return Dismissible(
      key: Key(marker.id),
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
        final shouldDelete = await _deleteConfirmation();
        if (shouldDelete) {
          await _deleteMarker(marker.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Forage location deleted')),
          );
        }
        return shouldDelete;
      },
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showMarkerDetails(marker),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Optimized image container
                if (marker.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: CachedNetworkImage(
                        imageUrl: marker.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey[400]!,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error),
                        ),
                        fadeInDuration: const Duration(milliseconds: 300),
                        memCacheHeight: 160, // 2x display size for retina
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.photo,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            // Name
                            StyledHeadingSmall(
                              marker.name,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Description
                      Text(
                        marker.description,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Location coordinates
                      FutureBuilder<String>(
                        future: _getLocationAddress(
                            marker.latitude, marker.longitude),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox();
                          }
                          return Text(
                            snapshot.data ??
                                '${marker.latitude.toStringAsFixed(4)}, ${marker.longitude.toStringAsFixed(4)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('MMM dd').format(marker.timestamp),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Type icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getTypeColor(marker.type).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: ImageIcon(
                          AssetImage(
                            'lib/assets/images/${marker.type.toLowerCase()}_marker.png',
                          ),
                          size: 32,
                          color: _getTypeColor(marker.type),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
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
