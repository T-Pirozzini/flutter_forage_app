import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class MarkerButtons extends StatelessWidget {
  const MarkerButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      spacing: 3,
      mini: false,
      childPadding: const EdgeInsets.all(5),
      spaceBetweenChildren: 4,
      foregroundColor: Colors.white,
      backgroundColor: Colors.grey.shade800,
      activeForegroundColor: Colors.black,
      activeBackgroundColor: Colors.deepOrange.shade300,
      elevation: 8.0,
      animationCurve: Curves.elasticInOut,
      isOpenOnStart: false,
      shape: const RoundedRectangleBorder(),
      // childMargin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      children: [
        SpeedDialChild(
          child: const Icon(Icons.accessibility),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          label: 'First',
          onTap: () => {},
        ),
        SpeedDialChild(
          child: const Icon(Icons.brush),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          label: 'Second',
          onTap: () => debugPrint('SECOND CHILD'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.margin),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          label: 'Show Snackbar',
          visible: true,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(("Third Child Pressed")))),
          onLongPress: () => debugPrint('THIRD CHILD LONG PRESS'),
        ),
      ],
    );
  }
}
