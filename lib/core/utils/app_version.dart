import 'package:package_info_plus/package_info_plus.dart';

/// Utility for reading the current app version at runtime.
class AppVersion {
  static PackageInfo? _packageInfo;

  /// Initialize once during app startup.
  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// Returns the version string (e.g., "4.5.6").
  static String get current => _packageInfo?.version ?? '0.0.0';
}
