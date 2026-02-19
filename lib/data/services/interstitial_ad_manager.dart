import 'package:flutter/foundation.dart';
import 'package:flutter_forager_app/data/services/ad_mob_service.dart';

/// Wraps AdMobService with frequency capping for user-friendly interstitial ads.
///
/// Rules:
/// 1. No ads within the first 3 minutes of session start (warm-up period)
/// 2. At most 1 interstitial every 4 minutes after warm-up
/// 3. Only triggered after content-creation completions (never mid-flow)
/// 4. Silently no-ops if conditions aren't met
class InterstitialAdManager {
  InterstitialAdManager._();
  static final InterstitialAdManager instance = InterstitialAdManager._();

  DateTime? _sessionStart;
  DateTime? _lastAdShown;

  /// Warm-up period: no ads for this duration after session start
  static const Duration _warmUpPeriod = Duration(minutes: 3);

  /// Cooldown between consecutive interstitials
  static const Duration _adCooldown = Duration(minutes: 4);

  /// Call once during app startup to start the session clock
  /// and preload the first interstitial.
  void initialize() {
    _sessionStart = DateTime.now();
    AdMobService.loadInterstitialAd();
    debugPrint('[InterstitialAdManager] Initialized.');
  }

  /// Attempt to show an interstitial if all frequency conditions are met.
  /// Fire-and-forget — callers should NOT depend on the result for navigation.
  bool tryShowAd() {
    final now = DateTime.now();

    if (_sessionStart == null) {
      debugPrint('[InterstitialAdManager] Not initialized. Skipping.');
      return false;
    }

    if (now.difference(_sessionStart!) < _warmUpPeriod) {
      debugPrint('[InterstitialAdManager] Warm-up period. Skipping.');
      return false;
    }

    if (_lastAdShown != null && now.difference(_lastAdShown!) < _adCooldown) {
      debugPrint('[InterstitialAdManager] Cooldown active. Skipping.');
      return false;
    }

    _lastAdShown = now;
    AdMobService.showInterstitialAd();
    debugPrint('[InterstitialAdManager] Showing interstitial.');
    return true;
  }
}
