import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_locations_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    return Column(
      children: [
        const Text('This is the Dashboard Page'),
        ElevatedButton(
          onPressed: () {
            // Navigate to the ForageLocations page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ForageLocations(
                  userId: currentUser.email!,
                  userName: currentUser.email!.split("@")[0],
                ),
              ),
            );
          },
          child: const Text('View Your Forage Locations'),
        ),
        Text('Output how many new users have joined since last login'),
        Text(
            'Display any pending friend requests - redirect to the friends page'),
        Text('have a button to go to yoour profile page'),
        Text('display an ad when navigating to locations page '),
        Text(
            ' have a button to go exploring - maybe this page should be the profile page?'),
      ],
    );
  }
}
