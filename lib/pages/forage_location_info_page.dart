import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForageLocationInfo extends StatefulWidget {
  final String name;
  final String description;
  final String image;
  final double lat;
  final double lng;
  final String timestamp;
  final String type;

  const ForageLocationInfo(
      {super.key,
      required this.name,
      required this.description,
      required this.image,
      required this.lat,
      required this.lng,
      required this.timestamp,
      required this.type});

  @override
  State<ForageLocationInfo> createState() => _ForageLocationInfoState();
}

class _ForageLocationInfoState extends State<ForageLocationInfo> {
  // current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.name),
      content: Column(
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: Image.file(File(widget.image),),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
