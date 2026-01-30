import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_forager_app/data/repositories/activity_feed_repository.dart';
import 'package:flutter_forager_app/data/repositories/bookmark_repository.dart';
import 'package:flutter_forager_app/data/repositories/collection_repository.dart';
import 'package:flutter_forager_app/data/repositories/custom_marker_type_repository.dart';
import 'package:flutter_forager_app/data/repositories/following_repository.dart';
import 'package:flutter_forager_app/data/repositories/friend_repository.dart';
import 'package:flutter_forager_app/data/repositories/marker_repository.dart';
import 'package:flutter_forager_app/data/repositories/post_repository.dart';
import 'package:flutter_forager_app/data/repositories/recipe_repository.dart';
import 'package:flutter_forager_app/data/repositories/saved_recipe_repository.dart';
import 'package:flutter_forager_app/data/repositories/user_repository.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';
import 'package:flutter_forager_app/data/services/post_migration_service.dart';

/// Providers for repositories
///
/// These providers make repositories available throughout the app via Riverpod.
/// Use these providers in your widgets and other providers to access data.

/// FirestoreService provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// MarkerRepository provider
final markerRepositoryProvider = Provider<MarkerRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return MarkerRepository(firestoreService: firestoreService);
});

/// UserRepository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return UserRepository(firestoreService: firestoreService);
});

/// PostRepository provider
final postRepositoryProvider = Provider<PostRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return PostRepository(firestoreService: firestoreService);
});

/// RecipeRepository provider
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return RecipeRepository(firestoreService: firestoreService);
});

/// CustomMarkerTypeRepository provider
final customMarkerTypeRepositoryProvider = Provider<CustomMarkerTypeRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return CustomMarkerTypeRepository(firestoreService: firestoreService);
});

/// FriendRepository provider
///
/// Manages friend relationships and friend requests using subcollections.
final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FriendRepository(firestoreService: firestoreService);
});

/// FollowingRepository provider
///
/// Manages one-way follow relationships (unlike Friends which are mutual).
/// Used for filtering posts/recipes by followed users.
final followingRepositoryProvider = Provider<FollowingRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FollowingRepository(firestoreService: firestoreService);
});

/// BookmarkRepository provider
///
/// Manages user bookmarks (saved locations) using subcollections.
final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return BookmarkRepository(firestoreService: firestoreService);
});

/// CollectionRepository provider
///
/// Manages location collections and subscriptions using subcollections.
final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return CollectionRepository(firestoreService: firestoreService);
});

/// ActivityFeedRepository provider
///
/// Manages the activity feed for friend updates.
final activityFeedRepositoryProvider = Provider<ActivityFeedRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ActivityFeedRepository(firestoreService: firestoreService);
});

/// SavedRecipeRepository provider
///
/// Manages user's saved/bookmarked recipes using subcollections.
final savedRecipeRepositoryProvider = Provider<SavedRecipeRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return SavedRecipeRepository(firestoreService: firestoreService);
});

/// PostMigrationService provider
///
/// Handles migration of Posts from array-based to subcollection-based architecture.
final postMigrationServiceProvider = Provider<PostMigrationService>((ref) {
  final postRepository = ref.watch(postRepositoryProvider);
  return PostMigrationService(postRepository: postRepository);
});
