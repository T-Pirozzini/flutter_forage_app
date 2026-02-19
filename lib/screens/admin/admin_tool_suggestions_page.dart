import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Admin page for viewing tool suggestions from users
class AdminToolSuggestionsPage extends StatelessWidget {
  const AdminToolSuggestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tool Suggestions'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textWhite,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ToolSuggestions')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 48, color: AppTheme.textMedium),
                  const SizedBox(height: 12),
                  Text(
                    'No suggestions yet',
                    style: AppTheme.body(color: AppTheme.textMedium),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final suggestion = data['suggestion'] ?? '';
              final userId = data['userId'] ?? 'anonymous';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final dateStr = createdAt != null
                  ? DateFormat('MMM d, yyyy - h:mm a').format(createdAt)
                  : 'Unknown date';

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion,
                        style: AppTheme.body(
                          size: 14,
                          weight: FontWeight.w500,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 14, color: AppTheme.textMedium),
                          const SizedBox(width: 4),
                          Text(
                            userId,
                            style: AppTheme.caption(
                              size: 11,
                              color: AppTheme.textMedium,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            dateStr,
                            style: AppTheme.caption(
                              size: 11,
                              color: AppTheme.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
