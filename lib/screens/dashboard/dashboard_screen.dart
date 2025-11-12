import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/utils/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/delivery_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/admin_stats_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/delivery_model.dart';
import '../../models/user_model.dart';
import '../../models/location_model.dart';
import '../../services/admin_stats_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Start location updates when dashboard loads (only for drivers)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userAsync = ref.read(authStateProvider);
      userAsync.whenData((user) {
        if (user != null && user.role == UserRole.driver) {
          ref.read(locationUpdateProvider.notifier).startUpdates();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final activeDeliveriesAsync = ref.watch(activeDeliveriesProvider);
    final deliveryHistoryAsync = ref.watch(deliveryHistoryProvider);
    final currentLocationAsync = ref.watch(currentLocationProvider);
    final adminStatsAsync = ref.watch(adminStatsProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAdmin = user.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      extendBody: true, // Allows body to extend behind bottom navigation
      body: SafeArea(
        bottom: false, // Don't add bottom padding, we'll handle it
        child: Column(
          children: [
            // Header
                _buildHeader(
                  context,
                  ref,
                  userAsync,
                  currentLocationAsync,
                  isAdmin,
                ),

                // Stats Card (only for drivers)
                if (!isAdmin) _buildStatsCard(context, ref),

            // Content
            Expanded(
              child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      90,
                    ), // Bottom padding for floating nav
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                      children: isAdmin
                          ? [
                              // Admin Stats Cards with Charts
                              _buildDeliveryStatusCard(
                                context,
                                adminStatsAsync,
                              ),
                              const SizedBox(height: 16),
                              _buildUserActivityCard(context, adminStatsAsync),
                              const SizedBox(height: 16),
                              _buildRevenueCard(context, adminStatsAsync),
                              const SizedBox(height: 16),
                              _buildQuickStatsCards(context, adminStatsAsync),
                              const SizedBox(height: 16),
                              // Additional Stats Cards
                              _buildAdditionalStatsGrid(
                                context,
                                adminStatsAsync,
                              ),
                            ]
                          : [
                    // Current Deliveries
                              _buildCurrentDeliveries(
                                context,
                                activeDeliveriesAsync,
                              ),

                    const SizedBox(height: 24),

                              // Delivery History
                              _buildDeliveryHistory(
                                context,
                                deliveryHistoryAsync,
                              ),

                    const SizedBox(height: 24),

                              // Quick Actions (moved under delivery history)
                              _buildServices(context, ref),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
          bottomNavigationBar: _buildBottomNavigation(context, isAdmin),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<UserModel?> userAsync,
    AsyncValue<LocationModel> currentLocationAsync,
    bool isAdmin,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Profile Picture
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: userAsync.value?.driverDetails?.isOnline == true
                    ? AppTheme.accentColor
                    : AppTheme.borderColor,
                width: 2,
              ),
              image: userAsync.value?.profileImage != null
                  ? DecorationImage(
                      image: NetworkImage(userAsync.value!.profileImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: userAsync.value?.profileImage == null
                ? HugeIcon(
                    icon: AppIcons.user,
                    color: AppTheme.textPrimary,
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name and Address
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userAsync.value?.fullName ?? 'Loading...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                isAdmin
                    ? Text(
                        userAsync.value?.email ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                      )
                    : currentLocationAsync.when(
                        data: (location) => Text(
                          location.address.isNotEmpty
                              ? location.address
                              : 'Getting location...',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        loading: () => const Text(
                          'Getting location...',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        error: (_, __) => Text(
                          userAsync
                                  .value
                                  ?.driverDetails
                                  ?.currentLocation
                                  ?.address ??
                              'Location unavailable',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
          ),
          // Availability Toggle (only for drivers)
          if (!isAdmin) _buildAvailabilityToggle(context, ref),

          // Notifications
          IconButton(
            icon: Stack(
              children: [
                HugeIcon(
                  icon: AppIcons.bell,
                  color: AppTheme.textPrimary,
                  size: 24,
                ),
                // Badge would go here if there are unread notifications
              ],
            ),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, WidgetRef ref) {
    final activeDeliveriesAsync = ref.watch(activeDeliveriesProvider);
    final deliveryHistoryAsync = ref.watch(deliveryHistoryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Active Deliveries Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HugeIcon(
                      icon: AppIcons.car,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 11,
              color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  activeDeliveriesAsync.when(
                    data: (deliveries) => Text(
                      '${deliveries.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    loading: () => const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => const Text(
                      '0',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Container(
              width: 1,
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: AppTheme.borderColor,
            ),
            // Completed Today Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HugeIcon(
                      icon: AppIcons.checkmarkCircle,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 11,
              color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  deliveryHistoryAsync.when(
                    data: (deliveries) {
                      final now = DateTime.now();
                      final startOfDay = DateTime(now.year, now.month, now.day);
                      final todayCompleted = deliveries.where((d) {
                        if (d.status != DeliveryStatus.delivered) return false;
                        final deliveryTime = d.actualDeliveryTime ?? d.requestedDeliveryTime;
                        return deliveryTime.isAfter(startOfDay) || 
                               deliveryTime.isAtSameMomentAs(startOfDay);
                      }).length;
                      return Text(
                        '$todayCompleted',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => const Text(
                      '0',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentDeliveries(
    BuildContext context,
    AsyncValue<List<DeliveryModel>> deliveriesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Deliveries',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: deliveriesAsync.when(
            data: (deliveries) {
              if (deliveries.isEmpty) {
                return const Center(
                  child: Text(
                    'No active deliveries',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: deliveries.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12),
                    child: DeliveryCard(
                      delivery: deliveries[index],
                      isHorizontal: true,
                      onTap: () =>
                          context.push('/delivery/${deliveries[index].id}'),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
              child: Text(
                'Error loading deliveries',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServices(BuildContext context, WidgetRef ref) {
    final activeDeliveriesAsync = ref.watch(activeDeliveriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: activeDeliveriesAsync.when(
                data: (deliveries) => _buildServiceCard(
                  context,
                  AppIcons.map,
                  'Navigation',
                  deliveries.isEmpty ? 'No active delivery' : 'Navigate & Track',
                  AppTheme.accentColor,
                  deliveries.isEmpty ? null : () => context.push('/map'),
                  isEnabled: deliveries.isNotEmpty,
                ),
                loading: () => _buildServiceCard(
                  context,
                  AppIcons.map,
                  'Navigation',
                  'Loading...',
                  AppTheme.accentColor,
                  null,
                  isEnabled: false,
                ),
                error: (_, __) => _buildServiceCard(
                  context,
                  AppIcons.map,
                  'Navigation',
                  'No active delivery',
                  AppTheme.accentColor,
                  null,
                  isEnabled: false,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildServiceCard(
                context,
                AppIcons.list,
                'Deliveries',
                'View All',
                Colors.blue,
                () => context.push('/deliveries'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildServiceCard(
              context,
                AppIcons.lifebuoy,
                'Support',
                'Get Help',
                Colors.orange,
                () => context.push('/messaging'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(), // Empty space to maintain grid
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    List<List<dynamic>> icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback? onTap, {
    bool isEnabled = true,
  }) {
    final isDisabled = onTap == null || !isEnabled;
    
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
          padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDisabled 
                  ? AppTheme.borderColor 
                  : color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: isDisabled
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDisabled
                      ? AppTheme.borderColor.withOpacity(0.3)
                      : color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(
                  icon: icon,
                  color: isDisabled ? AppTheme.textSecondary : color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDisabled 
                      ? AppTheme.textSecondary 
                      : AppTheme.textPrimary,
                ),
              ),
            const SizedBox(height: 4),
            Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary.withOpacity(
                    isDisabled ? 0.5 : 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryHistory(
    BuildContext context,
    AsyncValue<List<DeliveryModel>> historyAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Delivery History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/deliveries'),
              child: const Text(
                'See all',
                style: TextStyle(color: AppTheme.accentColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        historyAsync.when(
          data: (deliveries) {
            if (deliveries.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No delivery history',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              );
            }
            // Limit to first 5 items for dashboard display
            final limitedDeliveries = deliveries.take(5).toList();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: limitedDeliveries.length,
              itemBuilder: (context, index) {
                // Alternate between yellow and blue for delivered items
                final delivery = limitedDeliveries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildHistoryCard(context, delivery, index),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: Text(
              'Error loading history',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ),
      ],
    );
  }

  // Delivery Status Card with Pie Chart
  Widget _buildDeliveryStatusCard(
    BuildContext context,
    AsyncValue<AdminStats> adminStatsAsync,
  ) {
    return adminStatsAsync.when(
      data: (stats) => _buildCard(
        title: 'Delivery Status',
        icon: AppIcons.document,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _buildDeliveryPieSections(stats),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(
                          'Pending',
                          Colors.orange,
                          stats.pendingDeliveries,
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          'Active',
                          Colors.blue,
                          stats.activeDeliveries,
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          'Completed',
                          Colors.green,
                          stats.completedDeliveries,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox(
                  'Total',
                  stats.totalDeliveries.toString(),
                  AppTheme.accentColor,
                ),
                _buildStatBox(
                  'Pending',
                  stats.pendingDeliveries.toString(),
                  Colors.orange,
                ),
                _buildStatBox(
                  'Active',
                  stats.activeDeliveries.toString(),
                  Colors.blue,
                ),
                _buildStatBox(
                  'Done',
                  stats.completedDeliveries.toString(),
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => _buildCard(
        title: 'Delivery Status',
        icon: AppIcons.document,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => _buildCard(
        title: 'Delivery Status',
        icon: AppIcons.document,
        child: Center(child: Text('Error: $error')),
      ),
    );
  }

  List<PieChartSectionData> _buildDeliveryPieSections(AdminStats stats) {
    final total = stats.totalDeliveries;
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey,
          title: 'No Data',
          radius: 60,
        ),
      ];
    }

    return [
      PieChartSectionData(
        value: stats.pendingDeliveries.toDouble(),
        color: Colors.orange,
        title:
            '${((stats.pendingDeliveries / total) * 100).toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: stats.activeDeliveries.toDouble(),
        color: Colors.blue,
        title:
            '${((stats.activeDeliveries / total) * 100).toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: stats.completedDeliveries.toDouble(),
        color: Colors.green,
        title:
            '${((stats.completedDeliveries / total) * 100).toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  // User Activity Card with Bar Chart
  Widget _buildUserActivityCard(
    BuildContext context,
    AsyncValue<AdminStats> adminStatsAsync,
  ) {
    return adminStatsAsync.when(
      data: (stats) => _buildCard(
        title: 'User Activity',
        icon: AppIcons.user,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (stats.totalDrivers +
                          stats.totalPharmacies +
                          stats.totalAdmins) *
                      1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text(
                                'Drivers',
                                style: TextStyle(fontSize: 12),
                              );
                            case 1:
                              return const Text(
                                'Pharmacies',
                                style: TextStyle(fontSize: 12),
                              );
                            case 2:
                              return const Text(
                                'Admins',
                                style: TextStyle(fontSize: 12),
                              );
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: stats.totalDrivers.toDouble(),
                          color: AppTheme.accentColor,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: stats.totalPharmacies.toDouble(),
                          color: Colors.purple,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: stats.totalAdmins.toDouble(),
                          color: Colors.orange,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox(
                  'Drivers',
                  stats.totalDrivers.toString(),
                  AppTheme.accentColor,
                ),
                _buildStatBox(
                  'Active',
                  stats.activeDrivers.toString(),
                  Colors.green,
                ),
                _buildStatBox(
                  'Pharmacies',
                  stats.totalPharmacies.toString(),
                  Colors.purple,
                ),
                _buildStatBox(
                  'Admins',
                  stats.totalAdmins.toString(),
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => _buildCard(
        title: 'User Activity',
        icon: AppIcons.user,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => _buildCard(
        title: 'User Activity',
        icon: AppIcons.user,
        child: Center(child: Text('Error: $error')),
      ),
    );
  }

  // Revenue Card
  Widget _buildRevenueCard(
    BuildContext context,
    AsyncValue<AdminStats> adminStatsAsync,
  ) {
    return adminStatsAsync.when(
      data: (stats) => _buildCard(
        title: 'Revenue Overview',
        icon: AppIcons.receipt,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildRevenueBox(
                    'Total Revenue',
                    '£${stats.totalRevenue.toStringAsFixed(2)}',
                    AppTheme.accentColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRevenueBox(
                    'Today',
                    '£${stats.todayRevenue.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.accentColor.withOpacity(0.1),
                    AppTheme.accentColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: AppIcons.receipt,
                      color: AppTheme.accentColor,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Revenue tracking active',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => _buildCard(
        title: 'Revenue Overview',
        icon: AppIcons.receipt,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => _buildCard(
        title: 'Revenue Overview',
        icon: AppIcons.receipt,
        child: Center(child: Text('Error: $error')),
      ),
    );
  }

  // Quick Stats Cards
  Widget _buildQuickStatsCards(
    BuildContext context,
    AsyncValue<AdminStats> adminStatsAsync,
  ) {
    return adminStatsAsync.when(
      data: (stats) => Row(
        children: [
          Expanded(
            child: _buildQuickStatCard(
              'Completion Rate',
              stats.totalDeliveries > 0
                  ? '${((stats.completedDeliveries / stats.totalDeliveries) * 100).toStringAsFixed(1)}%'
                  : '0%',
              AppIcons.document,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickStatCard(
              'Active Rate',
              stats.totalDrivers > 0
                  ? '${((stats.activeDrivers / stats.totalDrivers) * 100).toStringAsFixed(1)}%'
                  : '0%',
              AppIcons.user,
              AppTheme.accentColor,
            ),
          ),
        ],
      ),
      loading: () => const Row(
        children: [
          Expanded(child: Center(child: CircularProgressIndicator())),
          SizedBox(width: 12),
          Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  // Reusable Card Widget
  Widget _buildCard({
    required String title,
    required List<List<dynamic>> icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(icon: icon, color: AppTheme.accentColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRevenueBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
    String label,
    String value,
    List<List<dynamic>> icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Additional Stats Grid
  Widget _buildAdditionalStatsGrid(
    BuildContext context,
    AsyncValue<AdminStats> adminStatsAsync,
  ) {
    return adminStatsAsync.when(
      data: (stats) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildSmallStatCard(
                'Today\'s Deliveries',
                stats.todayDeliveries.toString(),
                AppIcons.clock,
                Colors.blue,
              ),
              _buildSmallStatCard(
                'Urgent Deliveries',
                stats.urgentDeliveries.toString(),
                AppIcons.clock,
                Colors.red,
              ),
              _buildSmallStatCard(
                'Failed',
                stats.failedDeliveries.toString(),
                AppIcons.close,
                Colors.red,
              ),
              _buildSmallStatCard(
                'Cancelled',
                stats.cancelledDeliveries.toString(),
                AppIcons.document,
                Colors.orange,
              ),
              _buildSmallStatCard(
                'Pending Approvals',
                stats.pendingApprovals.toString(),
                AppIcons.user,
                Colors.amber,
              ),
              _buildSmallStatCard(
                'Avg Cost',
                '£${stats.averageDeliveryCost.toStringAsFixed(2)}',
                AppIcons.receipt,
                Colors.green,
              ),
              _buildSmallStatCard(
                'Avg Time',
                '${stats.averageDeliveryTime.toStringAsFixed(0)} min',
                AppIcons.clock,
                AppTheme.accentColor,
              ),
              _buildSmallStatCard(
                'Avg Distance',
                '${stats.averageDeliveryDistance.toStringAsFixed(1)} km',
                AppIcons.map,
                Colors.purple,
              ),
              _buildSmallStatCard(
                'Avg Packages',
                stats.averagePackagesPerDelivery.toStringAsFixed(1),
                AppIcons.document,
                Colors.teal,
              ),
            ],
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildSmallStatCard(
    String label,
    String value,
    List<List<dynamic>> icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, bool isAdmin) {
    return SafeArea(
      top: false,
      child: Container(
        height: 70,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.blackBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: isAdmin
              ? [
                  // Admin navigation: Home, Map, Messages, Profile
            _buildNavItem(context, AppIcons.home, true, () {}),
            _buildNavItem(
              context,
              AppIcons.map,
              false,
                    () => context.push('/admin-map'),
            ),
            _buildNavItem(
              context,
                    AppIcons.chat,
              false,
                    () => context.push('/messaging'),
                  ),
                  _buildNavItem(
                    context,
                    AppIcons.user,
                    false,
                    () => context.push('/profile'),
                  ),
                ]
              : [
                  // Driver navigation: Home, Map, Add, Messages, Profile
                  _buildNavItem(context, AppIcons.home, true, () {}),
                  _buildNavItem(
                    context,
                    AppIcons.map,
                    false,
                    () => context.push('/map'),
                  ),
                  _buildNavItem(context, AppIcons.add, false, () {}),
            _buildNavItem(
              context,
              AppIcons.chat,
              false,
                    () => context.push('/messaging'),
            ),
            _buildNavItem(
              context,
              AppIcons.user,
              false,
              () => context.push('/profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    List<List<dynamic>> icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: HugeIcon(
        icon: icon,
        color: isActive ? AppTheme.accentColor : Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    DeliveryModel delivery,
    int index,
  ) {
    // Get border color based on delivery status
    final borderColor = _getStatusBorderColor(delivery.status);
    
    return GestureDetector(
      onTap: () => context.push('/delivery/${delivery.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryBackground, // Same background for all cards
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: borderColor,
              width: 3.0, // 3px thick left border
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${delivery.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      HugeIcon(
                        icon: delivery.status == DeliveryStatus.delivered
                            ? AppIcons.checkmarkCircle
                            : delivery.status == DeliveryStatus.inTransit ||
                                  delivery.status == DeliveryStatus.pickedUp
                            ? AppIcons.car
                            : AppIcons.clock,
                        size: 16,
                        color: delivery.status == DeliveryStatus.delivered
                            ? AppTheme.accentColor
                            : delivery.status == DeliveryStatus.inTransit ||
                                  delivery.status == DeliveryStatus.pickedUp
                            ? AppTheme.accentColor
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        delivery.statusDisplayText,
                        style: TextStyle(
                          fontSize: 14,
                          color: delivery.status == DeliveryStatus.delivered
                              ? AppTheme.accentColor
                              : delivery.status == DeliveryStatus.inTransit ||
                                    delivery.status == DeliveryStatus.pickedUp
                              ? AppTheme.accentColor
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(
                      delivery.actualDeliveryTime ??
                          delivery.requestedDeliveryTime,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            HugeIcon(icon: AppIcons.box, size: 48, color: AppTheme.accentColor),
          ],
        ),
      ),
    );
  }

  /// Get border color based on delivery status
  Color _getStatusBorderColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Colors.orange; // Orange for pending
      case DeliveryStatus.assigned:
        return Colors.blue; // Blue for assigned
      case DeliveryStatus.pickedUp:
        return Colors.cyan; // Cyan for picked up
      case DeliveryStatus.inTransit:
        return Colors.cyan; // Cyan for in transit
      case DeliveryStatus.delivered:
        return Colors.green; // Green for delivered
      case DeliveryStatus.failed:
        return Colors.red; // Red for failed
      case DeliveryStatus.cancelled:
        return Colors.grey; // Grey for cancelled
      case DeliveryStatus.returned:
        return Colors.orange; // Orange for returned
    }
  }

  Widget _buildAvailabilityToggle(BuildContext context, WidgetRef ref) {
    final userStreamAsync = ref.watch(currentUserStreamProvider);

    return userStreamAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        final isOnline = user.driverDetails?.isOnline ?? false;

        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: _CustomAvailabilityToggle(
            isOnline: isOnline,
            onChanged: (value) async {
              try {
                final driverService = ref.read(driverServiceProvider);
                await driverService.updateAvailabilityStatus(
                  userId: user.uid,
                  isOnline: value,
                );

                // Show feedback
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? 'You are now online' : 'You are now offline',
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: value ? Colors.green : Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating availability: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.only(right: 8),
        width: 80,
        height: 32,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Custom availability toggle widget with ONLINE/OFFLINE text and icon
class _CustomAvailabilityToggle extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onChanged;

  const _CustomAvailabilityToggle({
    required this.isOnline,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Dimensions
    const double toggleHeight = 40.0;
    const double toggleWidth = 120.0;
    const double thumbWidth = 56.0;
    const double thumbHeight = 32.0;
    const double padding = 4.0;

    // Calculate thumb position
    final double thumbLeft = isOnline
        ? toggleWidth - thumbWidth - padding
        : padding;

    // Calculate text position (opposite side of thumb)
    final double textLeft = isOnline ? padding : thumbWidth + padding * 2;

    return GestureDetector(
      onTap: () => onChanged(!isOnline),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        width: toggleWidth,
        height: toggleHeight,
        decoration: BoxDecoration(
          color: isOnline
              ? AppTheme.accentColor.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(toggleHeight / 2),
          border: Border.all(
            color: isOnline
                ? AppTheme.accentColor.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Status text on the opposite side of thumb
            Positioned(
              left: textLeft,
              top: 0,
              bottom: 0,
              right: isOnline ? thumbWidth + padding * 2 : padding,
              child: Center(
                child: Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isOnline
                        ? AppTheme.accentColor
                        : Colors.grey.withValues(alpha: 0.8),
                    letterSpacing: 0.8,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Animated thumb
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              left: thumbLeft,
              top: (toggleHeight - thumbHeight) / 2,
              child: Container(
                width: thumbWidth,
                height: thumbHeight,
                decoration: BoxDecoration(
                  color: isOnline ? AppTheme.accentColor : Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(thumbHeight / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: isOnline
                          ? AppTheme.accentColor.withValues(alpha: 0.3)
                          : Colors.transparent,
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: HugeIcon(
                    icon: isOnline ? AppIcons.checkmarkCircle : AppIcons.close,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
