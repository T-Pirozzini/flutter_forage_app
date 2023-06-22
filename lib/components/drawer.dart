import 'package:flutter/material.dart';
import 'list_tile.dart';

class CustomDrawer extends StatelessWidget {
  final void Function()? onProfileTap;
  final void Function()? onForageLocationsTap;
  final void Function()? onSignOutTap;
  final void Function()? onAboutTap;
  final void Function()? onAboutUsTap;

  const CustomDrawer(
      {super.key,
      required this.onProfileTap,
      required this.onSignOutTap,
      required this.onForageLocationsTap,
      required this.onAboutTap,
      required this.onAboutUsTap});

  @override
  Widget build(BuildContext context) {
    return Drawer(
        backgroundColor: Colors.grey[900],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //header
            Column(
              children: [
                DrawerHeader(
                  child: Image.asset('lib/assets/images/wicker-basket.png',
                      color: Colors.white, width: 100),
                ),
// profile list tile
                CustomListTile(
                  icon: Icons.person,
                  text: 'P R O F I L E',
                  onTap: onProfileTap,
                ),
                // home list tile
                CustomListTile(
                  icon: Icons.info_outline,
                  text: 'A B O U T',
                  onTap: onAboutTap,
                ),
                // profile list tile
                CustomListTile(
                  icon: Icons.smart_toy,
                  text: 'A B O U T  U S',
                  onTap: onAboutUsTap,
                ),
              ],
            ),

            // logout list tile
            Padding(
              padding: const EdgeInsets.only(bottom: 25.0),
              child: CustomListTile(
                  icon: Icons.logout, text: 'L O G O U T', onTap: onSignOutTap),
            ),
          ],
        ));
  }
}
