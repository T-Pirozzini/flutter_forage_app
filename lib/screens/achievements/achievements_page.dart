import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_forager_app/data/models/achievement.dart';
import 'package:flutter_forager_app/data/repositories/gamification_repository.dart';
import 'package:flutter_forager_app/providers/gamification/gamification_provider.dart';
import 'package:flutter_forager_app/shared/gamification/achievement_card.dart';
import 'package:flutter_forager_app/shared/screen_heading.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AchievementCategory _selectedCategory = AchievementCategory.general;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AchievementCategory.values.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = AchievementCategory.values[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    final gamificationRepo = ref.watch(gamificationRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const ScreenHeading(
          title: 'Achievements',
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: AchievementCategory.values.map((category) {
            return Tab(
              text: _getCategoryName(category),
            );
          }).toList(),
        ),
      ),
      body: FutureBuilder<List<AchievementStatus>>(
        future: gamificationRepo.getUserAchievements(currentUser.email!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading achievements: ${snapshot.error}'),
            );
          }

          final allAchievements = snapshot.data ?? [];
          final categoryAchievements = allAchievements
              .where((a) => a.achievement.category == _selectedCategory)
              .toList();

          // Sort: unlocked first, then by tier
          categoryAchievements.sort((a, b) {
            if (a.isUnlocked && !b.isUnlocked) return -1;
            if (!a.isUnlocked && b.isUnlocked) return 1;
            return a.achievement.tier.index.compareTo(b.achievement.tier.index);
          });

          final unlockedCount =
              categoryAchievements.where((a) => a.isUnlocked).length;
          final totalCount = categoryAchievements.length;

          return Column(
            children: [
              // Progress summary
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.deepOrange.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    Text(
                      '$unlockedCount / $totalCount Unlocked',
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
              ),

              // Achievements list
              Expanded(
                child: categoryAchievements.isEmpty
                    ? Center(
                        child: Text(
                          'No achievements in this category',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: categoryAchievements.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AchievementCard(
                              achievementStatus: categoryAchievements[index],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.general:
        return 'General';
      case AchievementCategory.forage:
        return 'Foraging';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.recipe:
        return 'Recipes';
      case AchievementCategory.exploration:
        return 'Explorer';
      case AchievementCategory.streak:
        return 'Streaks';
    }
  }
}
