import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/screens/my_foraging/tabs/my_locations_tab.dart';
import 'package:flutter_forager_app/screens/my_foraging/tabs/bookmarked_tab.dart';
import 'package:flutter_forager_app/screens/my_foraging/tabs/collections_tab.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Unified screen for managing all location-related data:
/// - My Locations: User's own markers
/// - Bookmarked: Saved locations from others
/// - Collections: Organized folders + subscriptions
class MyForagingPage extends ConsumerStatefulWidget {
  const MyForagingPage({Key? key}) : super(key: key);

  @override
  ConsumerState<MyForagingPage> createState() => _MyForagingPageState();
}

class _MyForagingPageState extends ConsumerState<MyForagingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser?.email == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Foraging'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please sign in to view your foraging data'),
        ),
      );
    }

    final userId = currentUser!.email!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Foraging',
          style: AppTheme.heading(size: 18, color: AppTheme.textWhite),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.secondary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: AppTheme.caption(size: 12, weight: FontWeight.w600),
          unselectedLabelStyle: AppTheme.caption(size: 12),
          tabs: const [
            Tab(
              text: 'My Locations',
              icon: Icon(Icons.location_on, size: 20),
            ),
            Tab(
              text: 'Bookmarked',
              icon: Icon(Icons.bookmark, size: 20),
            ),
            Tab(
              text: 'Collections',
              icon: Icon(Icons.folder, size: 20),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MyLocationsTab(userId: userId),
          BookmarkedTab(userId: userId),
          CollectionsTab(userId: userId),
        ],
      ),
    );
  }
}
