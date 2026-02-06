import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/roadmap_item.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Roadmap tab showing timeline of completed, in-progress, and planned items
class RoadmapTab extends ConsumerStatefulWidget {
  const RoadmapTab({super.key});

  @override
  ConsumerState<RoadmapTab> createState() => _RoadmapTabState();
}

class _RoadmapTabState extends ConsumerState<RoadmapTab> {
  final _currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: ref.read(userRepositoryProvider).streamById(_currentUser.email!),
      builder: (context, userSnapshot) {
        final isAdmin = userSnapshot.data?.isAdmin ?? false;

        return Column(
          children: [
            // Header with optional add button for admin
            _buildHeader(isAdmin),
            // Roadmap timeline
            Expanded(
              child: StreamBuilder<List<RoadmapItemModel>>(
                stream: ref.read(roadmapRepositoryProvider).streamAllItems(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data ?? [];

                  if (items.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Group items by status
                  final completed = items
                      .where((i) => i.status == RoadmapStatus.completed)
                      .toList();
                  final inProgress = items
                      .where((i) => i.status == RoadmapStatus.inProgress)
                      .toList();
                  final planned = items
                      .where((i) => i.status == RoadmapStatus.planned)
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // In Progress section
                      if (inProgress.isNotEmpty) ...[
                        _buildSectionHeader(
                          'In Progress',
                          Icons.pending,
                          AppTheme.warning,
                        ),
                        ...inProgress.map(
                          (item) => _RoadmapTimelineItem(
                            item: item,
                            isAdmin: isAdmin,
                            onEdit: () => _showEditDialog(item),
                            onDelete: () => _confirmDelete(item),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Planned section
                      if (planned.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Coming Soon',
                          Icons.schedule,
                          AppTheme.info,
                        ),
                        ...planned.map(
                          (item) => _RoadmapTimelineItem(
                            item: item,
                            isAdmin: isAdmin,
                            onEdit: () => _showEditDialog(item),
                            onDelete: () => _confirmDelete(item),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Completed section
                      if (completed.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Completed',
                          Icons.check_circle,
                          AppTheme.success,
                        ),
                        ...completed.map(
                          (item) => _RoadmapTimelineItem(
                            item: item,
                            isAdmin: isAdmin,
                            onEdit: () => _showEditDialog(item),
                            onDelete: () => _confirmDelete(item),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.timeline, color: AppTheme.primary, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Development Roadmap',
                  style: AppTheme.title(
                    size: 18,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  'See what we\'re working on',
                  style: AppTheme.caption(color: AppTheme.textMedium),
                ),
              ],
            ),
          ),
          if (isAdmin)
            IconButton(
              onPressed: _showAddDialog,
              icon: Icon(Icons.add_circle, color: AppTheme.primary),
              tooltip: 'Add roadmap item',
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: AppTheme.body(
              size: 16,
              weight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No roadmap items yet',
            style: AppTheme.body(color: AppTheme.textMedium),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back soon for updates!',
            style: AppTheme.caption(color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    _showItemDialog(null);
  }

  void _showEditDialog(RoadmapItemModel item) {
    _showItemDialog(item);
  }

  void _showItemDialog(RoadmapItemModel? existingItem) {
    final titleController = TextEditingController(text: existingItem?.title ?? '');
    final descController = TextEditingController(text: existingItem?.description ?? '');
    final versionController = TextEditingController(text: existingItem?.version ?? '');
    RoadmapStatus status = existingItem?.status ?? RoadmapStatus.planned;
    DateTime date = existingItem?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingItem == null ? 'Add Roadmap Item' : 'Edit Roadmap Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g., Community Features',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Brief description of the update',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: versionController,
                  decoration: const InputDecoration(
                    labelText: 'Version (optional)',
                    hintText: 'e.g., v4.5.4',
                  ),
                ),
                const SizedBox(height: 16),
                Text('Status', style: AppTheme.body(weight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: RoadmapStatus.values.map((s) {
                    return ChoiceChip(
                      label: Text(s.displayName),
                      selected: status == s,
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() => status = s);
                        }
                      },
                      selectedColor: _getStatusColor(s),
                      labelStyle: TextStyle(
                        color: status == s ? Colors.white : AppTheme.textDark,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Date: ', style: AppTheme.body(weight: FontWeight.w600)),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => date = picked);
                        }
                      },
                      child: Text(DateFormat('MMM d, yyyy').format(date)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    descController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title and description are required')),
                  );
                  return;
                }

                final item = RoadmapItemModel(
                  id: existingItem?.id ?? '',
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  version: versionController.text.trim().isNotEmpty
                      ? versionController.text.trim()
                      : null,
                  status: status,
                  date: date,
                );

                final repo = ref.read(roadmapRepositoryProvider);

                if (existingItem == null) {
                  await repo.addItem(item);
                } else {
                  await repo.updateItem(item);
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        existingItem == null
                            ? 'Item added'
                            : 'Item updated',
                      ),
                    ),
                  );
                }
              },
              child: Text(existingItem == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(RoadmapItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(roadmapRepositoryProvider).deleteItem(item.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item deleted')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(RoadmapStatus status) {
    switch (status) {
      case RoadmapStatus.completed:
        return AppTheme.success;
      case RoadmapStatus.inProgress:
        return AppTheme.warning;
      case RoadmapStatus.planned:
        return AppTheme.info;
    }
  }
}

/// Individual timeline item in the roadmap
class _RoadmapTimelineItem extends StatelessWidget {
  final RoadmapItemModel item;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoadmapTimelineItem({
    required this.item,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM yyyy');
    final statusColor = _getStatusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.surfaceLight,
                    width: 2,
                  ),
                ),
                child: item.status == RoadmapStatus.completed
                    ? Icon(Icons.check, size: 8, color: Colors.white)
                    : item.status == RoadmapStatus.inProgress
                        ? Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
              ),
              Container(
                width: 2,
                height: 60,
                color: statusColor.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Content card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Date, version, admin actions
                  Row(
                    children: [
                      Text(
                        dateFormat.format(item.date),
                        style: AppTheme.caption(
                          size: 12,
                          weight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      if (item.version != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.version!,
                            style: AppTheme.caption(
                              size: 10,
                              color: AppTheme.textMedium,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (isAdmin) ...[
                        InkWell(
                          onTap: onEdit,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: AppTheme.error.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    item.title,
                    style: AppTheme.body(
                      size: 15,
                      weight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    item.description,
                    style: AppTheme.body(
                      size: 13,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(RoadmapStatus status) {
    switch (status) {
      case RoadmapStatus.completed:
        return AppTheme.success;
      case RoadmapStatus.inProgress:
        return AppTheme.warning;
      case RoadmapStatus.planned:
        return AppTheme.info;
    }
  }
}
