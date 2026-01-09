import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_forager_app/data/models/gamification_constants.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/providers/gamification/gamification_provider.dart';
import 'package:flutter_forager_app/shared/screen_heading.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showFriendsOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _showFriendsOnly = _tabController.index == 1;
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
        title: const ScreenHeading(title: 'Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Friends'),
          ],
        ),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _showFriendsOnly
            ? gamificationRepo.getFriendsLeaderboard(currentUser.email!)
            : gamificationRepo.getLeaderboard(limit: 100),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading leaderboard: ${snapshot.error}'),
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
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(height: AppTheme.space16),
                  Text(
                    _showFriendsOnly
                        ? 'No friends yet!\nAdd friends to see their rankings'
                        : 'No rankings available',
                    style: AppTheme.body(
                      color: AppTheme.textMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<int>(
            future: gamificationRepo.getUserRank(currentUser.email!),
            builder: (context, rankSnapshot) {
              final currentUserRank = rankSnapshot.data ?? 0;

              return Column(
                children: [
                  // Current user rank card
                  if (currentUserRank > 0)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events, color: AppTheme.textWhite),
                          const SizedBox(width: AppTheme.space8),
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

                  // Leaderboard list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final rank = index + 1;
                        final isCurrentUser = user.email == currentUser.email;
                        final levelTitle =
                            LevelSystem.getLevelTitle(user.level);

                        return Card(
                          elevation: isCurrentUser ? 4 : 1,
                          color: isCurrentUser
                              ? AppTheme.accent.withOpacity(0.1)
                              : null,
                          margin: const EdgeInsets.only(bottom: AppTheme.space8),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.borderRadiusMedium,
                          ),
                          child: ListTile(
                            leading: SizedBox(
                              width: 50,
                              child: Row(
                                children: [
                                  // Rank with special styling for top 3
                                  if (rank <= 3)
                                    Icon(
                                      Icons.emoji_events,
                                      color: rank == 1
                                          ? AppTheme.xp
                                          : rank == 2
                                              ? AppTheme.textMedium
                                              : Colors.brown,
                                      size: 32,
                                    )
                                  else
                                    SizedBox(
                                      width: 32,
                                      child: Center(
                                        child: Text(
                                          '#$rank',
                                          style: AppTheme.heading(
                                            size: 16,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            title: Row(
                              children: [
                                // Profile pic
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      AppTheme.primary.withOpacity(0.2),
                                  foregroundImage: user.profilePic.isNotEmpty
                                      ? AssetImage(
                                          'lib/assets/images/${user.profilePic}')
                                      : null,
                                  child: user.profilePic.isEmpty
                                      ? const Icon(Icons.person,
                                          color: AppTheme.primary)
                                      : null,
                                ),
                                const SizedBox(width: AppTheme.space12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.username,
                                        style: AppTheme.title(
                                          size: 16,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      Text(
                                        'Level ${user.level} • $levelTitle',
                                        style: AppTheme.caption(
                                          size: 12,
                                          color: AppTheme.textMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.stars,
                                        size: 16, color: AppTheme.xp),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${user.points}',
                                      style: AppTheme.stats(
                                        size: 18,
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
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
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
    );
  }
}
