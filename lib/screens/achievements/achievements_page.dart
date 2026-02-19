import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_forager_app/data/models/achievement.dart';
import 'package:flutter_forager_app/data/models/gamification_constants.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/data/repositories/gamification_repository.dart';
import 'package:flutter_forager_app/providers/gamification/gamification_provider.dart';
import 'package:flutter_forager_app/screens/profile/user_profile_view_screen.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Combined Achievements and Leaderboard page with modern styling
class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedTab(int index, IconData icon, String label) {
    return AnimatedBuilder(
      animation: _mainTabController,
      builder: (context, child) {
        final isSelected = _mainTabController.index == index;
        return Tab(
          icon: Icon(
            icon,
            size: isSelected ? 22 : 16,
            color: isSelected
                ? AppTheme.textWhite
                : AppTheme.textWhite.withValues(alpha: 0.4),
          ),
          text: label,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please log in',
            style: AppTheme.body(color: AppTheme.textMedium),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryLight.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.textWhite),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Progress',
            style: AppTheme.heading(size: 20, color: AppTheme.textWhite),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _mainTabController,
            indicatorColor: AppTheme.xp,
            indicatorWeight: 3,
            labelColor: AppTheme.textWhite,
            unselectedLabelColor: AppTheme.textWhite.withValues(alpha: 0.5),
            labelStyle: AppTheme.caption(size: 14, weight: FontWeight.w600),
            unselectedLabelStyle:
                AppTheme.caption(size: 13, weight: FontWeight.w400),
            tabs: [
              _buildAnimatedTab(0, Icons.workspace_premium, 'Achievements'),
              _buildAnimatedTab(1, Icons.leaderboard, 'Leaderboard'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _mainTabController,
          children: [
            _AchievementsTab(userEmail: currentUser.email!),
            _LeaderboardTab(userEmail: currentUser.email!),
          ],
        ),
      ),
    );
  }
}

/// Achievements tab with category filters
class _AchievementsTab extends ConsumerStatefulWidget {
  final String userEmail;

  const _AchievementsTab({required this.userEmail});

  @override
  ConsumerState<_AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends ConsumerState<_AchievementsTab> {
  AchievementCategory _selectedCategory = AchievementCategory.general;
  List<AchievementStatus>? _cachedAchievements;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      final gamificationRepo = ref.read(gamificationRepositoryProvider);
      final achievements =
          await gamificationRepo.getUserAchievements(widget.userEmail);
      if (mounted) {
        setState(() {
          _cachedAchievements = achievements;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading achievements',
              style: AppTheme.body(color: AppTheme.textDark),
            ),
          ],
        ),
      );
    }

    final allAchievements = _cachedAchievements ?? [];
    final categoryAchievements = allAchievements
        .where((a) => a.achievement.category == _selectedCategory)
        .toList();

    // Sort: unlocked first, then by tier
    categoryAchievements.sort((a, b) {
      if (a.isUnlocked && !b.isUnlocked) return -1;
      if (!a.isUnlocked && b.isUnlocked) return 1;
      return a.achievement.tier.index.compareTo(b.achievement.tier.index);
    });

    final totalUnlocked = allAchievements.where((a) => a.isUnlocked).length;
    final totalCount = allAchievements.length;

    return Column(
      children: [
        // Overall progress header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.xp, AppTheme.xp.withValues(alpha: 0.7)],
            ),
            borderRadius: AppTheme.borderRadiusMedium,
            boxShadow: AppTheme.shadowMedium,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: AppTheme.textWhite,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalUnlocked / $totalCount Unlocked',
                      style: AppTheme.heading(
                        size: 20,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: AppTheme.borderRadiusSmall,
                      child: LinearProgressIndicator(
                        value: totalCount > 0 ? totalUnlocked / totalCount : 0,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Category filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: AchievementCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              final categoryCount = allAchievements
                  .where((a) => a.achievement.category == category)
                  .length;
              final categoryUnlocked = allAchievements
                  .where(
                      (a) => a.achievement.category == category && a.isUnlocked)
                  .length;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getCategoryName(category)),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.3)
                              : AppTheme.textMedium.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$categoryUnlocked/$categoryCount',
                          style: AppTheme.caption(
                            size: 10,
                            color: isSelected
                                ? AppTheme.textWhite
                                : AppTheme.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  selectedColor: AppTheme.primary,
                  checkmarkColor: AppTheme.textWhite,
                  labelStyle: AppTheme.caption(
                    size: 12,
                    color: isSelected ? AppTheme.textWhite : AppTheme.textDark,
                    weight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = category);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Achievements list
        Expanded(
          child: categoryAchievements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 64,
                        color: AppTheme.textMedium.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No achievements in this category',
                        style: AppTheme.body(color: AppTheme.textMedium),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categoryAchievements.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ModernAchievementCard(
                        achievementStatus: categoryAchievements[index],
                      ),
                    );
                  },
                ),
        ),
      ],
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

/// Modern achievement card with AppTheme styling
class _ModernAchievementCard extends StatelessWidget {
  final AchievementStatus achievementStatus;

  const _ModernAchievementCard({required this.achievementStatus});

  Color _getTierColor() {
    switch (achievementStatus.achievement.tier.name) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return AppTheme.xp;
      case 'platinum':
        return const Color(0xFF00CED1);
      case 'diamond':
        return const Color(0xFF00BFFF);
      default:
        return AppTheme.textMedium;
    }
  }

  IconData _getIconData() {
    final iconName = achievementStatus.achievement.icon;
    switch (iconName) {
      case 'eco':
        return Icons.eco;
      case 'person_add':
        return Icons.person_add;
      case 'group':
        return Icons.group;
      case 'groups':
        return Icons.groups;
      case 'share':
        return Icons.share;
      case 'restaurant':
        return Icons.restaurant;
      case 'bookmark':
        return Icons.bookmark;
      case 'restaurant_menu':
        return Icons.restaurant_menu;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'comment':
        return Icons.comment;
      case 'photo_camera':
        return Icons.photo_camera;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievement = achievementStatus.achievement;
    final isUnlocked = achievementStatus.isUnlocked;
    final progress = achievementStatus.progress;
    final tierColor = _getTierColor();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusMedium,
        border: isUnlocked
            ? Border.all(color: tierColor, width: 2)
            : Border.all(color: AppTheme.textLight.withValues(alpha: 0.2)),
        boxShadow: isUnlocked ? AppTheme.shadowMedium : AppTheme.shadowSoft,
      ),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.7,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Achievement icon with tier color
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: isUnlocked
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            tierColor,
                            tierColor.withValues(alpha: 0.7),
                          ],
                        )
                      : null,
                  color: isUnlocked ? null : AppTheme.backgroundLight,
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Icon(
                  _getIconData(),
                  size: 28,
                  color: isUnlocked ? Colors.white : AppTheme.textMedium,
                ),
              ),
              const SizedBox(width: 14),

              // Achievement details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.title,
                            style: AppTheme.title(
                              size: 15,
                              color: isUnlocked
                                  ? AppTheme.textDark
                                  : AppTheme.textMedium,
                            ),
                          ),
                        ),
                        if (isUnlocked)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: tierColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: tierColor,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: AppTheme.caption(
                        size: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Progress bar or points reward
                    if (!isUnlocked) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: AppTheme.borderRadiusSmall,
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: AppTheme.backgroundLight,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(tierColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: AppTheme.caption(
                              size: 11,
                              color: AppTheme.textMedium,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Icon(Icons.stars, size: 16, color: AppTheme.xp),
                          const SizedBox(width: 4),
                          Text(
                            '+${achievement.pointsReward} XP',
                            style: AppTheme.caption(
                              size: 12,
                              color: AppTheme.xp,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: tierColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              achievement.tier.name.toUpperCase(),
                              style: AppTheme.caption(
                                size: 9,
                                color: tierColor,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Leaderboard tab with Global and Friends filters
class _LeaderboardTab extends ConsumerStatefulWidget {
  final String userEmail;

  const _LeaderboardTab({required this.userEmail});

  @override
  ConsumerState<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<_LeaderboardTab> {
  bool _showFriendsOnly = false;

  @override
  Widget build(BuildContext context) {
    final gamificationRepo = ref.watch(gamificationRepositoryProvider);

    return Column(
      children: [
        // Toggle buttons for Global/Friends
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.borderRadiusMedium,
            boxShadow: AppTheme.shadowSoft,
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showFriendsOnly = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_showFriendsOnly
                          ? AppTheme.primary
                          : Colors.transparent,
                      borderRadius: AppTheme.borderRadiusMedium,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.public,
                          size: 18,
                          color: !_showFriendsOnly
                              ? AppTheme.textWhite
                              : AppTheme.textMedium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Global',
                          style: AppTheme.caption(
                            size: 14,
                            color: !_showFriendsOnly
                                ? AppTheme.textWhite
                                : AppTheme.textMedium,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showFriendsOnly = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _showFriendsOnly
                          ? AppTheme.primary
                          : Colors.transparent,
                      borderRadius: AppTheme.borderRadiusMedium,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people,
                          size: 18,
                          color: _showFriendsOnly
                              ? AppTheme.textWhite
                              : AppTheme.textMedium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Friends',
                          style: AppTheme.caption(
                            size: 14,
                            color: _showFriendsOnly
                                ? AppTheme.textWhite
                                : AppTheme.textMedium,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Leaderboard content
        Expanded(
          child: FutureBuilder<List<UserModel>>(
            future: _showFriendsOnly
                ? gamificationRepo.getFriendsLeaderboard(widget.userEmail)
                : gamificationRepo.getLeaderboard(limit: 100),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: AppTheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading leaderboard',
                        style: AppTheme.body(color: AppTheme.textDark),
                      ),
                    ],
                  ),
                );
              }

              final users = snapshot.data ?? [];

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showFriendsOnly ? Icons.group_off : Icons.leaderboard,
                        size: 64,
                        color: AppTheme.textMedium.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showFriendsOnly
                            ? 'No friends yet!\nAdd friends to see their rankings'
                            : 'No rankings available',
                        style: AppTheme.body(color: AppTheme.textMedium),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return FutureBuilder<int>(
                future: gamificationRepo.getUserRank(widget.userEmail),
                builder: (context, rankSnapshot) {
                  final currentUserRank = rankSnapshot.data ?? 0;

                  return Column(
                    children: [
                      // Current user rank card
                      if (currentUserRank > 0)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            borderRadius: AppTheme.borderRadiusMedium,
                            boxShadow: AppTheme.shadowMedium,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events,
                                  color: AppTheme.textWhite, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Your Rank: #$currentUserRank',
                                style: AppTheme.heading(
                                  size: 18,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Leaderboard list
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final rank = index + 1;
                            final isCurrentUser =
                                user.email == widget.userEmail;
                            final levelTitle =
                                LevelSystem.getLevelTitle(user.level);

                            return GestureDetector(
                              onTap: isCurrentUser
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              UserProfileViewScreen(
                                            userEmail: user.email,
                                            displayName: user.username,
                                          ),
                                        ),
                                      );
                                    },
                              child: _LeaderboardCard(
                                user: user,
                                rank: rank,
                                isCurrentUser: isCurrentUser,
                                levelTitle: levelTitle,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Modern leaderboard card
class _LeaderboardCard extends StatelessWidget {
  final UserModel user;
  final int rank;
  final bool isCurrentUser;
  final String levelTitle;

  const _LeaderboardCard({
    required this.user,
    required this.rank,
    required this.isCurrentUser,
    required this.levelTitle,
  });

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return AppTheme.xp; // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppTheme.textMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusMedium,
        border: isCurrentUser
            ? Border.all(color: AppTheme.accent, width: 2)
            : Border.all(color: AppTheme.textLight.withValues(alpha: 0.15)),
        boxShadow: isCurrentUser ? AppTheme.shadowMedium : AppTheme.shadowSoft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank indicator
            SizedBox(
              width: 44,
              child: rank <= 3
                  ? Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            rankColor,
                            rankColor.withValues(alpha: 0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: rankColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    )
                  : Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: AppTheme.caption(
                            size: 13,
                            color: AppTheme.textMedium,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
            ),

            // Profile pic
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
              foregroundImage: user.profilePic.isNotEmpty
                  ? AssetImage('lib/assets/images/${user.profilePic}')
                  : null,
              child: user.profilePic.isEmpty
                  ? Icon(Icons.person, color: AppTheme.primary, size: 22)
                  : null,
            ),
            const SizedBox(width: 12),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: AppTheme.title(
                      size: 15,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Lvl ${user.level}',
                          style: AppTheme.caption(
                            size: 10,
                            color: AppTheme.primary,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        levelTitle,
                        style: AppTheme.caption(
                          size: 11,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Points and streak
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars, size: 16, color: AppTheme.xp),
                    const SizedBox(width: 4),
                    Text(
                      '${user.points}',
                      style: AppTheme.stats(
                        size: 16,
                        color: AppTheme.xp,
                      ),
                    ),
                  ],
                ),
                if (user.currentStreak > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department,
                          size: 14, color: AppTheme.streak),
                      const SizedBox(width: 2),
                      Text(
                        '${user.currentStreak}',
                        style: AppTheme.caption(
                          size: 12,
                          color: AppTheme.streak,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
