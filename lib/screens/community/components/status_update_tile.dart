import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class StatusUpdateTile extends StatelessWidget {
  final Map<String, dynamic> update;
  final Timestamp? timestamp;

  const StatusUpdateTile({
    super.key,
    required this.update,
    required this.timestamp,
  });

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'abundant':
        return AppTheme.success;
      case 'moderate':
        return AppTheme.warning;
      case 'scarce':
        return AppTheme.error;
      case 'out of season':
        return AppTheme.textMedium;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'abundant':
        return Icons.check_circle;
      case 'moderate':
        return Icons.remove_circle;
      case 'scarce':
        return Icons.warning;
      case 'out of season':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM d');
    final status = update['status'] as String?;
    final statusColor = _getStatusColor(status);
    final username = update['username'] ?? update['userEmail']?.split('@')[0] ?? 'User';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusSmall,
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getStatusIcon(status),
                  size: 16,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              // User and status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: AppTheme.caption(
                        size: 12,
                        color: AppTheme.textDark,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Marked as ',
                          style: AppTheme.caption(
                            size: 11,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status ?? 'Unknown',
                            style: AppTheme.caption(
                              size: 10,
                              color: statusColor,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Timestamp
              if (timestamp != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dateFormat.format(timestamp!.toDate()),
                      style: AppTheme.caption(
                        size: 10,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    Text(
                      timeFormat.format(timestamp!.toDate()),
                      style: AppTheme.caption(
                        size: 10,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Notes section
          if (update['notes'] != null && (update['notes'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote,
                    size: 14,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      update['notes']!,
                      style: AppTheme.caption(
                        size: 12,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}