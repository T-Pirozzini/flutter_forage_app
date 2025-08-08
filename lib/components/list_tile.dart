import "package:flutter/material.dart";

class CustomListTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final void Function()? onTap;

  const CustomListTile(
      {super.key, required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 0, 0, 0),
          child: ListTile(
            dense: true,
            leading: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            title: Text(text,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, letterSpacing: 2)),
            onTap: onTap,
          ),
        ),
        const Divider(
            thickness: 1, color: Colors.white, indent: 20, endIndent: 30),
      ],
    );
  }
}
