import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/button.dart';
import '../shared/text_field.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailTextController = TextEditingController();
  final TextEditingController passwordTextController = TextEditingController();
  final TextEditingController confirmPasswordTextController =
      TextEditingController();

  void signUp() async {
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    // make sure passwords match
    if (passwordTextController.text != confirmPasswordTextController.text) {
      Navigator.pop(context);
      displayMessage('Passwords do not match');
      return;
    }
    try {
      // create the user
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailTextController.text,
        password: passwordTextController.text,
      );
      // after creating the user, create a new document in firestore called Users
      FirebaseFirestore.instance
          .collection('Users')
          .doc(userCredential.user!.email)
          .set({
        'username': emailTextController.text.split('@')[0],
        'bio': 'Fill in your bio here...',
        'email': emailTextController.text.toLowerCase(),
        'profilePic': 'profileImage1.jpg', // Default image
        'profileBackground': 'backgroundProfileImage1.jpg',

        // Social
        'friends': [],
        'friendRequests': [],
        'sentFriendRequests': [],

        // Future features
        'badges': [], 
        'streak': 0, 
        'totalForages': 0,
        'preferences': {
          'notifications': true,
          'privateProfile': false,
        },
        'createdAt': FieldValue.serverTimestamp(), 
        'lastActive': FieldValue.serverTimestamp(),
      });

      // pop loading circle
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        Navigator.pop(context);
        displayMessage('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        Navigator.pop(context);
        displayMessage('The account already exists for that email.');
      } else {
        Navigator.pop(context);
        displayMessage('The email is formatted incorrectly.');
      }
    } catch (e) {
      Navigator.pop(context);
      displayMessage('An error occurred. Please try again later.');
    }
  }

  void displayMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: ClipOval(
                        child: Image.asset(
                          'lib/assets/images/forager_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Let\'s create an account for you',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 25),
                  MyTextField(
                    controller: emailTextController,
                    hintText: 'Email',
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: passwordTextController,
                    hintText: 'Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: confirmPasswordTextController,
                    hintText: 'Confirm Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  MyButton(onTap: signUp, text: 'Sign Up'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          'Login now',
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
