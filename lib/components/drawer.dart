import 'package:flutter/material.dart';
import 'list_tile.dart';

class CustomDrawer extends StatelessWidget {
  final void Function()? onProfileTap;
  final void Function()? onForageLocationsTap;
  final void Function()? onSignOutTap;
  final void Function()? onAboutTap;
  final void Function()? onAboutUsTap;
  final void Function()? onCreditsTap;

  const CustomDrawer(
      {super.key,
      required this.onProfileTap,
      required this.onSignOutTap,
      required this.onForageLocationsTap,
      required this.onAboutTap,
      required this.onAboutUsTap,
      required this.onCreditsTap});

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
                  child: ClipOval(
                    child: Image.asset('lib/assets/images/forager_logo.png',
                        width: 138),
                  ),
                ),
                // profile tile
                CustomListTile(
                  icon: Icons.person,
                  text: 'PROFILE',
                  onTap: onProfileTap,
                ),
                // about tile
                CustomListTile(
                  icon: Icons.info_outline,
                  text: 'APP INFO',
                  onTap: onAboutTap,
                ),
                // About us tile
                CustomListTile(
                  icon: Icons.people,
                  text: 'ABOUT  US',
                  onTap: onAboutUsTap,
                ),
                // Credits tile
                CustomListTile(
                  icon: Icons.handshake_rounded,
                  text: 'CREDITS',
                  onTap: onCreditsTap,
                ),
              ],
            ),

            // logout list tile
            Padding(
              padding: const EdgeInsets.only(bottom: 25.0),
              child: CustomListTile(
                  icon: Icons.logout, text: 'SIGN OUT', onTap: onSignOutTap),
            ),
          ],
        ));
  }
}
