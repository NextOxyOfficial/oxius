import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
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
  final bool followDriver;

  // Profile info for rich markers
  final String? riderName;
  final String? riderAvatar;
  final String? driverName;
  final String? driverAvatar;
  final String? driverVehicleInfo; // e.g. "Honda Shine • DHA-1234"

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
    this.followDriver = false,
    this.riderName,
    this.riderAvatar,
    this.driverName,
    this.driverAvatar,
    this.driverVehicleInfo,
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
  
  // Default center (Dhaka, Bangladesh)
  static const LatLng _defaultCenter = LatLng(23.8103, 90.4125);

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

    // Auto-fit bounds when points change
    if (widget.pickupPoint != oldWidget.pickupPoint ||
        widget.dropPoint != oldWidget.dropPoint ||
        (driverChanged && !widget.followDriver)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds();
      });
    }

    if (driverChanged && widget.followDriver && widget.driverLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          LatLng(widget.driverLocation!.latitude, widget.driverLocation!.longitude),
          15.5,
        );
      });
    }
  }

  void _fitBounds() {
    final points = <LatLng>[];
    
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
    final latPadding = (maxLat - minLat) * 0.2;
    final lngPadding = (maxLng - minLng) * 0.2;
    
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

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _getInitialCenter(),
        initialZoom: 13,
        onTap: widget.onMapTap != null
            ? (tapPosition, point) {
                widget.onMapTap!(point.latitude, point.longitude);
              }
            : null,
      ),
      children: [
        // Tile layer (OpenStreetMap)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.adsyclub.oxius',
        ),
        
        // Route polyline
        if (widget.routeGeometry != null) _buildRouteLayer(),
        
        // Markers
        MarkerLayer(
          markers: _buildMarkers(),
        ),
      ],
    );
  }

  Widget _buildRouteLayer() {
    final coordinates = _parseRouteCoordinates();
    if (coordinates.isEmpty) return const SizedBox.shrink();
    
    return PolylineLayer(
      polylines: [
        Polyline(
          points: coordinates,
          strokeWidth: 4,
          color: const Color(0xFF6366F1),
        ),
      ],
    );
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
          width: hasRiderInfo ? 160 : 40,
          height: hasRiderInfo ? 72 : 50,
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
          width: 40,
          height: 50,
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

    // Nearby drivers
    if (widget.nearbyDrivers != null) {
      for (final driver in widget.nearbyDrivers!) {
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
                color: gradientColors.first.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: gradientColors.first.withOpacity(0.4), width: 1.5),
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
              colors: [gradientColors.first, gradientColors.first.withOpacity(0)],
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
      children: [
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
                color: const Color(0xFF6366F1).withOpacity(0.4),
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
          height: 10,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6366F1),
                const Color(0xFF6366F1).withOpacity(0),
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
      children: [
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
                color: const Color(0xFF10B981).withOpacity(0.4),
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
          height: 10,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981),
                const Color(0xFF10B981).withOpacity(0),
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
                color: const Color(0xFFF59E0B).withOpacity(0.4),
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
                const Color(0xFFF59E0B).withOpacity(0),
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
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Text(
          '🚗',
          style: TextStyle(fontSize: 20),
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
        border: Border.all(color: const Color(0xFF94A3B8), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        driver.vehicleIcon,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
