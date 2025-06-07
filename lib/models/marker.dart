// models/marker.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MarkerComment {
  final String userId;
  final String userEmail;
  final String text;
  final DateTime timestamp;

  MarkerComment({
    required this.userId,
    required this.userEmail,
    required this.text,
    required this.timestamp,
  });

  factory MarkerComment.fromMap(Map<String, dynamic> map) {
    return MarkerComment(
      userId: map['userId'],
      userEmail: map['userEmail'],
      text: map['text'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'text': text,
      'timestamp': timestamp,
    };
  }
}

class MarkerStatusUpdate {
  final String status;
  final String userId;
  final String userEmail;
  final String? username;
  final DateTime timestamp;
  final String? notes;

  MarkerStatusUpdate({
    required this.status,
    required this.userId,
    required this.userEmail,
    this.username,
    required this.timestamp,
    this.notes,
  });

  factory MarkerStatusUpdate.fromMap(Map<String, dynamic> map) {
    return MarkerStatusUpdate(
      status: map['status'],
      userId: map['userId'],
      userEmail: map['userEmail'],
      username: map['username'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'userId': userId,
      'userEmail': userEmail,
      if (username != null) 'username': username,
      'timestamp': timestamp,
      if (notes != null) 'notes': notes,
    };
  }
}

class MarkerModel {
  final String id;
  final String name;
  final String description;
  final String type;
  final List<String> imageUrls;
  final String markerOwner;
  final DateTime timestamp;  
  final double latitude;
  final double longitude;
  final String status; 
  final List<MarkerComment> comments;
  final String currentStatus;
  final List<MarkerStatusUpdate> statusHistory;

  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  MarkerModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.imageUrls,
    required this.markerOwner,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.status = 'active',
    this.comments = const [],
    required this.currentStatus,
    this.statusHistory = const [],
  });

  factory MarkerModel.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final location = data['location'] as Map<String, dynamic>;
  
  // Handle status history conversion
  List<MarkerStatusUpdate> history = [];
  if (data['statusHistory'] != null) {
    history = (data['statusHistory'] as List<dynamic>).map((item) {
      return MarkerStatusUpdate.fromMap(item as Map<String, dynamic>);
    }).toList();
  }

  // Handle comments conversion
  List<MarkerComment> comments = [];
  if (data['comments'] != null) {
    comments = (data['comments'] as List<dynamic>).map((comment) {
      return MarkerComment.fromMap(comment as Map<String, dynamic>);
    }).toList();
  }

  return MarkerModel(
    id: doc.id,
    name: data['name'] ?? '',
    description: data['description'] ?? '',
    type: data['type'] ?? 'plant',
    imageUrls: List<String>.from(data['images'] ?? []),
    markerOwner: data['markerOwner'] ?? '',
    timestamp: (data['timestamp'] as Timestamp).toDate(),
    latitude: (location['latitude'] as num).toDouble(),
    longitude: (location['longitude'] as num).toDouble(),
    status: data['status'] ?? 'active',
    comments: comments,
    currentStatus: data['currentStatus'] ?? 'active',
    statusHistory: history,
  );
}

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'image': imageUrls,
      'markerOwner': markerOwner,
      'timestamp': timestamp,      
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'status': status,
      'comments': comments.map((c) => c.toMap()).toList(),
      'currentStatus': currentStatus,
      'statusHistory': statusHistory.map((s) => s.toMap()).toList(),
    };
  }
  GeoPoint get geoPoint => GeoPoint(latitude, longitude);
}