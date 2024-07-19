import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/screens/friends/friend_request_page.dart';
import 'package:flutter_forager_app/screens/friends/friends_page.dart';
import 'package:flutter_forager_app/screens/profile/profile_page.dart';

class FriendsController extends StatefulWidget {
  final int currentTab;
  const FriendsController({super.key, required this.currentTab});

  @override
  State<FriendsController> createState() => _TimeSheetControllerState();
}

class _TimeSheetControllerState extends State<FriendsController> {
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.currentTab,
      child: Scaffold(
        backgroundColor: const Color(0xFFDFD3C3),
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Your Friends'),
              Tab(text: 'Requests'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FriendsPage(),
            FriendRequestPage(),
          ],
        ),
      ),
    );
  }
}
