// models/marker.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory MarkerModel.fromFirestore(DocumentSnapshot doc) {
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
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      latitude: (location['latitude'] as num).toDouble(),
      longitude: (location['longitude'] as num).toDouble(),
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
    };
  }
  GeoPoint get geoPoint => GeoPoint(latitude, longitude);
}