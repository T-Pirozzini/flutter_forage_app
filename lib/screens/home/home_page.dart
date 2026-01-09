import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/services/ad_mob_service.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/screens/profile/profile_page.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_locations_page.dart';
import 'package:flutter_forager_app/screens/recipes/recipes_page.dart';
import 'package:flutter_forager_app/screens/progress/progress_page.dart';
import 'package:flutter_forager_app/shared/gamification/gamification_helper.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../drawer/drawer.dart';
import '../community/community_page.dart';
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

  @override
  void initState() {
    super.initState();
    currentIndex = widget.currentIndex;
    AdMobService.loadInterstitialAd();

    // Update daily streak
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GamificationHelper.updateStreak(
        context: context,
        ref: ref,
        userId: currentUser.email!,
      );
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
    // Option A Navigation: Explore | Community | Profile | Recipes | Progress
    final pages = [
      MapPage(), // Explore tab - Map is the primary action
      const CommunityPage(), // Community tab
      _buildProfileStream(), // Profile tab
      RecipesPage(), // Recipes tab
      const ProgressPage(), // Progress tab - Achievements + Leaderboard
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: AppTheme.primary,
        title: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Image.asset(
            'assets/images/forager_logo_2.png',
          ),
        ),
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
          Expanded(child: pages[currentIndex]),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Progress',
          ),
        ],
      ),
      extendBody: true,
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
