import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({
    super.key,
  });

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  String? username;

  int likeCount = 0;
  bool isFavorite = false;

  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
      if (isFavorite) {
        likeCount++;
      } else {
        likeCount--;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchUsername();
  }

  Future<void> fetchUsername() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.email)
        .get();

    if (userDoc.exists) {
      setState(() {
        username = userDoc.data()?['username'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('COMMUNITY'),
        titleTextStyle: GoogleFonts.philosopher(
            fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2.5),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade400,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Posts')
                  .orderBy('postTimestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final posts = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final imageUrl = post['imageUrl'];
                      // final likeCount = post['likeCount'] ?? 0;
                      final saveCount = post['saveCount'] ?? 0;
                      // final commentCount = post['commentCount'] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            side: BorderSide(
                              color: Colors
                                  .deepOrange.shade200, // Set the border color
                              width: 1.0, // Set the border thickness
                            ), // Set the border radius
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12.0),
                                  topRight: Radius.circular(12.0),
                                ),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                ),
                              ),
                              ListTile(
                                title: Row(
                                  children: [
                                    Image.asset(
                                        "lib/assets/images/${post['type'].toLowerCase()}.png",
                                        width: 20,
                                        height: 20),
                                    const SizedBox(width: 5),
                                    Text(
                                      post['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5),
                                    Text(post['description']),
                                  ],
                                ),
                                // Handle like button tap
                                // Increment likeCount and update Firestore
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.favorite,
                                        color: isFavorite ? Colors.red : null,
                                      ),
                                      onPressed: toggleFavorite,
                                    ),
                                    Text('$likeCount'),
                                    IconButton(
                                      icon: const Icon(Icons.bookmark_add),
                                      onPressed: () {
                                        // Handle like button tap
                                        // Increment likeCount and update Firestore
                                      },
                                    ),
                                    Text('$saveCount'),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 16),
                                        const SizedBox(width: 5),
                                        Text(post['user'].split('@')[0]),
                                      ],
                                    ),
                                    FutureBuilder<String?>(
                                      future: getAreaFromCoordinates(
                                          post['latitude'], post['longitude']),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Text(snapshot.data ?? '');
                                        } else if (snapshot.hasError) {
                                          return Text(
                                              'Error: ${snapshot.error}');
                                        } else {
                                          return const SizedBox.shrink();
                                        }
                                      },
                                    ),
                                    Text(
                                      post['postTimestamp'].split(' ')[0],
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.deepOrange.shade400),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
          ),
        ],
      ),
    );
  }
}

Future<String?> getAreaFromCoordinates(
    double latitude, double longitude) async {
  try {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(latitude, longitude);

    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks[0];

      String? area = placemark.locality ??
          placemark.subLocality ??
          placemark.administrativeArea;

      return area;
    }
  } catch (e) {
    print('Error: $e');
  }

  return null;
}
