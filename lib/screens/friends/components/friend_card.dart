import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/friend.dart';
import 'package:flutter_forager_app/data/models/location_sharing_info.dart';
import 'package:flutter_forager_app/data/models/user.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Modern friend card component for the Friends tab.
///
/// Features:
/// - Avatar with Trusted Forager badge
/// - Text labels for badges (not just icons)
/// - Location sharing info
/// - Three action buttons: View Locations, Forage Together, More menu
/// - Responsive layout that doesn't overflow
class FriendCard extends StatelessWidget {
  final FriendModel friend;
  final UserModel? userData;
  final LocationSharingInfo sharingInfo;
  final VoidCallback onViewLocations;
  final VoidCallback onForageTogether;
  final VoidCallback onViewProfile;
  final VoidCallback onToggleTrustedForager;
  final VoidCallback onToggleEmergencyContact;
  final VoidCallback onRemoveFriend;

  const FriendCard({
    super.key,
    required this.friend,
    this.userData,
    required this.sharingInfo,
    required this.onViewLocations,
    required this.onForageTogether,
    required this.onViewProfile,
    required this.onToggleTrustedForager,
    required this.onToggleEmergencyContact,
    required this.onRemoveFriend,
  });

  Future<String> _getProfileImageUrl(String imageName) async {
    if (imageName.isEmpty) return '';
    try {
      final ref = firebase_storage.FirebaseStorage.instance
          .ref('profile_images/$imageName');
      return await ref.getDownloadURL();
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOpenToForage = userData?.openToForage ?? false;
    final memberSince = userData?.createdAt.toDate();
    final friendCount = userData?.friends.length ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
        side: friend.closeFriend
            ? BorderSide(color: AppTheme.xp, width: 2)
            : BorderSide.none,
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: AppTheme.borderRadiusMedium,
        onTap: onViewLocations,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar + Name + Badges
              _buildHeader(isOpenToForage, friendCount),

              const SizedBox(height: 10),

              // Badge labels row (Trusted Forager, Emergency Contact)
              _buildBadgeLabels(),

              const SizedBox(height: 10),

              // Location sharing info
              _buildLocationSharingRow(),

              const SizedBox(height: 12),

              // Action buttons row
              _buildActionButtons(context),

              // Reputation row (member info)
              if (memberSince != null) ...[
                const SizedBox(height: 10),
                _buildReputationRow(memberSince, friendCount),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isOpenToForage, int friendCount) {
    return Row(
      children: [
        // Avatar with Trusted Forager badge
        Stack(
          children: [
            FutureBuilder<String>(
              future: _getProfileImageUrl(friend.photoUrl ?? ''),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage(snapshot.data!),
                  );
                }
                return CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    friend.displayName.isNotEmpty
                        ? friend.displayName[0].toUpperCase()
                        : '?',
                    style: AppTheme.title(color: Colors.white, size: 20),
                  ),
                );
              },
            ),
            if (friend.closeFriend)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.xp,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.star,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Name and quick info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                friend.displayName,
                style: AppTheme.title(size: 16),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Quick info row
              Row(
                children: [
                  Icon(Icons.people, size: 12, color: AppTheme.textMedium),
                  const SizedBox(width: 4),
                  Text(
                    '$friendCount friends',
                    style: AppTheme.caption(size: 11),
                  ),
                  if (isOpenToForage) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.nature_people,
                              size: 10, color: AppTheme.success),
                          const SizedBox(width: 3),
                          Text(
                            'Open to Forage',
                            style: AppTheme.caption(
                              size: 9,
                              weight: FontWeight.w600,
                              color: AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeLabels() {
    final List<Widget> badges = [];

    if (friend.closeFriend) {
      badges.add(_buildTextBadge(
        icon: Icons.star,
        label: 'Trusted Forager',
        color: AppTheme.xp,
        description: 'Sees precise locations',
      ));
    }

    if (friend.isEmergencyContact) {
      badges.add(_buildTextBadge(
        icon: Icons.shield,
        label: 'Emergency Contact',
        color: AppTheme.warning,
        description: 'Notified of your foraging plans',
      ));
    }

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: badges,
    );
  }

  Widget _buildTextBadge({
    required IconData icon,
    required String label,
    required Color color,
    String? description,
  }) {
    return Tooltip(
      message: description ?? '',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTheme.caption(
                size: 11,
                weight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSharingRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sharingInfo.displayText,
              style: AppTheme.caption(size: 12),
            ),
          ),
          if (sharingInfo.hasHiddenLocations)
            Tooltip(
              message: 'Become a Trusted Forager to see all locations',
              child: Icon(
                Icons.visibility_off,
                size: 14,
                color: AppTheme.textMedium,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // View Locations button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onViewLocations,
            icon: const Icon(Icons.map, size: 16),
            label: const Text('Locations'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              textStyle: AppTheme.caption(size: 12, weight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Forage Together button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onForageTogether,
            icon: const Icon(Icons.nature_people, size: 16),
            label: const Text('Forage'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              textStyle: AppTheme.caption(size: 12, weight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // More menu
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppTheme.textMedium),
          tooltip: 'More options',
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusMedium,
          ),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                onViewProfile();
                break;
              case 'trusted':
                onToggleTrustedForager();
                break;
              case 'emergency':
                onToggleEmergencyContact();
                break;
              case 'remove':
                onRemoveFriend();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, color: AppTheme.info, size: 20),
                  const SizedBox(width: 12),
                  const Text('View Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'trusted',
              child: Row(
                children: [
                  Icon(
                    friend.closeFriend ? Icons.star : Icons.star_border,
                    color: AppTheme.xp,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    friend.closeFriend
                        ? 'Remove Trusted Forager'
                        : 'Make Trusted Forager',
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'emergency',
              child: Row(
                children: [
                  Icon(
                    friend.isEmergencyContact
                        ? Icons.shield
                        : Icons.shield_outlined,
                    color: AppTheme.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    friend.isEmergencyContact
                        ? 'Remove Emergency Contact'
                        : 'Set Emergency Contact',
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.person_remove, color: AppTheme.error, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Remove Friend',
                    style: TextStyle(color: AppTheme.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReputationRow(DateTime memberSince, int friendCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildReputationItem(
            Icons.calendar_today,
            'Member ${DateFormat('MMM yyyy').format(memberSince)}',
          ),
          Container(
            width: 1,
            height: 12,
            color: AppTheme.textMedium.withValues(alpha: 0.3),
          ),
          _buildReputationItem(
            Icons.handshake,
            'Friends ${DateFormat('MMM yyyy').format(friend.addedAt)}',
          ),
        ],
      ),
    );
  }

  Widget _buildReputationItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppTheme.textMedium),
        const SizedBox(width: 4),
        Text(text, style: AppTheme.caption(size: 10)),
      ],
    );
  }
}
