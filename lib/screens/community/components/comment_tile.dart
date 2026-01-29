import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;

  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final timestamp = comment['timestamp'] as Timestamp?;
    final displayTime = timestamp != null
        ? DateFormat('MMM d, h:mm a').format(timestamp.toDate())
        : 'Just now'; // More user-friendly than "pending..."

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
            child: Icon(Icons.person, size: 20, color: AppTheme.accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StyledText(
                      comment['username'] ??
                          comment['userEmail']?.split('@')[0] ??
                          'Anonymous',
                      color: AppTheme.secondary,
                    ),
                    StyledTextSmall(
                      displayTime,
                      color: AppTheme.textMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                StyledText(comment['text'] ?? '', color: AppTheme.textDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
