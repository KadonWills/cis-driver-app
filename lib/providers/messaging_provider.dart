import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/messaging_service.dart';

final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService();
});

