import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase_options.dart';

class FirebaseService {
  static FirebaseFirestore? _firestore;
  static FirebaseAuth? _auth;
  static FirebaseStorage? _storage;

  static Future<void> initialize() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      
      // Validate that we have required configuration
      if (options.apiKey.isEmpty || options.appId.isEmpty) {
        throw Exception(
          'Firebase configuration is incomplete. Please run "flutterfire configure" '
          'or update lib/firebase_options.dart with valid Firebase credentials.'
        );
      }
      
      await Firebase.initializeApp(options: options);
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      _storage = FirebaseStorage.instance;
    } catch (e) {
      throw Exception(
        'Failed to initialize Firebase: $e\n'
        'Please ensure:\n'
        '1. Firebase project is properly configured\n'
        '2. Run "flutterfire configure" to generate firebase_options.dart\n'
        '3. For iOS: Add GoogleService-Info.plist to ios/Runner/\n'
        '4. For Android: Add google-services.json to android/app/'
      );
    }
  }

  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception('Firebase not initialized');
    }
    return _firestore!;
  }

  static FirebaseAuth get auth {
    if (_auth == null) {
      throw Exception('Firebase not initialized');
    }
    return _auth!;
  }

  static FirebaseStorage get storage {
    if (_storage == null) {
      throw Exception('Firebase not initialized');
    }
    return _storage!;
  }
}

