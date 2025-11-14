import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_location_model.dart';
import '../models/location_model.dart';
import 'firebase_service.dart';

class AdminLocationService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// Stream of driver locations (for pulsating markers)
  Stream<List<UserLocationModel>> getDriverLocations() {
    if (kDebugMode) {
      debugPrint('📍 [ADMIN LOCATION] Starting stream for driver locations');
    }

    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .where('driverDetails.isOnline', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
          if (kDebugMode) {
            debugPrint(
              '📍 [ADMIN LOCATION] Received ${snapshot.docs.length} driver users',
            );
          }

          final locations = <UserLocationModel>[];

          for (var doc in snapshot.docs) {
            try {
              final userData = doc.data();

              // Create UserLocationModel from user document
              final userLocation = UserLocationModel.fromUserDocument(
                doc,
                userData,
              );
              if (userLocation.location != null) {
                locations.add(userLocation);
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint(
                  '📍 [ADMIN LOCATION] Error processing location for ${doc.id}: $e',
                );
              }
            }
          }

          if (kDebugMode) {
            debugPrint(
              '📍 [ADMIN LOCATION] Processed ${locations.length} driver locations',
            );
          }
          return locations;
        });
  }

  /// Stream of pharmacy/healthcare unit locations (static markers)
  Stream<List<PharmacyLocationModel>> getPharmacyLocations() {
    if (kDebugMode) {
      debugPrint('📍 [ADMIN LOCATION] Starting stream for pharmacy locations');
    }

    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'pharmacy')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
          if (kDebugMode) {
            debugPrint(
              '📍 [ADMIN LOCATION] Received ${snapshot.docs.length} pharmacy users',
            );
          }

          final locations = <PharmacyLocationModel>[];

          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();

              // Try to get location from pharmacyDetails.location
              Map<String, dynamic>? locationData;
              String? pharmacyName;

              // Check pharmacyDetails.location
              final pharmacyDetails =
                  data['pharmacyDetails'] as Map<String, dynamic>?;
              if (pharmacyDetails != null) {
                locationData =
                    pharmacyDetails['location'] as Map<String, dynamic>?;
                pharmacyName = pharmacyDetails['pharmacyName'] as String?;
              }

              // Fallback: check driverDetails.currentLocation (for drivers who may have location)
              if (locationData == null) {
                final driverDetails =
                    data['driverDetails'] as Map<String, dynamic>?;
                if (driverDetails != null) {
                  locationData =
                      driverDetails['currentLocation'] as Map<String, dynamic>?;
                }
              }

              // Fallback: check coordinates field (for older data structure)
              if (locationData == null) {
                final coordinates =
                    data['coordinates'] as Map<String, dynamic>?;
                if (coordinates != null) {
                  final lat = coordinates['lat'] as num?;
                  final lng = coordinates['lng'] as num?;
                  if (lat != null && lng != null) {
                    locationData = {
                      'latitude': lat.toDouble(),
                      'longitude': lng.toDouble(),
                      'address': data['address'] as String? ?? '',
                      'city': data['city'] as String? ?? '',
                      'postcode': data['postcode'] as String? ?? '',
                      'country': 'UK',
                    };
                  }
                }
              }

              if (locationData != null) {
                final firstName = data['firstName'] as String? ?? '';
                final lastName = data['lastName'] as String? ?? '';
                final name = pharmacyName ?? '$firstName $lastName'.trim();

                locations.add(
                  PharmacyLocationModel(
                    userId: doc.id,
                    name: name.isEmpty
                        ? data['email'] as String? ?? 'Unknown Pharmacy'
                        : name,
                    location: LocationModel.fromMap(locationData),
                  ),
                );
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint(
                  '📍 [ADMIN LOCATION] Error processing pharmacy ${doc.id}: $e',
                );
              }
            }
          }

          if (kDebugMode) {
            debugPrint(
              '📍 [ADMIN LOCATION] Processed ${locations.length} pharmacy locations',
            );
          }
          return locations;
        });
  }
}

/// Model for pharmacy/healthcare unit locations
class PharmacyLocationModel {
  final String userId;
  final String name;
  final LocationModel location;

  PharmacyLocationModel({
    required this.userId,
    required this.name,
    required this.location,
  });
}
