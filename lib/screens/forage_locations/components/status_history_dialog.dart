import 'package:flutter/material.dart';
import 'package:flutter_forager_app/models/marker.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:intl/intl.dart';

class StatusHistoryDialog extends StatelessWidget {
  final List<MarkerStatusUpdate> history;

  const StatusHistoryDialog({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Status History'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: history.length,
          itemBuilder: (context, index) {
            final update = history[index];
            return ListTile(
              leading: Icon(
                _getStatusIcon(update.status),
                color: _getStatusColor(update.status),
              ),
              title: Text('${update.username ?? update.userEmail}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StyledText('Changed to ${update.status.toUpperCase()}'),
                  if (update.notes != null) StyledText(update.notes!),
                  StyledText(
                    DateFormat.yMMMd().add_jm().format(update.timestamp),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'ripe':
        return Icons.check_circle;
      case 'stale':
        return Icons.warning;
      case 'not_found':
        return Icons.error_outline;
      case 'active':
      default:
        return Icons.location_on;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ripe':
        return Colors.green;
      case 'stale':
        return Colors.orange;
      case 'not_found':
        return Colors.red;
      case 'active':
      default:
        return Colors.blue;
    }
  }
}
