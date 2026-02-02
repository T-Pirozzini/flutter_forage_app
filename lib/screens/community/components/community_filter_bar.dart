import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_forager_app/providers/community/community_filter_provider.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// A horizontal scrollable filter bar for community posts.
///
/// Allows users to filter posts by:
/// - All (default)
/// - Recent (most recent first)
/// - Friends (posts from friends only)
/// - Following (posts from followed users)
/// - Nearby (posts within a radius)
class CommunityFilterBar extends ConsumerWidget {
  const CommunityFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(communityFilterProvider);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: CommunityFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = CommunityFilter.values[index];
          final isSelected = filter == currentFilter;

          return _FilterChip(
            filter: filter,
            isSelected: isSelected,
            onTap: () {
              ref.read(communityFilterProvider.notifier).state = filter;
            },
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final CommunityFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.textLight.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFilterIcon(filter),
              size: 14,
              color: isSelected ? Colors.white : AppTheme.textMedium,
            ),
            const SizedBox(width: 6),
            Text(
              filter.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFilterIcon(CommunityFilter filter) {
    switch (filter) {
      case CommunityFilter.all:
        return Icons.public;
      case CommunityFilter.recent:
        return Icons.schedule;
      case CommunityFilter.friends:
        return Icons.people;
      case CommunityFilter.following:
        return Icons.person_add;
      case CommunityFilter.nearby:
        return Icons.near_me;
    }
  }
}
