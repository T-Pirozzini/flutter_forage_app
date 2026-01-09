import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_forager_app/data/repositories/gamification_repository.dart';

/// Provider for GamificationRepository
final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return GamificationRepository(userRepository: userRepository);
});
