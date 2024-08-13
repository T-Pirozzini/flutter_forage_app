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

  void saveMarkerInfo(
    String markerName,
    String markerDescription,
    String markerType,
    String? markerImageUrl,
    double markerLatitude,
    double markerLongitude,
    Timestamp timestamp,
    String markerOwner,
  ) async {
    final userMarkersRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.email)
        .collection('Markers');
    final markerQuerySnapshot = await userMarkersRef.get();
    final markerCount = markerQuerySnapshot.size;

    if (markerCount <= 9) {
      if (markerImageUrl != null) {
        FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.email)
            .collection('Markers')
            .add({
          'name': markerName,
          'description': markerDescription,
          'type': markerType,
          'image': markerImageUrl,
          'location': {
            'latitude': markerLatitude,
            'longitude': markerLongitude,
          },
          'timestamp': timestamp,
          'markerOwner': markerOwner,
        });
      } else {
        FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.email)
            .collection('Markers')
            .add({
          'name': markerName,
          'description': markerDescription,
          'type': markerType,
          'image':
              'https://st2.depositphotos.com/2586633/46477/v/600/depositphotos_464771766-stock-illustration-no-photo-or-blank-image.jpg',
          'location': {
            'latitude': markerLatitude,
            'longitude': markerLongitude,
          },
          'timestamp': timestamp,
          'markerOwner': markerOwner,
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marker limit reached. You cannot save more markers.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void removeMarkerInfo(
      String markerName,
      String markerDescription,
      String markerType,
      String? markerImageUrl,
      double markerLatitude,
      double markerLongitude,
      Timestamp timestamp,
      String markerOwner) async {
    final userMarkersRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.email)
        .collection('Markers');

    await userMarkersRef
        .where('name', isEqualTo: markerName)
        .where('description', isEqualTo: markerDescription)
        .where('type', isEqualTo: markerType)
        .where('image', isEqualTo: markerImageUrl)
        .where('location.latitude', isEqualTo: markerLatitude)
        .where('location.longitude', isEqualTo: markerLongitude)
        .where('timestamp', isEqualTo: timestamp)
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        doc.reference.delete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,      
      appBar: AppBar(
        title: const Text('COMMUNITY'),
        titleTextStyle: GoogleFonts.philosopher(
            fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2.5),
        centerTitle: true,
        backgroundColor: Colors.grey.shade600,
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            width: double.infinity,
            color: Colors.grey.shade300,
            child: Column(
              children: [
                Text("Care to share your secret spots with us?"),
                Text('Like and/or bookmark forage locations and go explore!'),
              ],
            ),
          ),
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
                      final likeCount = post['likeCount'] ?? 0;
                      final bookmarkCount = post['bookmarkCount'] ?? 0;

                      // final commentCount = post['commentCount'] ?? 0;

                      final CollectionReference postsCollection =
                          FirebaseFirestore.instance.collection('Posts');
                      bool isFavorite =
                          (post['likedBy'] ?? []).contains(currentUser.email);

                      void toggleFavorite() async {
                        final currentUserEmail = currentUser.email;
                        final List<dynamic>? likedBy =
                            post['likedBy'] as List<dynamic>?;

                        if (likedBy != null &&
                            likedBy.contains(currentUserEmail)) {
                          // User has already liked the post, remove their like
                          isFavorite = false;
                          final int newLikeCount = likeCount - 1;

                          final documentSnapshot =
                              await postsCollection.doc(post.id).get();
                          if (documentSnapshot.exists) {
                            postsCollection.doc(post.id).update({
                              'likeCount': newLikeCount,
                              'likedBy':
                                  FieldValue.arrayRemove([currentUserEmail]),
                            });
                          }
                        } else {
                          // User has not liked the post, allow them to like it
                          isFavorite = true;
                          final int newLikeCount = likeCount + 1;

                          final documentSnapshot =
                              await postsCollection.doc(post.id).get();
                          if (documentSnapshot.exists) {
                            postsCollection.doc(post.id).update({
                              'likeCount': newLikeCount,
                              'likedBy':
                                  FieldValue.arrayUnion([currentUserEmail]),
                            });
                          }
                        }

                        setState(() {});
                      }

                      bool isBookmarked = (post['bookmarkedBy'] ?? [])
                          .contains(currentUser.email);

                      void toggleBookmark() async {
                        final currentUserEmail = currentUser.email;
                        final List<dynamic>? bookmarkedBy =
                            post['bookmarkedBy'] as List<dynamic>?;

                        if (bookmarkedBy != null &&
                            bookmarkedBy.contains(currentUserEmail)) {
                          // User has already liked the post, remove their like
                          isBookmarked = false;
                          final int newBookmarkCount = bookmarkCount - 1;

                          final documentSnapshot =
                              await postsCollection.doc(post.id).get();
                          if (documentSnapshot.exists) {
                            postsCollection.doc(post.id).update({
                              'bookmarkCount': newBookmarkCount,
                              'bookmarkedBy':
                                  FieldValue.arrayRemove([currentUserEmail]),
                            });
                            removeMarkerInfo(
                              post['name'],
                              post['description'],
                              post['type'],
                              post['imageUrl'],
                              post['latitude'],
                              post['longitude'],
                              Timestamp.fromDate(
                                  DateTime.parse(post['postTimestamp'])),
                              post['user'],
                            );
                          }
                        } else {
                          // User has not liked the post, allow them to like it
                          isBookmarked = true;
                          final int newBookmarkCount = bookmarkCount + 1;

                          final documentSnapshot =
                              await postsCollection.doc(post.id).get();
                          if (documentSnapshot.exists) {
                            postsCollection.doc(post.id).update({
                              'bookmarkCount': newBookmarkCount,
                              'bookmarkedBy':
                                  FieldValue.arrayUnion([currentUserEmail]),
                            });
                            saveMarkerInfo(
                              post['name'],
                              post['description'],
                              post['type'],
                              post['imageUrl'],
                              post['latitude'],
                              post['longitude'],
                              Timestamp.fromDate(
                                  DateTime.parse(post['postTimestamp'])),
                              post['user'],
                            );
                          }
                        }

                        setState(() {});
                      }

                      void deletePost() async {
                        final currentUserEmail = currentUser.email;
                        if (post['user'] == currentUserEmail) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirmation'),
                                content: const Text(
                                    'Are you sure you want to delete this post?'),
                                actions: [
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('Delete'),
                                    onPressed: () async {
                                      await postsCollection
                                          .doc(post.id)
                                          .delete();
                                      Navigator.of(context)
                                          .pop(); // Close the confirmation dialog
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Post deleted.'),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('You can only delete your own posts.'),
                            ),
                          );
                        }
                      }

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
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.favorite,
                                      color: isFavorite ? Colors.red : null,
                                    ),
                                    onPressed: toggleFavorite,
                                  ),
                                  Text('$likeCount',
                                      style: const TextStyle(fontSize: 18)),
                                  IconButton(
                                    icon: const Icon(Icons.bookmark_add),
                                    color: isBookmarked ? Colors.blue : null,
                                    onPressed: toggleBookmark,
                                  ),
                                  Text('$bookmarkCount',
                                      style: const TextStyle(fontSize: 18)),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: deletePost,
                                  ),
                                ],
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
