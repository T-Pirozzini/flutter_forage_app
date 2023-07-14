import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/pages/friend_request_page.dart';
import 'package:flutter_forager_app/pages/friends_page.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  // all users
  final usersCollection = FirebaseFirestore.instance.collection('Users');

  // profile UI
  final double coverHeight = 200.0;
  final double profileHeight = 100.0;

  // edit text field - generic
  Future<void> editField(String field) async {
    String newValue = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Edit $field",
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter new $field",
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          onChanged: (value) {
            newValue = value;
          },
        ),
        actions: [
          // cancel button
          TextButton(
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),

          // save button
          TextButton(
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.of(context).pop(newValue),
          ),
        ],
      ),
    );
    // update in Firestore
    if (newValue.trim().isNotEmpty) {
      // only update if there is something in the textfield
      await usersCollection.doc(currentUser.email).update(
        {
          field: newValue,
        },
      );
    }
  }

  // background image options
  List<String> imageBackgroundOptions = [
    'backgroundProfileImage1.jpg',
    'backgroundProfileImage2.jpg',
    'backgroundProfileImage3.jpg',
    'backgroundProfileImage4.jpg',
    'backgroundProfileImage5.jpg',
    'backgroundProfileImage6.jpg',
  ];

  // initial background image
  String selectedBackgroundOption = 'backgroundProfileImage1.jpg';

  // edit profile background image
  Future<void> editProfileBackground(String field) async {
    String newValue = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Edit $field",
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          height: 420,
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: imageBackgroundOptions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final option = imageBackgroundOptions[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedBackgroundOption = option;
                    newValue = option;
                  });
                },
                child: Container(
                  height: 20,
                  width: 20,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('lib/assets/images/$option'),
                      fit: BoxFit.cover,
                    ),
                    border: selectedBackgroundOption == option
                        ? Border.all(color: Colors.deepOrange, width: 4)
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          // cancel button
          TextButton(
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),

          // save button
          TextButton(
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.of(context).pop(newValue),
          ),
        ],
      ),
    );

    // update in Firestore
    if (newValue.trim().isNotEmpty) {
      // only update if there is something in the textfield
      await usersCollection.doc(currentUser.email).update(
        {
          field: newValue,
        },
      );
    }
  }

  // Profile image options
  List<String> imageProfileOptions = [
    'profileImage1.jpg',
    'profileImage2.jpg',
    'profileImage3.jpg',
    'profileImage4.jpg',
    'profileImage5.jpg',
    'profileImage6.jpg',
  ];

  // initial profile image
  String selectedProfileOption = 'profileImage1.jpg';

  // edit profile image
  Future<void> editProfileImage(String field) async {
    String newValue = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Edit $field",
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          height: 420,
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: imageProfileOptions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final option = imageProfileOptions[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    Navigator.of(context).pop(newValue);
                    selectedProfileOption = option;
                    newValue = option;
                  });
                },
                child: Container(
                  height: 20,
                  width: 20,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('lib/assets/images/$option'),
                      fit: BoxFit.cover,
                    ),
                    border: selectedProfileOption == option
                        ? Border.all(color: Colors.deepOrange, width: 4)
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          // cancel button
          TextButton(
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),

          // save button
          TextButton(
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.of(context).pop(newValue),
          ),
        ],
      ),
    );

    // update in Firestore
    if (newValue.trim().isNotEmpty) {
      // only update if there is something in the textfield
      await usersCollection.doc(currentUser.email).update(
        {
          field: newValue,
        },
      );
    }
  }

  // back to main page
  void goHome() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange.shade100,
      appBar: AppBar(
        title: const Text('PROFILE', style: TextStyle(letterSpacing: 2.5)),
        titleTextStyle:
            GoogleFonts.philosopher(fontSize: 24, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade300,
      ),
      body: Column(
        children: [
          buildTop(),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(currentUser.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  selectedBackgroundOption =
                      userData['profileBackground'] ?? selectedBackgroundOption;
                  selectedProfileOption =
                      userData['profilePic'] ?? selectedProfileOption;
                  return Center(
                    child: ListView(
                      padding: const EdgeInsets.only(
                        top: 20,
                      ),
                      children: [
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 40.0),
                                  child: Text(
                                    userData['username'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => editField('username'),
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              userData['email'],
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Container(
                          height: 80,
                          margin: const EdgeInsets.all(8.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  userData['bio'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => editField('bio'),
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('lib/assets/images/friends.png',
                                      width: 40, color: Colors.deepOrange),
                                  const SizedBox(width: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('You have '),
                                      Text(
                                        userData['friends'].length.toString(),
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const Text(' friend(s).'),
                                      IconButton(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const FriendsPage(),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(
                              thickness: 2,
                              indent: 15,
                              endIndent: 15,
                              color: Colors.white,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('You have '),
                                Text(
                                  userData['friendRequests'].length.toString(),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text(' pending friend requests.'),
                                IconButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const FriendRequestPage(),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(
                              thickness: 2,
                              indent: 15,
                              endIndent: 15,
                              color: Colors.white,
                            ),
                            if (userData['sentFriendRequests'].length < 1)
                              const Text(
                                  'You haven\'t sent any friend requests.')
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('You have sent '),
                                  Text(
                                    userData['sentFriendRequests']
                                        .length
                                        .toString(),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Text(' friend requests.'),
                                  IconButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const FriendRequestPage(),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ],
                              ),
                            const Divider(
                              thickness: 2,
                              indent: 15,
                              endIndent: 15,
                              color: Colors.white,
                            ),
                            if (userData['posts'].length < 1)
                              const Text('You haven\'t posted anything yet.')
                            else
                              Text(userData['posts'].toString()),
                            const Divider(
                              thickness: 2,
                              indent: 15,
                              endIndent: 15,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 15),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                onTap: goHome,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset('lib/assets/images/forage.png',
                                        width: 40, color: Colors.deepOrange),
                                    const Text(
                                      'Let\'s forage!',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

  Widget buildTop() {
    final top = coverHeight - profileHeight / 2 - 25;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          child: buildCoverImage(),
        ),
        Positioned(
          top: top,
          child: buildProfileImage(),
        ),
        Positioned(
          top: top,
          right: 10,
          child: IconButton(
            onPressed: () => editProfileBackground('profileBackground'),
            icon: const Icon(
              Icons.edit,
              color: Colors.deepOrange,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildCoverImage() => ClipPath(
        clipper: _BottomCurveClipper(),
        child: Container(
          color: Colors.white,
          child: Image.asset(
            'lib/assets/images/$selectedBackgroundOption',
            width: double.infinity,
            height: coverHeight,
            fit: BoxFit.cover,
          ),
        ),
      );

  Widget buildProfileImage() => Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0), // Add padding around the circle
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 4.0,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'lib/assets/images/$selectedProfileOption',
                width: profileHeight,
                height: profileHeight,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 25,
            right: 15,
            child: IconButton(
              onPressed: () => editProfileImage('profilePic'),
              icon: const Icon(
                Icons.edit,
                color: Colors.deepOrange,
              ),
            ),
          ),
        ],
      );
}

// curve for the background image
class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
        size.width / 2, size.height * 1.3, size.width, size.height - 80);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
