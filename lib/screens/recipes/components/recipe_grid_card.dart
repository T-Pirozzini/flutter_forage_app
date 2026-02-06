import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/recipe.dart';
import 'package:flutter_forager_app/screens/recipes/recipe_detail_screen.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// A simplified recipe card designed for grid display.
///
/// Shows only:
/// - Primary image (first image only)
/// - Recipe name
/// - Foraged ingredient count
/// - Comment count badge
/// - Author + date (small footer)
///
/// Tapping navigates to RecipeDetailScreen for full recipe view.
class RecipeGridCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onRecipeUpdated;

  const RecipeGridCard({
    super.key,
    required this.recipe,
    this.onRecipeUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(
              recipe: recipe,
              onRecipeUpdated: onRecipeUpdated,
            ),
          ),
        );
      },
      borderRadius: AppTheme.borderRadiusMedium,
      child: Card(
        elevation: 2,
        shadowColor: AppTheme.primary.withValues(alpha: 0.2),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusMedium,
          side: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.15),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primary image
            _buildImage(),

            // Recipe name
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
              child: Text(
                recipe.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.title(
                  size: 14,
                  weight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ),

            // Stats row: foraged count + comment count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  // Foraged ingredients
                  Icon(
                    Icons.eco,
                    size: 14,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${recipe.foragedIngredientCount}',
                    style: AppTheme.caption(
                      size: 12,
                      color: AppTheme.textMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Comment count
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 14,
                    color: AppTheme.textMedium,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${recipe.commentCount}',
                    style: AppTheme.caption(
                      size: 12,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Footer: author + date
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                '@${recipe.userName} • ${dateFormat.format(recipe.timestamp)}',
                style: AppTheme.caption(
                  size: 10,
                  color: AppTheme.textMedium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (recipe.imageUrls.isEmpty) {
      return Container(
        height: 100,
        width: double.infinity,
        color: AppTheme.surfaceLight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: 32,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 4),
            Text(
              'No image',
              style: AppTheme.caption(
                size: 10,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 100,
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: recipe.imageUrls.first,
        fit: BoxFit.cover,
        memCacheHeight: 300,
        placeholder: (context, url) => Container(
          color: AppTheme.surfaceLight,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primary,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppTheme.surfaceLight,
          child: Icon(
            Icons.image_not_supported,
            color: AppTheme.textLight,
          ),
        ),
      ),
    );
  }
}
