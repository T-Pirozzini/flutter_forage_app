import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class MarkerButtons extends StatefulWidget {
  const MarkerButtons({
    super.key,
  });

  @override
  State<MarkerButtons> createState() => _MarkerButtonsState();
}

class _MarkerButtonsState extends State<MarkerButtons> {
  void saveMarkerInfo(String currentPosition, String markerType,
      String markerName, String markerDescription) {
    FirebaseFirestore.instance.collection('markers').add({
      'position': currentPosition,
      'type': markerType,
      'name': markerName,
      'description': markerDescription,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      spacing: 0,
      mini: false,
      childrenButtonSize: const Size(70, 70),
      spaceBetweenChildren: 3,
      foregroundColor: Colors.white,
      backgroundColor: Colors.grey.shade800,
      activeForegroundColor: Colors.black,
      activeBackgroundColor: Colors.deepOrange.shade300,
      elevation: 8.0,
      animationCurve: Curves.elasticInOut,
      isOpenOnStart: false,
      shape: const RoundedRectangleBorder(),
      children: [
        SpeedDialChild(
          child: Image.asset('lib/assets/images/fern.png', width: 40),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => saveMarkerInfo(
              'Vancouver', 'fern', 'Fern', 'This is a fern'),
        ),
        SpeedDialChild(
            child: Image.asset('lib/assets/images/berries.png', width: 40),
            backgroundColor: Colors.grey.shade800,
            foregroundColor: Colors.white,
            onTap: () => {}),
        SpeedDialChild(
          child: Image.asset('lib/assets/images/mushroom.png', width: 40),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => {},
        ),
        SpeedDialChild(
          child: Image.asset('lib/assets/images/tree.png', width: 40),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => {},
        ),
        SpeedDialChild(
          child: Image.asset('lib/assets/images/fish.png', width: 40),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => {},
        ),
      ],
    );
  }
}
