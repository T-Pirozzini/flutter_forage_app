import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_forager_app/data/services/ad_mob_service.dart';
import 'package:flutter_forager_app/data/services/marker_icon_service.dart';
import 'package:flutter_forager_app/data/services/notification_service.dart';
import 'package:flutter_forager_app/screens/drawer/about_page.dart';
import 'package:flutter_forager_app/screens/drawer/about_us_page.dart';
import 'package:flutter_forager_app/screens/drawer/credits_page.dart';
import 'package:flutter_forager_app/screens/home/home_page.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'auth/auth_page.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Background message handler for FCM.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message received: ${message.notification?.title}');
}

Future main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  // Allow google_fonts to fetch fonts from network
  // Fonts are cached after first download
  GoogleFonts.config.allowRuntimeFetching = true;

  MobileAds.instance.initialize();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register FCM background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize push notification service
  await NotificationService.instance.initialize();

  // Don't block startup - icons will load in background after first frame
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Defer icon preloading to after first frame (non-blocking startup)
      MarkerIconService.initialize();
      requestTrackingPermission(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // dismiss keyboard when user taps outside of text field
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // Can be changed to ThemeMode.system
        initialRoute: '/auth',
        routes: {
          '/auth': (context) => const AuthPage(),
          '/home': (context) => const HomePage(currentIndex: 2), // Start on Explore
          '/about': (context) => const AboutPage(),
          '/about-us': (context) => const AboutUsPage(),
          '/credits': (context) => const CreditsPage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
