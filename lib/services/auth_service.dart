import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';
import 'firebase_service.dart';
import 'local_storage_service.dart';
import 'audit_log_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final AuditLogService _auditLog = AuditLogService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('   ⚠️ No current user in Firebase Auth');
      return null;
    }

    debugPrint('   Fetching user document from Firestore: ${user.uid}');
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      debugPrint('   ⚠️ User document does not exist in Firestore');
      return null;
    }

    debugPrint('   ✅ User document found in Firestore');
    try {
      final userModel = UserModel.fromFirestore(doc);
      debugPrint('   ✅ UserModel created successfully');
      return userModel;
    } catch (e, stackTrace) {
      debugPrint('   ❌ Error creating UserModel from Firestore document');
      debugPrint('   Error: $e');
      debugPrint('   Stack trace: $stackTrace');
      debugPrint('   Document data: ${doc.data()}');
      rethrow;
    }
  }

  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('🔐 [LOGIN REQUEST] $timestamp');
    debugPrint('   Email: $email');
    debugPrint('   Password length: ${password.length} characters');

    try {
      debugPrint('   Attempting Firebase authentication...');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        debugPrint('   ✅ Firebase authentication successful');
        debugPrint('   User ID: ${credential.user!.uid}');
        debugPrint('   Email verified: ${credential.user!.emailVerified}');

        debugPrint('   Fetching user data from Firestore...');
        final userModel = await getCurrentUser();

        if (userModel != null) {
          debugPrint('   ✅ User data retrieved successfully');
          debugPrint('   User full name: ${userModel.fullName}');
          debugPrint('   User first name: ${userModel.firstName}');
          debugPrint('   User last name: ${userModel.lastName}');
          debugPrint('   User role: ${userModel.role.name}');
          debugPrint('   User email: ${userModel.email}');
          debugPrint('   User ID: ${userModel.uid}');
          debugPrint('   Is approved: ${userModel.isApproved}');
          debugPrint('   Is active: ${userModel.isActive}');
          debugPrint('   Profile complete: ${userModel.profileComplete}');

          // Save user data locally
          debugPrint('   Saving user data to local storage...');
          await LocalStorageService.saveUserData(userModel);

          debugPrint('   ✅ [LOGIN SUCCESS] $timestamp');
        } else {
          debugPrint('   ⚠️ User data not found in Firestore');
          debugPrint('   ✅ [LOGIN SUCCESS - No User Data] $timestamp');
        }

        return userModel;
      }

      debugPrint('   ❌ [LOGIN FAILED] No user credential returned');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('   ❌ [LOGIN FAILED] Firebase Auth Exception');
      debugPrint('   Error code: ${e.code}');
      debugPrint('   Error message: ${e.message}');
      debugPrint('   ❌ [LOGIN ERROR] $timestamp - ${e.code}: ${e.message}');
      throw Exception('Sign in failed: ${e.message}');
    } catch (e, stackTrace) {
      debugPrint('   ❌ [LOGIN FAILED] Unexpected error');
      debugPrint('   Error: $e');
      debugPrint('   Stack trace: $stackTrace');
      debugPrint('   ❌ [LOGIN ERROR] $timestamp - $e');
      throw Exception('Sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    debugPrint('🚪 [LOGOUT] Signing out user...');

    // Clear local storage
    await LocalStorageService.clearAll();

    // Sign out from Firebase
    await _auth.signOut();

    debugPrint('🚪 [LOGOUT] User signed out successfully');
  }

  Future<void> updateLastLogin() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({'lastLoginAt': FieldValue.serverTimestamp()});

      // Log audit event
      await _auditLog.logUserUpdate(
        userId: user.uid,
        message: 'Updated last login timestamp',
        changes: {'lastLoginAt': 'updated'},
      );
    }
  }
}
