import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/driver_service.dart';

final driverServiceProvider = Provider<DriverService>((ref) => DriverService());
