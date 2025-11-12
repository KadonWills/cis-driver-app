import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import 'firebase_service.dart';

class AdminStats {
  final int totalDeliveries;
  final int pendingDeliveries;
  final int activeDeliveries;
  final int completedDeliveries;
  final int failedDeliveries;
  final int cancelledDeliveries;
  final int urgentDeliveries;
  final int todayDeliveries;
  final int totalDrivers;
  final int activeDrivers;
  final int totalPharmacies;
  final int activePharmacies;
  final int totalAdmins;
  final int pendingApprovals;
  final double totalRevenue;
  final double todayRevenue;
  final double averageDeliveryCost;
  final double averageDeliveryTime; // in minutes
  final double averageDeliveryDistance; // in km
  final double averagePackagesPerDelivery;

  AdminStats({
    required this.totalDeliveries,
    required this.pendingDeliveries,
    required this.activeDeliveries,
    required this.completedDeliveries,
    required this.failedDeliveries,
    required this.cancelledDeliveries,
    required this.urgentDeliveries,
    required this.todayDeliveries,
    required this.totalDrivers,
    required this.activeDrivers,
    required this.totalPharmacies,
    required this.activePharmacies,
    required this.totalAdmins,
    required this.pendingApprovals,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.averageDeliveryCost,
    required this.averageDeliveryTime,
    required this.averageDeliveryDistance,
    required this.averagePackagesPerDelivery,
  });
}

class AdminStatsService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Helper function to safely extract int from map
  int _safeIntFromMap(Map<String, dynamic> map, String key, {int defaultValue = 0}) {
    try {
      final value = map[key];
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    } catch (e) {
      debugPrint('⚠️ [ADMIN STATS] Error extracting int for key $key: $e');
      return defaultValue;
    }
  }

  // Helper function to safely extract double from map
  double _safeDoubleFromMap(Map<String, dynamic> map, String key, {double defaultValue = 0.0}) {
    try {
      final value = map[key];
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    } catch (e) {
      debugPrint('⚠️ [ADMIN STATS] Error extracting double for key $key: $e');
      return defaultValue;
    }
  }

  Future<AdminStats> getStats() async {
    debugPrint('📊 [ADMIN STATS] Fetching app statistics...');
    
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _getDeliveryStats(),
        _getUserStats(),
        _getRevenueStats(),
        _getAdvancedStats(),
      ]);

      final deliveryStats = results[0];
      final userStats = results[1];
      final revenueStats = results[2];
      final advancedStats = results[3];

      final stats = AdminStats(
        totalDeliveries: _safeIntFromMap(deliveryStats, 'total'),
        pendingDeliveries: _safeIntFromMap(deliveryStats, 'pending'),
        activeDeliveries: _safeIntFromMap(deliveryStats, 'active'),
        completedDeliveries: _safeIntFromMap(deliveryStats, 'completed'),
        failedDeliveries: _safeIntFromMap(deliveryStats, 'failed'),
        cancelledDeliveries: _safeIntFromMap(deliveryStats, 'cancelled'),
        urgentDeliveries: _safeIntFromMap(deliveryStats, 'urgent'),
        todayDeliveries: _safeIntFromMap(deliveryStats, 'today'),
        totalDrivers: _safeIntFromMap(userStats, 'totalDrivers'),
        activeDrivers: _safeIntFromMap(userStats, 'activeDrivers'),
        totalPharmacies: _safeIntFromMap(userStats, 'totalPharmacies'),
        activePharmacies: _safeIntFromMap(userStats, 'activePharmacies'),
        totalAdmins: _safeIntFromMap(userStats, 'totalAdmins'),
        pendingApprovals: _safeIntFromMap(userStats, 'pendingApprovals'),
        totalRevenue: _safeDoubleFromMap(revenueStats, 'total'),
        todayRevenue: _safeDoubleFromMap(revenueStats, 'today'),
        averageDeliveryCost: _safeDoubleFromMap(advancedStats, 'avgCost'),
        averageDeliveryTime: _safeDoubleFromMap(advancedStats, 'avgTime'),
        averageDeliveryDistance: _safeDoubleFromMap(advancedStats, 'avgDistance'),
        averagePackagesPerDelivery: _safeDoubleFromMap(advancedStats, 'avgPackages'),
      );

      debugPrint('📊 [ADMIN STATS] Stats fetched successfully');
      return stats;
    } catch (e, stackTrace) {
      debugPrint('❌ [ADMIN STATS] Error fetching stats: $e');
      debugPrint('   Stack trace: $stackTrace');
      // Return empty stats on error
      return AdminStats(
        totalDeliveries: 0,
        pendingDeliveries: 0,
        activeDeliveries: 0,
        completedDeliveries: 0,
        failedDeliveries: 0,
        cancelledDeliveries: 0,
        urgentDeliveries: 0,
        todayDeliveries: 0,
        totalDrivers: 0,
        activeDrivers: 0,
        totalPharmacies: 0,
        activePharmacies: 0,
        totalAdmins: 0,
        pendingApprovals: 0,
        totalRevenue: 0.0,
        todayRevenue: 0.0,
        averageDeliveryCost: 0.0,
        averageDeliveryTime: 0.0,
        averageDeliveryDistance: 0.0,
        averagePackagesPerDelivery: 0.0,
      );
    }
  }

  Future<Map<String, dynamic>> _getDeliveryStats() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final deliveriesSnapshot = await _firestore
          .collection(AppConstants.deliveriesCollection)
          .get();

      int total = deliveriesSnapshot.docs.length;
      int pending = 0;
      int active = 0;
      int completed = 0;
      int failed = 0;
      int cancelled = 0;
      int urgent = 0;
      int today = 0;

      for (var doc in deliveriesSnapshot.docs) {
      try {
        final data = doc.data();
        if (data.isEmpty) continue;
        
        final status = data['status'] as String?;
        final priority = data['priority'] as String?;
        final createdAt = data['createdAt'] as Timestamp?;
        
        if (status != null) {
          if (status == AppConstants.deliveryStatusPending) {
            pending++;
          } else if (status == AppConstants.deliveryStatusAssigned ||
              status == AppConstants.deliveryStatusPickedUp ||
              status == AppConstants.deliveryStatusInTransit) {
            active++;
          } else if (status == AppConstants.deliveryStatusDelivered) {
            completed++;
          } else if (status == AppConstants.deliveryStatusFailed) {
            failed++;
          } else if (status == AppConstants.deliveryStatusCancelled) {
            cancelled++;
          }
        }
        
        if (priority != null && (priority == 'urgent' || priority == 'emergency')) {
          urgent++;
        }
        
        if (createdAt != null) {
          try {
            final createdDate = createdAt.toDate();
            if (createdDate.isAfter(startOfDay)) {
              today++;
            }
          } catch (e) {
            debugPrint('⚠️ [ADMIN STATS] Error parsing createdAt: $e');
          }
        }
      } catch (e) {
        debugPrint('⚠️ [ADMIN STATS] Error processing delivery ${doc.id}: $e');
      }
      }

      return {
        'total': total,
        'pending': pending,
        'active': active,
        'completed': completed,
        'failed': failed,
        'cancelled': cancelled,
        'urgent': urgent,
        'today': today,
      };
    } catch (e) {
      debugPrint('❌ [ADMIN STATS] Error in _getDeliveryStats: $e');
      return {
        'total': 0,
        'pending': 0,
        'active': 0,
        'completed': 0,
        'failed': 0,
        'cancelled': 0,
        'urgent': 0,
        'today': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _getUserStats() async {
    try {
      final usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .get();

      int totalDrivers = 0;
      int activeDrivers = 0;
      int totalPharmacies = 0;
      int activePharmacies = 0;
      int totalAdmins = 0;
      int pendingApprovals = 0;

      for (var doc in usersSnapshot.docs) {
      try {
        final data = doc.data();
        if (data.isEmpty) continue;
        
        final role = data['role'] as String?;
        final isActive = (data['isActive'] as bool?) ?? false;
        final isApproved = (data['isApproved'] as bool?) ?? false;

        if (role != null) {
          if (role == AppConstants.roleDriver) {
            totalDrivers++;
            if (isActive) activeDrivers++;
          } else if (role == AppConstants.rolePharmacy) {
            totalPharmacies++;
            if (isActive) activePharmacies++;
          } else if (role == AppConstants.roleAdmin) {
            totalAdmins++;
          }
        }
        
        if (!isApproved) {
          pendingApprovals++;
        }
      } catch (e) {
        debugPrint('⚠️ [ADMIN STATS] Error processing user ${doc.id}: $e');
      }
      }

      return {
        'totalDrivers': totalDrivers,
        'activeDrivers': activeDrivers,
        'totalPharmacies': totalPharmacies,
        'activePharmacies': activePharmacies,
        'totalAdmins': totalAdmins,
        'pendingApprovals': pendingApprovals,
      };
    } catch (e) {
      debugPrint('❌ [ADMIN STATS] Error in _getUserStats: $e');
      return {
        'totalDrivers': 0,
        'activeDrivers': 0,
        'totalPharmacies': 0,
        'activePharmacies': 0,
        'totalAdmins': 0,
        'pendingApprovals': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _getRevenueStats() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final allDeliveriesSnapshot = await _firestore
          .collection(AppConstants.deliveriesCollection)
          .where('status', isEqualTo: AppConstants.deliveryStatusDelivered)
          .get();

      double totalRevenue = 0.0;
      double todayRevenue = 0.0;

      for (var doc in allDeliveriesSnapshot.docs) {
      try {
        final data = doc.data();
        if (data.isEmpty) continue;
        
        double cost = 0.0;
        try {
          final costValue = data['cost'];
          if (costValue != null) {
            if (costValue is num) {
              cost = costValue.toDouble();
            } else if (costValue is String) {
              cost = double.tryParse(costValue) ?? 0.0;
            }
          }
        } catch (e) {
          debugPrint('⚠️ [ADMIN STATS] Error parsing cost: $e');
          cost = 0.0;
        }
        
        totalRevenue += cost;

        final deliveryTime = data['actualDeliveryTime'] as Timestamp?;
        if (deliveryTime != null) {
          try {
            final deliveryDate = deliveryTime.toDate();
            if (deliveryDate.isAfter(startOfDay)) {
              todayRevenue += cost;
            }
          } catch (e) {
            debugPrint('⚠️ [ADMIN STATS] Error parsing deliveryTime: $e');
          }
        }
      } catch (e) {
        debugPrint('⚠️ [ADMIN STATS] Error processing revenue delivery ${doc.id}: $e');
      }
      }

      return {
        'total': totalRevenue,
        'today': todayRevenue,
      };
    } catch (e) {
      debugPrint('❌ [ADMIN STATS] Error in _getRevenueStats: $e');
      return {
        'total': 0.0,
        'today': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> _getAdvancedStats() async {
    try {
      final deliveriesSnapshot = await _firestore
          .collection(AppConstants.deliveriesCollection)
          .get();

      double totalCost = 0.0;
      double totalTime = 0.0;
      double totalDistance = 0.0;
      int completedCount = 0;
      int totalPackages = 0;
      int deliveriesWithData = 0;

      for (var doc in deliveriesSnapshot.docs) {
      try {
        final data = doc.data();
        if (data.isEmpty) continue;
        
        final status = data['status'] as String?;
        
        // Safe cost parsing
        double cost = 0.0;
        try {
          final costValue = data['cost'];
          if (costValue != null) {
            if (costValue is num) {
              cost = costValue.toDouble();
            } else if (costValue is String) {
              cost = double.tryParse(costValue) ?? 0.0;
            }
          }
        } catch (e) {
          debugPrint('⚠️ [ADMIN STATS] Error parsing cost in advanced stats: $e');
        }
        
        totalCost += cost;
        
        // Safe packages parsing
        final packages = data['packages'];
        if (packages != null && packages is List) {
          totalPackages += packages.length;
        }

        if (status == AppConstants.deliveryStatusDelivered) {
          completedCount++;
          
          // Safe duration parsing
          double? actualDuration;
          try {
            final durationValue = data['actualDuration'];
            if (durationValue != null) {
              if (durationValue is num) {
                actualDuration = durationValue.toDouble();
              } else if (durationValue is String) {
                actualDuration = double.tryParse(durationValue);
              }
            }
          } catch (e) {
            debugPrint('⚠️ [ADMIN STATS] Error parsing actualDuration: $e');
          }
          
          // Safe distance parsing
          double? actualDistance;
          try {
            final distanceValue = data['actualDistance'];
            if (distanceValue != null) {
              if (distanceValue is num) {
                actualDistance = distanceValue.toDouble();
              } else if (distanceValue is String) {
                actualDistance = double.tryParse(distanceValue);
              }
            }
          } catch (e) {
            debugPrint('⚠️ [ADMIN STATS] Error parsing actualDistance: $e');
          }
          
          if (actualDuration != null && actualDuration > 0) {
            totalTime += actualDuration;
            deliveriesWithData++;
          }
          
          if (actualDistance != null && actualDistance > 0) {
            totalDistance += actualDistance / 1000; // Convert meters to km
          }
        }
      } catch (e) {
        debugPrint('⚠️ [ADMIN STATS] Error processing delivery in advanced stats ${doc.id}: $e');
      }
      }

      final avgCost = deliveriesSnapshot.docs.isNotEmpty 
          ? totalCost / deliveriesSnapshot.docs.length 
          : 0.0;
      final avgTime = deliveriesWithData > 0 
          ? totalTime / deliveriesWithData 
          : 0.0;
      final avgDistance = completedCount > 0 
          ? totalDistance / completedCount 
          : 0.0;
      final avgPackages = deliveriesSnapshot.docs.isNotEmpty 
          ? totalPackages / deliveriesSnapshot.docs.length 
          : 0.0;

      return {
        'avgCost': avgCost,
        'avgTime': avgTime,
        'avgDistance': avgDistance,
        'avgPackages': avgPackages,
      };
    } catch (e) {
      debugPrint('❌ [ADMIN STATS] Error in _getAdvancedStats: $e');
      return {
        'avgCost': 0.0,
        'avgTime': 0.0,
        'avgDistance': 0.0,
        'avgPackages': 0.0,
      };
    }
  }
}

