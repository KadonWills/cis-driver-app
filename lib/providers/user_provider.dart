import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

/// Real-time stream of current user data from Firestore
/// Updates automatically when user document changes (e.g., isOnline status)
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) async* {
  final authService = ref.watch(authServiceProvider);
  final firestore = FirebaseService.firestore;

  await for (final user in authService.authStateChanges) {
    if (user == null) {
      yield null;
    } else {
      // Stream user document for real-time updates
      await for (final doc
          in firestore
              .collection(AppConstants.usersCollection)
              .doc(user.uid)
              .snapshots()) {
        if (!doc.exists) {
          yield null;
        } else {
          try {
            yield UserModel.fromFirestore(doc);
          } catch (e) {
            yield null;
          }
        }
      }
    }
  }
});
