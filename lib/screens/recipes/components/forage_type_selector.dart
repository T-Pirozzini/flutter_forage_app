import 'package:flutter/material.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Horizontal scrollable selector for forage types.
///
/// Used in recipe creation to categorize foraged ingredients.
/// Shows PNG marker icons with type-specific colors.
class ForageTypeSelector extends StatelessWidget {
  final String? selectedType;
  final Function(String?) onTypeSelected;
  final bool allowDeselect;

  const ForageTypeSelector({
    super.key,
    this.selectedType,
    required this.onTypeSelected,
    this.allowDeselect = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type (optional)',
          style: AppTheme.caption(
            size: 12,
            color: AppTheme.textMedium,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ForageTypeUtils.allTypes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final type = ForageTypeUtils.allTypes[index];
              final isSelected = selectedType == type;
              final color = ForageTypeUtils.getTypeColor(type);

              return GestureDetector(
                onTap: () {
                  if (isSelected && allowDeselect) {
                    onTypeSelected(null);
                  } else {
                    onTypeSelected(type);
                  }
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.2)
                            : AppTheme.surfaceLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? color
                              : AppTheme.textLight.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Image.asset(
                          'lib/assets/images/${type}_marker.png',
                          width: 28,
                          height: 28,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to icon if image not found
                            return ForageTypeUtils.getTypeIcon(type, size: 24);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ForageTypeUtils.normalizeType(type),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? color : AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
