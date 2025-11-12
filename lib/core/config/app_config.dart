import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Helper to safely get env values
  static String _getEnv(String key, [String defaultValue = '']) {
    try {
      return dotenv.env[key] ?? defaultValue;
    } catch (e) {
      // dotenv not loaded, return default
      return defaultValue;
    }
  }

  // Firebase
  static String get firebaseApiKey => _getEnv('FIREBASE_API_KEY');
  static String get firebaseAuthDomain => _getEnv('FIREBASE_AUTH_DOMAIN');
  static String get firebaseProjectId => _getEnv('FIREBASE_PROJECT_ID');
  static String get firebaseStorageBucket => _getEnv('FIREBASE_STORAGE_BUCKET');
  static String get firebaseMessagingSenderId =>
      _getEnv('FIREBASE_MESSAGING_SENDER_ID');
  static String get firebaseAppId => _getEnv('FIREBASE_APP_ID');
  static String get firebaseDatabaseUrl => _getEnv('FIREBASE_DATABASE_URL');

  // Mapbox
  static String get mapboxAccessToken => _getEnv('MAPBOX_ACCESS_TOKEN');

  // App
  static String get appUrl =>
      _getEnv('APP_URL', 'http://www.conceptillustrated.com');
  static bool get useFirebaseEmulators =>
      _getEnv('USE_FIREBASE_EMULATORS') == 'true';
  static bool get requireEmailVerification =>
      _getEnv('REQUIRE_EMAIL_VERIFICATION') == 'true';
}
