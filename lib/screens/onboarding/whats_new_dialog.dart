import 'package:flutter/material.dart';
import 'package:flutter_forager_app/core/utils/app_version.dart';
import 'package:flutter_forager_app/data/models/whats_new_page_model.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Shows a "What's New in v{version}" bottom sheet.
/// Returns true if the dialog was actually shown, false if no content exists.
Future<bool> showWhatsNewDialog(BuildContext context) async {
  final version = AppVersion.current;
  final items = WhatsNewContent.forVersion(version);

  if (items.isEmpty) return false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _WhatsNewSheet(version: version, items: items),
  );

  return true;
}

class _WhatsNewSheet extends StatelessWidget {
  final String version;
  final List<WhatsNewItem> items;

  const _WhatsNewSheet({required this.version, required this.items});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textMedium.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.auto_awesome, size: 32, color: AppTheme.secondary),
                const SizedBox(height: 8),
                Text(
                  "What's New in v$version",
                  style: AppTheme.title(size: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  "Here's what we've been working on",
                  style:
                      AppTheme.caption(size: 13, color: AppTheme.textMedium),
                ),
              ],
            ),
          ),
          // Item list
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildItem(item);
              },
            ),
          ),
          // Dismiss button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Got it!'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(WhatsNewItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 20, color: AppTheme.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTheme.title(size: 14)),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: AppTheme.caption(size: 12, color: AppTheme.textMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
