import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_location_info_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'home_page.dart';

class ForageLocations extends StatefulWidget {
  final String userId;
  final String userName;

  const ForageLocations(
      {Key? key, required this.userId, required this.userName})
      : super(key: key);

  @override
  State<ForageLocations> createState() => _ForageLocationsState();
}

class _ForageLocationsState extends State<ForageLocations> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('LOCATIONS', style: TextStyle(letterSpacing: 2.5)),
            Text(
              'User: ${widget.userName}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
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
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No locations found'),
                  );
                }

                if (snapshot.hasData) {
                  final forageLocations = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: forageLocations.length,
                    itemBuilder: (context, index) {
                      final markerData =
                          forageLocations[index].data() as Map<String, dynamic>;
                      final timestamp = markerData['timestamp'] as Timestamp;
                      final dateTime = timestamp.toDate();
                      final formattedDate = dateFormat.format(dateTime);

                      return Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red.shade400,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          // Delete the marker data from Firestore
                          FirebaseFirestore.instance
                              .collection('Users')
                              .doc(widget.userId)
                              .collection('Markers')
                              .doc(forageLocations[index].id)
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Forage location deleted'),
                            ),
                          );
                        },
                        child: Column(
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
                                      imageUrl: markerData['image'],
                                      markerOwner: markerData['markerOwner'],
                                    );
                                  },
                                );
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  side: BorderSide(
                                    color: Colors.deepOrange
                                        .shade200, // Set the border color
                                    width: 1.0, // Set the border thickness
                                  ), // Set the border radius
                                ),
                                elevation: 1.5,
                                child: ListTile(
                                  title: Text(markerData['name']),
                                  leading: ImageIcon(
                                    AssetImage(
                                      'lib/assets/images/${markerData['type'].toLowerCase()}_marker.png',
                                    ),
                                    size: 38,
                                  ),
                                  subtitle: Text(markerData['description']),
                                  trailing: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Latitude: ${markerData['location']['latitude'].toStringAsFixed(2)}',
                                      ),
                                      Text(
                                        'Longitude: ${markerData['location']['longitude'].toStringAsFixed(2)}',
                                      ),
                                      Text('Time: $formattedDate'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
