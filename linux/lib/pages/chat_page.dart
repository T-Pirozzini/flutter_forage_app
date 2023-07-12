import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:lottie/lottie.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 500,
          child: Lottie.network(
            'https://assets8.lottiefiles.com/packages/lf20_0zv8teye.json',
            repeat: true,
            height: 300,
          ),
        ),
        Text('Current User: ${currentUser!.email!}'),
      ],
    );
  }
}
