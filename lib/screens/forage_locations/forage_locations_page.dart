import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_location_info_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ForageLocations extends StatefulWidget {
  final String userId;
  final String userName;
  final bool userLocations;

  const ForageLocations(
      {Key? key,
      required this.userId,
      required this.userName,
      required this.userLocations})
      : super(key: key);

  @override
  State<ForageLocations> createState() => _ForageLocationsState();
}

class _ForageLocationsState extends State<ForageLocations> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

  bool _isDeleting = false;

  Future<bool> _deleteConfirmation() async {
    if (_isDeleting) {
      return false; // Prevent showing the dialog if it's already open
    }
    _isDeleting = true;
    bool shouldDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Forage Location'),
          content: const Text(
              'Are you sure you want to delete this forage location?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // No, don't delete
                _isDeleting =
                    false; // Reset the flag when the dialog is dismissed
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Yes, delete
                _isDeleting =
                    false; // Reset the flag when the dialog is dismissed
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return shouldDelete;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
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
      ),
      body: Stack(
        children: [
          // Center the logo in the background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity:
                  0.4, // Adjust the opacity to make the logo less intrusive
              child: Image.asset(
                'assets/images/forager_appbar_logo.png',
                width: double.infinity, // Adjust the width as needed
                height: 200, // Adjust the height as needed
              ),
            ),
          ),
          // List of tiles on top of the logo
          StreamBuilder<QuerySnapshot>(
            stream: widget.userLocations
                ? FirebaseFirestore.instance
                    .collection('Users')
                    .doc(widget.userId)
                    .collection('Markers')
                    .where('markerOwner', isEqualTo: widget.userId)
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('Users')
                    .doc(widget.userId)
                    .collection('Markers')
                    .where('markerOwner', isNotEqualTo: widget.userId)
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
                      confirmDismiss: (direction) async {
                        bool shouldDelete = await _deleteConfirmation();
                        if (shouldDelete) {
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
                          return true;
                        }
                        return false;
                      },
                      child: GestureDetector(
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
                          margin: const EdgeInsets.all(
                            4.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            side: BorderSide(
                              color: Colors.deepOrange.shade200,
                              width: 2.0,
                            ),
                          ),
                          elevation: 1.5,
                          child: ListTile(
                            dense: true,
                            title: Text(markerData['name']),
                            leading: ImageIcon(
                              AssetImage(
                                'lib/assets/images/${markerData['type'].toLowerCase()}_marker.png',
                              ),
                              size: 38,
                            ),
                            subtitle: Text(markerData['description']),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
        ],
      ),
    );
  }
}
