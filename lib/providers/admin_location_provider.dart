import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_location_service.dart';
import '../models/user_location_model.dart';

final adminLocationServiceProvider = Provider<AdminLocationService>((ref) => AdminLocationService());

final driverLocationsProvider = StreamProvider<List<UserLocationModel>>((ref) {
  final adminLocationService = ref.watch(adminLocationServiceProvider);
  return adminLocationService.getDriverLocations();
});

final pharmacyLocationsProvider = StreamProvider<List<PharmacyLocationModel>>((ref) {
  final adminLocationService = ref.watch(adminLocationServiceProvider);
  return adminLocationService.getPharmacyLocations();
});
