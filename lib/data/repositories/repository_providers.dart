import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_forager_app/data/repositories/marker_repository.dart';
import 'package:flutter_forager_app/data/repositories/user_repository.dart';
import 'package:flutter_forager_app/data/services/firebase/firestore_service.dart';

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
