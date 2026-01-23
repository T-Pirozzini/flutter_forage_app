import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_forager_app/data/services/ad_mob_service.dart';
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

Future main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent google_fonts from blocking on network failures
  // Uses cached fonts or falls back to system fonts when offline
  GoogleFonts.config.allowRuntimeFetching = false;

  MobileAds.instance.initialize();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
