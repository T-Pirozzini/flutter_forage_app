import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatusUpdateTile extends StatelessWidget {
  final Map<String, dynamic> update;
  final Timestamp? timestamp;

  const StatusUpdateTile({
    super.key,
    required this.update,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${update['username'] ?? update['userEmail']?.split('@')[0] ?? 'User'} '
                'marked as ${update['status']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (timestamp != null)
                Text(
                  timeFormat.format(timestamp!.toDate()),
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
  }
}