import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/admin/admin_messages_page.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomDrawer extends ConsumerWidget {
  final void Function()? onForageLocationsTap;
  final void Function()? onSignOutTap;
  final void Function()? onAboutTap;
  final void Function()? onAboutUsTap;
  final void Function()? onCreditsTap;
  final void Function()? showDeleteConfirmationDialog;

  const CustomDrawer({
    super.key,
    required this.onSignOutTap,
    required this.onForageLocationsTap,
    required this.onAboutTap,
    required this.onAboutUsTap,
    required this.onCreditsTap,
    required this.showDeleteConfirmationDialog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

    return Drawer(
      backgroundColor: AppTheme.surfaceDark,
      child: SafeArea(
        child: Column(
          children: [
            // User header with avatar and info
            StreamBuilder<UserModel?>(
              stream: ref.read(userRepositoryProvider).streamById(currentUserEmail),
              builder: (context, snapshot) {
                final user = snapshot.data;
                final username = user?.username ?? currentUserEmail.split('@')[0];
                final profilePic = user?.profilePic ?? 'profileImage1.jpg';
                final isAdmin = user?.isAdmin ?? false;

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary,
                        AppTheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Large centered logo at top
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 20),
                        child: Image.asset(
                          'assets/images/forager_logo_3.png',
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // User info section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundDark.withValues(alpha: 0.3),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            // User avatar
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.secondary, width: 2),
                                image: DecorationImage(
                                  image: AssetImage('lib/assets/images/$profilePic'),
                                  fit: BoxFit.cover,
                                  onError: (_, __) {},
                                ),
                              ),
                              child: profilePic.isEmpty
                                  ? Icon(Icons.person, color: AppTheme.textWhite, size: 28)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            // User info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          username,
                                          style: AppTheme.title(
                                            size: 17,
                                            color: AppTheme.textWhite,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isAdmin) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.secondary,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'ADMIN',
                                            style: AppTheme.caption(
                                              size: 9,
                                              color: AppTheme.textDark,
                                              weight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentUserEmail,
                                    style: AppTheme.caption(
                                      size: 12,
                                      color: AppTheme.textWhite.withValues(alpha: 0.7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  // App Info
                  _DrawerMenuItem(
                    icon: Icons.info_outline,
                    label: 'App Info',
                    onTap: onAboutTap,
                  ),
                  // About Us
                  _DrawerMenuItem(
                    icon: Icons.people_outline,
                    label: 'About Us',
                    onTap: onAboutUsTap,
                  ),
                  // Admin (conditional)
                  StreamBuilder<UserModel?>(
                    stream: ref.read(userRepositoryProvider).streamById(currentUserEmail),
                    builder: (context, snapshot) {
                      final isAdmin = snapshot.data?.isAdmin ?? false;
                      if (!isAdmin) return const SizedBox.shrink();

                      return _DrawerMenuItem(
                        icon: Icons.admin_panel_settings,
                        label: 'Admin Messages',
                        iconColor: AppTheme.secondary,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminMessagesPage(),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 8),
                  Divider(
                    color: AppTheme.textLight.withValues(alpha: 0.2),
                    indent: 20,
                    endIndent: 20,
                  ),
                  const SizedBox(height: 8),

                  // Sign Out
                  _DrawerMenuItem(
                    icon: Icons.logout,
                    label: 'Sign Out',
                    onTap: onSignOutTap,
                  ),
                ],
              ),
            ),

            // Delete account at bottom
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: showDeleteConfirmationDialog,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: AppTheme.error.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delete Account',
                        style: AppTheme.caption(
                          size: 13,
                          color: AppTheme.error.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern drawer menu item
class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppTheme.primary).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: AppTheme.body(
                    size: 15,
                    color: AppTheme.textWhite,
                    weight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppTheme.textLight.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
