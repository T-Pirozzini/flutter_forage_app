import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_forager_app/core/constants/firestore_collections.dart';

/// Migration service to move markers from subcollections to root collection
///
/// This can be run from within the app (triggered by admin user or debug screen)
/// instead of as a standalone script.
class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate all markers from user subcollections to root Markers collection
  ///
  /// [dryRun] - If true, only logs what would be done without making changes
  /// Returns a MigrationResult with stats
  Future<MigrationResult> migrateMarkersToRootCollection({
    bool dryRun = true,
  }) async {
    print('\n${'=' * 80}');
    print('FIRESTORE MARKER MIGRATION');
    print('${'=' * 80}');
    print('Mode: ${dryRun ? "DRY RUN (no changes)" : "LIVE MIGRATION"}');
    print('');

    int totalMarkers = 0;
    int migratedMarkers = 0;
    int skippedMarkers = 0;
    int errorCount = 0;
    final List<String> errors = [];

    try {
      // Step 1: Get all users
      print('Step 1: Fetching all users...');
      final usersSnapshot = await _firestore
          .collection(FirestoreCollections.users)
          .get();
      print('✓ Found ${usersSnapshot.docs.length} users\n');

      // Step 2: Process each user's markers
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        print('Processing user: $userId');

        try {
          // Get user's markers subcollection
          final markersSnapshot = await _firestore
              .collection(FirestoreCollections.users)
              .doc(userId)
              .collection('Markers')
              .get();

          if (markersSnapshot.docs.isEmpty) {
            print('  No markers found');
            continue;
          }

          print('  Found ${markersSnapshot.docs.length} markers');
          totalMarkers += markersSnapshot.docs.length;

          // Step 3: Migrate each marker
          for (final markerDoc in markersSnapshot.docs) {
            final markerId = markerDoc.id;
            final markerData = markerDoc.data();

            try {
              // Check if marker already exists in root collection
              final existingMarker = await _firestore
                  .collection(FirestoreCollections.markers)
                  .doc(markerId)
                  .get();

              if (existingMarker.exists) {
                print('  ⊘ Skipping $markerId (already exists)');
                skippedMarkers++;
                continue;
              }

              // Add userId field to marker data
              final migratedData = {
                ...markerData,
                'userId': userId,
                'markerOwner': userId, // Keep for backwards compatibility
                'migratedAt': FieldValue.serverTimestamp(),
              };

              if (!dryRun) {
                // Write to root Markers collection
                await _firestore
                    .collection(FirestoreCollections.markers)
                    .doc(markerId)
                    .set(migratedData);

                print('  ✓ Migrated: $markerId');
              } else {
                print('  [DRY RUN] Would migrate: $markerId');
              }

              migratedMarkers++;
            } catch (e) {
              print('  ✗ Error migrating marker $markerId: $e');
              errors.add('User $userId, Marker $markerId: $e');
              errorCount++;
            }
          }
        } catch (e) {
          print('  ✗ Error processing user $userId: $e');
          errors.add('User $userId: $e');
          errorCount++;
        }
      }

      // Summary
      print('\n${'=' * 80}');
      print('MIGRATION SUMMARY');
      print('${'=' * 80}');
      print('Total markers found:     $totalMarkers');
      print('Migrated successfully:   $migratedMarkers');
      print('Skipped (already exist): $skippedMarkers');
      print('Errors:                  $errorCount');
      print('');

      if (dryRun) {
        print('This was a DRY RUN. No changes were made.');
        print('Run again with dryRun: false to perform actual migration.');
      } else {
        print('✓ Migration complete!');
        print('\nNEXT STEPS:');
        print('1. Verify markers in Firebase Console (Markers collection)');
        print('2. Test the app with migrated data');
        print('3. After confirming, you can delete old subcollections');
      }

      return MigrationResult(
        totalMarkers: totalMarkers,
        migratedMarkers: migratedMarkers,
        skippedMarkers: skippedMarkers,
        errorCount: errorCount,
        errors: errors,
        success: errorCount == 0,
      );
    } catch (e) {
      print('\n✗ Migration failed: $e');
      return MigrationResult(
        totalMarkers: 0,
        migratedMarkers: 0,
        skippedMarkers: 0,
        errorCount: 1,
        errors: ['Fatal error: $e'],
        success: false,
      );
    }
  }

  /// Quick check to see how many markers would be migrated
  Future<int> countMarkersToMigrate() async {
    int count = 0;
    try {
      final usersSnapshot = await _firestore
          .collection(FirestoreCollections.users)
          .get();

      for (final userDoc in usersSnapshot.docs) {
        final markersSnapshot = await _firestore
            .collection(FirestoreCollections.users)
            .doc(userDoc.id)
            .collection('Markers')
            .get();
        count += markersSnapshot.docs.length;
      }
    } catch (e) {
      print('Error counting markers: $e');
    }
    return count;
  }

  /// Migrate friends from old User.friends array to new Friends subcollection
  ///
  /// Old architecture: User document has `friends: List<String>` array
  /// New architecture: `/Users/{userId}/Friends/{friendEmail}` subcollection
  ///
  /// [dryRun] - If true, only logs what would be done without making changes
  /// Returns a FriendMigrationResult with stats
  Future<FriendMigrationResult> migrateFriendsToSubcollection({
    bool dryRun = true,
    String? specificUserId, // Optional: migrate only for specific user
  }) async {
    print('\n${'=' * 80}');
    print('FIRESTORE FRIEND MIGRATION');
    print('${'=' * 80}');
    print('Mode: ${dryRun ? "DRY RUN (no changes)" : "LIVE MIGRATION"}');
    if (specificUserId != null) {
      print('Migrating for user: $specificUserId');
    }
    print('');

    int totalFriendships = 0;
    int migratedFriendships = 0;
    int skippedFriendships = 0;
    int errorCount = 0;
    final List<String> errors = [];

    try {
      // Step 1: Get users to process
      print('Step 1: Fetching users...');
      QuerySnapshot usersSnapshot;

      if (specificUserId != null) {
        // Get specific user
        final doc = await _firestore
            .collection(FirestoreCollections.users)
            .doc(specificUserId)
            .get();
        if (!doc.exists) {
          return FriendMigrationResult(
            totalFriendships: 0,
            migratedFriendships: 0,
            skippedFriendships: 0,
            errorCount: 1,
            errors: ['User $specificUserId not found'],
            success: false,
          );
        }
        usersSnapshot = await _firestore
            .collection(FirestoreCollections.users)
            .where(FieldPath.documentId, isEqualTo: specificUserId)
            .get();
      } else {
        usersSnapshot = await _firestore
            .collection(FirestoreCollections.users)
            .get();
      }

      print('✓ Found ${usersSnapshot.docs.length} users to process\n');

      // Step 2: Process each user's friends array
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data() as Map<String, dynamic>;

        print('Processing user: $userId');

        try {
          // Get friends array from old architecture
          final List<String> friendsArray =
              List<String>.from(userData['friends'] ?? []);

          if (friendsArray.isEmpty) {
            print('  No friends in array');
            continue;
          }

          print('  Found ${friendsArray.length} friends in array');
          totalFriendships += friendsArray.length;

          // Get user's display name and photo for reciprocal entries
          final userDisplayName = userData['username'] ?? userId;
          final userPhotoUrl = userData['profilePic'];

          // Step 3: Migrate each friend
          for (final friendEmail in friendsArray) {
            try {
              // Check if friend already exists in subcollection
              final existingFriend = await _firestore
                  .collection(FirestoreCollections.users)
                  .doc(userId)
                  .collection('Friends')
                  .doc(friendEmail)
                  .get();

              if (existingFriend.exists) {
                print('  ⊘ Skipping $friendEmail (already in subcollection)');
                skippedFriendships++;
                continue;
              }

              // Get friend's user document for display name and photo
              final friendDoc = await _firestore
                  .collection(FirestoreCollections.users)
                  .doc(friendEmail)
                  .get();

              final friendData = friendDoc.exists
                  ? friendDoc.data() as Map<String, dynamic>
                  : <String, dynamic>{};
              final friendDisplayName = friendData['username'] ?? friendEmail;
              final friendPhotoUrl = friendData['profilePic'];

              final now = Timestamp.now();

              // Create friend entry for this user
              final friendEntryForUser = {
                'friendEmail': friendEmail,
                'displayName': friendDisplayName,
                if (friendPhotoUrl != null) 'photoUrl': friendPhotoUrl,
                'addedAt': now,
                'closeFriend': false,
                'migratedAt': now,
              };

              // Create reciprocal friend entry (other user's subcollection)
              final friendEntryForOther = {
                'friendEmail': userId,
                'displayName': userDisplayName,
                if (userPhotoUrl != null) 'photoUrl': userPhotoUrl,
                'addedAt': now,
                'closeFriend': false,
                'migratedAt': now,
              };

              if (!dryRun) {
                // Use batch write for atomicity
                final batch = _firestore.batch();

                // Add to current user's Friends subcollection
                batch.set(
                  _firestore
                      .collection(FirestoreCollections.users)
                      .doc(userId)
                      .collection('Friends')
                      .doc(friendEmail),
                  friendEntryForUser,
                );

                // Add reciprocal entry to friend's subcollection
                // (Check if it already exists first)
                final reciprocalExists = await _firestore
                    .collection(FirestoreCollections.users)
                    .doc(friendEmail)
                    .collection('Friends')
                    .doc(userId)
                    .get();

                if (!reciprocalExists.exists) {
                  batch.set(
                    _firestore
                        .collection(FirestoreCollections.users)
                        .doc(friendEmail)
                        .collection('Friends')
                        .doc(userId),
                    friendEntryForOther,
                  );
                }

                // Create FriendshipIndex entry
                final sortedEmails = [userId, friendEmail]..sort();
                final indexId = '${sortedEmails[0]}_${sortedEmails[1]}';

                final indexExists = await _firestore
                    .collection('FriendshipIndex')
                    .doc(indexId)
                    .get();

                if (!indexExists.exists) {
                  batch.set(
                    _firestore.collection('FriendshipIndex').doc(indexId),
                    {
                      'users': sortedEmails,
                      'createdAt': now,
                      'status': 'active',
                    },
                  );
                }

                await batch.commit();
                print('  ✓ Migrated: $friendEmail (bidirectional)');
              } else {
                print('  [DRY RUN] Would migrate: $friendEmail');
              }

              migratedFriendships++;
            } catch (e) {
              print('  ✗ Error migrating friend $friendEmail: $e');
              errors.add('User $userId, Friend $friendEmail: $e');
              errorCount++;
            }
          }
        } catch (e) {
          print('  ✗ Error processing user $userId: $e');
          errors.add('User $userId: $e');
          errorCount++;
        }
      }

      // Summary
      print('\n${'=' * 80}');
      print('FRIEND MIGRATION SUMMARY');
      print('${'=' * 80}');
      print('Total friendships found:  $totalFriendships');
      print('Migrated successfully:    $migratedFriendships');
      print('Skipped (already exist):  $skippedFriendships');
      print('Errors:                   $errorCount');
      print('');

      if (dryRun) {
        print('This was a DRY RUN. No changes were made.');
        print('Run again with dryRun: false to perform actual migration.');
      } else {
        print('✓ Friend migration complete!');
        print('\nNEXT STEPS:');
        print('1. Verify friends in Firebase Console (Users/{email}/Friends subcollection)');
        print('2. Test the app - friends should now appear in Friends page');
        print('3. After confirming, the old friends array can be left as backup');
      }

      return FriendMigrationResult(
        totalFriendships: totalFriendships,
        migratedFriendships: migratedFriendships,
        skippedFriendships: skippedFriendships,
        errorCount: errorCount,
        errors: errors,
        success: errorCount == 0,
      );
    } catch (e) {
      print('\n✗ Friend migration failed: $e');
      return FriendMigrationResult(
        totalFriendships: 0,
        migratedFriendships: 0,
        skippedFriendships: 0,
        errorCount: 1,
        errors: ['Fatal error: $e'],
        success: false,
      );
    }
  }

  /// Quick check to see how many friends would be migrated
  Future<int> countFriendsToMigrate() async {
    int count = 0;
    try {
      final usersSnapshot = await _firestore
          .collection(FirestoreCollections.users)
          .get();

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final friendsArray = List<String>.from(userData['friends'] ?? []);
        count += friendsArray.length;
      }
    } catch (e) {
      print('Error counting friends: $e');
    }
    return count;
  }

  /// Migrate a single user's friends (useful for on-demand migration)
  Future<FriendMigrationResult> migrateUserFriends(String userId) async {
    return migrateFriendsToSubcollection(
      dryRun: false,
      specificUserId: userId,
    );
  }
}

/// Result of a marker migration operation
class MigrationResult {
  final int totalMarkers;
  final int migratedMarkers;
  final int skippedMarkers;
  final int errorCount;
  final List<String> errors;
  final bool success;

  MigrationResult({
    required this.totalMarkers,
    required this.migratedMarkers,
    required this.skippedMarkers,
    required this.errorCount,
    required this.errors,
    required this.success,
  });

  @override
  String toString() {
    return '''
MigrationResult(
  total: $totalMarkers,
  migrated: $migratedMarkers,
  skipped: $skippedMarkers,
  errors: $errorCount,
  success: $success
)''';
  }
}

/// Result of a friend migration operation
class FriendMigrationResult {
  final int totalFriendships;
  final int migratedFriendships;
  final int skippedFriendships;
  final int errorCount;
  final List<String> errors;
  final bool success;

  FriendMigrationResult({
    required this.totalFriendships,
    required this.migratedFriendships,
    required this.skippedFriendships,
    required this.errorCount,
    required this.errors,
    required this.success,
  });

  @override
  String toString() {
    return '''
FriendMigrationResult(
  total: $totalFriendships,
  migrated: $migratedFriendships,
  skipped: $skippedFriendships,
  errors: $errorCount,
  success: $success
)''';
  }
}
