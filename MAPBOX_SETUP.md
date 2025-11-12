# Mapbox Setup Guide

This app uses Mapbox Maps SDK for Flutter v2.12.0. Follow these steps to ensure Mapbox is properly configured.

## Access Token Configuration

The Mapbox access token is configured in `lib/main.dart` with the following priority:

1. **--dart-define** (Recommended for production)
2. **.env file** (For development)
3. **Hardcoded fallback** (Current token as fallback)

## Running the App

### Option 1: Using --dart-define (Recommended)

```bash
# For running
flutter run --dart-define ACCESS_TOKEN=YOUR_MAPBOX_ACCESS_TOKEN

# For building
flutter build apk --dart-define ACCESS_TOKEN=YOUR_MAPBOX_ACCESS_TOKEN
flutter build ios --dart-define ACCESS_TOKEN=YOUR_MAPBOX_ACCESS_TOKEN
```

### Option 2: Using .env file

Create a `.env` file in the project root:

```
MAPBOX_ACCESS_TOKEN=pk.eyJ1Ijoia2Fkb254IiwiYSI6ImNtaDVtOTFydzA3a3oya3BtaGJwaWNqZDcifQ.UZGRaZCaSziQpUi61eKEGQ
```

Then run normally:
```bash
flutter run
```

### Option 3: VS Code Configuration

Add to `.vscode/launch.json`:

```json
{
    "configurations": [
        {
            "name": "Flutter",
            "request": "launch",
            "type": "dart",
            "program": "lib/main.dart",
            "args": [
                "--dart-define",
                "ACCESS_TOKEN=pk.eyJ1Ijoia2Fkb254IiwiYSI6ImNtaDVtOTFydzA3a3oya3BtaGJwaWNqZDcifQ.UZGRaZCaSziQpUi61eKEGQ"
            ]
        }
    ]
}
```

## Current Token

The current Mapbox access token is configured as a fallback in `lib/main.dart`. For production, it's recommended to use `--dart-define` to avoid hardcoding tokens in source code.

## Documentation

- [Mapbox Maps SDK for Flutter Documentation](https://docs.mapbox.com/flutter/maps/guides/install/)
- [Access Token Best Practices](https://docs.mapbox.com/flutter/maps/guides/access-tokens/)

