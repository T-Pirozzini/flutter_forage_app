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
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
              'lib/assets/images/${widget.type.toLowerCase()}_marker.png',
              width: 50),

          SizedBox(width: 8), // Adjust the spacing between the icon and text
          Text(widget.name.toUpperCase(),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              height: 200,
              width: 400,
              child: Image.file(
                File(widget.image),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.description),
            ],
          ),
          SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date/Time: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(widget.timestamp),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Text('Lat: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.lat.toStringAsFixed(2)),
              SizedBox(width: 10),
              Text('Lng: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.lng.toStringAsFixed(2)),
            ],
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
