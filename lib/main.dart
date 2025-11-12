import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/config/app_config.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (optional - app can run without .env file)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env file not found, app will use default values or Firebase options
    debugPrint('Warning: .env file not found. Using default configuration.');
  }

  // Configure Mapbox access token
  // Priority: 1. --dart-define ACCESS_TOKEN, 2. .env file, 3. hardcoded fallback
  String mapboxToken = const String.fromEnvironment(
    'ACCESS_TOKEN',
    defaultValue: '',
  );
  
  if (mapboxToken.isEmpty) {
    mapboxToken = AppConfig.mapboxAccessToken;
  }
  
  if (mapboxToken.isEmpty) {
    // Fallback to provided token
    mapboxToken = 'pk.eyJ1Ijoia2Fkb254IiwiYSI6ImNtaDVtOTFydzA3a3oya3BtaGJwaWNqZDcifQ.UZGRaZCaSziQpUi61eKEGQ';
  }
  
  if (mapboxToken.isNotEmpty) {
    MapboxOptions.setAccessToken(mapboxToken);
    debugPrint('Mapbox access token configured successfully');
  } else {
    debugPrint('Warning: Mapbox access token not configured');
  }

  // Initialize Firebase
  await FirebaseService.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CIS Driver App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
