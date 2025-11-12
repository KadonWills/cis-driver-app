import 'package:go_router/go_router.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/delivery/delivery_details_screen.dart';
import '../../screens/map/map_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/earnings/earnings_screen.dart';
import '../../screens/delivery/delivery_list_screen.dart';
import '../../screens/messaging/messaging_screen.dart';
import '../../screens/admin/admin_map_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/delivery/:id',
      builder: (context, state) {
        final deliveryId = state.pathParameters['id']!;
        return DeliveryDetailsScreen(deliveryId: deliveryId);
      },
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/admin-map',
      builder: (context, state) => const AdminMapScreen(),
    ),
    GoRoute(
      path: '/deliveries',
      builder: (context, state) => const DeliveryListScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/earnings',
      builder: (context, state) => const EarningsScreen(),
    ),
    GoRoute(
      path: '/messaging',
      builder: (context, state) {
        final userId = state.uri.queryParameters['userId'];
        return MessagingScreen(otherUserId: userId);
      },
    ),
  ],
);

