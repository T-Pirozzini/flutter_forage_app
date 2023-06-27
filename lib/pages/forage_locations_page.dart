import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/pages/forage_location_info_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'home_page.dart';

class ForageLocations extends StatefulWidget {
  final String userId;
  const ForageLocations({Key? key, required this.userId}) : super(key: key);

  @override
  State<ForageLocations> createState() => _ForageLocationsState();
}

class _ForageLocationsState extends State<ForageLocations> {
  // current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  // Create a DateFormat instance
  final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FORAGE LOCATIONS'),
        titleTextStyle:
            GoogleFonts.philosopher(fontSize: 24, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade400,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(
                  lat: 0,
                  lng: 0,
                  followUser: true,
                  currentIndex: 0,
                ),
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(widget.userId)
                  .collection('Markers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final forageLocations = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: forageLocations.length,
                    itemBuilder: (context, index) {
                      final markerData =
                          forageLocations[index].data() as Map<String, dynamic>;
                      final timestamp = markerData['timestamp'] as Timestamp;

                      // Convert Firestore Timestamp to DateTime
                      final dateTime = timestamp.toDate();

                      // Format the date
                      final formattedDate = dateFormat.format(dateTime);
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return ForageLocationInfo(
                                    name: markerData['name'],
                                    description: markerData['description'],
                                    type: markerData['type'],
                                    lat: markerData['location']['latitude'],
                                    lng: markerData['location']['longitude'],
                                    timestamp: formattedDate,
                                    image: markerData['image'],
                                  );
                                },
                              );
                            },
                            child: ListTile(
                              title: Text(markerData['name']),
                              leading: ImageIcon(
                                AssetImage(
                                    'lib/assets/images/${markerData['type'].toLowerCase()}_marker.png'),
                                size: 38,
                              ),
                              subtitle: Text(markerData['description']),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Latitude: ${markerData['location']['latitude'].toStringAsFixed(2)}'),
                                  Text(
                                      'Longitude: ${markerData['location']['longitude'].toStringAsFixed(2)}'),
                                  Text('Time: $formattedDate'),
                                ],
                              ),
                            ),
                          ),
                          Divider(
                              color: Colors.deepOrange.shade100, thickness: 2),
                        ],
                      );
                    },
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
