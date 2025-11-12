import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/location_model.dart';
import '../core/constants/app_constants.dart';

class LocationService {
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position> getCurrentPosition() async {
    bool hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  Future<LocationModel> getLocationFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return LocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          address: _formatAddress(place),
          postcode: place.postalCode ?? '',
          city: place.locality ?? place.subAdministrativeArea ?? '',
          county: place.administrativeArea,
          country: place.country ?? 'UK',
        );
      }
    } catch (e) {
      // Fallback if geocoding fails
    }

    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      address: '${position.latitude}, ${position.longitude}',
      postcode: '',
      city: '',
      country: 'UK',
    );
  }

  String _formatAddress(Placemark place) {
    final parts = <String>[];
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
      parts.add(place.subThoroughfare!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    return parts.join(', ');
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // in km
  }

  /// Update user location to Firestore every 15 seconds
  /// Updates both user_locations collection and users/{userId}/driverDetails/currentLocation
  Timer? _locationUpdateTimer;

  Future<void> startLocationUpdates(String userId) async {
    debugPrint('📍 [LOCATION] Starting location updates for user: $userId');
    
    // Stop any existing updates
    stopLocationUpdates();

    // Check permissions
    final hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      debugPrint('📍 [LOCATION] Location permission denied');
      return;
    }
    final firestore = FirebaseFirestore.instance;
    
    // Update immediately
    await _updateLocationToFirestore(userId, firestore);
    
    // Then update every 15 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      await _updateLocationToFirestore(userId, firestore);
    });
  }

  Future<void> _updateLocationToFirestore(String userId, FirebaseFirestore firestore) async {
    try {
      final position = await getCurrentPosition();
      final location = await getLocationFromPosition(position);
      
      // Update user_locations collection
      await firestore
          .collection('user_locations')
          .doc(userId)
          .set({
        'location': location.toMap(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'isOnline': true,
      }, SetOptions(merge: true));

      // Update users/{userId}/driverDetails/currentLocation
      await firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'driverDetails.currentLocation': location.toMap(),
        'driverDetails.lastLocationUpdate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('📍 [LOCATION] Updated location: ${location.latitude}, ${location.longitude}');
    } catch (e) {
      debugPrint('📍 [LOCATION] Error updating location: $e');
    }
  }

  void stopLocationUpdates() {
    debugPrint('📍 [LOCATION] Stopping location updates');
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }
}
