import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

enum DeliveryStatus {
  pending,
  assigned,
  pickedUp,
  inTransit,
  delivered,
  failed,
  cancelled,
  returned,
}

enum DeliveryPriority { low, standard, urgent, emergency }

class PackageDetails {
  final String description;
  final double? weight;
  final String? temperature;
  final bool isControlled;
  final double? value;
  final String? specialInstructions;

  PackageDetails({
    required this.description,
    this.weight,
    this.temperature,
    required this.isControlled,
    this.value,
    this.specialInstructions,
  });

  factory PackageDetails.fromMap(Map<String, dynamic> map) {
    return PackageDetails(
      description: map['description'] ?? '',
      weight: map['weight']?.toDouble(),
      temperature: map['temperature'],
      isControlled: map['isControlled'] ?? false,
      value: map['value']?.toDouble(),
      specialInstructions: map['specialInstructions'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      if (weight != null) 'weight': weight,
      if (temperature != null) 'temperature': temperature,
      'isControlled': isControlled,
      if (value != null) 'value': value,
      if (specialInstructions != null)
        'specialInstructions': specialInstructions,
    };
  }
}

class DeliveryModel {
  final String id;
  final String pharmacyId;
  final String? driverId;
  final List<PackageDetails> packages;
  final LocationModel pickupLocation;
  final String? pickupInstructions;
  final String pickupContactName;
  final String pickupContactPhone;
  final LocationModel deliveryLocation;
  final String? deliveryInstructions;
  final String recipientName;
  final String recipientPhone;
  final DateTime requestedPickupTime;
  final DateTime requestedDeliveryTime;
  final DateTime? actualPickupTime;
  final DateTime? actualDeliveryTime;
  final DeliveryStatus status;
  final DeliveryPriority priority;
  final double? estimatedDistance;
  final double? estimatedDuration;
  final double? actualDistance;
  final double? actualDuration;
  final double cost;
  final String paymentStatus;
  final bool requiresPhotoProof;
  final bool requiresSignature;
  final bool ageVerificationRequired;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  DeliveryModel({
    required this.id,
    required this.pharmacyId,
    this.driverId,
    required this.packages,
    required this.pickupLocation,
    this.pickupInstructions,
    required this.pickupContactName,
    required this.pickupContactPhone,
    required this.deliveryLocation,
    this.deliveryInstructions,
    required this.recipientName,
    required this.recipientPhone,
    required this.requestedPickupTime,
    required this.requestedDeliveryTime,
    this.actualPickupTime,
    this.actualDeliveryTime,
    required this.status,
    required this.priority,
    this.estimatedDistance,
    this.estimatedDuration,
    this.actualDistance,
    this.actualDuration,
    required this.cost,
    required this.paymentStatus,
    required this.requiresPhotoProof,
    required this.requiresSignature,
    required this.ageVerificationRequired,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory DeliveryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeliveryModel(
      id: doc.id,
      pharmacyId: data['pharmacyId'] ?? '',
      driverId: data['driverId'],
      packages:
          (data['packages'] as List<dynamic>?)
              ?.map((p) => PackageDetails.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      pickupLocation: LocationModel.fromMap(
        data['pickupLocation'] as Map<String, dynamic>,
      ),
      pickupInstructions: data['pickupInstructions'],
      pickupContactName: data['pickupContactName'] ?? '',
      pickupContactPhone: data['pickupContactPhone'] ?? '',
      deliveryLocation: LocationModel.fromMap(
        data['deliveryLocation'] as Map<String, dynamic>,
      ),
      deliveryInstructions: data['deliveryInstructions'],
      recipientName: data['recipientName'] ?? '',
      recipientPhone: data['recipientPhone'] ?? '',
      requestedPickupTime: (data['requestedPickupTime'] as Timestamp).toDate(),
      requestedDeliveryTime: (data['requestedDeliveryTime'] as Timestamp)
          .toDate(),
      actualPickupTime: data['actualPickupTime'] != null
          ? (data['actualPickupTime'] as Timestamp).toDate()
          : null,
      actualDeliveryTime: data['actualDeliveryTime'] != null
          ? (data['actualDeliveryTime'] as Timestamp).toDate()
          : null,
      status: _parseStatus(data['status'] ?? 'pending'),
      priority: _parsePriority(data['priority'] ?? 'standard'),
      estimatedDistance: data['estimatedDistance']?.toDouble(),
      estimatedDuration: data['estimatedDuration']?.toDouble(),
      actualDistance: data['actualDistance']?.toDouble(),
      actualDuration: data['actualDuration']?.toDouble(),
      cost: (data['cost'] ?? 0.0).toDouble(),
      paymentStatus: data['paymentStatus'] ?? 'pending',
      requiresPhotoProof: data['requiresPhotoProof'] ?? false,
      requiresSignature: data['requiresSignature'] ?? false,
      ageVerificationRequired: data['ageVerificationRequired'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pharmacyId': pharmacyId,
      if (driverId != null) 'driverId': driverId,
      'packages': packages.map((p) => p.toMap()).toList(),
      'pickupLocation': pickupLocation.toMap(),
      if (pickupInstructions != null) 'pickupInstructions': pickupInstructions,
      'pickupContactName': pickupContactName,
      'pickupContactPhone': pickupContactPhone,
      'deliveryLocation': deliveryLocation.toMap(),
      if (deliveryInstructions != null)
        'deliveryInstructions': deliveryInstructions,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'requestedPickupTime': Timestamp.fromDate(requestedPickupTime),
      'requestedDeliveryTime': Timestamp.fromDate(requestedDeliveryTime),
      if (actualPickupTime != null)
        'actualPickupTime': Timestamp.fromDate(actualPickupTime!),
      if (actualDeliveryTime != null)
        'actualDeliveryTime': Timestamp.fromDate(actualDeliveryTime!),
      'status': _statusToString(status),
      'priority': _priorityToString(priority),
      if (estimatedDistance != null) 'estimatedDistance': estimatedDistance,
      if (estimatedDuration != null) 'estimatedDuration': estimatedDuration,
      if (actualDistance != null) 'actualDistance': actualDistance,
      if (actualDuration != null) 'actualDuration': actualDuration,
      'cost': cost,
      'paymentStatus': paymentStatus,
      'requiresPhotoProof': requiresPhotoProof,
      'requiresSignature': requiresSignature,
      'ageVerificationRequired': ageVerificationRequired,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  static DeliveryStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return DeliveryStatus.pending;
      case 'assigned':
        return DeliveryStatus.assigned;
      case 'picked_up':
        return DeliveryStatus.pickedUp;
      case 'in_transit':
        return DeliveryStatus.inTransit;
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'failed':
        return DeliveryStatus.failed;
      case 'cancelled':
        return DeliveryStatus.cancelled;
      case 'returned':
        return DeliveryStatus.returned;
      default:
        return DeliveryStatus.pending;
    }
  }

  static String _statusToString(DeliveryStatus status) {
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

  static DeliveryPriority _parsePriority(String priority) {
    switch (priority) {
      case 'low':
        return DeliveryPriority.low;
      case 'standard':
        return DeliveryPriority.standard;
      case 'urgent':
        return DeliveryPriority.urgent;
      case 'emergency':
        return DeliveryPriority.emergency;
      default:
        return DeliveryPriority.standard;
    }
  }

  static String _priorityToString(DeliveryPriority priority) {
    switch (priority) {
      case DeliveryPriority.low:
        return 'low';
      case DeliveryPriority.standard:
        return 'standard';
      case DeliveryPriority.urgent:
        return 'urgent';
      case DeliveryPriority.emergency:
        return 'emergency';
    }
  }

  String get statusDisplayText {
    switch (status) {
      case DeliveryStatus.pending:
        return 'Looking for Courier';
      case DeliveryStatus.assigned:
        return 'Assigned';
      case DeliveryStatus.pickedUp:
        return 'Picked Up';
      case DeliveryStatus.inTransit:
        return 'In Delivery';
      case DeliveryStatus.delivered:
        return 'Received';
      case DeliveryStatus.failed:
        return 'Failed';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
      case DeliveryStatus.returned:
        return 'Returned';
    }
  }
}
