import 'package:flutter/material.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/providers/map/map_state_provider.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compact filter bar with icon filters for marker types
///
/// Allows users to show/hide markers by type in real-time.
/// Tapping a chip toggles visibility - no "Apply" button needed.
class MarkerFilterChips extends ConsumerWidget {
  const MarkerFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleTypes = ref.watch(visibleMarkerTypesProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate chip width to fit label + all types dynamically
    final filterLabelWidth = 52.0;
    final chipWidth = (screenWidth - 32 - filterLabelWidth) / ForageTypeUtils.allTypes.length;

    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Filter label
          Container(
            width: filterLabelWidth,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 18,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 2),
                Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 32,
            color: AppTheme.primary.withValues(alpha: 0.1),
          ),
          // Filter chips
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ForageTypeUtils.allTypes.map((type) {
                final isSelected = visibleTypes.contains(type);
                final typeColor = ForageTypeUtils.getTypeColor(type);

                return GestureDetector(
                  onTap: () {
                    final current = ref.read(visibleMarkerTypesProvider);
                    if (isSelected) {
                      // Don't allow deselecting all - keep at least one visible
                      if (current.length > 1) {
                        ref.read(visibleMarkerTypesProvider.notifier).state =
                            current.where((t) => t != type).toSet();
                      }
                    } else {
                      ref.read(visibleMarkerTypesProvider.notifier).state = {
                        ...current,
                        type
                      };
                    }
                  },
                  child: SizedBox(
                    width: chipWidth.clamp(32.0, 44.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon container
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? typeColor
                                : typeColor.withValues(alpha: 0.12),
                            border: Border.all(
                              color: isSelected
                                  ? typeColor
                                  : typeColor.withValues(alpha: 0.25),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: typeColor.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Image.asset(
                              'lib/assets/images/${_getAssetName(type)}_marker.png',
                              width: 14,
                              height: 14,
                              color: isSelected ? Colors.white : typeColor,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.place,
                                size: 14,
                                color: isSelected ? Colors.white : typeColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Label
                        Text(
                          _getShortLabel(type),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? typeColor : AppTheme.textMedium,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Maps type names to asset file names (handles singular/plural differences)
  String _getAssetName(String type) {
    switch (type.toLowerCase()) {
      case 'mushrooms':
      case 'mushroom':
        return 'mushroom';
      case 'trees':
      case 'tree':
        return 'tree';
      case 'plants':
      case 'plant':
        return 'plant';
      case 'herbs':
      case 'herb':
        return 'plant'; // Use plant as fallback
      case 'berries':
      case 'berry':
        return 'berries';
      case 'nuts':
      case 'nut':
        return 'nuts';
      default:
        return type.toLowerCase();
    }
  }

  /// Get short label for compact display
  String _getShortLabel(String type) {
    switch (type.toLowerCase()) {
      case 'mushrooms':
      case 'mushroom':
        return 'Shroom';
      case 'berries':
      case 'berry':
        return 'Berry';
      case 'plants':
      case 'plant':
        return 'Plant';
      case 'herbs':
      case 'herb':
        return 'Herb';
      case 'trees':
      case 'tree':
        return 'Tree';
      case 'fish':
        return 'Fish';
      case 'nuts':
      case 'nut':
        return 'Nut';
      case 'shellfish':
        return 'Shell';
      case 'other':
        return 'Other';
      default:
        return type.length > 5 ? type.substring(0, 5) : type;
    }
  }
}
