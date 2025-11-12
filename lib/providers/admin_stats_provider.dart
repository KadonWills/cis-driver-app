import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_stats_service.dart';

final adminStatsServiceProvider = Provider<AdminStatsService>((ref) => AdminStatsService());

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final adminStatsService = ref.watch(adminStatsServiceProvider);
  return await adminStatsService.getStats();
});

