import 'package:flutter/material.dart';
import 'package:flutter_forager_app/screens/community/community_page.dart';
import 'package:flutter_forager_app/screens/recipes/recipes_page.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Combined Feed page with Community and Recipes tabs
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCommunityInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Text('About Community'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share your foraging finds with the community!',
              style: AppTheme.body(size: 14, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            Text(
              'Like and bookmark locations to save them for later exploration.',
              style: AppTheme.body(size: 14, color: AppTheme.textMedium),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: AppTheme.borderRadiusMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to share:',
                    style: AppTheme.caption(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStep('1', 'Create a marker on the map'),
                  const SizedBox(height: 4),
                  _buildStep('2', 'Open your location details'),
                  const SizedBox(height: 4),
                  _buildStep('3', 'Tap "Share with Community"'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showRecipesInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Text('About Recipes'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discover and share recipes featuring foraged ingredients!',
              style: AppTheme.body(size: 14, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            Text(
              'Save your favorite recipes and share your own creations with the community.',
              style: AppTheme.body(size: 14, color: AppTheme.textMedium),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTheme.body(size: 13, color: AppTheme.textMedium),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.primary,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.secondary,
            indicatorWeight: 3,
            labelColor: AppTheme.textWhite,
            unselectedLabelColor: AppTheme.textWhite.withValues(alpha: 0.6),
            labelStyle: AppTheme.caption(size: 13, weight: FontWeight.w600),
            unselectedLabelStyle: AppTheme.caption(size: 13),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Community'),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _showCommunityInfo,
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppTheme.textWhite.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Recipes'),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _showRecipesInfo,
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppTheme.textWhite.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              CommunityPage(),
              RecipesPage(),
            ],
          ),
        ),
      ],
    );
  }
}
