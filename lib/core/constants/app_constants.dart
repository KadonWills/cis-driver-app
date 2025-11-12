class AppConstants {
  // Collections
  static const String usersCollection = 'users';
  static const String deliveriesCollection = 'deliveries';
  static const String notificationsCollection = 'notifications';
  static const String messagesCollection = 'messages';
  static const String conversationsCollection = 'conversations';
  static const String contactMessagesCollection = 'contact_messages';

  // Storage Paths
  static const String driversDocumentsPath = 'drivers';
  static const String deliveryPhotosPath = 'deliveries';
  static const String deliverySignaturesPath = 'signatures';

  // Status Values
  static const String deliveryStatusPending = 'pending';
  static const String deliveryStatusAssigned = 'assigned';
  static const String deliveryStatusPickedUp = 'picked_up';
  static const String deliveryStatusInTransit = 'in_transit';
  static const String deliveryStatusDelivered = 'delivered';
  static const String deliveryStatusFailed = 'failed';
  static const String deliveryStatusCancelled = 'cancelled';
  static const String deliveryStatusReturned = 'returned';

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleDriver = 'driver';
  static const String rolePharmacy = 'pharmacy';

  // Location Update Interval (seconds)
  static const int locationUpdateInterval = 5;

  // Map Configuration
  static const double defaultZoomLevel = 15.0;
  static const double routeLineWidth = 5.0;
}

