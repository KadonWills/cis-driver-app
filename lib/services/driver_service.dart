import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import '../core/constants/app_constants.dart';
import 'audit_log_service.dart';

class DriverService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final AuditLogService _auditLog = AuditLogService();

  /// Update driver's online/availability status
  Future<void> updateAvailabilityStatus({
    required String userId,
    required bool isOnline,
  }) async {
    try {
      debugPrint(
        '🚗 [DRIVER SERVICE] Updating availability: isOnline=$isOnline',
      );

      // Update user_locations collection
      await _firestore.collection('user_locations').doc(userId).set({
        'isOnline': isOnline,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update users/{userId}/driverDetails/isOnline
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'driverDetails.isOnline': isOnline,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      debugPrint('🚗 [DRIVER SERVICE] Availability updated successfully');

      // Log audit event
      await _auditLog.logUserUpdate(
        userId: userId,
        message: isOnline ? 'Driver went online' : 'Driver went offline',
        changes: {'isOnline': isOnline},
      );
    } catch (e) {
      debugPrint('❌ [DRIVER SERVICE] Error updating availability: $e');
      rethrow;
    }
  }
}
