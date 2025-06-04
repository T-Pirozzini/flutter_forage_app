import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/components/ad_mob_service.dart';
import 'package:flutter_forager_app/models/user.dart';
import 'package:flutter_forager_app/screens/profile/profile_page.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_locations_page.dart';
import 'package:flutter_forager_app/screens/recipes/recipes_page.dart';
import 'package:flutter_forager_app/theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../drawer/drawer.dart';
import '../community/community_page.dart';
import '../forage/map_page.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class HomePage extends StatefulWidget {
  final double lat;
  final double lng;
  final int currentIndex;
  final bool followUser;

  const HomePage({
    super.key,
    required this.lat,
    required this.lng,
    required this.followUser,
    required this.currentIndex,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  late bool followUser;
  int currentIndex = 0;
  double lat = 0;
  double lng = 0;
  BannerAd? _banner;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    followUser = widget.followUser;
    lat = widget.lat;
    lng = widget.lng;
    currentIndex = widget.currentIndex;
    _createBannerAd();
    AdMobService.loadInterstitialAd();
  }

  void _createBannerAd() {
    _banner = BannerAd(
      adUnitId: AdMobService.bannerAdUnitId!,
      size: AdSize.fullBanner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) => setState(() => _isBannerAdLoaded = true),
        onAdFailedToLoad: (Ad ad, LoadAdError error) => ad.dispose(),
      ),
      request: const AdRequest(),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildProfileStream(),
      RecipesPage(),
      const CommunityPage(),
    ];

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Image.asset(
            'assets/images/forager_appbar_logo.png',
            height: kToolbarHeight,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: AppColors.textColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FontAwesomeIcons.compass,
                        color: AppColors.textColor, size: 32),
                    const SizedBox(height: 4),
                    Text('Go Forage!',
                        style: TextStyle(color: AppColors.textColor)),
                  ],
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPage(
                      lat: lat,
                      lng: lng,
                      followUser: followUser,
                    ),
                  ),
                ),
              ),
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
                width: double.infinity,
                height: 50,
                child: AdWidget(ad: _banner!),
              ),
            Expanded(child: pages[currentIndex]),
          ],
        ),
        bottomNavigationBar: ConvexAppBar(
          style: TabStyle.reactCircle,
          items: const [
            TabItem(
              icon: Icons.home,
              title: 'Dashboard',
            ),
            TabItem(icon: Icons.menu_book, title: 'Recipes'),
            TabItem(icon: Icons.people, title: 'Community'),
          ],
          initialActiveIndex: currentIndex,
          color: AppColors.textColor,
          backgroundColor: AppColors.primaryAccent,
          activeColor: AppColors.secondaryColor,
          curveSize: 100,
          top: -30,
          onTap: (int i) => setState(() => currentIndex = i),
          curve: Curves.easeInOutQuad,
        ),
        extendBody: true,
      ),
    );
  }

  Widget _buildProfileStream() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.email)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.hasError) {
          return const Center(child: Text('Error loading profile'));
        }
        return ProfilePage(user: UserModel.fromFirestore(snapshot.data!));
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
