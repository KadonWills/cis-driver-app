import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../services/delivery_service.dart';
import '../models/delivery_model.dart';
import 'auth_provider.dart';

final deliveryServiceProvider = Provider<DeliveryService>((ref) => DeliveryService());

final activeDeliveriesProvider = StreamProvider<List<DeliveryModel>>((ref) {
  debugPrint('📦 [PROVIDER] activeDeliveriesProvider accessed');
  final deliveryService = ref.watch(deliveryServiceProvider);
  final userAsync = ref.watch(authStateProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) {
        debugPrint('   ⚠️ No user authenticated, returning empty list');
        return Stream.value([]);
      }
      debugPrint('   ✅ User authenticated: ${user.uid}, fetching active deliveries');
      return deliveryService.getActiveDeliveries(user.uid);
    },
    loading: () {
      debugPrint('   ⏳ Auth state loading, returning empty list');
      return Stream.value([]);
    },
    error: (error, stackTrace) {
      debugPrint('   ❌ Auth state error: $error');
      return Stream.value([]);
    },
  );
});

final pendingDeliveriesProvider = StreamProvider<List<DeliveryModel>>((ref) {
  debugPrint('📦 [PROVIDER] pendingDeliveriesProvider accessed');
  final deliveryService = ref.watch(deliveryServiceProvider);
  debugPrint('   ✅ Fetching pending deliveries');
  return deliveryService.getPendingDeliveries();
});

final unassignedDeliveriesProvider = StreamProvider<List<DeliveryModel>>((ref) {
  debugPrint('📦 [PROVIDER] unassignedDeliveriesProvider accessed');
  final deliveryService = ref.watch(deliveryServiceProvider);
  debugPrint('   ✅ Fetching unassigned deliveries');
  return deliveryService.getUnassignedDeliveries();
});

final deliveryHistoryProvider = StreamProvider<List<DeliveryModel>>((ref) {
  debugPrint('📦 [PROVIDER] deliveryHistoryProvider accessed - streaming all deliveries');
  final deliveryService = ref.watch(deliveryServiceProvider);
  final userAsync = ref.watch(authStateProvider);
  
  return userAsync.when(
    data: (user) {
      final currentUserId = user?.uid;
      debugPrint('   ✅ Streaming all deliveries for user: $currentUserId');
      return deliveryService.getAllDeliveries(currentUserId);
    },
    loading: () {
      debugPrint('   ⏳ Auth state loading, returning empty stream');
      return Stream.value(<DeliveryModel>[]);
    },
    error: (error, stackTrace) {
      debugPrint('   ❌ Auth state error: $error');
      return Stream.value(<DeliveryModel>[]);
    },
  );
});

final todayEarningsProvider = FutureProvider<double>((ref) async {
  final deliveryService = ref.watch(deliveryServiceProvider);
  final userAsync = ref.watch(authStateProvider);
  
  return userAsync.when(
    data: (user) async {
      if (user == null) return 0.0;
      return await deliveryService.getTodayEarnings(user.uid);
    },
    loading: () async => 0.0,
    error: (_, __) async => 0.0,
  );
});

final deliveryProvider = StreamProvider.family<DeliveryModel?, String>((ref, deliveryId) {
  debugPrint('📦 [PROVIDER] deliveryProvider accessed for delivery: $deliveryId');
  final deliveryService = ref.watch(deliveryServiceProvider);
  debugPrint('   ✅ Fetching delivery: $deliveryId');
  return deliveryService.getDelivery(deliveryId);
});

