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
            tabs: const [
              Tab(text: 'Community'),
              Tab(text: 'Recipes'),
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
