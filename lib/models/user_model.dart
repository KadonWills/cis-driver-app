import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

enum UserRole {
  admin,
  driver,
  pharmacy,
}

class DriverDetails {
  final String licenseNumber;
  final DateTime licenseExpiryDate;
  final String vehicleType;
  final String vehicleRegistration;
  final DateTime vehicleInsuranceExpiry;
  final DateTime? motExpiry;
  final LocationModel? currentLocation;
  final bool isOnline;
  final double maxDeliveryRadius;
  final EmergencyContact emergencyContact;
  final BankDetails? bankDetails;
  final String? nationalInsuranceNumber;
  final Map<String, dynamic>? documents;

  DriverDetails({
    required this.licenseNumber,
    required this.licenseExpiryDate,
    required this.vehicleType,
    required this.vehicleRegistration,
    required this.vehicleInsuranceExpiry,
    this.motExpiry,
    this.currentLocation,
    required this.isOnline,
    required this.maxDeliveryRadius,
    required this.emergencyContact,
    this.bankDetails,
    this.nationalInsuranceNumber,
    this.documents,
  });

  factory DriverDetails.fromMap(Map<String, dynamic> map) {
    // Helper function to safely convert Timestamp to DateTime
    DateTime? _parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }
    
    // Helper function to get required DateTime with fallback
    DateTime _getRequiredTimestamp(dynamic value, DateTime fallback) {
      final parsed = _parseTimestamp(value);
      return parsed ?? fallback;
    }
    
    return DriverDetails(
      licenseNumber: map['licenseNumber'] ?? '',
      licenseExpiryDate: _getRequiredTimestamp(
        map['licenseExpiryDate'],
        DateTime.now(), // Fallback to current time if null
      ),
      vehicleType: map['vehicleType'] ?? '',
      vehicleRegistration: map['vehicleRegistration'] ?? '',
      vehicleInsuranceExpiry: _getRequiredTimestamp(
        map['vehicleInsuranceExpiry'],
        DateTime.now(), // Fallback to current time if null
      ),
      motExpiry: _parseTimestamp(map['motExpiry']),
      currentLocation: map['currentLocation'] != null
          ? LocationModel.fromMap(
              map['currentLocation'] as Map<String, dynamic>)
          : null,
      isOnline: map['isOnline'] ?? false,
      maxDeliveryRadius: (map['maxDeliveryRadius'] ?? 0.0).toDouble(),
      emergencyContact: map['emergencyContact'] != null
          ? EmergencyContact.fromMap(
              map['emergencyContact'] as Map<String, dynamic>)
          : EmergencyContact(
              name: '',
              phoneNumber: '',
              relationship: '',
            ),
      bankDetails: map['bankDetails'] != null
          ? BankDetails.fromMap(
              map['bankDetails'] as Map<String, dynamic>)
          : null,
      nationalInsuranceNumber: map['nationalInsuranceNumber'],
      documents: map['documents'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'licenseNumber': licenseNumber,
      'licenseExpiryDate': Timestamp.fromDate(licenseExpiryDate),
      'vehicleType': vehicleType,
      'vehicleRegistration': vehicleRegistration,
      'vehicleInsuranceExpiry': Timestamp.fromDate(vehicleInsuranceExpiry),
      if (motExpiry != null) 'motExpiry': Timestamp.fromDate(motExpiry!),
      if (currentLocation != null)
        'currentLocation': currentLocation!.toMap(),
      'isOnline': isOnline,
      'maxDeliveryRadius': maxDeliveryRadius,
      'emergencyContact': emergencyContact.toMap(),
      if (bankDetails != null) 'bankDetails': bankDetails!.toMap(),
      if (nationalInsuranceNumber != null)
        'nationalInsuranceNumber': nationalInsuranceNumber,
      if (documents != null) 'documents': documents,
    };
  }
}

class EmergencyContact {
  final String name;
  final String phoneNumber;
  final String relationship;

  EmergencyContact({
    required this.name,
    required this.phoneNumber,
    required this.relationship,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      relationship: map['relationship'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
    };
  }
}

class BankDetails {
  final String accountHolderName;
  final String accountNumber;
  final String sortCode;
  final String bankName;

  BankDetails({
    required this.accountHolderName,
    required this.accountNumber,
    required this.sortCode,
    required this.bankName,
  });

  factory BankDetails.fromMap(Map<String, dynamic> map) {
    return BankDetails(
      accountHolderName: map['accountHolderName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      sortCode: map['sortCode'] ?? '',
      bankName: map['bankName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'sortCode': sortCode,
      'bankName': bankName,
    };
  }
}

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final bool isApproved;
  final bool isActive;
  final bool profileComplete;
  final String? profileImage;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final List<String> fcmTokens;
  final DriverDetails? driverDetails;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isApproved,
    required this.isActive,
    required this.profileComplete,
    this.profileImage,
    this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    required this.fcmTokens,
    this.driverDetails,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Helper function to safely convert Timestamp to DateTime
    DateTime? _parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }
    
    // Helper function to get DateTime with fallback
    DateTime _getRequiredTimestamp(dynamic value, DateTime fallback) {
      final parsed = _parseTimestamp(value);
      return parsed ?? fallback;
    }
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      role: _parseRole(data['role'] ?? 'driver'),
      isApproved: data['isApproved'] ?? false,
      isActive: data['isActive'] ?? false,
      profileComplete: data['profileComplete'] ?? false,
      profileImage: data['profileImage'],
      phoneNumber: data['phoneNumber'],
      createdAt: _getRequiredTimestamp(
        data['createdAt'],
        DateTime.now(), // Fallback to current time if null
      ),
      updatedAt: _getRequiredTimestamp(
        data['updatedAt'],
        DateTime.now(), // Fallback to current time if null
      ),
      lastLoginAt: _parseTimestamp(data['lastLoginAt']),
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
      driverDetails: data['driverDetails'] != null
          ? DriverDetails.fromMap(
              data['driverDetails'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': _roleToString(role),
      'isApproved': isApproved,
      'isActive': isActive,
      'profileComplete': profileComplete,
      if (profileImage != null) 'profileImage': profileImage,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (lastLoginAt != null) 'lastLoginAt': Timestamp.fromDate(lastLoginAt!),
      'fcmTokens': fcmTokens,
      if (driverDetails != null) 'driverDetails': driverDetails!.toMap(),
    };
  }

  static UserRole _parseRole(String role) {
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

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.driver:
        return 'driver';
      case UserRole.pharmacy:
        return 'pharmacy';
    }
  }

  String get fullName => '$firstName $lastName';
}

