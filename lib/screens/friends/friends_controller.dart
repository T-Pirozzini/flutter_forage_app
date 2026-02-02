import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/screens/friends/friend_request_page.dart';
import 'package:flutter_forager_app/screens/friends/friends_page.dart';
import 'package:flutter_forager_app/screens/friends/tabs/activity_tab.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

class FriendsController extends StatefulWidget {
  final int currentTab;
  const FriendsController({super.key, required this.currentTab});

  @override
  State<FriendsController> createState() => _FriendsControllerState();
}

class _FriendsControllerState extends State<FriendsController> {
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: widget.currentTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Friends',
            style: AppTheme.heading(size: 18, color: AppTheme.textWhite),
          ),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: AppTheme.secondary,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: AppTheme.caption(size: 12, weight: FontWeight.w600),
            unselectedLabelStyle: AppTheme.caption(size: 12),
            tabs: const [
              Tab(text: 'Friends', icon: Icon(Icons.people, size: 20)),
              Tab(text: 'Requests', icon: Icon(Icons.person_add, size: 20)),
              Tab(text: 'Activity', icon: Icon(Icons.dynamic_feed, size: 20)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const FriendsPage(),
            const FriendRequestPage(),
            ActivityTab(userId: currentUser.email!),
          ],
        ),
      ),
    );
  }
}
