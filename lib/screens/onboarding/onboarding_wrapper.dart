import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/core/utils/app_version.dart';
import 'package:flutter_forager_app/data/models/notification_preferences.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/repositories/user_repository.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/screens/home/home_page.dart';
import 'package:flutter_forager_app/screens/onboarding/onboarding_screen.dart';
import 'package:flutter_forager_app/screens/onboarding/whats_new_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wrapper that determines whether to show onboarding or home page
///
/// Checks if the current user has completed onboarding.
/// If not, shows the onboarding flow first.
class OnboardingWrapper extends ConsumerWidget {
  const OnboardingWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // Should never happen - AuthPage already checked auth
      return const Scaffold(
        body: Center(
          child: Text('Authentication error'),
        ),
      );
    }

    final userRepo = ref.read(userRepositoryProvider);

    return FutureBuilder<UserModel?>(
      future: userRepo.getById(currentUser.email!),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading user data: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Trigger rebuild to retry
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data;

        // User data not found - show error or create user
        if (user == null) {
          // This might happen for new users who haven't been created yet
          // You might want to handle user creation here
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add, size: 64),
                  const SizedBox(height: 16),
                  const Text('Setting up your account...'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Create user with default values
                      final now = Timestamp.now();
                      await userRepo.create(
                        UserModel(
                          uid: currentUser.email!,
                          email: currentUser.email!,
                          username: currentUser.displayName ?? 'Forager',
                          bio: '',
                          profilePic: 'profileImage1.jpg',
                          profileBackground: 'backgroundProfileImage1.jpg',
                          friends: const [],
                          friendRequests: const {},
                          sentFriendRequests: const {},
                          savedRecipes: const [],
                          savedLocations: const [],
                          forageStats: const {},
                          preferences: const {},
                          createdAt: now,
                          lastActive: now,
                          // Gamification defaults
                          points: 0,
                          level: 1,
                          achievements: const [],
                          activityStats: const {},
                          currentStreak: 0,
                          longestStreak: 0,
                          lastActivityDate: DateTime.now(),
                          // Premium defaults
                          subscriptionTier: 'free',
                          subscriptionExpiry: null,
                          hasCompletedOnboarding: false,
                          // Notification defaults
                          notificationPreferences:
                              const NotificationPreferences(
                            enabled: true,
                            socialNotifications: true,
                            seasonalAlerts: true,
                            locationReminders: true,
                            recipeNotifications: true,
                            communityUpdates: false,
                            achievementNotifications: true,
                            fcmToken: null,
                          ),
                        ),
                        id: currentUser.email!,
                      );
                      // Trigger rebuild
                      if (context.mounted) {
                        (context as Element).markNeedsBuild();
                      }
                    },
                    child: const Text('Create Account'),
                  ),
                ],
              ),
            ),
          );
        }

        // Check if user needs onboarding
        if (user.needsOnboarding) {
          return OnboardingScreen(
            isTutorial: false,
            onComplete: () async {
              // Mark onboarding as complete with current version
              await userRepo.completeOnboarding(
                currentUser.email!,
                appVersion: AppVersion.current,
              );

              // Navigate to home page
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomePage(currentIndex: 2),
                  ),
                );
              }
            },
          );
        }

        // Check if returning user needs to see What's New
        if (user.needsWhatsNew(AppVersion.current)) {
          return _HomeWithWhatsNew(
            userEmail: currentUser.email!,
            userRepo: userRepo,
          );
        }

        // User has completed onboarding and seen latest version, show home page
        return const HomePage(currentIndex: 2);
      },
    );
  }
}

/// Shows the home page, then triggers the What's New dialog once.
class _HomeWithWhatsNew extends ConsumerStatefulWidget {
  final String userEmail;
  final UserRepository userRepo;

  const _HomeWithWhatsNew({
    required this.userEmail,
    required this.userRepo,
  });

  @override
  ConsumerState<_HomeWithWhatsNew> createState() => _HomeWithWhatsNewState();
}

class _HomeWithWhatsNewState extends ConsumerState<_HomeWithWhatsNew> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWhatsNew();
    });
  }

  Future<void> _showWhatsNew() async {
    if (!mounted) return;
    final shown = await showWhatsNewDialog(context);
    if (shown) {
      await widget.userRepo.markTutorialVersionSeen(
        widget.userEmail,
        AppVersion.current,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage(currentIndex: 2);
  }
}
