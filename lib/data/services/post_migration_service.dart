import 'package:flutter/foundation.dart';
import 'package:flutter_forager_app/data/repositories/post_repository.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle migration of Posts from array-based to subcollection-based architecture.
///
/// Migration moves:
/// - `likedBy` array -> `/Posts/{postId}/Likes/{userEmail}` subcollection
/// - `comments` array -> `/Posts/{postId}/Comments/{commentId}` subcollection
///
/// The original arrays are kept for backward compatibility but new operations
/// use the subcollections for scalability.
class PostMigrationService {
  static const String _migrationKey = 'posts_subcollection_migration_v1';

  final PostRepository _postRepository;

  PostMigrationService({PostRepository? postRepository})
      : _postRepository = postRepository ??
            PostRepository(firestoreService: FirestoreService());

  /// Check if migration has already been completed
  Future<bool> isMigrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }

  /// Mark migration as complete
  Future<void> _markMigrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
  }

  /// Run the migration if not already done
  ///
  /// Returns the number of posts migrated, or -1 if already migrated.
  Future<int> runMigrationIfNeeded() async {
    if (await isMigrationComplete()) {
      debugPrint('Post migration already complete, skipping.');
      return -1;
    }

    try {
      final count = await _postRepository.migrateAllPosts();
      await _markMigrationComplete();
      debugPrint('Post migration complete: $count posts migrated');
      return count;
    } catch (e) {
      debugPrint('Post migration failed: $e');
      rethrow;
    }
  }

  /// Force re-run migration (for testing/debugging)
  Future<int> forceMigration() async {
    try {
      final count = await _postRepository.migrateAllPosts();
      await _markMigrationComplete();
      debugPrint('Forced post migration complete: $count posts migrated');
      return count;
    } catch (e) {
      debugPrint('Forced post migration failed: $e');
      rethrow;
    }
  }

  /// Reset migration flag (for testing/debugging)
  Future<void> resetMigrationFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationKey);
    debugPrint('Post migration flag reset');
  }

  /// Migrate a single post by ID
  Future<void> migratePost(String postId) async {
    try {
      await _postRepository.migratePostToSubcollections(postId);
      debugPrint('Migrated post: $postId');
    } catch (e) {
      debugPrint('Failed to migrate post $postId: $e');
      rethrow;
    }
  }
}
