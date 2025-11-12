# CIS Driver App - Setup Instructions

## Prerequisites

- Flutter SDK 3.35.7 or compatible version
- Dart SDK (latest stable compatible with Flutter 3.35.7)
- iOS: Xcode 14+ (for iOS development)
- Android: Android Studio with Android SDK (for Android development)
- Firebase account with project configured
- Mapbox account with access token

## Installation Steps

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Firebase Configuration

#### Option A: Using FlutterFire CLI (Recommended)

1. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

2. Configure Firebase:
```bash
flutterfire configure
```

This will generate the `lib/firebase_options.dart` file with proper configuration.

#### Option B: Manual Configuration

Update `lib/firebase_options.dart` with your Firebase project credentials:
- API Key
- App ID (iOS and Android)
- Project ID
- Storage Bucket
- Messaging Sender ID

### 3. Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
# Firebase Configuration
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=your_auth_domain
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_storage_bucket
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
FIREBASE_DATABASE_URL=your_database_url

# Mapbox Configuration
MAPBOX_ACCESS_TOKEN=your_mapbox_token

# Application Configuration
APP_URL=http://www.conceptillustrated.com
USE_FIREBASE_EMULATORS=false
REQUIRE_EMAIL_VERIFICATION=false
```

### 4. iOS Configuration

1. Open `ios/Runner.xcworkspace` in Xcode
2. Add Mapbox access token to `Info.plist`:
```xml
<key>MBXAccessToken</key>
<string>your_mapbox_token</string>
```

3. Configure location permissions in `Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to track deliveries</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to track deliveries in the background</string>
```

### 5. Android Configuration

1. Add Mapbox access token to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.mapbox.maps.mapboxAccessToken"
    android:value="your_mapbox_token" />
```

2. Add permissions to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
```

3. Update `android/app/build.gradle`:
```gradle
minSdkVersion 21
```

### 6. Run the App

```bash
# For iOS
flutter run -d ios

# For Android
flutter run -d android
```

## Project Structure

```
lib/
├── core/
│   ├── config/          # App configuration
│   ├── constants/       # App constants
│   ├── router/          # Navigation router
│   └── theme/           # Theme and styling
├── models/              # Data models
├── providers/           # Riverpod providers
├── screens/             # App screens
│   ├── auth/           # Authentication screens
│   ├── dashboard/       # Dashboard screen
│   ├── delivery/       # Delivery screens
│   ├── map/            # Map screen
│   ├── profile/        # Profile screen
│   └── settings/       # Settings screen
├── services/            # Business logic services
└── widgets/             # Reusable widgets
    └── common/          # Common widgets
```

## Key Features

1. **Authentication**: Email/password login with Firebase Auth
2. **Dashboard**: View current deliveries, history, and stats
3. **Delivery Details**: View delivery information and swipe to update status
4. **Map View**: Real-time GPS tracking and route navigation
5. **Profile**: View and edit driver profile
6. **Earnings**: Track daily earnings from deliveries

## Design System

- **Primary Color**: Royal Blue (#4169E1)
- **Background**: White (#FFFFFF)
- **Text**: Black (#000000) and Gray (#666666)
- **Icons**: HugeIcons Flutter package

## Firebase Collections

- `users/{userId}` - User profiles
- `deliveries/{deliveryId}` - Delivery records
- `notifications/{userId}/messages/{notificationId}` - User notifications

## Troubleshooting

### Package Installation Issues

If you encounter package installation errors:
```bash
flutter clean
flutter pub get
```

### Firebase Issues

- Ensure Firebase project is properly configured
- Check that `firebase_options.dart` is generated correctly
- Verify Firebase rules allow driver access

### Mapbox Issues

- Verify Mapbox access token is correct
- Check that Mapbox SDK is properly configured for your platform
- Ensure location permissions are granted

### Build Issues

For iOS:
```bash
cd ios
pod install
cd ..
flutter run
```

For Android:
- Ensure Android SDK is properly configured
- Check that `minSdkVersion` is set correctly

## Development Notes

- The app uses Riverpod for state management
- Real-time updates use Firestore streams
- Location tracking updates every 5-10 seconds when active
- Map integration uses Mapbox Maps SDK

## Next Steps

1. Set up Firebase project and configure authentication
2. Configure Firestore security rules for drivers
3. Set up Mapbox account and get access token
4. Test on both iOS and Android devices
5. Configure push notifications (Firebase Cloud Messaging)

