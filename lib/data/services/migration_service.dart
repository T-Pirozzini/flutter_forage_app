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
}

/// Result of a migration operation
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
