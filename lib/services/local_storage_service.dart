import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class LocalStorageService {
  static const String _userJsonKey = 'cached_user_json';

  /// Save user data locally (converts Timestamps to ISO strings for JSON)
  static Future<void> saveUserData(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert to JSON-serializable map (Timestamps -> ISO strings)
      final userMap = _userModelToJson(user);
      final userJson = jsonEncode(userMap);
      
      await prefs.setString(_userJsonKey, userJson);
      
      if (kDebugMode) {
        debugPrint('💾 [LOCAL STORAGE] User data saved locally');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [LOCAL STORAGE] Error saving user data: $e');
      }
    }
  }

  /// Load user data from local storage
  static Future<UserModel?> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userJsonKey);
      
      if (userJson == null) {
        if (kDebugMode) {
          debugPrint('💾 [LOCAL STORAGE] No cached user data found');
        }
        return null;
      }
      
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      
      // Convert JSON map back to UserModel
      final user = _userModelFromJson(userMap);
      
      if (kDebugMode) {
        debugPrint('💾 [LOCAL STORAGE] User data loaded from cache');
      }
      return user;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [LOCAL STORAGE] Error loading user data: $e');
      }
      return null;
    }
  }

  /// Clear all local user data
  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userJsonKey);
      
      if (kDebugMode) {
        debugPrint('💾 [LOCAL STORAGE] User data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [LOCAL STORAGE] Error clearing user data: $e');
      }
    }
  }

  /// Clear all local storage (for logout)
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (kDebugMode) {
        debugPrint('💾 [LOCAL STORAGE] All local data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [LOCAL STORAGE] Error clearing all data: $e');
      }
    }
  }

  /// Convert UserModel to JSON-serializable map
  static Map<String, dynamic> _userModelToJson(UserModel user) {
    final map = user.toMap();
    
    // Convert Timestamps to ISO strings
    if (map['createdAt'] is Timestamp) {
      map['createdAt'] = (map['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (map['updatedAt'] is Timestamp) {
      map['updatedAt'] = (map['updatedAt'] as Timestamp).toDate().toIso8601String();
    }
    if (map['lastLoginAt'] is Timestamp) {
      map['lastLoginAt'] = (map['lastLoginAt'] as Timestamp).toDate().toIso8601String();
    }
    
    // Handle driverDetails timestamps
    if (map['driverDetails'] != null) {
      final driverDetails = map['driverDetails'] as Map<String, dynamic>;
      if (driverDetails['licenseExpiryDate'] is Timestamp) {
        driverDetails['licenseExpiryDate'] = 
            (driverDetails['licenseExpiryDate'] as Timestamp).toDate().toIso8601String();
      }
      if (driverDetails['vehicleInsuranceExpiry'] is Timestamp) {
        driverDetails['vehicleInsuranceExpiry'] = 
            (driverDetails['vehicleInsuranceExpiry'] as Timestamp).toDate().toIso8601String();
      }
      if (driverDetails['motExpiry'] is Timestamp) {
        driverDetails['motExpiry'] = 
            (driverDetails['motExpiry'] as Timestamp).toDate().toIso8601String();
      }
    }
    
    // Add uid for reconstruction
    map['uid'] = user.uid;
    
    return map;
  }

  /// Convert JSON map back to UserModel
  static UserModel _userModelFromJson(Map<String, dynamic> map) {
    // Convert ISO strings back to Timestamps
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }
    
    DateTime getRequiredDateTime(dynamic value, DateTime fallback) {
      final parsed = parseDateTime(value);
      return parsed ?? fallback;
    }
    
    // Convert driverDetails timestamps
    Map<String, dynamic>? driverDetailsMap;
    if (map['driverDetails'] != null) {
      driverDetailsMap = Map<String, dynamic>.from(map['driverDetails'] as Map);
      driverDetailsMap['licenseExpiryDate'] = Timestamp.fromDate(getRequiredDateTime(
        driverDetailsMap['licenseExpiryDate'],
        DateTime.now(),
      ));
      driverDetailsMap['vehicleInsuranceExpiry'] = Timestamp.fromDate(getRequiredDateTime(
        driverDetailsMap['vehicleInsuranceExpiry'],
        DateTime.now(),
      ));
      final motExpiry = parseDateTime(driverDetailsMap['motExpiry']);
      if (motExpiry != null) {
        driverDetailsMap['motExpiry'] = Timestamp.fromDate(motExpiry);
      }
    }
    
    // Create a Firestore-like document structure
    final data = Map<String, dynamic>.from(map);
    data['createdAt'] = Timestamp.fromDate(getRequiredDateTime(map['createdAt'], DateTime.now()));
    data['updatedAt'] = Timestamp.fromDate(getRequiredDateTime(map['updatedAt'], DateTime.now()));
    if (map['lastLoginAt'] != null) {
      final lastLogin = parseDateTime(map['lastLoginAt']);
      if (lastLogin != null) {
        data['lastLoginAt'] = Timestamp.fromDate(lastLogin);
      }
    }
    
    if (driverDetailsMap != null) {
      data['driverDetails'] = driverDetailsMap;
    }
    
    // Create UserModel directly from the data map
    // We'll use a helper that mimics fromFirestore but works with a map
    return _createUserModelFromMap(map['uid'] as String, data);
  }

  /// Create UserModel from a map (similar to fromFirestore but without DocumentSnapshot)
  static UserModel _createUserModelFromMap(String uid, Map<String, dynamic> data) {
    // Helper function to safely convert Timestamp to DateTime
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }
    
    // Helper function to get DateTime with fallback
    DateTime getRequiredTimestamp(dynamic value, DateTime fallback) {
      final parsed = parseTimestamp(value);
      return parsed ?? fallback;
    }
    
    UserRole parseRole(String role) {
      switch (role) {
        case 'admin':
          return UserRole.admin;
        case 'driver':
          return UserRole.driver;
        case 'pharmacy':
          return UserRole.pharmacy;
        default:
          return UserRole.driver;
      }
    }
    
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      role: parseRole(data['role'] ?? 'driver'),
      isApproved: data['isApproved'] ?? false,
      isActive: data['isActive'] ?? false,
      profileComplete: data['profileComplete'] ?? false,
      profileImage: data['profileImage'],
      phoneNumber: data['phoneNumber'],
      createdAt: getRequiredTimestamp(
        data['createdAt'],
        DateTime.now(),
      ),
      updatedAt: getRequiredTimestamp(
        data['updatedAt'],
        DateTime.now(),
      ),
      lastLoginAt: parseTimestamp(data['lastLoginAt']),
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
      driverDetails: data['driverDetails'] != null
          ? DriverDetails.fromMap(
              data['driverDetails'] as Map<String, dynamic>)
          : null,
    );
  }
}

