import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static String? get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-8699226690238380/2859427622';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-8699226690238380/8111754306';
    }
    return null;
  }

  static final BannerAdListener bannerListener = BannerAdListener(
    onAdLoaded: (ad) => debugPrint('Ad loaded: ${ad.adUnitId}.'),
    onAdFailedToLoad: (ad, error) {
      ad.dispose();
      debugPrint('Ad failed to load: ${ad.adUnitId}, $error');
    },
    onAdOpened: (ad) => debugPrint('Ad opened: ${ad.adUnitId}.'),
    onAdClosed: (ad) => debugPrint('Ad closed: ${ad.adUnitId}.'),
  );

  static String? get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ad unit ID
      // return 'ca-app-pub-8699226690238380/9665198761'; // production ad unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ad unit ID
    }
    return null;
  }

  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;

  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId!,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          debugPrint('Interstitial ad loaded: ${ad.adUnitId}.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  static void showInterstitialAd() {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) =>
            debugPrint('Interstitial ad showed: ${ad.adUnitId}.'),
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          loadInterstitialAd(); // Load a new ad for the next time
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          debugPrint('Interstitial ad failed to show: $error');
          loadInterstitialAd(); // Load a new ad for the next time
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
      _isInterstitialAdReady = false;
    } else {
      debugPrint('Interstitial ad is not ready.');
    }
  }
}
