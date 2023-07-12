import "package:flutter/material.dart";

class CustomListTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final void Function()? onTap;

  const CustomListTile(
      {super.key, required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(text, style: const TextStyle(color: Colors.white)),
        onTap: onTap,
      ),
    );
  }
}
