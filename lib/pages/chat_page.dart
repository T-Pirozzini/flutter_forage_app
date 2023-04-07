import 'package:flutter/material.dart';

import 'package:lottie/lottie.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Lottie.network(
        'https://assets8.lottiefiles.com/packages/lf20_0zv8teye.json',
        repeat: true,
        height: 300,
      ),
    );
  }
}
