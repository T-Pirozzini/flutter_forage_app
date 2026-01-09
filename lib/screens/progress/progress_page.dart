import 'package:flutter/material.dart';
import 'package:flutter_forager_app/screens/achievements/achievements_page.dart';
import 'package:flutter_forager_app/screens/leaderboard/leaderboard_page.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Combined Progress screen with Achievements and Leaderboard tabs
class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage>
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
            indicatorColor: AppTheme.xp,
            labelColor: AppTheme.textWhite,
            unselectedLabelColor: AppTheme.textWhite.withOpacity(0.6),
            labelStyle: AppTheme.title(size: 16, color: AppTheme.textWhite),
            tabs: const [
              Tab(
                icon: Icon(Icons.workspace_premium),
                text: 'Achievements',
              ),
              Tab(
                icon: Icon(Icons.leaderboard),
                text: 'Leaderboard',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              AchievementsPage(),
              LeaderboardPage(),
            ],
          ),
        ),
      ],
    );
  }
}
