# Firebase Setup Guide - Fix "Auth is Malformed or Expired" Error

## Quick Fix Steps

### 1. Install FlutterFire CLI (if not already installed)

```bash
dart pub global activate flutterfire_cli
```

### 2. Configure Firebase for Your Project

```bash
flutterfire configure
```

This command will:
- Connect to your Firebase project
- Generate proper `firebase_options.dart` file
- Download `GoogleService-Info.plist` for iOS
- Download `google-services.json` for Android

### 3. Verify Configuration Files

After running `flutterfire configure`, verify:

**iOS:**
- File exists: `ios/Runner/GoogleService-Info.plist`
- File exists: `lib/firebase_options.dart` with valid iOS app ID

**Android:**
- File exists: `android/app/google-services.json`
- File exists: `lib/firebase_options.dart` with valid Android app ID

### 4. Clean and Rebuild

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## Manual Configuration (Alternative)

If you can't use FlutterFire CLI, you need to:

### For iOS:

1. Download `GoogleService-Info.plist` from Firebase Console:
   - Go to Firebase Console → Project Settings → Your iOS App
   - Download `GoogleService-Info.plist`
   - Place it in `ios/Runner/GoogleService-Info.plist`

2. Update `lib/firebase_options.dart`:
   - Replace placeholder values with actual values from Firebase Console
   - Ensure `iosBundleId` matches your app's bundle identifier

### For Android:

1. Download `google-services.json` from Firebase Console:
   - Go to Firebase Console → Project Settings → Your Android App
   - Download `google-services.json`
   - Place it in `android/app/google-services.json`

2. Update `lib/firebase_options.dart`:
   - Replace `YOUR_ANDROID_APP_ID` with actual Android app ID

## Common Issues

### Error: "the supplied auth is malformed or has expired"

**Causes:**
1. Invalid or expired Firebase API key
2. Missing or incorrect app IDs
3. Missing `GoogleService-Info.plist` (iOS) or `google-services.json` (Android)
4. Bundle ID mismatch (iOS)

**Solutions:**
1. Regenerate Firebase configuration using `flutterfire configure`
2. Verify API key is valid in Firebase Console
3. Ensure all configuration files are in correct locations
4. Check bundle ID matches Firebase project settings

### Check Your Current Configuration

Your current `firebase_options.dart` shows:
- iOS App ID: `1:523486500169:ios:a7ac6f757589adbde23698` ✅ (looks valid)
- Android App ID: `1:523486500169:android:YOUR_ANDROID_APP_ID` ❌ (placeholder!)

**Action Required:**
- Run `flutterfire configure` to fix Android app ID
- Or manually update the Android app ID in `firebase_options.dart`

## Verify Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `concept-illustrated-mvp`
3. Go to Project Settings
4. Verify iOS and Android apps are registered
5. Check that API keys are valid and not expired

## Need Help?

If issues persist:
1. Check Firebase Console for any project-level errors
2. Verify your Firebase project billing is enabled (required for some features)
3. Ensure your app is registered in Firebase Console with correct bundle IDs
4. Try regenerating API keys in Firebase Console

