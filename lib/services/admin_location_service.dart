import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_location_model.dart';
import '../models/location_model.dart';
import 'firebase_service.dart';

class AdminLocationService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// Stream of driver locations (for pulsating markers)
  Stream<List<UserLocationModel>> getDriverLocations() {
    debugPrint('📍 [ADMIN LOCATION] Starting stream for driver locations');
    
    return _firestore
        .collection('user_locations')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
      debugPrint('📍 [ADMIN LOCATION] Received ${snapshot.docs.length} location updates');
      
      final locations = <UserLocationModel>[];
      
      for (var doc in snapshot.docs) {
        try {
          // Fetch user data to get role and name
          final userDoc = await _firestore
              .collection('users')
              .doc(doc.id)
              .get();
          
          final userData = userDoc.data();
          final role = userData?['role'] as String?;
          
          // Only include drivers
          if (role == 'driver') {
            final userLocation = UserLocationModel.fromFirestore(doc, userData);
            if (userLocation.location != null) {
              locations.add(userLocation);
            }
          }
        } catch (e) {
          debugPrint('📍 [ADMIN LOCATION] Error processing location for ${doc.id}: $e');
        }
      }
      
      debugPrint('📍 [ADMIN LOCATION] Processed ${locations.length} driver locations');
      return locations;
    });
  }

  /// Stream of pharmacy/healthcare unit locations (static markers)
  Stream<List<PharmacyLocationModel>> getPharmacyLocations() {
    debugPrint('📍 [ADMIN LOCATION] Starting stream for pharmacy locations');
    
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'pharmacy')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
      debugPrint('📍 [ADMIN LOCATION] Received ${snapshot.docs.length} pharmacy users');
      
      final locations = <PharmacyLocationModel>[];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          
          // Try to get location from pharmacyDetails.location
          Map<String, dynamic>? locationData;
          String? pharmacyName;
          
          // Check pharmacyDetails.location
          final pharmacyDetails = data['pharmacyDetails'] as Map<String, dynamic>?;
          if (pharmacyDetails != null) {
            locationData = pharmacyDetails['location'] as Map<String, dynamic>?;
            pharmacyName = pharmacyDetails['pharmacyName'] as String?;
          }
          
          // Fallback: check if there's a location in user_locations
          if (locationData == null) {
            try {
              final locationDoc = await _firestore
                  .collection('user_locations')
                  .doc(doc.id)
                  .get();
              
              if (locationDoc.exists) {
                final locData = locationDoc.data();
                locationData = locData?['location'] as Map<String, dynamic>?;
              }
            } catch (e) {
              debugPrint('📍 [ADMIN LOCATION] Error fetching location for pharmacy ${doc.id}: $e');
            }
          }
          
          // Fallback: check coordinates field (for older data structure)
          if (locationData == null) {
            final coordinates = data['coordinates'] as Map<String, dynamic>?;
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
            
            locations.add(PharmacyLocationModel(
              userId: doc.id,
              name: name.isEmpty ? data['email'] as String? ?? 'Unknown Pharmacy' : name,
              location: LocationModel.fromMap(locationData),
            ));
          }
        } catch (e) {
          debugPrint('📍 [ADMIN LOCATION] Error processing pharmacy ${doc.id}: $e');
        }
      }
      
      debugPrint('📍 [ADMIN LOCATION] Processed ${locations.length} pharmacy locations');
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
