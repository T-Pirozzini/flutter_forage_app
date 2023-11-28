import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'forage_locations_page.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;

  // navigate to forage locations page
  void goToForageLocationsPage(String friendId, String friendName) {
    // pop menu drawer
    Navigator.pop(context);
    // go to new page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForageLocations(
          userId: friendId,
          userName: friendName,
        ),
      ),
    );
  }

  // Deleting Friends
  bool _isDeleting = false;
  Future<bool> _deleteFriendConfirmation() async {
    if (_isDeleting) {
      return false; // Prevent showing the dialog if it's already open
    }
    _isDeleting = true;
    bool shouldDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Friend'),
          content: const Text('Are you sure you want to delete this friend?'),
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

  Future<DocumentSnapshot> fetchFriendData(String friendId) async {
    return await FirebaseFirestore.instance
        .collection('Users')
        .doc(friendId)
        .get();
  }

  String formatTimeAgo(Timestamp timestamp) {
    // Convert Firestore Timestamp to DateTime
    final friendTimestamp = timestamp.toDate();
    final currentDate = DateTime.now();

    // Calculate the difference
    final difference = currentDate.difference(friendTimestamp);

    // Format the difference
    if (difference.inDays >= 1) {
      return '${difference.inDays} days';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} hours';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} minutes';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUsername = FirebaseAuth.instance.currentUser!.email!;

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text(
          'FRIENDS',
          style: TextStyle(letterSpacing: 2.5),
        ),
        titleTextStyle:
            GoogleFonts.philosopher(fontSize: 24, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade400,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 60.0),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(currentUser.email)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Your Friends ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '(${currentUsername.split('@')[0]})',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ],
                        ),
                        Text('Tap on Friend to view their Forage Locations.'),
                        Text('Swipe left to remove Friend.'),
                        Expanded(
                          child: ListView.builder(
                            itemCount: userData['friends'].length,
                            itemBuilder: (context, index) {
                              final friendObject = userData['friends'][index];
                              if (friendObject != null &&
                                  friendObject is Map<String, dynamic>) {
                                final friendId = friendObject['email'];
                                return FutureBuilder<DocumentSnapshot>(
                                  future: fetchFriendData(friendId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    if (snapshot.hasError) {
                                      // Handle error appropriately
                                      return const Text("Error loading data");
                                    }
                                    if (!snapshot.hasData) {
                                      return const Text("No data available");
                                    }
                                    final friendData = snapshot.data!.data()
                                        as Map<String, dynamic>;
                                    final friendUsername =
                                        friendData['username'];
                                    final friendEmail = friendData['email'];
                                    final friendBio = friendData['bio'];
                                    final friendTimestamp = userData['friends']
                                        .firstWhere((element) {
                                      return element['email'] == friendEmail;
                                    },
                                            orElse: () => {
                                                  'timestamp': Timestamp.now()
                                                })['timestamp'];

                                    String friendSince;
                                    if (friendTimestamp is Timestamp) {
                                      friendSince =
                                          formatTimeAgo(friendTimestamp);
                                    } else {
                                      friendSince = 'Unknown';
                                    }

                                    return GestureDetector(
                                      onTap: () => goToForageLocationsPage(
                                          friendId, friendUsername),
                                      child: Dismissible(
                                        key: UniqueKey(),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          color: Colors.red.shade400,
                                          alignment: Alignment.centerRight,
                                          padding:
                                              const EdgeInsets.only(right: 16),
                                          child: const Icon(Icons.delete,
                                              color: Colors.white),
                                        ),
                                        confirmDismiss: (direction) async {
                                          bool shouldDelete =
                                              await _deleteFriendConfirmation();
                                          if (shouldDelete) {
                                            // Delete the friend from the user's data
                                            FirebaseFirestore.instance
                                                .collection('Users')
                                                .doc(currentUser.email)
                                                .update({
                                              'friends': FieldValue.arrayRemove(
                                                  [friendObject]),
                                            });
                                            // Delete the user from the friend's data
                                            FirebaseFirestore.instance
                                                .collection('Users')
                                                .doc(friendId)
                                                .update({
                                              'friends': FieldValue.arrayRemove(
                                                  [friendObject]),
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text('Friend deleted'),
                                              ),
                                            );
                                          }
                                          return null;
                                        },
                                        child: Card(
                                          child: ListTile(
                                            title: Row(
                                              children: [
                                                const Icon(Icons
                                                    .account_circle_outlined),
                                                SizedBox(width: 5),
                                                Text(
                                                    '$friendUsername ($friendSince)'),
                                              ],
                                            ),
                                            subtitle: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.group_outlined,
                                                      color: Colors.deepOrange,
                                                    ),
                                                    Text(
                                                      "Friends: ${friendData['friends'].length}",
                                                      style: const TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .info_outline_rounded,
                                                      color: Colors.deepOrange,
                                                    ),
                                                    Text('$friendBio'),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            trailing: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.pin_drop_outlined,
                                                      color: Colors.deepOrange,
                                                    ),
                                                    Text(
                                                      '10 Locations',
                                                      style: const TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 2),
                                                const Icon(Icons.double_arrow),
                                              ],
                                            ),
                                            iconColor:
                                                Colors.deepOrange.shade400,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        // Expanded(
                        //   child: ListView.builder(
                        //     itemCount: userData['friends'].length,
                        //     itemBuilder: (context, index) {
                        //       final friendObject = userData['friends'][index];
                        //       if (friendObject != null &&
                        //           friendObject is Map<String, dynamic>) {
                        //         final friendId = friendObject['email'];
                        //         return FutureBuilder<DocumentSnapshot>(
                        //           future: FirebaseFirestore.instance
                        //               .collection('Users')
                        //               .doc(friendId)
                        //               .get(),
                        //           builder: (context, snapshot) {
                        //             if (snapshot.hasData) {
                        //               final friendData = snapshot.data!.data();
                        //               if (friendData != null &&
                        //                   friendData is Map<String, dynamic>) {
                        //                 final friendEmail = friendData['email'];
                        //                 final friendUsername =
                        //                     friendData['username'];
                        //                 final friendProfilePic =
                        //                     friendData['profilePic'];
                        //                 final friendTotal =
                        //                     friendData['friends'].length;
                        //                 final friendObject = {
                        //                   'email': friendEmail,
                        //                   'username': friendUsername,
                        //                   'profilePic': friendProfilePic,
                        //                   'friends': friendTotal,
                        //                 };

                        //                 return GestureDetector(
                        //                   onTap: () => goToForageLocationsPage(
                        //                       friendId, friendUsername),
                        //                   child: Dismissible(
                        //                     key: UniqueKey(),
                        //                     direction:
                        //                         DismissDirection.endToStart,
                        //                     background: Container(
                        //                       color: Colors.red.shade400,
                        //                       alignment: Alignment.centerRight,
                        //                       padding: const EdgeInsets.only(
                        //                           right: 16),
                        //                       child: const Icon(Icons.delete,
                        //                           color: Colors.white),
                        //                     ),
                        //                     confirmDismiss: (direction) async {
                        //                       bool shouldDelete =
                        //                           await _deleteFriendConfirmation();
                        //                       if (shouldDelete) {
                        //                         // Delete the friend from the user's data
                        //                         FirebaseFirestore.instance
                        //                             .collection('Users')
                        //                             .doc(currentUser.email)
                        //                             .update({
                        //                           'friends':
                        //                               FieldValue.arrayRemove(
                        //                                   [friendObject]),
                        //                         });
                        //                         // Delete the user from the friend's data
                        //                         FirebaseFirestore.instance
                        //                             .collection('Users')
                        //                             .doc(friendId)
                        //                             .update({
                        //                           'friends':
                        //                               FieldValue.arrayRemove(
                        //                                   [friendObject]),
                        //                         });
                        //                         ScaffoldMessenger.of(context)
                        //                             .showSnackBar(
                        //                           const SnackBar(
                        //                             content:
                        //                                 Text('Friend deleted'),
                        //                           ),
                        //                         );
                        //                       }
                        //                       return null;
                        //                     },
                        //                     child: Card(
                        //                       child: ListTile(
                        //                         title: Text(friendUsername),
                        //                         subtitle: Text(friendEmail),
                        //                         trailing: const Icon(
                        //                             Icons.double_arrow),
                        //                         iconColor:
                        //                             Colors.deepOrange.shade400,
                        //                       ),
                        //                     ),
                        //                   ),
                        //                 );
                        //               }
                        //             }
                        //             return const SizedBox();
                        //           },
                        //         );
                        //       }
                        //       return null;
                        //     },
                        //   ),
                        // ),
                      ],
                    );
                  } else {
                    return Center(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
