import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../../models/rideshare_models.dart';

class RideshareMapWidget extends StatefulWidget {
  final RidePoint? pickupPoint;
  final RidePoint? dropPoint;
  final RidePoint? driverLocation;
  final double? driverHeading;
  final Map<String, dynamic>? routeGeometry;
  final List<NearbyDriver>? nearbyDrivers;
  final String? activeSelection;
  final Function(double latitude, double longitude)? onMapTap;
  final Function(double latitude, double longitude)? onCenterChanged;
  final bool followDriver;
  final bool showNearbyDriverMarkers;

  // Profile info for rich markers
  final String? riderName;
  final String? riderAvatar;
  final String? driverName;
  final String? driverAvatar;
  final String? driverVehicleInfo; // e.g. "Honda Shine • DHA-1234"
  final String? vehicleType; // 'bike', 'car', 'cng'

  // Live passenger location (for driver map)
  final RidePoint? passengerLocation;
  final String? passengerName;
  final String? passengerAvatar;

  const RideshareMapWidget({
    super.key,
    this.pickupPoint,
    this.dropPoint,
    this.driverLocation,
    this.driverHeading,
    this.routeGeometry,
    this.nearbyDrivers,
    this.activeSelection,
    this.onMapTap,
    this.onCenterChanged,
    this.followDriver = false,
    this.showNearbyDriverMarkers = false,
    this.riderName,
    this.riderAvatar,
    this.driverName,
    this.driverAvatar,
    this.driverVehicleInfo,
    this.vehicleType,
    this.passengerLocation,
    this.passengerName,
    this.passengerAvatar,
  });

  @override
  State<RideshareMapWidget> createState() => _RideshareMapWidgetState();
}

class _RideshareMapWidgetState extends State<RideshareMapWidget> {
  final MapController _mapController = MapController();
  bool _initialFitDone = false;
  double _lastKnownZoom = 13;
  DateTime? _lastManualMapGestureAt;
  
  // Default center (Dhaka, Bangladesh)
  static const LatLng _defaultCenter = LatLng(23.8103, 90.4125);
  static const Duration _manualMapControlHold = Duration(seconds: 8);

  List<NearbyDriver> get _visibleNearbyDrivers =>
      (widget.nearbyDrivers ?? const <NearbyDriver>[])
          .where((driver) => driver.isOnline)
          .toList(growable: false);

  @override
  void initState() {
    super.initState();
    // Defer initial fit so the map controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_initialFitDone) {
        _initialFitDone = true;
        _fitBounds();
      }
    });
  }

  @override
  void didUpdateWidget(RideshareMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final driverChanged =
        widget.driverLocation?.latitude != oldWidget.driverLocation?.latitude ||
        widget.driverLocation?.longitude != oldWidget.driverLocation?.longitude;
    final routeChanged = widget.routeGeometry?.toString() != oldWidget.routeGeometry?.toString();

    // Auto-fit bounds when points change
    if (widget.pickupPoint != oldWidget.pickupPoint ||
        widget.dropPoint != oldWidget.dropPoint ||
        routeChanged ||
        (driverChanged && !widget.followDriver)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds();
      });
    }

    if (driverChanged && widget.followDriver && widget.driverLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _shouldPauseAutoFollow()) {
          return;
        }
        _mapController.move(
          LatLng(widget.driverLocation!.latitude, widget.driverLocation!.longitude),
          _lastKnownZoom.clamp(6.0, 19.0).toDouble(),
        );
      });
    }
  }

  bool _shouldPauseAutoFollow() {
    final lastGestureAt = _lastManualMapGestureAt;
    if (lastGestureAt == null) {
      return false;
    }

    return DateTime.now().difference(lastGestureAt) < _manualMapControlHold;
  }

  void _fitBounds() {
    final points = <LatLng>[];
    points.addAll(_parseRouteCoordinates());
    
    if (widget.pickupPoint != null) {
      points.add(LatLng(widget.pickupPoint!.latitude, widget.pickupPoint!.longitude));
    }
    if (widget.dropPoint != null) {
      points.add(LatLng(widget.dropPoint!.latitude, widget.dropPoint!.longitude));
    }
    if (widget.driverLocation != null) {
      points.add(LatLng(widget.driverLocation!.latitude, widget.driverLocation!.longitude));
    }
    if (widget.passengerLocation != null) {
      points.add(LatLng(widget.passengerLocation!.latitude, widget.passengerLocation!.longitude));
    }
    
    if (points.isEmpty) return;
    
    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }
    
    // Calculate bounds
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    
    // Add padding
    final latPadding = math.max((maxLat - minLat) * 0.2, 0.0025);
    final lngPadding = math.max((maxLng - minLng) * 0.2, 0.0025);
    
    final bounds = LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
    
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  LatLng _getInitialCenter() {
    if (widget.pickupPoint != null) {
      return LatLng(widget.pickupPoint!.latitude, widget.pickupPoint!.longitude);
    }
    if (widget.dropPoint != null) {
      return LatLng(widget.dropPoint!.latitude, widget.dropPoint!.longitude);
    }
    return _defaultCenter;
  }

  // Bangladesh bounding box
  static final LatLngBounds _bangladeshBounds = LatLngBounds(
    const LatLng(20.50, 88.00),
    const LatLng(26.80, 92.80),
  );

  @override
  Widget build(BuildContext context) {
    final routeCoordinates = _parseRouteCoordinates();

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _getInitialCenter(),
              initialZoom: 13,
              cameraConstraint: CameraConstraint.contain(bounds: _bangladeshBounds),
              minZoom: 6,
              maxZoom: 19,
              onPositionChanged: (camera, hasGesture) {
                _lastKnownZoom = camera.zoom ?? _lastKnownZoom;
                if (hasGesture) {
                  _lastManualMapGestureAt = DateTime.now();
                }
                final center = camera.center;
                if (center == null) {
                  return;
                }
                widget.onCenterChanged?.call(center.latitude, center.longitude);
              },
              onTap: widget.onMapTap != null
                  ? (tapPosition, point) {
                      widget.onMapTap!(point.latitude, point.longitude);
                    }
                  : null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.adsyclub.oxius',
                retinaMode: RetinaMode.isHighDensity(context),
                maxZoom: 20,
              ),
              if (routeCoordinates.isNotEmpty) _buildRouteLayer(routeCoordinates),
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.transparent,
                      const Color(0xFF0F172A).withValues(alpha: 0.18),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 76,
            child: _buildStatusPanel(routeCoordinates),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                _buildMapActionButton(
                  icon: Icons.fit_screen_rounded,
                  tooltip: 'Fit route',
                  onPressed: _fitBounds,
                ),
                const SizedBox(height: 8),
                _buildMapActionButton(
                  icon: widget.followDriver && widget.driverLocation != null
                      ? Icons.my_location_rounded
                      : Icons.center_focus_strong_rounded,
                  tooltip: widget.followDriver && widget.driverLocation != null
                      ? 'Follow driver'
                      : 'Focus map',
                  onPressed: _focusPrimaryLocation,
                  isHighlighted: widget.followDriver && widget.driverLocation != null,
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _buildLegendPanel(routeCoordinates),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteLayer(List<LatLng> coordinates) {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: coordinates,
          strokeWidth: 10,
          color: Colors.white.withValues(alpha: 0.72),
        ),
        Polyline(
          points: coordinates,
          strokeWidth: 5.5,
          color: const Color(0xFF4F46E5),
        ),
        Polyline(
          points: coordinates,
          strokeWidth: 2.25,
          color: const Color(0xFF93C5FD).withValues(alpha: 0.95),
        ),
      ],
    );
  }

  void _focusPrimaryLocation() {
    if (widget.followDriver && widget.driverLocation != null) {
      _mapController.move(
        LatLng(widget.driverLocation!.latitude, widget.driverLocation!.longitude),
        15.5,
      );
      return;
    }
    if (widget.passengerLocation != null) {
      _mapController.move(
        LatLng(widget.passengerLocation!.latitude, widget.passengerLocation!.longitude),
        15,
      );
      return;
    }
    if (widget.pickupPoint != null) {
      _mapController.move(
        LatLng(widget.pickupPoint!.latitude, widget.pickupPoint!.longitude),
        15,
      );
      return;
    }
    if (widget.dropPoint != null) {
      _mapController.move(
        LatLng(widget.dropPoint!.latitude, widget.dropPoint!.longitude),
        15,
      );
      return;
    }
    _fitBounds();
  }

  Widget _buildStatusPanel(List<LatLng> routeCoordinates) {
    final hasRoute = routeCoordinates.isNotEmpty;
    final nearbyCount = _visibleNearbyDrivers.length;
    final title = widget.followDriver && widget.driverLocation != null
        ? 'Live trip tracking'
        : widget.onMapTap != null
            ? 'Smart route planner'
            : hasRoute
                ? 'Route preview'
                : 'Service area view';
    final subtitle = widget.onMapTap != null
        ? 'Tap to place your ${widget.activeSelection == 'drop' ? 'drop-off' : 'pickup'} point.'
        : widget.followDriver && widget.driverLocation != null
            ? 'Driver movement stays centered while the trip updates live.'
            : hasRoute
                ? 'Pickup, drop-off and trip path are framed together.'
                : nearbyCount > 0
                  ? '$nearbyCount online drivers available around your selected area.'
                    : 'Zoom and inspect the current service area.';

    return _buildGlassPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.followDriver && widget.driverLocation != null
                      ? Icons.radar_rounded
                      : widget.onMapTap != null
                          ? Icons.touch_app_rounded
                          : Icons.map_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasRoute)
                _buildInfoChip(
                  icon: Icons.alt_route_rounded,
                  label: '${routeCoordinates.length} route points',
                  tint: const Color(0xFF4F46E5),
                ),
              if (nearbyCount > 0)
                _buildInfoChip(
                  icon: Icons.local_taxi_rounded,
                  label: '$nearbyCount online nearby',
                  tint: const Color(0xFF0F766E),
                ),
              if (widget.followDriver && widget.driverLocation != null)
                _buildInfoChip(
                  icon: Icons.radar_rounded,
                  label: 'Follow mode',
                  tint: const Color(0xFF059669),
                ),
              if (widget.onMapTap != null)
                _buildInfoChip(
                  icon: Icons.edit_location_alt_rounded,
                  label: widget.activeSelection == 'drop'
                      ? 'Drop-off selection'
                      : 'Pickup selection',
                  tint: const Color(0xFFD97706),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendPanel(List<LatLng> routeCoordinates) {
    final items = <Widget>[];

    if (widget.pickupPoint != null) {
      items.add(
        _buildLegendChip(
          icon: Icons.trip_origin_rounded,
          label: _compactPointLabel(widget.pickupPoint!, 'Pickup'),
          tint: const Color(0xFF4F46E5),
        ),
      );
    }
    if (widget.dropPoint != null) {
      items.add(
        _buildLegendChip(
          icon: Icons.flag_rounded,
          label: _compactPointLabel(widget.dropPoint!, 'Drop-off'),
          tint: const Color(0xFF059669),
        ),
      );
    }
    if (widget.driverLocation != null) {
      items.add(
        _buildLegendChip(
          icon: Icons.directions_car_rounded,
          label: widget.driverName?.trim().isNotEmpty == true ? widget.driverName!.trim() : 'Driver live',
          tint: const Color(0xFF0EA5E9),
        ),
      );
    }
    if (widget.passengerLocation != null) {
      items.add(
        _buildLegendChip(
          icon: Icons.person_pin_circle_rounded,
          label: widget.passengerName?.trim().isNotEmpty == true ? widget.passengerName!.trim() : 'Passenger live',
          tint: const Color(0xFFF59E0B),
        ),
      );
    }
    if (routeCoordinates.isEmpty && widget.nearbyDrivers != null && widget.nearbyDrivers!.isNotEmpty) {
      items.add(
        _buildLegendChip(
          icon: Icons.groups_rounded,
          label: '${_visibleNearbyDrivers.length} online drivers nearby',
          tint: const Color(0xFF334155),
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildGlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items,
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isHighlighted = false,
  }) {
    final backgroundColor = isHighlighted
        ? const Color(0xFF4F46E5).withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.9);
    final iconColor = isHighlighted ? Colors.white : const Color(0xFF0F172A);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: isHighlighted ? 0.18 : 0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassPanel({required EdgeInsetsGeometry padding, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip({
    required IconData icon,
    required String label,
    required Color tint,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _compactPointLabel(RidePoint point, String fallback) {
    final value = point.displayTitle.trim();
    if (value.isEmpty) {
      return fallback;
    }
    if (value.length <= 22) {
      return value;
    }
    return '${value.substring(0, 22)}...';
  }

  List<LatLng> _parseRouteCoordinates() {
    if (widget.routeGeometry == null) return [];
    
    try {
      // Handle GeoJSON format
      if (widget.routeGeometry!.containsKey('coordinates')) {
        final coords = widget.routeGeometry!['coordinates'] as List;
        return coords.map((c) {
          if (c is List && c.length >= 2) {
            return LatLng(
              (c[1] as num).toDouble(),
              (c[0] as num).toDouble(),
            );
          }
          return null;
        }).whereType<LatLng>().toList();
      }
      
      // Handle OSRM format
      if (widget.routeGeometry!.containsKey('routes')) {
        final routes = widget.routeGeometry!['routes'] as List;
        if (routes.isNotEmpty) {
          final route = routes[0] as Map<String, dynamic>;
          if (route.containsKey('geometry')) {
            final geometry = route['geometry'];
            if (geometry is Map && geometry.containsKey('coordinates')) {
              final coords = geometry['coordinates'] as List;
              return coords.map((c) {
                if (c is List && c.length >= 2) {
                  return LatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  );
                }
                return null;
              }).whereType<LatLng>().toList();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing route coordinates: $e');
    }
    
    return [];
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    
    // Pickup marker (with rider profile if available)
    if (widget.pickupPoint != null) {
      final hasRiderInfo = widget.riderName != null && widget.riderName!.isNotEmpty;
      markers.add(
        Marker(
          point: LatLng(widget.pickupPoint!.latitude, widget.pickupPoint!.longitude),
          width: hasRiderInfo ? 160 : 116,
          height: hasRiderInfo ? 72 : 80,
          child: hasRiderInfo
              ? _buildProfileMarker(
                  name: widget.riderName!,
                  avatarUrl: widget.riderAvatar,
                  subtitle: 'Passenger',
                  gradientColors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  icon: Icons.person_rounded,
                )
              : _buildPickupMarker(),
        ),
      );
    }
    
    // Drop marker
    if (widget.dropPoint != null) {
      markers.add(
        Marker(
          point: LatLng(widget.dropPoint!.latitude, widget.dropPoint!.longitude),
          width: 90,
          height: 76,
          child: _buildDropMarker(),
        ),
      );
    }
    
    // Driver marker (with driver profile if available)
    if (widget.driverLocation != null) {
      final hasDriverInfo = widget.driverName != null && widget.driverName!.isNotEmpty;
      markers.add(
        Marker(
          point: LatLng(widget.driverLocation!.latitude, widget.driverLocation!.longitude),
          width: hasDriverInfo ? 180 : 50,
          height: hasDriverInfo ? 82 : 50,
          child: hasDriverInfo
              ? _buildProfileMarker(
                  name: widget.driverName!,
                  avatarUrl: widget.driverAvatar,
                  subtitle: widget.driverVehicleInfo ?? 'Driver',
                  gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                  icon: Icons.directions_car_rounded,
                )
              : _buildDriverMarker(),
        ),
      );
    }
    
    // Live passenger location (shown on driver map)
    if (widget.passengerLocation != null) {
      final hasPassengerInfo = widget.passengerName != null && widget.passengerName!.isNotEmpty;
      markers.add(
        Marker(
          point: LatLng(widget.passengerLocation!.latitude, widget.passengerLocation!.longitude),
          width: hasPassengerInfo ? 160 : 40,
          height: hasPassengerInfo ? 72 : 50,
          child: hasPassengerInfo
              ? _buildProfileMarker(
                  name: widget.passengerName!,
                  avatarUrl: widget.passengerAvatar,
                  subtitle: 'Passenger (Live)',
                  gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                  icon: Icons.person_pin_circle_rounded,
                )
              : _buildPassengerLiveMarker(),
        ),
      );
    }

    // Nearby drivers are represented as a count overlay by default. Showing
    // individual live positions would leak driver whereabouts before a ride is assigned.
    if (widget.showNearbyDriverMarkers && _visibleNearbyDrivers.isNotEmpty) {
      for (final driver in _visibleNearbyDrivers) {
        markers.add(
          Marker(
            point: LatLng(driver.latitude, driver.longitude),
            width: 36,
            height: 36,
            child: _buildNearbyDriverMarker(driver),
          ),
        );
      }
    }
    
    return markers;
  }

  Widget _buildProfileMarker({
    required String name,
    String? avatarUrl,
    required String subtitle,
    required List<Color> gradientColors,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: gradientColors.first.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: gradientColors),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(icon, size: 14, color: Colors.white),
                        ),
                      )
                    : Icon(icon, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                        color: gradientColors.first,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Pin tail
        Container(
          width: 2,
          height: 8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientColors.first, gradientColors.first.withValues(alpha: 0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickupMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'পিকআপ পয়েন্ট',
            style: GoogleFonts.notoSansBengali(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        Container(
          width: 3,
          height: 8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6366F1),
                const Color(0xFF6366F1).withValues(alpha: 0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'গন্তব্য',
            style: GoogleFonts.notoSansBengali(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.flag_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        Container(
          width: 3,
          height: 8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981),
                const Color(0xFF10B981).withValues(alpha: 0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerLiveMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_pin_circle_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        Container(
          width: 3,
          height: 10,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF59E0B),
                const Color(0xFFF59E0B).withValues(alpha: 0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverMarker() {
    final heading = widget.driverHeading ?? 0;
    return Transform.rotate(
      angle: heading * (math.pi / 180),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF6366F1), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          _vehicleIconData(widget.vehicleType),
          size: 22,
          color: const Color(0xFF6366F1),
        ),
      ),
    );
  }

  Widget _buildNearbyDriverMarker(NearbyDriver driver) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF6366F1), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        _vehicleIconData(driver.vehicleType),
        size: 16,
        color: const Color(0xFF334155),
      ),
    );
  }

  IconData _vehicleIconData(String? vehicleType) {
    switch (vehicleType) {
      case 'bike':
        return Icons.two_wheeler_rounded;
      case 'cng':
        return Icons.electric_rickshaw_rounded;
      case 'car':
      default:
        return Icons.directions_car_rounded;
    }
  }
}
