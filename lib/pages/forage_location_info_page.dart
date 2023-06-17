import 'dart:io';
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
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: false,
      title: Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              Image.asset(
                  'lib/assets/images/${widget.type.toLowerCase()}_marker.png',
                  width: 50),
              const SizedBox(width: 10),
              Text(
                widget.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                height: 200,
                width: 400,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(widget.image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline_rounded),
                    Text('Description: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(widget.description),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.calendar_month_rounded),
                    Text(
                      'Date/Time: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(widget.timestamp),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.pin_drop_outlined),
                Text('Location: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              children: [
                const Text('Lat: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.lat.toStringAsFixed(2)),
                const SizedBox(width: 10),
                const Text('Lng: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.lng.toStringAsFixed(2)),
              ],
            ),
          ],
        ),
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
