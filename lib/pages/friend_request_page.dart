import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FriendRequestPage extends StatefulWidget {
  const FriendRequestPage({super.key});

  @override
  State<FriendRequestPage> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends State<FriendRequestPage> {
  List<String> pendingFriendRequests = []; // List of pending friend requests
  List<String> sentFriendRequests = []; // List of sent friend requests

  @override
  void initState() {
    super.initState();
    // Initialize pendingFriendRequests and sentFriendRequests lists
    pendingFriendRequests = ['friend1', 'friend2'];
    sentFriendRequests = ['friend3', 'friend4'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FRIEND REQUESTS'),
        titleTextStyle:
            GoogleFonts.philosopher(fontSize: 24, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade300,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Pending Friend Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: pendingFriendRequests.length,
              itemBuilder: (context, index) {
                final friendRequest = pendingFriendRequests[index];
                return ListTile(
                  title: Text(friendRequest),
                  // Add any additional widgets or functionality for pending friend requests
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Sent Friend Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sentFriendRequests.length,
              itemBuilder: (context, index) {
                final friendRequest = sentFriendRequests[index];
                return ListTile(
                  title: Text(friendRequest),
                  // Add any additional widgets or functionality for sent friend requests
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
