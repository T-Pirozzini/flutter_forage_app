import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/marker.dart';
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
              title: StyledText('${update.username ?? update.userEmail}',
                  color: Colors.white),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StyledText('Changed to ${update.status.toUpperCase()}',
                      color: Colors.deepOrange),
                  if (update.notes != null)
                    StyledText(update.notes!, color: Colors.white70),
                  StyledText(
                    DateFormat.yMMMd().add_jm().format(update.timestamp),
                    color: Colors.white54,
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
      case 'abundant':
        return Icons.eco; // or Icons.local_florist
      case 'sparse':
        return Icons.water_drop; // represents limited availability
      case 'out_of_season':
        return Icons.hourglass_empty;
      case 'no_longer_available':
        return Icons.not_interested;
      case 'active':
      default:
        return Icons.location_on;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'abundant':
        return Colors.green;
      case 'sparse':
        return Colors.orange;
      case 'out_of_season':
        return Colors.blueGrey;
      case 'no_longer_available':
        return Colors.red;
      case 'active':
      default:
        return Colors.blue;
    }
  }
}
