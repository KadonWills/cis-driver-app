import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/delivery_model.dart';
import '../core/constants/app_constants.dart';
import 'firebase_service.dart';
import 'audit_log_service.dart';

class DeliveryService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final AuditLogService _auditLog = AuditLogService();

  Stream<List<DeliveryModel>> getDriverDeliveries(String driverId) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('📦 [DELIVERY LOADING] getDriverDeliveries - $timestamp');
    debugPrint('   Driver ID: $driverId');
    debugPrint(
      '   Query: deliveries where driverId == $driverId, ordered by createdAt desc',
    );

    return _firestore
        .collection(AppConstants.deliveriesCollection)
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            '   ✅ Received snapshot: ${snapshot.docs.length} documents',
          );
          debugPrint(
            '   📊 Snapshot metadata: hasPendingWrites=${snapshot.metadata.hasPendingWrites}, isFromCache=${snapshot.metadata.isFromCache}',
          );

          try {
            final deliveries = snapshot.docs.map((doc) {
              try {
                return DeliveryModel.fromFirestore(doc);
              } catch (e, stackTrace) {
                debugPrint('   ❌ Error parsing delivery ${doc.id}: $e');
                debugPrint('   Stack trace: $stackTrace');
                rethrow;
              }
            }).toList();

            debugPrint(
              '   ✅ Successfully parsed ${deliveries.length} deliveries',
            );
            if (deliveries.isNotEmpty) {
              debugPrint(
                '   📋 Delivery IDs: ${deliveries.map((d) => d.id).join(", ")}',
              );
            }
            return deliveries;
          } catch (e, stackTrace) {
            debugPrint('   ❌ Error processing deliveries: $e');
            debugPrint('   Stack trace: $stackTrace');
            rethrow;
          }
        });
  }

  Stream<List<DeliveryModel>> getActiveDeliveries(String driverId) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('📦 [DELIVERY LOADING] getActiveDeliveries - $timestamp');
    debugPrint('   Driver ID: $driverId');
    debugPrint(
      '   Query: deliveries where driverId == $driverId AND status IN [assigned, picked_up, in_transit]',
    );

    return _firestore
        .collection(AppConstants.deliveriesCollection)
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: ['assigned', 'picked_up', 'in_transit'])
        .orderBy('status')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            '   ✅ Received snapshot: ${snapshot.docs.length} active deliveries',
          );
          debugPrint(
            '   📊 Snapshot metadata: hasPendingWrites=${snapshot.metadata.hasPendingWrites}, isFromCache=${snapshot.metadata.isFromCache}',
          );

          try {
            final deliveries = snapshot.docs.map((doc) {
              try {
                final delivery = DeliveryModel.fromFirestore(doc);
                debugPrint(
                  '   📦 Delivery ${delivery.id}: status=${delivery.status.name}',
                );
                return delivery;
              } catch (e, stackTrace) {
                debugPrint('   ❌ Error parsing active delivery ${doc.id}: $e');
                debugPrint('   Stack trace: $stackTrace');
                rethrow;
              }
            }).toList();

            debugPrint(
              '   ✅ Successfully parsed ${deliveries.length} active deliveries',
            );
            if (deliveries.isNotEmpty) {
              final statusCounts = <String, int>{};
              for (var d in deliveries) {
                statusCounts[d.status.name] =
                    (statusCounts[d.status.name] ?? 0) + 1;
              }
              debugPrint('   📊 Status breakdown: $statusCounts');
            }
            return deliveries;
          } catch (e, stackTrace) {
            debugPrint('   ❌ Error processing active deliveries: $e');
            debugPrint('   Stack trace: $stackTrace');
            rethrow;
          }
        });
  }

  Stream<List<DeliveryModel>> getPendingDeliveries() {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('📦 [DELIVERY LOADING] getPendingDeliveries - $timestamp');
    debugPrint(
      '   Query: deliveries where status == pending, ordered by createdAt desc',
    );

    return _firestore
        .collection(AppConstants.deliveriesCollection)
        .where('status', isEqualTo: AppConstants.deliveryStatusPending)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            '   ✅ Received snapshot: ${snapshot.docs.length} pending deliveries',
          );
          debugPrint(
            '   📊 Snapshot metadata: hasPendingWrites=${snapshot.metadata.hasPendingWrites}, isFromCache=${snapshot.metadata.isFromCache}',
          );

          try {
            final deliveries = snapshot.docs.map((doc) {
              try {
                return DeliveryModel.fromFirestore(doc);
              } catch (e, stackTrace) {
                debugPrint('   ❌ Error parsing pending delivery ${doc.id}: $e');
                debugPrint('   Stack trace: $stackTrace');
                rethrow;
              }
            }).toList();

            debugPrint(
              '   ✅ Successfully parsed ${deliveries.length} pending deliveries',
            );
            if (deliveries.isNotEmpty) {
              debugPrint(
                '   📋 Pending delivery IDs: ${deliveries.map((d) => d.id).join(", ")}',
              );
            }
            return deliveries;
          } catch (e, stackTrace) {
            debugPrint('   ❌ Error processing pending deliveries: $e');
            debugPrint('   Stack trace: $stackTrace');
            rethrow;
          }
        });
  }

  Stream<List<DeliveryModel>> getUnassignedDeliveries() {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('📦 [DELIVERY LOADING] getUnassignedDeliveries - $timestamp');
    debugPrint(
      '   Query: deliveries where status == pending AND driverId is null, ordered by createdAt desc',
    );

    return _firestore
        .collection(AppConstants.deliveriesCollection)
        .where('status', isEqualTo: AppConstants.deliveryStatusPending)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            '   ✅ Received snapshot: ${snapshot.docs.length} pending deliveries (filtering for unassigned)',
          );
          debugPrint(
            '   📊 Snapshot metadata: hasPendingWrites=${snapshot.metadata.hasPendingWrites}, isFromCache=${snapshot.metadata.isFromCache}',
          );

          try {
            // Filter in memory to get only deliveries without a driverId (unassigned)
            final deliveries = snapshot.docs
                .map((doc) {
                  try {
                    return DeliveryModel.fromFirestore(doc);
                  } catch (e, stackTrace) {
                    debugPrint('   ❌ Error parsing delivery ${doc.id}: $e');
                    debugPrint('   Stack trace: $stackTrace');
                    rethrow;
                  }
                })
                .where(
                  (delivery) =>
                      delivery.driverId == null || delivery.driverId!.isEmpty,
                )
                .toList();

            debugPrint(
              '   ✅ Successfully parsed ${deliveries.length} unassigned deliveries (from ${snapshot.docs.length} pending)',
            );
            if (deliveries.isNotEmpty) {
              debugPrint(
                '   📋 Unassigned delivery IDs: ${deliveries.map((d) => d.id).join(", ")}',
              );
            }
            return deliveries;
          } catch (e, stackTrace) {
            debugPrint('   ❌ Error processing unassigned deliveries: $e');
            debugPrint('   Stack trace: $stackTrace');
            rethrow;
          }
        });
  }

  Stream<DeliveryModel?> getDelivery(String deliveryId) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('📦 [DELIVERY LOADING] getDelivery - $timestamp');
    debugPrint('   Delivery ID: $deliveryId');

    return _firestore
        .collection(AppConstants.deliveriesCollection)
        .doc(deliveryId)
        .snapshots()
        .map((doc) {
          debugPrint('   📄 Document exists: ${doc.exists}');
          debugPrint(
            '   📊 Snapshot metadata: hasPendingWrites=${doc.metadata.hasPendingWrites}, isFromCache=${doc.metadata.isFromCache}',
          );

          if (!doc.exists) {
            debugPrint('   ⚠️ Delivery document does not exist: $deliveryId');
            return null;
          }

          try {
            final delivery = DeliveryModel.fromFirestore(doc);
            debugPrint('   ✅ Successfully loaded delivery: $deliveryId');
            debugPrint(
              '   📋 Delivery details: status=${delivery.status.name}, driverId=${delivery.driverId}, pharmacyId=${delivery.pharmacyId}',
            );
            return delivery;
          } catch (e, stackTrace) {
            debugPrint('   ❌ Error parsing delivery $deliveryId: $e');
            debugPrint('   Stack trace: $stackTrace');
            debugPrint('   Document data: ${doc.data()}');
            rethrow;
          }
        });
  }

  Future<void> acceptDelivery(String deliveryId, String driverId) async {
    await _firestore
        .collection(AppConstants.deliveriesCollection)
        .doc(deliveryId)
        .update({
          'driverId': driverId,
          'status': AppConstants.deliveryStatusAssigned,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    // Log audit event
    await _auditLog.logDeliveryUpdate(
      deliveryId: deliveryId,
      action: 'delivery_accepted',
      message: 'Driver accepted delivery',
      changes: {
        'driverId': driverId,
        'status': AppConstants.deliveryStatusAssigned,
      },
    );
  }

  Future<void> updateDeliveryStatus(
    String deliveryId,
    DeliveryStatus status, {
    String? driverId,
  }) async {
    final updates = <String, dynamic>{
      'status': _statusToString(status),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Set driverId if provided (when accepting/picking up delivery)
    if (driverId != null) {
      updates['driverId'] = driverId;
    }

    if (status == DeliveryStatus.pickedUp) {
      updates['actualPickupTime'] = FieldValue.serverTimestamp();
    } else if (status == DeliveryStatus.delivered) {
      updates['actualDeliveryTime'] = FieldValue.serverTimestamp();
    }

    await _firestore
        .collection(AppConstants.deliveriesCollection)
        .doc(deliveryId)
        .update(updates);

    // Log audit event
    final statusString = _statusToString(status);
    await _auditLog.logDeliveryUpdate(
      deliveryId: deliveryId,
      action: 'delivery_status_update',
      message: 'Updated delivery status to $statusString',
      changes: {
        'status': statusString,
        if (driverId != null) 'driverId': driverId,
        if (status == DeliveryStatus.pickedUp) 'actualPickupTime': 'set',
        if (status == DeliveryStatus.delivered) 'actualDeliveryTime': 'set',
      },
    );
  }

  Stream<List<DeliveryModel>> getAllDeliveries(String? currentUserId) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('📦 [DELIVERY LOADING] getAllDeliveries Stream - $timestamp');
    debugPrint('   Current User ID: $currentUserId');
    debugPrint(
      '   Query: all deliveries, ordered by createdAt desc (will filter by driverId)',
    );

    return _firestore
        .collection(AppConstants.deliveriesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map<List<DeliveryModel>>((snapshot) {
          debugPrint(
            '   ✅ Stream update: ${snapshot.docs.length} deliveries found',
          );
          debugPrint(
            '   📊 Snapshot metadata: hasPendingWrites=${snapshot.metadata.hasPendingWrites}, isFromCache=${snapshot.metadata.isFromCache}',
          );

          try {
            final allDeliveries = snapshot.docs
                .map((doc) {
                  try {
                    return DeliveryModel.fromFirestore(doc);
                  } catch (e, stackTrace) {
                    debugPrint('   ❌ Error parsing delivery ${doc.id}: $e');
                    debugPrint('   Stack trace: $stackTrace');
                    return null;
                  }
                })
                .whereType<DeliveryModel>()
                .toList();

            // Filter out deliveries assigned to other drivers
            // Show only: unassigned deliveries (driverId is null/empty) OR deliveries assigned to current user
            final filteredDeliveries = allDeliveries.where((delivery) {
              final driverId = delivery.driverId;
              // Include if unassigned or assigned to current user
              return driverId == null ||
                  driverId.isEmpty ||
                  (currentUserId != null && driverId == currentUserId);
            }).toList();

            debugPrint(
              '   ✅ Successfully parsed ${allDeliveries.length} deliveries',
            );
            debugPrint(
              '   🔍 Filtered to ${filteredDeliveries.length} deliveries (removed ${allDeliveries.length - filteredDeliveries.length} assigned to other drivers)',
            );
            if (filteredDeliveries.isNotEmpty) {
              debugPrint(
                '   📋 Delivery IDs: ${filteredDeliveries.map((d) => d.id).join(", ")}',
              );
            }
            return filteredDeliveries;
          } catch (e, stackTrace) {
            debugPrint('   ❌ Error processing deliveries: $e');
            debugPrint('   Stack trace: $stackTrace');
            return <DeliveryModel>[];
          }
        })
        .handleError((error, stackTrace) {
          if (error is FirebaseException) {
            if (error.code == 'failed-precondition' &&
                error.message?.contains('index') == true) {
              debugPrint('   ⚠️ Firestore index required for this query');
              debugPrint('   📝 Index creation URL: ${error.message}');
              debugPrint('   💡 Run: firebase deploy --only firestore:indexes');
            } else {
              debugPrint(
                '   ❌ Firebase error: ${error.code} - ${error.message}',
              );
            }
          } else {
            debugPrint('   ❌ Error in stream: $error');
          }
        });
  }

  Future<List<DeliveryModel>> getDeliveredDeliveries(
    String driverId,
    int limit,
  ) async {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('📦 [DELIVERY LOADING] getDeliveredDeliveries - $timestamp');
    debugPrint('   Driver ID: $driverId');
    debugPrint('   Limit: $limit');
    debugPrint(
      '   Query: deliveries where driverId == $driverId AND status == delivered (will sort by actualDeliveryTime in memory)',
    );

    try {
      // Query without orderBy to include all delivered deliveries (even those without actualDeliveryTime)
      // We'll sort by actualDeliveryTime in memory instead
      // Note: This avoids index requirements and ensures we get all delivered deliveries
      final snapshot = await _firestore
          .collection(AppConstants.deliveriesCollection)
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: AppConstants.deliveryStatusDelivered)
          .get();

      debugPrint(
        '   ✅ Query completed: ${snapshot.docs.length} delivered deliveries found',
      );
      debugPrint(
        '   📊 Snapshot metadata: hasPendingWrites=${snapshot.metadata.hasPendingWrites}, isFromCache=${snapshot.metadata.isFromCache}',
      );

      try {
        final deliveries = snapshot.docs.map((doc) {
          try {
            return DeliveryModel.fromFirestore(doc);
          } catch (e, stackTrace) {
            debugPrint('   ❌ Error parsing delivered delivery ${doc.id}: $e');
            debugPrint('   Stack trace: $stackTrace');
            rethrow;
          }
        }).toList();

        // Sort by actualDeliveryTime descending, with nulls last
        deliveries.sort((a, b) {
          if (a.actualDeliveryTime == null && b.actualDeliveryTime == null) {
            // Both null, sort by updatedAt descending
            return b.updatedAt.compareTo(a.updatedAt);
          }
          if (a.actualDeliveryTime == null) return 1; // nulls go to end
          if (b.actualDeliveryTime == null) return -1; // nulls go to end
          return b.actualDeliveryTime!.compareTo(a.actualDeliveryTime!);
        });

        // Apply limit after sorting
        final limitedDeliveries = deliveries.take(limit).toList();

        debugPrint(
          '   ✅ Successfully parsed ${limitedDeliveries.length} delivered deliveries (from ${deliveries.length} total)',
        );
        if (limitedDeliveries.isNotEmpty) {
          debugPrint(
            '   📋 Delivered delivery IDs: ${limitedDeliveries.map((d) => d.id).join(", ")}',
          );
          debugPrint(
            '   📅 Delivery times: ${limitedDeliveries.map((d) => d.actualDeliveryTime?.toIso8601String() ?? "null").join(", ")}',
          );
        }
        return limitedDeliveries;
      } catch (e, stackTrace) {
        debugPrint('   ❌ Error processing delivered deliveries: $e');
        debugPrint('   Stack trace: $stackTrace');
        rethrow;
      }
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' &&
          e.message?.contains('index') == true) {
        debugPrint('   ⚠️ Firestore index required for this query');
        debugPrint('   📝 Index creation URL: ${e.message}');
        debugPrint('   💡 Run: firebase deploy --only firestore:indexes');
        debugPrint('   ⚠️ Returning empty list until index is created');
        return [];
      }
      debugPrint(
        '   ❌ Firebase error executing query: ${e.code} - ${e.message}',
      );
      debugPrint('   Stack trace: ${StackTrace.current}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('   ❌ Error executing query: $e');
      debugPrint('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<double> getTodayEarnings(String driverId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await _firestore
        .collection(AppConstants.deliveriesCollection)
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: AppConstants.deliveryStatusDelivered)
        .where(
          'actualDeliveryTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .get();

    double total = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      total += (data['cost'] ?? 0.0).toDouble();
    }
    return total;
  }

  String _statusToString(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'pending';
      case DeliveryStatus.assigned:
        return 'assigned';
      case DeliveryStatus.pickedUp:
        return 'picked_up';
      case DeliveryStatus.inTransit:
        return 'in_transit';
      case DeliveryStatus.delivered:
        return 'delivered';
      case DeliveryStatus.failed:
        return 'failed';
      case DeliveryStatus.cancelled:
        return 'cancelled';
      case DeliveryStatus.returned:
        return 'returned';
    }
  }
}
