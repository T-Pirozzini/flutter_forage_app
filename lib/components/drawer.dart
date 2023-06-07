import 'package:flutter/material.dart';
import 'list_tile.dart';

class CustomDrawer extends StatelessWidget {
  final void Function()? onProfileTap;
  final void Function()? onSignOutTap;
  const CustomDrawer(
      {super.key, required this.onProfileTap, required this.onSignOutTap});

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

                // home list tile
                CustomListTile(
                  icon: Icons.hotel_class_sharp,
                  text: 'M Y   F O R A G E   L O C A T I O N S',
                  onTap: () => Navigator.pop(context),
                ),
                // profile list tile
                CustomListTile(
                    icon: Icons.person,
                    text: 'P R O F I L E',
                    onTap: onProfileTap),
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
