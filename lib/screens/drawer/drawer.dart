import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/screens/drawer/feedback.dart';
import '../../components/list_tile.dart';

class CustomDrawer extends StatelessWidget {
  // final void Function()? onProfileTap;
  final void Function()? onForageLocationsTap;
  final void Function()? onSignOutTap;
  final void Function()? onAboutTap;
  final void Function()? onAboutUsTap;
  final void Function()? onCreditsTap;
  final void Function()? showDeleteConfirmationDialog;

  const CustomDrawer(
      {super.key,
      // required this.onProfileTap,
      required this.onSignOutTap,
      required this.onForageLocationsTap,
      required this.onAboutTap,
      required this.onAboutUsTap,
      required this.onCreditsTap,
      required this.showDeleteConfirmationDialog});

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email;
    final userName = currentUserEmail!.split('@')[0];

    return Drawer(
        backgroundColor: Colors.grey[900],
        child: SingleChildScrollView(
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
                  // CustomListTile(
                  //   icon: Icons.person,
                  //   text: 'PROFILE',
                  //   onTap: onProfileTap,
                  // ),
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
                  // CustomListTile(
                  //   icon: Icons.handshake_rounded,
                  //   text: 'CREDITS',
                  //   onTap: onCreditsTap,
                  // ),

                  UserFeedback(userName: userName, userEmail: currentUserEmail),
                  const Divider(
                      thickness: 1,
                      color: Colors.white,
                      indent: 20,
                      endIndent: 30),
                ],
              ),

              // logout list tile
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: CustomListTile(
                    icon: Icons.logout, text: 'SIGN OUT', onTap: onSignOutTap),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 25.0),
                child: ListTile(
                    title: Row(
                      children: [
                        Icon(Icons.delete_forever,
                            color: Colors.white, size: 30),
                        Text('Delete Account?',
                            style:
                                TextStyle(color: Colors.white, fontSize: 18)),
                      ],
                    ),
                    onTap: showDeleteConfirmationDialog),
              ),
            ],
          ),
        ));
  }
}
