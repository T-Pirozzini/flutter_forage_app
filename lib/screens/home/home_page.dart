import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/services/ad_mob_service.dart';
import 'package:flutter_forager_app/data/services/notification_service.dart';
import 'package:flutter_forager_app/screens/notifications/notifications_page.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/screens/profile/profile_page.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_locations_page.dart';
import 'package:flutter_forager_app/screens/feed/feed_page.dart';
import 'package:flutter_forager_app/screens/tools/tools_page.dart';
import 'package:flutter_forager_app/screens/feedback/feedback.dart';
import 'package:flutter_forager_app/shared/gamification/gamification_helper.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../drawer/drawer.dart';
import '../forage/map_page.dart';

class HomePage extends ConsumerStatefulWidget {
  final int currentIndex;

  const HomePage({
    super.key,
    required this.currentIndex,
  });

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  int currentIndex = 0;
  BannerAd? _banner;
  bool _isBannerAdLoaded = false;

  // Keep page instances to prevent recreation
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.currentIndex;

    // Initialize pages once to prevent recreation
    // New order: Feed | Profile | EXPLORE (center) | Tools | Feedback
    _pages = [
      const FeedPage(), // Feed tab (index 0)
      _buildProfileStream(), // Profile tab (index 1)
      MapPage(), // EXPLORE tab - CENTER, prominent (index 2)
      const ToolsPage(), // Tools tab (index 3)
      const FeedbackPage(), // Feedback tab (index 4)
    ];

    // Defer non-critical work to let map render first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Delay streak update (Firestore write can wait)
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          GamificationHelper.updateStreak(
            context: context,
            ref: ref,
            userId: currentUser.email!,
          );
        }
      });

      // Save FCM token for push notifications (defer to not block startup)
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          NotificationService.instance.getAndSaveToken();
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _createBannerAd();
  }

  void _createBannerAd() async {
    final adSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
    );

    _banner = BannerAd(
      adUnitId: AdMobService.bannerAdUnitId!,
      size: adSize ?? AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) => setState(() => _isBannerAdLoaded = true),
        onAdFailedToLoad: (Ad ad, LoadAdError error) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: AppTheme.primary,
        // Hamburger menu + User avatar on LEFT
        leadingWidth: 100,
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hamburger menu icon - opens drawer
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Menu',
                ),
                // User avatar - navigates to profile tab
                GestureDetector(
                  onTap: () => setState(() => currentIndex = 1), // Profile tab
                  child: StreamBuilder<UserModel?>(
                    stream: ref
                        .read(userRepositoryProvider)
                        .streamById(currentUser.email!),
                    builder: (context, snapshot) {
                      final profilePic =
                          snapshot.data?.profilePic ?? 'profileImage1.jpg';
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: AppTheme.textWhite, width: 2),
                              image: DecorationImage(
                                image: AssetImage('lib/assets/images/$profilePic'),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {},
                              ),
                            ),
                            child: snapshot.data?.profilePic == null
                                ? Icon(Icons.person,
                                    color: AppTheme.textWhite, size: 22)
                                : null,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Forager logo CENTERED
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Image.asset(
            'assets/images/forager_logo_3.png',
            height: 54,
            fit: BoxFit.contain,
          ),
        ),
        // Welcome message + Notifications bell on RIGHT
        actions: [
          // Welcome message with username
          StreamBuilder<UserModel?>(
            stream: ref
                .read(userRepositoryProvider)
                .streamById(currentUser.email!),
            builder: (context, snapshot) {
              final username = snapshot.data?.username ??
                  currentUser.email!.split('@')[0];
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: AppTheme.textWhite.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    username,
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
          // Notification bell with unread badge
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: _buildNotificationBell(),
          ),
        ],
      ),
      drawer: CustomDrawer(
        onSignOutTap: _signOut,
        onForageLocationsTap: _goToForageLocationsPage,
        onAboutTap: goToAboutPage,
        onAboutUsTap: goAboutUsPage,
        onCreditsTap: goCreditsPage,
        showDeleteConfirmationDialog: _showDeleteConfirmationDialog,
      ),
      body: Column(
        children: [
          if (_isBannerAdLoaded && _banner != null)
            Container(
              width: _banner!.size.width.toDouble(),
              height: _banner!.size.height.toDouble(),
              alignment: Alignment.center,
              child: AdWidget(ad: _banner!),
            ),
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (int i) => setState(() => currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surfaceLight,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textMedium,
        selectedLabelStyle: AppTheme.caption(
          size: 12,
          weight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTheme.caption(
          size: 12,
        ),
        elevation: 8,
        // New order: Feed | Profile | EXPLORE (center) | Tools | Feedback
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          // EXPLORE - Prominent center tab with amber background (oversized)
          BottomNavigationBarItem(
            icon: Transform.translate(
              offset: const Offset(0, -12), // Hang over the nav bar edge
              child: SizedBox(
                height: 84, // Increased height to prevent overflow
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14), // Restored padding
                      decoration: BoxDecoration(
                        color: currentIndex == 2
                            ? AppTheme.secondary
                            : AppTheme.secondary.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.surfaceLight,
                          width: 3,
                        ),
                        boxShadow: currentIndex == 2
                            ? [
                                BoxShadow(
                                  color: AppTheme.secondary.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        Icons.explore,
                        color: currentIndex == 2
                            ? AppTheme.textWhite
                            : AppTheme.textWhite.withValues(alpha: 0.6),
                        size: currentIndex == 2 ? 28 : 24,
                      ),
                    ),
                    const Spacer(), // Push text to bottom
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Explore',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: currentIndex == 2 ? FontWeight.w600 : FontWeight.normal,
                          color: currentIndex == 2 ? AppTheme.primary : AppTheme.textMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            label: '', // Empty - we handle label in icon widget
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.build_outlined),
            label: 'Tools',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.feedback_outlined),
            label: 'Feedback',
          ),
        ],
      ),
      extendBody: true,
    );
  }

  Widget _buildNotificationBell() {
    final userId = FirebaseAuth.instance.currentUser?.email;
    if (userId == null) {
      return Icon(Icons.notifications_outlined,
          color: AppTheme.textWhite, size: 28);
    }

    final notifRepo = ref.read(notificationRepositoryProvider);

    return StreamBuilder<int>(
      stream: notifRepo.streamUnreadCount(userId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                unreadCount > 0
                    ? Icons.notifications
                    : Icons.notifications_outlined,
                color: AppTheme.textWhite,
                size: 28,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileStream() {
    final userRepo = ref.read(userRepositoryProvider);

    return StreamBuilder<UserModel?>(
      stream: userRepo.streamById(currentUser.email!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading profile: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Profile not found'));
        }
        return ProfilePage(user: snapshot.data!);
      },
    );
  }

  // Navigation methods
  void goToAboutPage() => Navigator.popAndPushNamed(context, '/about');
  void goAboutUsPage() => Navigator.popAndPushNamed(context, '/about-us');
  void goCreditsPage() => Navigator.popAndPushNamed(context, '/credits');

  void _goToForageLocationsPage() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForageLocations(
          userId: currentUser.email!,
          userName: currentUser.email!.split("@")[0],
          userLocations: true,
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/auth');
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content:
            const Text('This action will permanently delete your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _deleteAccount(),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      await FirebaseAuth.instance.currentUser?.delete();
      Navigator.pushReplacementNamed(context, '/auth');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }
}
