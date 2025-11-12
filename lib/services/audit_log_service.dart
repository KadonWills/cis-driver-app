import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

class AuditLogService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseService.auth;

  /// Log an audit event for data updates
  Future<void> logUpdate({
    required String action,
    required String collection,
    String? documentId,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('📝 [AUDIT LOG] No user authenticated, skipping audit log');
        return;
      }

      // Get user details
      final userId = user.uid;
      final userEmail = user.email ?? 'unknown@email.com';
      
      // Get user name from Firestore
      String userName = 'Unknown User';
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          final displayName = userData?['displayName'] as String?;
          final firstName = userData?['firstName'] as String? ?? '';
          final lastName = userData?['lastName'] as String? ?? '';
          
          if (displayName != null && displayName.trim().isNotEmpty) {
            userName = displayName;
          } else if (firstName.isNotEmpty) {
            userName = lastName.isNotEmpty ? '$firstName $lastName' : firstName;
          }
        }
      } catch (e) {
        debugPrint('📝 [AUDIT LOG] Error fetching user name: $e');
      }

      // Get IP address (for mobile, we'll use a placeholder or try to get it)
      String ipAddress = '::ffff:127.0.0.1'; // Default for mobile
      try {
        // Try to get IP from a service (optional, can be null)
        // For mobile apps, IP detection is limited
        // You could call an external service like ipify.org if needed
      } catch (e) {
        debugPrint('📝 [AUDIT LOG] Could not determine IP address: $e');
      }

      // Get user agent (device info)
      String userAgent = 'Mobile App';
      try {
        if (Platform.isAndroid) {
          userAgent = 'Android Mobile App';
        } else if (Platform.isIOS) {
          userAgent = 'iOS Mobile App';
        }
      } catch (e) {
        debugPrint('📝 [AUDIT LOG] Could not determine user agent: $e');
      }

      // Create audit log entry
      final auditLog = {
        'action': action,
        'collection': collection,
        'documentId': documentId,
        'message': message,
        'metadata': metadata ?? {},
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'ipAddress': ipAddress,
        'userAgent': userAgent,
        'source': 'mobile', // Source of the audit log entry
        'type': 'audit',
        'level': 'info',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to audit_logs collection
      await _firestore.collection('audit_logs').add(auditLog);
      
      debugPrint('📝 [AUDIT LOG] Logged: $action on $collection');
    } catch (e, stackTrace) {
      debugPrint('❌ [AUDIT LOG] Error logging audit: $e');
      debugPrint('   Stack trace: $stackTrace');
      // Don't throw - audit logging should not break the main operation
    }
  }

  /// Log a delivery update
  Future<void> logDeliveryUpdate({
    required String deliveryId,
    required String action,
    required String message,
    Map<String, dynamic>? changes,
  }) async {
    await logUpdate(
      action: action,
      collection: 'deliveries',
      documentId: deliveryId,
      message: message,
      metadata: {
        'deliveryId': deliveryId,
        'changes': changes ?? {},
      },
    );
  }

  /// Log a message update
  Future<void> logMessageUpdate({
    required String action,
    required String message,
    String? conversationId,
    String? messageId,
    Map<String, dynamic>? metadata,
  }) async {
    final logMetadata = <String, dynamic>{
      if (conversationId != null) 'conversationId': conversationId,
      if (messageId != null) 'messageId': messageId,
      ...?metadata,
    };

    await logUpdate(
      action: action,
      collection: 'messages',
      documentId: messageId,
      message: message,
      metadata: logMetadata,
    );
  }

  /// Log a user location update
  Future<void> logLocationUpdate({
    required String userId,
    Map<String, dynamic>? locationData,
  }) async {
    await logUpdate(
      action: 'location_update',
      collection: 'user_locations',
      documentId: userId,
      message: 'Updated user location',
      metadata: {
        'userId': userId,
        'locationData': locationData ?? {},
      },
    );
  }

  /// Log a user profile update
  Future<void> logUserUpdate({
    required String userId,
    required String message,
    Map<String, dynamic>? changes,
  }) async {
    await logUpdate(
      action: 'user_update',
      collection: 'users',
      documentId: userId,
      message: message,
      metadata: {
        'userId': userId,
        'changes': changes ?? {},
      },
    );
  }
}

