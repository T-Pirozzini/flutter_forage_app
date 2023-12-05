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
}
