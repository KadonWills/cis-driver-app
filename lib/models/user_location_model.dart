import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';
import 'user_model.dart';

class UserLocationModel {
  final String userId;
  final String? userName;
  final UserRole? role;
  final LocationModel? location;
  final DateTime? lastUpdated;
  final bool isOnline;

  UserLocationModel({
    required this.userId,
    this.userName,
    this.role,
    this.location,
    this.lastUpdated,
    required this.isOnline,
  });

  /// Create from user document (new approach - location stored in user document)
  factory UserLocationModel.fromUserDocument(DocumentSnapshot doc, Map<String, dynamic> userData) {
    final driverDetails = userData['driverDetails'] as Map<String, dynamic>?;
    final locationData = driverDetails?['currentLocation'] as Map<String, dynamic>?;
    
    UserRole? role;
    String? userName;
    
    final roleString = userData['role'] as String?;
    if (roleString == 'driver') {
      role = UserRole.driver;
    } else if (roleString == 'pharmacy') {
      role = UserRole.pharmacy;
    } else if (roleString == 'admin') {
      role = UserRole.admin;
    }
    
    final firstName = userData['firstName'] as String? ?? '';
    final lastName = userData['lastName'] as String? ?? '';
    userName = '$firstName $lastName'.trim();
    if (userName.isEmpty) {
      userName = userData['email'] as String?;
    }

    return UserLocationModel(
      userId: doc.id,
      userName: userName,
      role: role,
      location: locationData != null ? LocationModel.fromMap(locationData) : null,
      lastUpdated: (driverDetails?['lastLocationUpdate'] as Timestamp?)?.toDate(),
      isOnline: driverDetails?['isOnline'] as bool? ?? false,
    );
  }

  /// Legacy factory for user_locations collection (kept for backward compatibility)
  factory UserLocationModel.fromFirestore(DocumentSnapshot doc, Map<String, dynamic>? userData) {
    final data = doc.data() as Map<String, dynamic>;
    final locationData = data['location'] as Map<String, dynamic>?;
    
    UserRole? role;
    String? userName;
    
    if (userData != null) {
      final roleString = userData['role'] as String?;
      if (roleString == 'driver') {
        role = UserRole.driver;
      } else if (roleString == 'pharmacy') {
        role = UserRole.pharmacy;
      } else if (roleString == 'admin') {
        role = UserRole.admin;
      }
      
      final firstName = userData['firstName'] as String? ?? '';
      final lastName = userData['lastName'] as String? ?? '';
      userName = '$firstName $lastName'.trim();
      if (userName.isEmpty) {
        userName = userData['email'] as String?;
      }
    }

    return UserLocationModel(
      userId: doc.id,
      userName: userName,
      role: role,
      location: locationData != null ? LocationModel.fromMap(locationData) : null,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
      isOnline: data['isOnline'] as bool? ?? false,
    );
  }
}

