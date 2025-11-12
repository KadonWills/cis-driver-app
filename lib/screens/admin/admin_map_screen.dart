import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../core/utils/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_location_provider.dart';
import '../../models/user_location_model.dart';
import '../../services/admin_location_service.dart';

class AdminMapScreen extends ConsumerStatefulWidget {
  const AdminMapScreen({super.key});

  @override
  ConsumerState<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends ConsumerState<AdminMapScreen> with TickerProviderStateMixin {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  final Map<String, AnimationController> _pulseControllers = {};
  Timer? _updateTimer;

  final Map<String, UserLocationModel> _driverLocations = {};
  final Map<String, PharmacyLocationModel> _pharmacyLocations = {};

  @override
  void initState() {
    super.initState();
    // Start timer to update marker pulsing for drivers
    _updateTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted && pointAnnotationManager != null && _driverLocations.isNotEmpty) {
        _updateDriverMarkerPulses();
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    for (var controller in _pulseControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverLocationsAsync = ref.watch(driverLocationsProvider);
    final pharmacyLocationsAsync = ref.watch(pharmacyLocationsProvider);

    // Listen to location updates
    ref.listen(driverLocationsProvider, (previous, next) {
      next.whenData((locations) {
        if (mapboxMap != null && pointAnnotationManager != null) {
          _updateDriverMarkers(locations);
        }
      });
    });

    ref.listen(pharmacyLocationsProvider, (previous, next) {
      next.whenData((locations) {
        if (mapboxMap != null && pointAnnotationManager != null) {
          _updatePharmacyMarkers(locations);
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
            _buildTopBar(context),

            // Bottom Legend
            _buildBottomLegend(driverLocationsAsync, pharmacyLocationsAsync),

            // Bottom Info
            _buildBottomInfo(driverLocationsAsync, pharmacyLocationsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return MapWidget(
      key: const ValueKey("adminMapWidget"),
      cameraOptions: CameraOptions(
        center: Point(
          coordinates: Position(-0.1276, 51.5074), // London default
        ),
        zoom: 10.0,
      ),
      styleUri: MapboxStyles.MAPBOX_STREETS,
      textureView: true,
      onMapCreated: (MapboxMap map) {
        setState(() {
          mapboxMap = map;
        });
        _initializeMap(map);
      },
    );
  }

  Future<void> _initializeMap(MapboxMap map) async {
    try {
      pointAnnotationManager = await map.annotations.createPointAnnotationManager();
      
      // Start listening to locations
      final driverLocationsAsync = ref.read(driverLocationsProvider);
      final pharmacyLocationsAsync = ref.read(pharmacyLocationsProvider);
      
      driverLocationsAsync.whenData((locations) {
        _updateDriverMarkers(locations);
      });
      
      pharmacyLocationsAsync.whenData((locations) {
        _updatePharmacyMarkers(locations);
      });
    } catch (e) {
      debugPrint('❌ [ADMIN MAP] Error initializing map: $e');
    }
  }

  Future<void> _updateDriverMarkerPulses() async {
    if (pointAnnotationManager == null) return;

    try {
      // Get all existing markers
      final allMarkers = <PointAnnotationOptions>[];
      
      // Add pharmacy markers (static, no pulsing)
      for (var pharmacy in _pharmacyLocations.values) {
        allMarkers.add(PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              pharmacy.location.longitude,
              pharmacy.location.latitude,
            ),
          ),
          iconColor: Colors.purple.toARGB32(),
          textField: 'P',
          textSize: 12.0,
          iconImage: 'marker-icon',
          iconSize: 1.8, // Static size for pharmacies
        ));
      }
      
      // Add driver markers (with pulsing)
      for (var driver in _driverLocations.values) {
        if (driver.location == null) continue;
        
        // Get pulse value from animation controller
        final pulseValue = _pulseControllers[driver.userId]?.value ?? 0.5;
        // Pulse size between 1.5 and 2.5 for drivers (more dramatic pulsing)
        final iconSize = 1.5 + (pulseValue * 1.0);
        
        allMarkers.add(PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              driver.location!.longitude,
              driver.location!.latitude,
            ),
          ),
          iconColor: AppTheme.accentColor.toARGB32(),
          textField: 'D',
          textSize: 12.0,
          iconImage: 'marker-icon',
          iconSize: iconSize,
        ));
      }

      // Recreate all markers
      await pointAnnotationManager!.deleteAll();
      if (allMarkers.isNotEmpty) {
        await pointAnnotationManager!.createMulti(allMarkers);
      }
    } catch (e) {
      debugPrint('❌ [ADMIN MAP] Error updating marker pulses: $e');
    }
  }

  Future<void> _updateDriverMarkers(List<UserLocationModel> locations) async {
    if (pointAnnotationManager == null) return;

    try {
      // Update driver locations map
      _driverLocations.clear();
      for (var location in locations) {
        if (location.location != null) {
          _driverLocations[location.userId] = location;
        }
      }

      // Clean up controllers for removed drivers
      final currentDriverIds = locations.map((l) => l.userId).toSet();
      final controllersToRemove = _pulseControllers.keys
          .where((id) => !currentDriverIds.contains(id))
          .toList();
      for (var userId in controllersToRemove) {
        _pulseControllers[userId]?.dispose();
        _pulseControllers.remove(userId);
      }

      // Create pulsing animation controllers for new drivers
      for (var location in locations) {
        if (location.location == null) continue;
        
        if (!_pulseControllers.containsKey(location.userId)) {
          final controller = AnimationController(
            vsync: this,
            duration: const Duration(seconds: 2),
          )..repeat();
          _pulseControllers[location.userId] = controller;
        }
      }

      // Update all markers (drivers + pharmacies)
      await _updateDriverMarkerPulses();
      
      // Fit camera to show all markers
      await _fitCameraToAllMarkers();
    } catch (e) {
      debugPrint('❌ [ADMIN MAP] Error updating driver markers: $e');
    }
  }

  Future<void> _updatePharmacyMarkers(List<PharmacyLocationModel> locations) async {
    if (pointAnnotationManager == null) return;

    try {
      // Update pharmacy locations map
      _pharmacyLocations.clear();
      for (var location in locations) {
        _pharmacyLocations[location.userId] = location;
      }

      // Update all markers (drivers + pharmacies)
      await _updateDriverMarkerPulses();
      
      // Fit camera to show all markers
      await _fitCameraToAllMarkers();
    } catch (e) {
      debugPrint('❌ [ADMIN MAP] Error updating pharmacy markers: $e');
    }
  }

  Future<void> _fitCameraToAllMarkers() async {
    if (mapboxMap == null) return;
    
    try {
      final allLocations = <Position>[];
      
      // Add driver locations
      for (var driver in _driverLocations.values) {
        if (driver.location != null) {
          allLocations.add(Position(
            driver.location!.longitude,
            driver.location!.latitude,
          ));
        }
      }
      
      // Add pharmacy locations
      for (var pharmacy in _pharmacyLocations.values) {
        allLocations.add(Position(
          pharmacy.location.longitude,
          pharmacy.location.latitude,
        ));
      }
      
      if (allLocations.isEmpty) return;
      
      if (allLocations.length == 1) {
        // Single location - center on it
        await mapboxMap!.flyTo(
          CameraOptions(
            center: Point(coordinates: allLocations.first),
            zoom: 15.0,
          ),
          MapAnimationOptions(duration: 1000),
        );
      } else {
        // Multiple locations - fit bounds
        final lats = allLocations.map((p) => p.lat).toList();
        final lngs = allLocations.map((p) => p.lng).toList();
        
        final minLat = lats.reduce((a, b) => a < b ? a : b);
        final maxLat = lats.reduce((a, b) => a > b ? a : b);
        final minLng = lngs.reduce((a, b) => a < b ? a : b);
        final maxLng = lngs.reduce((a, b) => a > b ? a : b);
        
        final centerLat = (minLat + maxLat) / 2;
        final centerLng = (minLng + maxLng) / 2;
        final latSpan = maxLat - minLat;
        final lngSpan = maxLng - minLng;
        final maxSpan = latSpan > lngSpan ? latSpan : lngSpan;
        
        // Calculate zoom level based on span
        double zoom = 10.0;
        if (maxSpan > 0) {
          zoom = 15.0 - (maxSpan * 50);
          if (zoom < 8.0) zoom = 8.0;
          if (zoom > 15.0) zoom = 15.0;
        }
        
        await mapboxMap!.flyTo(
          CameraOptions(
            center: Point(
              coordinates: Position(centerLng, centerLat),
            ),
            zoom: zoom,
          ),
          MapAnimationOptions(duration: 1000),
        );
      }
    } catch (e) {
      debugPrint('❌ [ADMIN MAP] Error fitting camera: $e');
    }
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: HugeIcon(icon: AppIcons.arrowLeft, color: AppTheme.textPrimary, size: 24),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Live Locations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomLegend(
    AsyncValue<List<UserLocationModel>> driverLocationsAsync,
    AsyncValue<List<PharmacyLocationModel>> pharmacyLocationsAsync,
  ) {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Legend',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildLegendItem(
                    'Pharmacies & Healthcare Units',
                    Colors.purple,
                    Icons.local_pharmacy,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildLegendItem(
                    'Drivers (Live)',
                    AppTheme.accentColor,
                    Icons.directions_car,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomInfo(
    AsyncValue<List<UserLocationModel>> driverLocationsAsync,
    AsyncValue<List<PharmacyLocationModel>> pharmacyLocationsAsync,
  ) {
    return driverLocationsAsync.when(
      data: (drivers) => pharmacyLocationsAsync.when(
        data: (pharmacies) => Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('Pharmacies', pharmacies.length.toString(), Colors.purple),
                _buildInfoItem('Drivers', drivers.length.toString(), AppTheme.accentColor),
                _buildInfoItem('Total', (pharmacies.length + drivers.length).toString(), AppTheme.textPrimary),
              ],
            ),
          ),
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color) {
    return Column(
      children: [
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
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
