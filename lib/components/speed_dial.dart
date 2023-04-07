import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:lottie/lottie.dart';

class MarkerButtons extends StatefulWidget {
  const MarkerButtons({super.key});

  @override
  State<MarkerButtons> createState() => _MarkerButtonsState();
}

class _MarkerButtonsState extends State<MarkerButtons> {
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
          child: Lottie.network(
            'https://assets9.lottiefiles.com/packages/lf20_WnTNaLqbIz.json',
          ),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => {},
        ),
        SpeedDialChild(
          child: Lottie.network(
            'https://assets2.lottiefiles.com/packages/lf20_o1Bpa0VeaC.json',
          ),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => {},
        ),
        SpeedDialChild(
            child: Lottie.network(
              'https://assets4.lottiefiles.com/packages/lf20_flosnlcw.json',
            ),
            backgroundColor: Colors.grey.shade800,
            foregroundColor: Colors.white,
            onTap: () => {}),
        SpeedDialChild(
          child: Lottie.network(
            'https://assets1.lottiefiles.com/packages/lf20_Wje5ae.json',
          ),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => {},
        ),
        SpeedDialChild(
          child: Lottie.network(
            'https://assets2.lottiefiles.com/packages/lf20_xd9ypluc.json',
          ),
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          onTap: () => {},
        ),
      ],
    );
  }
}
