import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/post_comment.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// A tile displaying a single comment.
///
/// Supports both:
/// - New PostCommentModel (from subcollection)
/// - Legacy Map<String, dynamic> (for backward compatibility)
class CommentTile extends StatelessWidget {
  final PostCommentModel? commentModel;
  final Map<String, dynamic>? legacyComment;

  const CommentTile({
    super.key,
    this.commentModel,
    this.legacyComment,
  }) : assert(commentModel != null || legacyComment != null,
            'Either commentModel or legacyComment must be provided');

  /// Factory constructor for new PostCommentModel
  const CommentTile.fromModel({super.key, required PostCommentModel comment})
      : commentModel = comment,
        legacyComment = null;

  /// Factory constructor for legacy Map format
  const CommentTile.fromMap({super.key, required Map<String, dynamic> comment})
      : commentModel = null,
        legacyComment = comment;

  @override
  Widget build(BuildContext context) {
    // Extract data from either model or legacy map
    final String username;
    final String text;
    final DateTime? createdAt;
    final String? profilePic;

    if (commentModel != null) {
      username = commentModel!.username.isNotEmpty
          ? commentModel!.username
          : commentModel!.userEmail.split('@')[0];
      text = commentModel!.text;
      createdAt = commentModel!.createdAt;
      profilePic = commentModel!.profilePic;
    } else {
      final legacy = legacyComment!;
      username = legacy['username'] ??
          legacy['userEmail']?.split('@')[0] ??
          'Anonymous';
      text = legacy['text'] ?? '';

      // Handle legacy timestamp (could be Timestamp or DateTime)
      final timestampValue = legacy['timestamp'] ?? legacy['createdAt'];
      if (timestampValue is Timestamp) {
        createdAt = timestampValue.toDate();
      } else if (timestampValue is DateTime) {
        createdAt = timestampValue;
      } else {
        createdAt = null;
      }
      profilePic = legacy['profilePic'];
    }

    final displayTime = createdAt != null
        ? DateFormat('MMM d, h:mm a').format(createdAt)
        : 'Just now';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
            backgroundImage:
                profilePic != null ? NetworkImage(profilePic) : null,
            child: profilePic == null
                ? Icon(Icons.person, size: 18, color: AppTheme.primary)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: AppTheme.borderRadiusSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StyledTextMedium(
                        username,
                        color: AppTheme.secondary,
                      ),
                      StyledTextSmall(
                        displayTime,
                        color: AppTheme.textLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: AppTheme.body(size: 14, color: AppTheme.textDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
