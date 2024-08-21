import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static String? get bannerAdUnitId {
    if (Platform.isAndroid) {
      // return 'ca-app-pub-3940256099942544/6300978111'; // Test ad unit ID
      return 'ca-app-pub-8699226690238380/2859427622'; // production ad unit ID
    } else if (Platform.isIOS) {
      // return 'ca-app-pub-8699226690238380/8111754306';
      return ' ca-app-pub-8699226690238380/8111754306'; // production ad unit ID
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
      // return 'ca-app-pub-3940256099942544/1033173712'; // Test ad unit ID
      return 'ca-app-pub-8699226690238380/9665198761'; // production ad unit ID
    } else if (Platform.isIOS) {
      // return 'ca-app-pub-3940256099942544/4411468910'; // Test ad unit ID
      return 'ca-app-pub-8699226690238380/3632912923'; // production ad unit ID
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

// Tracking permissions for iOS 14+

Future<void> showCustomTrackingDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // User must tap button
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Your Privacy is Important'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('We use your data to provide personalized ads.'),
              Text('Please allow tracking to support our services.'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Continue'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> requestTrackingPermission(BuildContext context) async {
  if (await AppTrackingTransparency.trackingAuthorizationStatus ==
      TrackingStatus.notDetermined) {
    // Show the explainer dialog
    await showCustomTrackingDialog(context);
    // Wait for dialog animation
    await Future.delayed(const Duration(milliseconds: 200));
    // Request the system tracking authorization dialog
    await AppTrackingTransparency.requestTrackingAuthorization();
  }
}
