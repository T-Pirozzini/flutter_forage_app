import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PostModel {
  final String id;
  final String name;
  final String description;
  final String type;
  final List<String> imageUrls;
  final String userEmail;
  final DateTime postTimestamp;
  final double latitude;
  final double longitude;
  final int likeCount;
  final List<String> likedBy;
  final int bookmarkCount;
  final List<String> bookmarkedBy;
  final int commentCount;
  final String originalMarkerOwner;
  final List<Map<String, dynamic>> comments;
  String currentStatus;
  final List<Map<String, dynamic>> statusHistory;

  PostModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.imageUrls,
    required this.userEmail,
    required this.postTimestamp,
    required this.latitude,
    required this.longitude,
    required this.likeCount,
    required this.likedBy,
    required this.bookmarkCount,
    required this.bookmarkedBy,
    required this.commentCount,
    required this.originalMarkerOwner,
    this.comments = const [],
    this.currentStatus = 'active',
    this.statusHistory = const [],
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null for post ${doc.id}');
    }

    final mapData = data as Map<String, dynamic>;

    // Fallback support for location data
    double latitude = 0.0;
    double longitude = 0.0;

    if (mapData['location'] is Map<String, dynamic>) {
      final loc = mapData['location'] as Map<String, dynamic>;
      latitude = (loc['latitude'] as num?)?.toDouble() ?? 0.0;
      longitude = (loc['longitude'] as num?)?.toDouble() ?? 0.0;
    } else {
      // Fallback to flat latitude/longitude string fields
      final latStr = mapData['latitude']?.toString();
      final lonStr = mapData['longitude']?.toString();
      latitude = double.tryParse(latStr ?? '') ?? 0.0;
      longitude = double.tryParse(lonStr ?? '') ?? 0.0;
    }

    final images = mapData['images'] ?? [mapData['imageUrl'] ?? ''];
    final userEmail = mapData['userEmail'] ?? mapData['user'] ?? '';

    DateTime postTimestamp;
    if (mapData['postTimestamp'] is Timestamp) {
      postTimestamp = (mapData['postTimestamp'] as Timestamp).toDate();
    } else if (mapData['postTimestamp'] is String) {
      postTimestamp = _parseTimestamp(mapData['postTimestamp']);
    } else {
      postTimestamp = _parseTimestamp(mapData['timestamp'] ?? '1970-01-01');
    }

    // Process comments with proper timestamp handling
    final rawComments = List<Map<String, dynamic>>.from(mapData['comments'] ?? []);
    final processedComments = rawComments.map((comment) {
      // Handle both Timestamp and FieldValue cases
      final timestamp = comment['timestamp'];
      return {
        ...comment,
        'timestamp': timestamp is Timestamp ? timestamp : null,
      };
    }).toList();

    return PostModel(
      id: doc.id,
      name: mapData['name'] ?? '',
      description: mapData['description'] ?? '',
      type: mapData['type'] ?? 'plant',
      imageUrls: images is String ? [images] : List<String>.from(images ?? []),
      userEmail: userEmail,
      postTimestamp: postTimestamp,
      latitude: latitude,
      longitude: longitude,
      likeCount: mapData['likeCount'] ?? 0,
      likedBy: List<String>.from(mapData['likedBy'] ?? []),
      bookmarkCount: mapData['bookmarkCount'] ?? 0,
      bookmarkedBy: List<String>.from(mapData['bookmarkedBy'] ?? []),
      commentCount: mapData['commentCount'] ?? 0,
      originalMarkerOwner:
          mapData['originalMarkerOwner'] ?? mapData['markerOwner'] ?? '',
      comments: processedComments,
      currentStatus: mapData['currentStatus'] ?? 'active',
      statusHistory:
          List<Map<String, dynamic>>.from(mapData['statusHistory'] ?? []),
    );
  }

  // Helper to parse timestamp strings or fall back to epoch
  static DateTime _parseTimestamp(String timestamp) {
    try {
      final formats = [
        DateFormat('yyyy-MM-dd HH:mm:ss.SSSSSS'),
        DateFormat('MMM d, yyyy HH:mm'),
        DateFormat('yyyy-MM-dd'),
      ];
      for (final format in formats) {
        try {
          return format.parse(timestamp);
        } catch (e) {
          continue;
        }
      }
      return DateTime.fromMillisecondsSinceEpoch(0); // Fallback to epoch
    } catch (e) {
      return DateTime.fromMillisecondsSinceEpoch(0); // Fallback to epoch
    }
  }
}
