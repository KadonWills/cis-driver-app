import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/app_icons.dart';
import '../../core/config/app_config.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/location_provider.dart';
import '../../models/delivery_model.dart';
import '../../models/location_model.dart';
import 'package:intl/intl.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  PolylineAnnotationManager? polylineAnnotationManager;
  Timer? _locationUpdateTimer;
  LocationModel? _currentLocation;
  Map<String, dynamic>? _currentRoute;
  Map<String, dynamic>? _nextInstruction;
  bool _isFollowingUser = true; // Free-driving mode: follow user location

  @override
  void initState() {
    super.initState();
    // Start free-driving mode: track location and update camera
    _startFreeDriving();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  /// Start free-driving navigation mode
  void _startFreeDriving() {
    // Update location and camera every 2 seconds for smooth tracking
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && mapboxMap != null && _isFollowingUser) {
        final currentLocationAsync = ref.read(currentLocationProvider);
        currentLocationAsync.whenData((location) {
          _currentLocation = location;
          _updateCameraToLocation(location);
          _updateMarkers();
          _updateNavigationInstructions();
        });
      }
    });
  }

  /// Update camera to follow user location (free-driving mode)
  Future<void> _updateCameraToLocation(LocationModel location) async {
    if (mapboxMap == null || !_isFollowingUser) return;

    try {
      await mapboxMap?.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(location.longitude, location.latitude),
          ),
          zoom: 16.0, // Close zoom for navigation
          bearing:
              0.0, // Rotate map based on heading (heading not available in LocationModel)
          pitch: 45.0, // Slight pitch for better navigation view
        ),
        MapAnimationOptions(
          duration: 1000, // Smooth 1 second transition
          startDelay: 0,
        ),
      );
    } catch (e) {
      debugPrint('❌ [MAP SCREEN] Error updating camera: $e');
    }
  }

  /// Update navigation instructions from current route
  Future<void> _updateNavigationInstructions() async {
    if (_currentRoute == null || _currentLocation == null) {
      setState(() {
        _nextInstruction = null;
      });
      return;
    }

    try {
      final steps = _currentRoute!['steps'] as List?;
      if (steps == null || steps.isEmpty) return;

      // Find the next step based on current location
      // For simplicity, show the first step
      final nextStep = steps.first as Map<String, dynamic>;
      final maneuver = nextStep['maneuver'] as Map<String, dynamic>?;
      final instruction = nextStep['bannerInstructions'] as List?;

      if (maneuver != null || instruction != null) {
        String instructionText = 'Continue straight';
        if (instruction?.isNotEmpty == true) {
          try {
            final firstInstruction = instruction!.first as Map<String, dynamic>;
            final primary =
                firstInstruction['primary'] as Map<String, dynamic>?;
            instructionText =
                primary?['text'] as String? ?? 'Continue straight';
          } catch (e) {
            instructionText = 'Continue straight';
          }
        }

        setState(() {
          _nextInstruction = {
            'type': maneuver?['type'] ?? 'straight',
            'instruction': instructionText,
            'distance': nextStep['distance'] as double?,
          };
        });
      }
    } catch (e) {
      debugPrint('❌ [MAP SCREEN] Error updating instructions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDeliveriesAsync = ref.watch(activeDeliveriesProvider);
    final currentLocationAsync = ref.watch(currentLocationProvider);

    // Listen to deliveries changes in build method
    ref.listen(activeDeliveriesProvider, (previous, next) {
      next.whenData((deliveries) {
        if (mapboxMap != null) {
          _updateMapMarkers(deliveries);
        }
      });
    });

    // Listen to location changes
    ref.listen(currentLocationProvider, (previous, next) {
      next.whenData((location) {
        if (mapboxMap != null && pointAnnotationManager != null) {
          _updateUserLocationMarker(location);
        }
      });
    });

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Map
            _buildMap(),

            // Top Bar
            _buildTopBar(context, ref, currentLocationAsync),

            // Footer
            _buildFooter(context, activeDeliveriesAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final currentLocationAsync = ref.watch(currentLocationProvider);

    return currentLocationAsync.when(
      data: (location) => MapWidget(
        key: const ValueKey("mapWidget"),
        cameraOptions: CameraOptions(
          center: Point(
            coordinates: Position(location.longitude, location.latitude),
          ),
          zoom: 15.0,
        ),
        styleUri: MapboxStyles.MAPBOX_STREETS,
        textureView: true,
        onMapCreated: (MapboxMap map) {
          setState(() {
            mapboxMap = map;
          });
          _initializeMap(map);
        },
      ),
      loading: () => MapWidget(
        key: const ValueKey("mapWidget"),
        cameraOptions: CameraOptions(
          center: Point(
            coordinates: Position(
              -0.1276,
              51.5074,
            ), // London default [lng, lat]
          ),
          zoom: 15.0,
        ),
        styleUri: MapboxStyles.MAPBOX_STREETS,
        textureView: true,
        onMapCreated: (MapboxMap map) {
          setState(() {
            mapboxMap = map;
          });
          _initializeMap(map);
        },
      ),
      error: (_, __) => MapWidget(
        key: const ValueKey("mapWidget"),
        cameraOptions: CameraOptions(
          center: Point(
            coordinates: Position(
              -0.1276,
              51.5074,
            ), // London default [lng, lat]
          ),
          zoom: 15.0,
        ),
        styleUri: MapboxStyles.MAPBOX_STREETS,
        textureView: true,
        onMapCreated: (MapboxMap map) {
          setState(() {
            mapboxMap = map;
          });
          _initializeMap(map);
        },
      ),
    );
  }

  Future<void> _initializeMap(MapboxMap map) async {
    try {
      debugPrint('🗺️ [MAP SCREEN] Initializing map...');

      // Initialize annotation managers
      final pointAnnotationManager = await map.annotations
          .createPointAnnotationManager();
      final polylineAnnotationManager = await map.annotations
          .createPolylineAnnotationManager();

      debugPrint('🗺️ [MAP SCREEN] Annotation managers created');

      setState(() {
        this.pointAnnotationManager = pointAnnotationManager;
        this.polylineAnnotationManager = polylineAnnotationManager;
      });

      // Add custom marker images to style (latest Mapbox approach)
      await _addMarkerImagesToStyle(map);

      // Wait a bit more for managers to be ready
      await Future.delayed(const Duration(milliseconds: 300));

      // Load initial active deliveries
      final activeDeliveriesAsync = ref.read(activeDeliveriesProvider);
      activeDeliveriesAsync.whenData((deliveries) {
        debugPrint('🗺️ [MAP SCREEN] Initial deliveries: ${deliveries.length}');
        _updateMapMarkers(deliveries);
      });

      // Add user location marker
      final currentLocationAsync = ref.read(currentLocationProvider);
      currentLocationAsync.whenData((location) async {
        debugPrint(
          '🗺️ [MAP SCREEN] Initial location: ${location.latitude}, ${location.longitude}',
        );
        _updateUserLocationMarker(location);

        // Wait a bit for map to be fully loaded
        await Future.delayed(const Duration(milliseconds: 500));
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [MAP SCREEN] Error initializing map: $e');
      debugPrint('❌ [MAP SCREEN] Stack trace: $stackTrace');
    }
  }

  /// Add custom marker images to the map style using latest Mapbox approach
  /// Note: The latest Mapbox Maps SDK (v2.12) recommends using iconColor + textField
  /// for optimal performance, which we're already using. This method is a placeholder
  /// for future enhancements if custom images are needed.
  Future<void> _addMarkerImagesToStyle(MapboxMap map) async {
    try {
      // The latest Mapbox Maps SDK approach for Flutter recommends:
      // 1. Using iconColor for colored circle backgrounds (native, performant)
      // 2. Using textField for emoji/icon overlays
      // 3. This avoids the need for custom image assets and style.addImage calls

      // Our current implementation already follows this best practice
      debugPrint(
        '✅ [MAP SCREEN] Using latest Mapbox approach: iconColor + textField',
      );
    } catch (e) {
      debugPrint('⚠️ [MAP SCREEN] Could not initialize marker style: $e');
    }
  }

  Future<void> _updateUserLocationMarker(LocationModel location) async {
    if (pointAnnotationManager == null) return;
    // Update markers when location changes
    _updateMarkers();
  }

  /// Update markers using latest Mapbox Maps SDK approach
  /// Uses PointAnnotationOptions with iconColor and textField for optimal performance
  Future<void> _updateMarkers() async {
    if (pointAnnotationManager == null || mapboxMap == null) return;

    try {
      // Get current location
      final currentLocationAsync = ref.read(currentLocationProvider);
      final currentLocation = currentLocationAsync.value;

      // Get active deliveries
      final activeDeliveriesAsync = ref.read(activeDeliveriesProvider);
      final deliveries = activeDeliveriesAsync.value ?? [];

      // Only update if we have data to show
      if (currentLocation == null && deliveries.isEmpty) {
        return;
      }

      // Clear all existing markers
      await pointAnnotationManager?.deleteAll();

      final allMarkers = <PointAnnotationOptions>[];

      // Add user location marker using latest Mapbox Maps SDK approach
      // Recommended: Use iconColor + textField for optimal performance
      if (currentLocation != null) {
        allMarkers.add(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                currentLocation.longitude,
                currentLocation.latitude,
              ),
            ),
            // Latest approach: iconColor creates a colored circle background
            iconColor: Colors.blue.value,
            iconSize: 2.5, // Circle size
            // textField adds emoji/icon overlay on top
            textField: '📍',
            textColor: Colors.white.value,
            textSize: 20.0,
            textOffset: [0.0, 0.0],
          ),
        );
      }

      // Add delivery location markers using latest Mapbox approach
      for (final delivery in deliveries) {
        // Pickup location marker (green circle with package icon)
        allMarkers.add(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                delivery.pickupLocation.longitude,
                delivery.pickupLocation.latitude,
              ),
            ),
            iconColor: Colors.green.value,
            iconSize: 2.5,
            textField: '📦',
            textColor: Colors.white.value,
            textSize: 20.0,
            textOffset: [0.0, 0.0],
          ),
        );

        // Delivery location marker (red circle with house icon)
        allMarkers.add(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                delivery.deliveryLocation.longitude,
                delivery.deliveryLocation.latitude,
              ),
            ),
            iconColor: Colors.red.value,
            iconSize: 2.5,
            textField: '🏠',
            textColor: Colors.white.value,
            textSize: 20.0,
            textOffset: [0.0, 0.0],
          ),
        );
      }

      // Create all markers at once (batch operation for better performance)
      if (allMarkers.isNotEmpty && pointAnnotationManager != null) {
        await pointAnnotationManager!.createMulti(allMarkers);
        debugPrint('📍 [MAP SCREEN] Created ${allMarkers.length} markers');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [MAP SCREEN] Error updating markers: $e');
      debugPrint('❌ [MAP SCREEN] Stack trace: $stackTrace');
    }
  }

  Future<void> _updateMapMarkers(List<DeliveryModel> deliveries) async {
    if (pointAnnotationManager == null ||
        polylineAnnotationManager == null ||
        mapboxMap == null)
      return;

    try {
      // Step 1: Clear existing polylines
      await polylineAnnotationManager?.deleteAll();

      // Step 2: Add routes for each delivery
      for (final delivery in deliveries) {
        await _addRouteForDelivery(delivery);
      }

      // Step 3: Fit camera to show routes first
      if (deliveries.isNotEmpty) {
        await _fitCameraToRoute(deliveries);
      }

      // Step 4: Wait for routes and camera to fully render
      await Future.delayed(const Duration(milliseconds: 200));

      // Step 5: Add markers LAST - this ensures they render on top of everything
      await _updateMarkers();
    } catch (e) {
      debugPrint('❌ [MAP SCREEN] Error updating map markers: $e');
    }
  }

  Future<Map<String, dynamic>?> _addRouteForDelivery(
    DeliveryModel delivery,
  ) async {
    if (polylineAnnotationManager == null) return null;

    try {
      // Use current location as start if available, otherwise use pickup location
      final startLng =
          _currentLocation?.longitude ?? delivery.pickupLocation.longitude;
      final startLat =
          _currentLocation?.latitude ?? delivery.pickupLocation.latitude;

      // Fetch enhanced route from Mapbox Directions API with traffic data
      final routeData = await _getRouteData(
        startLng,
        startLat,
        delivery.deliveryLocation.longitude,
        delivery.deliveryLocation.latitude,
        includeTraffic: true,
        includeInstructions: true,
      );

      if (routeData['coordinates'] != null &&
          (routeData['coordinates'] as List).isNotEmpty) {
        final lineString = LineString(
          coordinates: routeData['coordinates'] as List<Position>,
        );

        // Determine route color based on traffic congestion
        int routeColor = AppTheme.accentColor.toARGB32();
        final congestion = routeData['congestion'] as List?;
        if (congestion != null && congestion.isNotEmpty) {
          // Calculate average congestion
          double avgCongestion = 0;
          int validValues = 0;
          for (var value in congestion) {
            if (value is num) {
              avgCongestion += value.toDouble();
              validValues++;
            }
          }
          if (validValues > 0) {
            avgCongestion /= validValues;
            // Color coding: green (low) -> yellow (medium) -> red (high)
            if (avgCongestion < 30) {
              routeColor = Colors.green.value; // Low traffic
            } else if (avgCongestion < 70) {
              routeColor = Colors.orange.value; // Medium traffic
            } else {
              routeColor = Colors.red.value; // High traffic
            }
          }
        }

        // Create route polyline with enhanced styling
        await polylineAnnotationManager?.create(
          PolylineAnnotationOptions(
            geometry: lineString,
            lineColor: routeColor,
            lineWidth: 6.0, // Increased width for better visibility
            lineOpacity: 0.9,
            linePattern: null, // Can add pattern for dashed lines if needed
          ),
        );

        // Store route metadata for display
        if (routeData['distance'] != null || routeData['duration'] != null) {
          final distanceKm = routeData['distance'] != null
              ? ((routeData['distance'] as double) / 1000).toStringAsFixed(2)
              : "N/A";
          final durationMin = routeData['duration'] != null
              ? ((routeData['duration'] as double) / 60).toStringAsFixed(1)
              : "N/A";
          debugPrint(
            '📍 [ROUTE] Delivery ${delivery.id}: $distanceKm km, $durationMin min',
          );
        }

        return routeData; // Return route data for navigation instructions
      }
      return null;
    } catch (e) {
      debugPrint('❌ [MAP SCREEN] Error adding route for delivery: $e');
      return null;
    }
  }

  /// Fetch route data from Mapbox Directions API with enhanced features
  Future<Map<String, dynamic>> _getRouteData(
    double startLng,
    double startLat,
    double endLng,
    double endLat, {
    bool includeAlternatives = false,
    bool includeTraffic = true,
    bool includeInstructions = true,
  }) async {
    try {
      // Get Mapbox access token
      String accessToken = AppConfig.mapboxAccessToken;
      if (accessToken.isEmpty) {
        accessToken =
            'pk.eyJ1Ijoia2Fkb254IiwiYSI6ImNtaDVtOTFydzA3a3oya3BtaGJwaWNqZDcifQ.UZGRaZCaSziQpUi61eKEGQ';
      }

      // Enhanced Mapbox Directions API endpoint with all features
      var url =
          'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/'
          '$startLng,$startLat;$endLng,$endLat'
          '?geometries=geojson'
          '&overview=full'
          '&steps=$includeInstructions'
          '&alternatives=$includeAlternatives'
          '&annotations=duration,distance,speed,congestion'
          '&language=en'
          '&voice_instructions=true'
          '&banner_instructions=true'
          '&access_token=$accessToken';

      debugPrint(
        '🗺️ [MAP SCREEN] Fetching enhanced route from Mapbox Directions API',
      );

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = (data['routes'] as List).first as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List;
          final distance = route['distance'] as double?;
          final duration = route['duration'] as double?;
          final weight = route['weight'] as double?;
          final legs = route['legs'] as List?;
          final steps = legs?.isNotEmpty == true
              ? (legs!.first as Map<String, dynamic>)['steps'] as List?
              : null;

          // Extract traffic congestion data if available
          final annotations = route['annotation'] as Map<String, dynamic>?;
          final congestion = annotations?['congestion'] as List?;

          // Convert coordinates to Position list
          final routePositions = <Position>[];
          for (final coord in coordinates) {
            if (coord is List && coord.length >= 2) {
              routePositions.add(
                Position(coord[0] as double, coord[1] as double),
              );
            }
          }

          final distanceKm = distance != null
              ? (distance / 1000).toStringAsFixed(2)
              : "N/A";
          final durationMin = duration != null
              ? (duration / 60).toStringAsFixed(1)
              : "N/A";
          debugPrint(
            '🗺️ [MAP SCREEN] Enhanced route fetched: ${routePositions.length} points, '
            'distance: $distanceKm km, duration: $durationMin min',
          );

          return {
            'coordinates': routePositions,
            'distance': distance,
            'duration': duration,
            'weight': weight,
            'steps': steps,
            'congestion': congestion,
            'alternatives': data['routes'] as List?,
          };
        }
      }
    } catch (e) {
      debugPrint('🗺️ [MAP SCREEN] Error fetching route: $e');
    }

    // Fallback to straight line
    return {
      'coordinates': [Position(startLng, startLat), Position(endLng, endLat)],
      'distance': null,
      'duration': null,
    };
  }

  /// Fit camera to show the entire route with padding
  Future<void> _fitCameraToRoute(List<DeliveryModel> deliveries) async {
    if (mapboxMap == null || deliveries.isEmpty) return;

    try {
      // Get route coordinates from the first delivery
      final delivery = deliveries.first;
      final routeData = await _getRouteData(
        delivery.pickupLocation.longitude,
        delivery.pickupLocation.latitude,
        delivery.deliveryLocation.longitude,
        delivery.deliveryLocation.latitude,
      );

      // Get current location
      final currentLocationAsync = ref.read(currentLocationProvider);
      final currentLocation = currentLocationAsync.value;

      // Collect all coordinates (route + markers)
      final allCoordinates = <Position>[];

      // Add route coordinates
      if (routeData['coordinates'] != null) {
        allCoordinates.addAll(routeData['coordinates'] as List<Position>);
      }

      // Add pickup location
      allCoordinates.add(
        Position(
          delivery.pickupLocation.longitude,
          delivery.pickupLocation.latitude,
        ),
      );

      // Add delivery location
      allCoordinates.add(
        Position(
          delivery.deliveryLocation.longitude,
          delivery.deliveryLocation.latitude,
        ),
      );

      // Add user location if available
      if (currentLocation != null) {
        allCoordinates.add(
          Position(currentLocation.longitude, currentLocation.latitude),
        );
      }

      if (allCoordinates.isEmpty) return;

      // Calculate bounds
      double north = -90, south = 90, east = -180, west = 180;
      for (final coord in allCoordinates) {
        final lat = coord.lat.toDouble();
        final lng = coord.lng.toDouble();
        if (lat > north) north = lat;
        if (lat < south) south = lat;
        if (lng > east) east = lng;
        if (lng < west) west = lng;
      }

      // Add padding (10% on each side)
      final latPadding = (north - south) * 0.1;
      final lngPadding = (east - west) * 0.1;

      north += latPadding;
      south -= latPadding;
      east += lngPadding;
      west -= lngPadding;

      // Calculate center and zoom to fit all coordinates
      final centerLng = (west + east) / 2;
      final centerLat = (south + north) / 2;

      // Calculate zoom level based on span
      final latSpan = north - south;
      final lngSpan = east - west;
      final maxSpan = latSpan > lngSpan ? latSpan : lngSpan;

      // Calculate appropriate zoom level (increased for better route clarity)
      double zoom = 14.0;
      if (maxSpan > 0) {
        // Adjust zoom based on span (larger span = lower zoom)
        // Increased base zoom for better clarity
        zoom = 16.0 - (maxSpan * 80);
        if (zoom < 12.0) zoom = 12.0; // Minimum zoom increased
        if (zoom > 17.0) zoom = 17.0; // Maximum zoom increased
      }

      // Smoothly fly to calculated position with enhanced animation
      await mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(centerLng, centerLat)),
          zoom: zoom,
          bearing: 0.0,
          pitch: 0.0,
        ),
        MapAnimationOptions(
          duration: 1500, // Smooth 1.5 second animation
          startDelay: 0,
        ),
      );
    } catch (e) {
      debugPrint('❌ [MAP SCREEN] Error fitting camera to route: $e');
      // Fallback to simple bounds calculation
      final bounds = _calculateBounds(deliveries);
      final centerLng = (bounds['west']! + bounds['east']!) / 2;
      final centerLat = (bounds['south']! + bounds['north']!) / 2;

      await mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(centerLng, centerLat)),
          zoom: 12.0,
        ),
        MapAnimationOptions(duration: 1000),
      );
    }
  }

  Map<String, double> _calculateBounds(List<DeliveryModel> deliveries) {
    double north = -90, south = 90, east = -180, west = 180;

    for (final delivery in deliveries) {
      final pickupLat = delivery.pickupLocation.latitude;
      final pickupLng = delivery.pickupLocation.longitude;
      final deliveryLat = delivery.deliveryLocation.latitude;
      final deliveryLng = delivery.deliveryLocation.longitude;

      if (pickupLat > north) north = pickupLat;
      if (pickupLat < south) south = pickupLat;
      if (pickupLng > east) east = pickupLng;
      if (pickupLng < west) west = pickupLng;

      if (deliveryLat > north) north = deliveryLat;
      if (deliveryLat < south) south = deliveryLat;
      if (deliveryLng > east) east = deliveryLng;
      if (deliveryLng < west) west = deliveryLng;
    }

    // Include user location in bounds
    final currentLocationAsync = ref.read(currentLocationProvider);
    final currentLocation = currentLocationAsync.value;
    if (currentLocation != null) {
      if (currentLocation.latitude > north) north = currentLocation.latitude;
      if (currentLocation.latitude < south) south = currentLocation.latitude;
      if (currentLocation.longitude > east) east = currentLocation.longitude;
      if (currentLocation.longitude < west) west = currentLocation.longitude;
    }

    return {'north': north, 'south': south, 'east': east, 'west': west};
  }

  /// Build navigation info display (distance to next turn, street name)
  Widget _buildNavigationInfo(AsyncValue<LocationModel> currentLocationAsync) {
    return currentLocationAsync.when(
      data: (location) {
        // Show next instruction if available, otherwise show current address
        if (_nextInstruction != null) {
          final distance = _nextInstruction!['distance'] as double?;
          final instruction =
              _nextInstruction!['instruction'] as String? ?? 'Continue';
          final distanceText = distance != null
              ? '${(distance / 1609.34).toStringAsFixed(1)} mi'
              : '';

          return Row(
            children: [
              if (distanceText.isNotEmpty) ...[
                Text(
                  distanceText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  instruction,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }

        // Default: show current address
        return Row(
          children: [
            HugeIcon(icon: AppIcons.arrowLeft, size: 16, color: Colors.red),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                location.address,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<LocationModel> currentLocationAsync,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.7),
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              // Back button in rounded square
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: HugeIcon(
                    icon: AppIcons.arrowLeft,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildNavigationInfo(currentLocationAsync)),
              ElevatedButton(
                onPressed: () => _pauseShift(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.blackBackground,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.white, width: 1),
                  ),
                ),
                child: const Text('Pause shift'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    AsyncValue<List<DeliveryModel>> deliveriesAsync,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.blackBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: deliveriesAsync.when(
            data: (deliveries) {
              if (deliveries.isEmpty) {
                return const Center(
                  child: Text(
                    'No active deliveries',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              final delivery = deliveries.first;
              final distance = delivery.estimatedDistance != null
                  ? '${(delivery.estimatedDistance! / 1609.34).toStringAsFixed(1)} mile'
                  : '0 mile';
              final time = delivery.estimatedDuration != null
                  ? '${delivery.estimatedDuration!.toInt()} min'
                  : '0 min';
              final eta = DateFormat(
                'h:mm a',
              ).format(delivery.requestedDeliveryTime);

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    distance,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        eta,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (_, __) => const Center(
              child: Text(
                'Error loading deliveries',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _pauseShift(BuildContext context, WidgetRef ref) {
    // Update user's isOnline status
    final userAsync = ref.read(authStateProvider);
    userAsync.whenData((user) {
      if (user != null) {
        // Update Firestore
        // This would be done through a service
      }
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Shift paused')));
  }
}
