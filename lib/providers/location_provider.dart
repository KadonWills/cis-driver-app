import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../models/location_model.dart';
import 'auth_provider.dart';

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

final currentPositionProvider = StreamProvider<Position>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getPositionStream();
});

final currentLocationProvider = StreamProvider<LocationModel>((ref) async* {
  final locationService = ref.watch(locationServiceProvider);
  
  // Get position stream directly from the service
  await for (final position in locationService.getPositionStream()) {
    final location = await locationService.getLocationFromPosition(position);
    yield location;
  }
});

/// Provider to start/stop location updates to Firebase
final locationUpdateProvider = NotifierProvider<LocationUpdateNotifier, bool>(() {
  return LocationUpdateNotifier();
});

class LocationUpdateNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> startUpdates() async {
    if (state) return; // Already running
    
    final userAsync = ref.read(authStateProvider);
    await userAsync.whenData((user) async {
      if (user != null) {
        final locationService = ref.read(locationServiceProvider);
        await locationService.startLocationUpdates(user.uid);
        state = true;
      }
    });
  }

  void stopUpdates() {
    if (!state) return; // Not running
    
    final locationService = ref.read(locationServiceProvider);
    locationService.stopLocationUpdates();
    state = false;
  }
}

