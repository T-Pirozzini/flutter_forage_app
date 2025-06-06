import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String author;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.author,
    required this.text,
    required this.timestamp,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      author: map['author'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'author': author,
      'text': text,
      'timestamp': timestamp,
    };
  }
}
