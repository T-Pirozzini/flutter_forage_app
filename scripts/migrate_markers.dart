/// FIRESTORE MARKER MIGRATION SCRIPT
///
/// This script migrates all user markers from subcollections to a root collection.
///
/// BEFORE: Users/{userEmail}/Markers/{markerId}
/// AFTER:  Markers/{markerId} (with userId field)
///
/// IMPORTANT: Run this script ONCE before deploying the refactored app.
///
/// Usage:
/// 1. Ensure you have Firebase Admin SDK credentials
/// 2. Run: dart scripts/migrate_markers.dart
/// 3. Verify migration in Firebase Console
/// 4. Deploy new app version
///
/// Safety features:
/// - Dry run mode (test before actual migration)
/// - Keeps original subcollections intact
/// - Logs all operations
/// - Can be run multiple times safely (idempotent)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// You'll need to add your Firebase configuration here
// For security, use environment variables or a separate config file

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');

  print('='.repeat(80));
  print('FIRESTORE MARKER MIGRATION');
  print('='.repeat(80));
  print('Mode: ${dryRun ? "DRY RUN (no changes will be made)" : "LIVE MIGRATION"}');
  print('');

  if (!dryRun) {
    print('WARNING: This will migrate ALL markers to a new collection structure.');
    print('Press Ctrl+C to cancel, or wait 10 seconds to continue...');
    await Future.delayed(const Duration(seconds: 10));
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print('✓ Firebase initialized');
  } catch (e) {
    print('✗ Failed to initialize Firebase: $e');
    print('Make sure you have configured Firebase for this script.');
    return;
  }

  final firestore = FirebaseFirestore.instance;

  try {
    // Step 1: Get all users
    print('\nStep 1: Fetching all users...');
    final usersSnapshot = await firestore.collection('Users').get();
    print('✓ Found ${usersSnapshot.docs.length} users');

    int totalMarkers = 0;
    int migratedMarkers = 0;
    int skippedMarkers = 0;
    int errorCount = 0;

    // Step 2: Process each user's markers
    for (final userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      print('\nProcessing user: $userId');

      try {
        // Get user's markers subcollection
        final markersSnapshot = await firestore
            .collection('Users')
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
            final existingMarker = await firestore
                .collection('Markers')
                .doc(markerId)
                .get();

            if (existingMarker.exists) {
              print('  ⊘ Skipping $markerId (already exists in root collection)');
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
              await firestore
                  .collection('Markers')
                  .doc(markerId)
                  .set(migratedData);

              print('  ✓ Migrated marker: $markerId');
            } else {
              print('  [DRY RUN] Would migrate: $markerId');
            }

            migratedMarkers++;
          } catch (e) {
            print('  ✗ Error migrating marker $markerId: $e');
            errorCount++;
          }
        }
      } catch (e) {
        print('  ✗ Error processing user $userId: $e');
        errorCount++;
      }
    }

    // Summary
    print('\n' + '='.repeat(80));
    print('MIGRATION SUMMARY');
    print('='.repeat(80));
    print('Total markers found:    $totalMarkers');
    print('Migrated successfully:  $migratedMarkers');
    print('Skipped (already exist): $skippedMarkers');
    print('Errors:                 $errorCount');
    print('');

    if (dryRun) {
      print('This was a DRY RUN. No changes were made.');
      print('Run again without --dry-run to perform actual migration.');
    } else {
      print('Migration complete!');
      print('');
      print('NEXT STEPS:');
      print('1. Verify markers in Firebase Console (Markers collection)');
      print('2. Test the new app version with migrated data');
      print('3. After confirming everything works, you can delete old subcollections');
      print('   (Keep them for a while as backup)');
    }
  } catch (e) {
    print('\n✗ Migration failed: $e');
  }
}

extension Repeat on String {
  String repeat(int count) => List.filled(count, this).join();
}
