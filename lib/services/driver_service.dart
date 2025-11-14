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
      if (kDebugMode) {
        debugPrint(
          '🚗 [DRIVER SERVICE] Updating availability: isOnline=$isOnline',
        );
      }

      // Update users/{userId}/driverDetails/isOnline directly
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'driverDetails.isOnline': isOnline,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (kDebugMode) {
        debugPrint('🚗 [DRIVER SERVICE] Availability updated successfully');
      }

      // Log audit event
      await _auditLog.logUserUpdate(
        userId: userId,
        message: isOnline ? 'Driver went online' : 'Driver went offline',
        changes: {'isOnline': isOnline},
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [DRIVER SERVICE] Error updating availability: $e');
      }
      rethrow;
    }
  }
}
