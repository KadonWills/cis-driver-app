import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/utils/app_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';
import '../../widgets/common/swipe_action_button.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/location_provider.dart';
import '../../models/delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/config/app_config.dart';
import 'package:intl/intl.dart';

class DeliveryDetailsScreen extends ConsumerStatefulWidget {
  final String deliveryId;

  const DeliveryDetailsScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  ConsumerState<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends ConsumerState<DeliveryDetailsScreen> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  PolylineAnnotationManager? polylineAnnotationManager;
  double? _routeDistance; // in meters
  double? _routeDuration; // in seconds

  @override
  Widget build(BuildContext context) {
    final deliveryAsync = ref.watch(deliveryProvider(widget.deliveryId));
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: deliveryAsync.when(
          data: (delivery) {
            if (delivery == null) {
              return const Center(
                child: Text('Delivery not found'),
              );
            }
            return _buildContent(context, ref, delivery, userAsync.value?.uid);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: Text('Error loading delivery'),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, DeliveryModel delivery, String? userId) {
    final distance = '0 mile'; // Calculate from current location
    final time = '1 min'; // Calculate from route
    final eta = DateFormat('h:mm a').format(delivery.requestedDeliveryTime);

    return Column(
      children: [
        // Map Snippet
        _buildMapSnippet(),
        
        // Top Information Bar
        _buildTopInfoBar(distance, time, eta),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery Card (Light Green)
                _buildDeliveryCard(delivery),
                
                const SizedBox(height: 24),
                
                // Delivery Information
                _buildDeliveryInfo(delivery),
                
                const SizedBox(height: 24),
                
                // Special Instructions
                if (delivery.deliveryInstructions != null ||
                    (delivery.packages.isNotEmpty &&
                        delivery.packages[0].specialInstructions != null))
                  _buildSpecialInstructions(delivery),
                
                const SizedBox(height: 24),
                
                // Swipe Action Button (Royal Blue)
                _buildSwipeActionButton(context, ref, delivery),
              ],
            ),
          ),
        ),
        
        // Footer
        _buildFooter(context, delivery),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, DeliveryModel delivery) {
    final userAsync = ref.watch(authStateProvider);
    
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
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(
                child: Text(
                  'Please login',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            
            // Determine contact text and action based on user role
            final isDriver = user.role.toString().split('.').last == 'driver';
            final contactText = isDriver ? 'Contact Pharmacy' : 'Contact Admin';
            
            // Get the pharmacy ID - this is the pharmacy that created the delivery
            Future<String?> getContactUserId() async {
              if (isDriver) {
                // For drivers, use the pharmacyId (pharmacy that created the delivery)
                final pharmacyId = delivery.pharmacyId;
                if (pharmacyId.isEmpty) {
                  debugPrint('⚠️ [DELIVERY DETAILS] pharmacyId is empty, trying createdBy');
                  // Fallback to createdBy if pharmacyId is empty
                  return delivery.createdBy.isNotEmpty ? delivery.createdBy : null;
                }
                debugPrint('📞 [DELIVERY DETAILS] Contacting pharmacy: $pharmacyId');
                return pharmacyId;
              } else {
                // For admins, get admin user ID
                return await _getAdminUserId();
              }
            }
            
            return FutureBuilder<String?>(
              future: getContactUserId(),
              builder: (context, snapshot) {
                final userId = snapshot.data;
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                
                return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: TextButton(
                        onPressed: (userId != null && !isLoading)
                            ? () => _navigateToMessaging(context, userId)
                            : null,
                        child: Text(
                          contactText,
                          style: TextStyle(
                            color: (userId != null && !isLoading) 
                                ? Colors.white 
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: HugeIcon(
                    icon: AppIcons.chat,
                    color: Colors.white,
                    size: 24,
                  ),
                          onPressed: (userId != null && !isLoading)
                              ? () => _navigateToMessaging(context, userId)
                              : null,
                ),
                IconButton(
                  icon: HugeIcon(
                    icon: AppIcons.phone,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => _makePhoneCall(delivery.recipientPhone),
                ),
              ],
            ),
          ],
                );
              },
            );
          },
          loading: () => const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          error: (_, __) => const Center(
            child: Text(
              'Error loading user',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _getAdminUserId() async {
    try {
      // Query Firestore for an admin user
      final adminQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      
      if (adminQuery.docs.isNotEmpty) {
        return adminQuery.docs.first.id;
      }
      
      // Fallback: check for specific admin emails
      final emailQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', whereIn: ['kapolw@gmail.com', 'admin@conceptillustrated.com'])
          .limit(1)
          .get();
      
      if (emailQuery.docs.isNotEmpty) {
        return emailQuery.docs.first.id;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting admin user ID: $e');
      return null;
    }
  }

  void _navigateToMessaging(BuildContext context, String otherUserId) async {
    debugPrint('💬 [DELIVERY DETAILS] Navigating to messaging with user ID: $otherUserId');
    if (context.mounted) {
      context.push('/messaging?userId=$otherUserId');
    }
  }

  Widget _buildMapSnippet() {
    final deliveryAsync = ref.watch(deliveryProvider(widget.deliveryId));

    return deliveryAsync.when(
      data: (delivery) {
        if (delivery == null) {
          return const SizedBox.shrink();
        }
        
    return Container(
          height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
                MapWidget(
                  key: ValueKey('delivery_map_${delivery.id}'),
                  cameraOptions: _calculateCameraOptions(delivery),
                  styleUri: MapboxStyles.MAPBOX_STREETS,
                  textureView: true,
                  onMapCreated: (MapboxMap map) async {
                    setState(() {
                      mapboxMap = map;
                    });
                    await _initializeMap(map, delivery);
                  },
                ),
                // Zoom controls
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildZoomControls(),
                ),
                // Map overlay with route info
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: _buildRouteInfoCard(delivery),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        height: 300,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Container(
        height: 300,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
              color: AppTheme.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
        ),
              child: Center(
                child: HugeIcon(
                  icon: AppIcons.map,
                  size: 48,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
    );
  }

  Future<void> _initializeMap(MapboxMap map, DeliveryModel delivery) async {
    try {
      // Initialize annotation managers
      pointAnnotationManager = await map.annotations.createPointAnnotationManager();
      polylineAnnotationManager = await map.annotations.createPolylineAnnotationManager();

      // Add custom marker for pickup location (pharmacy) - Blue
      final pickupPoint = Point(
        coordinates: Position(
          delivery.pickupLocation.longitude,
          delivery.pickupLocation.latitude,
        ),
      );

      await pointAnnotationManager?.create(
        PointAnnotationOptions(
          geometry: pickupPoint,
          iconImage: 'marker-icon',
          iconSize: 1.8,
          iconColor: Colors.blue.value,
          textField: 'P',
          textColor: Colors.white.value,
          textSize: 14.0,
          textOffset: [0.0, 0.0],
        ),
      );

      // Add custom marker for delivery location - Green
      final deliveryPoint = Point(
        coordinates: Position(
          delivery.deliveryLocation.longitude,
          delivery.deliveryLocation.latitude,
        ),
      );

      await pointAnnotationManager?.create(
        PointAnnotationOptions(
          geometry: deliveryPoint,
          iconImage: 'marker-icon',
          iconSize: 1.8,
          iconColor: Colors.green.value,
          textField: 'D',
          textColor: Colors.white.value,
          textSize: 14.0,
          textOffset: [0.0, 0.0],
        ),
      );

      // Fetch route from Mapbox Directions API
      final routeData = await _getRouteData(
        delivery.pickupLocation.longitude,
        delivery.pickupLocation.latitude,
        delivery.deliveryLocation.longitude,
        delivery.deliveryLocation.latitude,
      );

      if (routeData['coordinates'].isNotEmpty) {
        final lineString = LineString(coordinates: routeData['coordinates'] as List<Position>);

        await polylineAnnotationManager?.create(
          PolylineAnnotationOptions(
            geometry: lineString,
            lineColor: AppTheme.accentColor.value,
            lineWidth: 4.0,
            lineOpacity: 0.8,
          ),
        );

        // Store route distance and duration for display
        setState(() {
          _routeDistance = routeData['distance'] as double?;
          _routeDuration = routeData['duration'] as double?;
        });
      }

      // Optionally add current location marker
      final currentLocationAsync = ref.read(currentLocationProvider);
      currentLocationAsync.whenData((location) async {
        final currentPoint = Point(
          coordinates: Position(
            location.longitude,
            location.latitude,
          ),
        );

        await pointAnnotationManager?.create(
          PointAnnotationOptions(
            geometry: currentPoint,
            iconImage: 'marker-icon',
            iconSize: 1.5,
            iconColor: Colors.red.value,
            textField: 'You',
            textColor: Colors.white.value,
            textSize: 10.0,
            textOffset: [0.0, 0.0],
          ),
        );
      });
    } catch (e) {
      debugPrint('Error initializing map: $e');
    }
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _zoomIn(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: HugeIcon(
                  icon: AppIcons.plus,
                  size: 20,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          Container(
            height: 1,
            color: AppTheme.borderColor.withValues(alpha: 0.2),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _zoomOut(),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: HugeIcon(
                  icon: AppIcons.minus,
                  size: 20,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _zoomIn() async {
    if (mapboxMap == null) return;
    
    final currentCamera = await mapboxMap!.getCameraState();
    final currentZoom = currentCamera.zoom;
    
    await mapboxMap!.flyTo(
      CameraOptions(
        center: currentCamera.center,
        zoom: (currentZoom + 1).clamp(10.0, 20.0),
      ),
      MapAnimationOptions(duration: 200),
    );
  }

  Future<void> _zoomOut() async {
    if (mapboxMap == null) return;
    
    final currentCamera = await mapboxMap!.getCameraState();
    final currentZoom = currentCamera.zoom;
    
    await mapboxMap!.flyTo(
      CameraOptions(
        center: currentCamera.center,
        zoom: (currentZoom - 1).clamp(10.0, 20.0),
      ),
      MapAnimationOptions(duration: 200),
    );
  }

  CameraOptions _calculateCameraOptions(DeliveryModel delivery) {
    // Calculate center point between pickup and delivery
    final centerLng = (delivery.pickupLocation.longitude + delivery.deliveryLocation.longitude) / 2;
    final centerLat = (delivery.pickupLocation.latitude + delivery.deliveryLocation.latitude) / 2;

    // Calculate distance to determine zoom level
    final latDiff = (delivery.pickupLocation.latitude - delivery.deliveryLocation.latitude).abs();
    final lngDiff = (delivery.pickupLocation.longitude - delivery.deliveryLocation.longitude).abs();
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    // Adjust zoom based on distance
    double zoom = 14.0;
    if (maxDiff > 0.1) {
      zoom = 11.0;
    } else if (maxDiff > 0.05) {
      zoom = 12.0;
    } else if (maxDiff > 0.01) {
      zoom = 13.0;
    }

    return CameraOptions(
      center: Point(
        coordinates: Position(centerLng, centerLat),
      ),
      zoom: zoom,
    );
  }

  Widget _buildRouteInfoCard(DeliveryModel delivery) {
    // Use route data if available, otherwise calculate straight-line distance
    double distanceKm;
    int estimatedMinutes;
    
    if (_routeDistance != null && _routeDuration != null) {
      // Use actual route data from Mapbox
      distanceKm = _routeDistance! / 1000; // convert meters to km
      estimatedMinutes = (_routeDuration! / 60).round(); // convert seconds to minutes
    } else {
      // Fallback to calculated distance
      distanceKm = _calculateDistance(
        delivery.pickupLocation.latitude,
        delivery.pickupLocation.longitude,
        delivery.deliveryLocation.latitude,
        delivery.deliveryLocation.longitude,
      );
      // Estimate duration (assuming average speed of 30 km/h in city)
      estimatedMinutes = (distanceKm / 30 * 60).round();
    }
    
    final distanceText = distanceKm < 1.0 
        ? '${(distanceKm * 1000).toStringAsFixed(0)} m'
        : '${distanceKm.toStringAsFixed(1)} km';
    
    final durationText = estimatedMinutes < 60 
        ? '$estimatedMinutes min'
        : '${(estimatedMinutes / 60).toStringAsFixed(1)} h';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pickup location
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pickup: ${delivery.pickupLocation.address}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Route info
          Row(
            children: [
              HugeIcon(
                icon: AppIcons.map,
                size: 16,
                color: AppTheme.accentColor,
              ),
              const SizedBox(width: 6),
              Text(
                distanceText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              HugeIcon(
                icon: AppIcons.clock,
                size: 16,
                color: AppTheme.accentColor,
              ),
              const SizedBox(width: 6),
              Text(
                durationText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Delivery location
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delivery: ${delivery.deliveryLocation.address}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula to calculate distance between two points
    const double earthRadius = 6371; // Earth radius in kilometers
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }

  /// Fetch route data from Mapbox Directions API
  /// Returns a map with 'coordinates', 'distance' (meters), and 'duration' (seconds)
  Future<Map<String, dynamic>> _getRouteData(
    double startLng,
    double startLat,
    double endLng,
    double endLat,
  ) async {
    try {
      // Get Mapbox access token
      String accessToken = AppConfig.mapboxAccessToken;
      if (accessToken.isEmpty) {
        // Fallback to hardcoded token if not in config
        accessToken = 'pk.eyJ1Ijoia2Fkb254IiwiYSI6ImNtaDVtOTFydzA3a3oya3BtaGJwaWNqZDcifQ.UZGRaZCaSziQpUi61eKEGQ';
      }

      // Mapbox Directions API endpoint
      final url = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving/'
        '$startLng,$startLat;$endLng,$endLat'
        '?geometries=geojson'
        '&overview=full'
        '&access_token=$accessToken',
      );

      debugPrint('🗺️ [ROUTE] Fetching route from Mapbox Directions API');
      debugPrint('   Start: $startLat, $startLng');
      debugPrint('   End: $endLat, $endLng');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = (data['routes'] as List).first as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List;
          final distance = route['distance'] as double?; // in meters
          final duration = route['duration'] as double?; // in seconds

          // Convert coordinates to Position list
          final routePositions = <Position>[];
          for (final coord in coordinates) {
            if (coord is List && coord.length >= 2) {
              // GeoJSON format is [lng, lat]
              routePositions.add(Position(coord[0] as double, coord[1] as double));
            }
          }

          debugPrint('🗺️ [ROUTE] Route fetched successfully: ${routePositions.length} points');
          debugPrint('   Distance: ${distance?.toStringAsFixed(0)}m, Duration: ${duration?.toStringAsFixed(0)}s');
          
          return {
            'coordinates': routePositions,
            'distance': distance,
            'duration': duration,
          };
        } else {
          debugPrint('🗺️ [ROUTE] No routes found in response');
        }
      } else {
        debugPrint('🗺️ [ROUTE] Error fetching route: ${response.statusCode}');
        debugPrint('   Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('🗺️ [ROUTE] Exception fetching route: $e');
    }

    // Fallback to straight line if API call fails
    debugPrint('🗺️ [ROUTE] Using straight line fallback');
    final fallbackDistance = _calculateDistance(startLat, startLng, endLat, endLng) * 1000; // convert to meters
    final fallbackDuration = (fallbackDistance / 30 * 60).round(); // estimate at 30 km/h
    
    return {
      'coordinates': [
        Position(startLng, startLat),
        Position(endLng, endLat),
      ],
      'distance': fallbackDistance,
      'duration': fallbackDuration.toDouble(),
    };
  }

  Widget _buildTopInfoBar(String distance, String time, String eta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.primaryBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            distance,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          Row(
            children: [
              Text(
                eta,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              HugeIcon(
                icon: AppIcons.arrowRight,
                size: 16,
                color: AppTheme.accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(DeliveryModel delivery) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.deliveryCardGreen, // Light green from mockup
        borderRadius: BorderRadius.circular(16),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    HugeIcon(
                      icon: AppIcons.car,
                      size: 16,
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      delivery.statusDisplayText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Package icon with arrows (stylized)
          Stack(
            children: [
              HugeIcon(
                icon: AppIcons.box,
                size: 48,
                color: AppTheme.accentColor,
              ),
              Positioned(
                right: -4,
                top: -4,
                child: HugeIcon(
                  icon: AppIcons.arrowRight,
                  size: 16,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(DeliveryModel delivery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Service', 'Express Parcel'),
        const SizedBox(height: 12),
        _buildInfoRow('Receiver', delivery.recipientName, isBold: true),
        const SizedBox(height: 12),
        _buildInfoRow('Address', delivery.deliveryLocation.address),
        const SizedBox(height: 12),
        _buildInfoRow(
          'Package Type',
          delivery.packages.isNotEmpty
              ? delivery.packages[0].description
              : 'N/A',
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Payment Method', 'Cash on Delivery'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialInstructions(DeliveryModel delivery) {
    final instructions = delivery.deliveryInstructions ??
        (delivery.packages.isNotEmpty
            ? delivery.packages[0].specialInstructions
            : null);

    if (instructions == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Text(
        instructions,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }


  void _handleSwipeAction(
      BuildContext context, WidgetRef ref, DeliveryModel delivery, DeliveryStatus? newStatus) {
    if (newStatus == null) return;
    
    final deliveryService = ref.read(deliveryServiceProvider);
    final userAsync = ref.read(authStateProvider);
    final activeDeliveriesAsync = ref.read(activeDeliveriesProvider);

    userAsync.whenData((user) async {
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // When picking up (status changes to assigned), set the driverId
      // Also set driverId if status is already assigned but driverId is missing
      String? driverId;
      final isUnassigned = delivery.driverId == null || delivery.driverId!.isEmpty;
      
      // Check if user is trying to pick up a new delivery while having active deliveries
      if (newStatus == DeliveryStatus.assigned && isUnassigned) {
        // Check if user already has active deliveries
        await activeDeliveriesAsync.whenData((activeDeliveries) async {
          // Filter out the current delivery if it's already assigned to this user
          final otherActiveDeliveries = activeDeliveries
              .where((d) => d.id != delivery.id)
              .where((d) => d.status == DeliveryStatus.assigned || 
                           d.status == DeliveryStatus.pickedUp || 
                           d.status == DeliveryStatus.inTransit)
              .toList();
          
          if (otherActiveDeliveries.isNotEmpty) {
            debugPrint('❌ [DELIVERY] User already has ${otherActiveDeliveries.length} active delivery(ies)');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You already have ${otherActiveDeliveries.length} active delivery(ies). Please complete them before picking up a new one.'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
      return;
    }

          // If no other active deliveries, proceed with assignment
          driverId = user.uid;
          debugPrint('🚗 [DELIVERY] Assigning delivery to driver: $driverId');
          debugPrint('   Current status: ${delivery.status}, current driverId: ${delivery.driverId}');
          
          try {
            await deliveryService.updateDeliveryStatus(
              delivery.id,
              newStatus,
              driverId: driverId,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Delivery status updated to ${_getStatusText(newStatus)}'),
                  backgroundColor: AppTheme.accentColor,
                ),
              );
            }
          } catch (error) {
            debugPrint('❌ [DELIVERY] Error updating status: $error');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        });
        return; // Exit early since we handled it in whenData
      }
      
      // For non-assignment status changes, set driverId if needed
      if (delivery.status == DeliveryStatus.assigned && isUnassigned && newStatus == DeliveryStatus.assigned) {
        // Status is already assigned but driverId is missing - set it
        driverId = user.uid;
        debugPrint('🚗 [DELIVERY] Setting missing driverId: $driverId');
        debugPrint('   Current status: ${delivery.status}, current driverId: ${delivery.driverId}');
      }
      
      // Prevent updating if assigned to another driver
      if (!isUnassigned && delivery.driverId != user.uid) {
        debugPrint('❌ [DELIVERY] Delivery is assigned to another driver: ${delivery.driverId}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This delivery is already assigned to another driver'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        await deliveryService.updateDeliveryStatus(
          delivery.id,
          newStatus,
          driverId: driverId,
        );

        if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delivery status updated to ${_getStatusText(newStatus)}'),
              backgroundColor: AppTheme.accentColor,
            ),
      );
        }

      if (newStatus == DeliveryStatus.delivered) {
          Future.delayed(const Duration(seconds: 1), () {
            if (context.mounted) {
        context.pop();
      }
          });
        }
      } catch (error) {
        debugPrint('❌ [DELIVERY] Error updating status: $error');
        if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
      );
        }
      }
    });
  }

  String _getStatusText(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.assigned:
        return 'Assigned';
      case DeliveryStatus.pickedUp:
        return 'Picked Up';
      case DeliveryStatus.inTransit:
        return 'In Transit';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.failed:
        return 'Failed';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
      case DeliveryStatus.returned:
        return 'Returned';
    }
  }

  Widget _buildSwipeActionButton(
      BuildContext context, WidgetRef ref, DeliveryModel delivery) {
    final userAsync = ref.watch(authStateProvider);
    
    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const SizedBox.shrink();
        }

        // Check if delivery is assigned to current user or unassigned
        final isAssignedToUser = delivery.driverId == user.uid;
        final isUnassigned = delivery.driverId == null || delivery.driverId!.isEmpty;

        String buttonText;
        DeliveryStatus? nextStatus;

        switch (delivery.status) {
          case DeliveryStatus.pending:
            // Only show "Pick up" if unassigned or assigned to current user
            if (isUnassigned || isAssignedToUser) {
              buttonText = 'Pick up';
              nextStatus = DeliveryStatus.assigned;
            } else {
              // Delivery is assigned to another driver
              return const SizedBox.shrink();
            }
            break;
          case DeliveryStatus.assigned:
            // Only allow pickup if assigned to current user
            if (isAssignedToUser) {
              buttonText = 'Pick up the order';
              nextStatus = DeliveryStatus.pickedUp;
            } else {
              return const SizedBox.shrink();
            }
            break;
          case DeliveryStatus.pickedUp:
            // Only allow in_transit if assigned to current user
            if (isAssignedToUser) {
              buttonText = 'Start delivery';
              nextStatus = DeliveryStatus.inTransit;
            } else {
              return const SizedBox.shrink();
            }
            break;
          case DeliveryStatus.inTransit:
            // Only allow complete if assigned to current user
            if (isAssignedToUser) {
              buttonText = 'Complete delivery';
              nextStatus = DeliveryStatus.delivered;
            } else {
              return const SizedBox.shrink();
            }
            break;
          default:
            // For delivered, failed, cancelled, returned - don't show button
            return const SizedBox.shrink();
        }

        return SwipeActionButton(
          text: 'Slide to $buttonText',
          onSwipeComplete: () => _handleSwipeAction(context, ref, delivery, nextStatus),
          icon: AppIcons.arrowRight,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

