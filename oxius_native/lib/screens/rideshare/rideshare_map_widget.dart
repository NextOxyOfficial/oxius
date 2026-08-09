import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;
import '../../models/rideshare_models.dart';
import 'rideshare_vehicle_catalog.dart';
import '../../widgets/app_network_image.dart';
import '../../utils/app_fonts.dart';

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

  /// True while the trip is actually running. Flipping to true glides the
  /// camera down to street-level zoom over the driver, which reads like the
  /// ride "starting" instead of a map that keeps hovering at city scale.
  final bool streetFocus;

  /// How far down the floating overlays (status panel, action buttons) start.
  ///
  /// A carded map keeps the default. A full-bleed map runs behind the status
  /// bar and behind the shell's drawer/avatar circles, so those callers push
  /// the overlays below both — otherwise the top button sits underneath the
  /// avatar and cannot be tapped at all.
  final double topInset;

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
    this.streetFocus = false,
    this.topInset = 12,
  });

  @override
  State<RideshareMapWidget> createState() => _RideshareMapWidgetState();
}

class _RideshareMapWidgetState extends State<RideshareMapWidget>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _initialFitDone = false;
  double _lastKnownZoom = 13;
  DateTime? _lastManualMapGestureAt;

  /// Which basemap is showing. Satellite is genuinely useful here — riders in
  /// Bangladesh navigate by buildings and landmarks far more than by street
  /// names, and a pickup pin dropped on a recognisable rooftop beats one
  /// dropped on an unlabelled road.
  _MapStyle _style = _MapStyle.standard;

  /// The status panel folds away on tap. It explains the map once; after that
  /// it is just a lid over the part of the map the rider is trying to aim at,
  /// so it retracts into a small chevron pill and comes back the same way.
  ///
  /// One controller drives the whole fold — width, height, opacity and the
  /// chevron all read the same curve, so nothing arrives ahead of the rest.
  late final AnimationController _statusPanelController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 220),
    value: 1,
  );
  late final Animation<double> _statusPanelCurve = CurvedAnimation(
    parent: _statusPanelController,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  bool get _statusPanelExpanded => _statusPanelController.value > 0.5;

  /// Street zoom the camera settles at while the trip runs.
  static const double _streetZoom = 17.0;

  AnimationController? _cameraController;

  /// Glides the camera instead of jumping it. Every internal reposition goes
  /// through here; one controller means a newer move silently cancels the
  /// one still in flight.
  void _animatedMove(LatLng target, double zoom,
      {Duration duration = const Duration(milliseconds: 650)}) {
    final camera = _mapController.camera;
    final latTween =
        Tween<double>(begin: camera.center.latitude, end: target.latitude);
    final lngTween =
        Tween<double>(begin: camera.center.longitude, end: target.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: zoom);

    _cameraController?.dispose();
    final controller = AnimationController(vsync: this, duration: duration);
    _cameraController = controller;
    final curve =
        CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(curve), lngTween.evaluate(curve)),
        zoomTween.evaluate(curve),
      );
    });
    controller.forward();
  }

  void _cycleMapStyle() {
    final next = _MapStyle.values[(_style.index + 1) % _MapStyle.values.length];
    setState(() => _style = next);
  }

  void _toggleStatusPanel() {
    if (_statusPanelExpanded) {
      _statusPanelController.reverse();
    } else {
      _statusPanelController.forward();
    }
  }

  /// Folds [child] away toward the badge, clipping and fading as it goes.
  ///
  /// SizeTransition would be the obvious tool, but it only scales the axis it
  /// folds on and lets the other one keep the full available width — which
  /// would leave a closed panel still stretched across the map. Driving both
  /// factors keeps the glass box hugging whatever is left of its contents.
  Widget _foldAway(Widget child) {
    return AnimatedBuilder(
      animation: _statusPanelCurve,
      builder: (context, inner) {
        final factor = math.max(_statusPanelCurve.value, 0.0);
        return ClipRect(
          child: Align(
            alignment: Alignment.topLeft,
            widthFactor: factor,
            heightFactor: factor,
            child: inner,
          ),
        );
      },
      child: FadeTransition(opacity: _statusPanelCurve, child: child),
    );
  }

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
  void dispose() {
    _cameraController?.dispose();
    _statusPanelController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RideshareMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final driverChanged = widget.driverLocation?.latitude !=
            oldWidget.driverLocation?.latitude ||
        widget.driverLocation?.longitude != oldWidget.driverLocation?.longitude;
    final routeChanged =
        widget.routeGeometry?.toString() != oldWidget.routeGeometry?.toString();

    // Auto-fit bounds when points change — never while street-focused, or
    // every driver ping would zoom the trip view back out to city scale.
    if (!widget.streetFocus &&
        (widget.pickupPoint != oldWidget.pickupPoint ||
            widget.dropPoint != oldWidget.dropPoint ||
            routeChanged ||
            (driverChanged && !widget.followDriver))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds();
      });
    }

    // The trip just started: dive from overview to street level over the
    // driver, smoothly — the moment that makes the map feel live.
    if (widget.streetFocus &&
        !oldWidget.streetFocus &&
        widget.driverLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _animatedMove(
          LatLng(widget.driverLocation!.latitude,
              widget.driverLocation!.longitude),
          _streetZoom,
          duration: const Duration(milliseconds: 1100),
        );
      });
      return;
    }

    if (driverChanged && widget.followDriver && widget.driverLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _shouldPauseAutoFollow()) {
          return;
        }
        // While street-focused, stay at street zoom even if the rider had
        // zoomed elsewhere earlier; otherwise keep whatever zoom they chose.
        final zoom = widget.streetFocus
            ? math.max(_lastKnownZoom, _streetZoom - 0.5)
            : _lastKnownZoom.clamp(6.0, 19.0).toDouble();
        _animatedMove(
          LatLng(widget.driverLocation!.latitude,
              widget.driverLocation!.longitude),
          zoom.clamp(6.0, 19.0).toDouble(),
          duration: const Duration(milliseconds: 900),
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
      points.add(
          LatLng(widget.pickupPoint!.latitude, widget.pickupPoint!.longitude));
    }
    if (widget.dropPoint != null) {
      points
          .add(LatLng(widget.dropPoint!.latitude, widget.dropPoint!.longitude));
    }
    if (widget.driverLocation != null) {
      points.add(LatLng(
          widget.driverLocation!.latitude, widget.driverLocation!.longitude));
    }
    if (widget.passengerLocation != null) {
      points.add(LatLng(widget.passengerLocation!.latitude,
          widget.passengerLocation!.longitude));
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
      return LatLng(
          widget.pickupPoint!.latitude, widget.pickupPoint!.longitude);
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

    // RepaintBoundary isolates the entire map layer (tiles, markers, polylines)
    // from the rest of the parent widget tree. Without it, every passenger
    // location ping / marker rebuild repaints the whole ride panel including
    // unrelated cards, sheets, and the status banner.
    return RepaintBoundary(
      child: DecoratedBox(
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
                cameraConstraint:
                    CameraConstraint.contain(bounds: _bangladeshBounds),
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
                  widget.onCenterChanged
                      ?.call(center.latitude, center.longitude);
                },
                onTap: widget.onMapTap != null
                    ? (tapPosition, point) {
                        widget.onMapTap!(point.latitude, point.longitude);
                      }
                    : null,
              ),
              children: [
                TileLayer(
                  key: ValueKey(_style),
                  urlTemplate: _style.tileUrl,
                  subdomains: _style.subdomains,
                  userAgentPackageName: 'com.adsyclub.oxius',
                  // Esri imagery has no @2x variant; asking for one returns
                  // 400s and a blank map on every high-density phone.
                  retinaMode: _style.supportsRetina &&
                      RetinaMode.isHighDensity(context),
                  maxZoom: 20,
                ),
                // Satellite alone hides every road and place name, which is
                // useless for choosing a pickup. The reference layer paints
                // just the labels and streets back on top.
                if (_style.labelOverlayUrl != null)
                  TileLayer(
                    key: ValueKey('${_style.name}-labels'),
                    urlTemplate: _style.labelOverlayUrl!,
                    userAgentPackageName: 'com.adsyclub.oxius',
                    maxZoom: 20,
                  ),
                if (routeCoordinates.isNotEmpty)
                  _buildRouteLayer(routeCoordinates),
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
              top: widget.topInset,
              left: 12,
              right: 76,
              child: _buildStatusPanel(routeCoordinates),
            ),
            Positioned(
              top: widget.topInset,
              right: 12,
              child: Column(
                children: [
                  _buildMapActionButton(
                    icon: Icons.fit_screen_rounded,
                    tooltip: 'রুট দেখুন',
                    onPressed: _fitBounds,
                  ),
                  const SizedBox(height: 8),
                  _buildMapActionButton(
                    icon: widget.followDriver && widget.driverLocation != null
                        ? Icons.my_location_rounded
                        : Icons.center_focus_strong_rounded,
                    tooltip:
                        widget.followDriver && widget.driverLocation != null
                            ? 'ড্রাইভার ফলো'
                            : 'ম্যাপ ফোকাস',
                    onPressed: _focusPrimaryLocation,
                    isHighlighted:
                        widget.followDriver && widget.driverLocation != null,
                  ),
                  const SizedBox(height: 8),
                  _buildMapActionButton(
                    icon: _style.icon,
                    tooltip: _style.nextLabel,
                    onPressed: _cycleMapStyle,
                    isHighlighted: _style != _MapStyle.standard,
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
        LatLng(
            widget.driverLocation!.latitude, widget.driverLocation!.longitude),
        15.5,
      );
      return;
    }
    if (widget.passengerLocation != null) {
      _mapController.move(
        LatLng(widget.passengerLocation!.latitude,
            widget.passengerLocation!.longitude),
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
        ? 'লাইভ ট্রিপ ট্র্যাকিং'
        : widget.onMapTap != null
            ? 'রুট প্ল্যানার'
            : hasRoute
                ? 'রুট প্রিভিউ'
                : 'সার্ভিস এরিয়া';
    final subtitle = widget.onMapTap != null
        ? 'ম্যাপে ট্যাপ করে ${widget.activeSelection == 'drop' ? 'গন্তব্য' : 'পিকআপ'} পয়েন্ট বসান।'
        : widget.followDriver && widget.driverLocation != null
            ? 'ড্রাইভারের অবস্থান লাইভ আপডেট হচ্ছে।'
            : hasRoute
                ? 'পিকআপ, গন্তব্য ও রুট একসাথে দেখানো হচ্ছে।'
                : nearbyCount > 0
                    ? 'আশেপাশে $nearbyCount জন ড্রাইভার অনলাইনে আছেন।'
                    : 'জুম করে সার্ভিস এরিয়া দেখুন।';

    final chips = <Widget>[
      if (hasRoute)
        _buildInfoChip(
          icon: Icons.alt_route_rounded,
          label: 'রুট প্রস্তুত',
          tint: const Color(0xFF4F46E5),
        ),
      if (nearbyCount > 0)
        _buildInfoChip(
          icon: Icons.local_taxi_rounded,
          label: 'আশেপাশে $nearbyCount জন',
          tint: const Color(0xFF0F766E),
        ),
      if (widget.followDriver && widget.driverLocation != null)
        _buildInfoChip(
          icon: Icons.radar_rounded,
          label: 'ফলো মোড',
          tint: const Color(0xFF059669),
        ),
      if (widget.onMapTap != null)
        _buildInfoChip(
          icon: Icons.edit_location_alt_rounded,
          label: widget.activeSelection == 'drop'
              ? 'গন্তব্য বাছাই'
              : 'পিকআপ বাছাই',
          tint: const Color(0xFFD97706),
        ),
    ];

    // Align + loose constraints let the panel hug its content, so folding it
    // away shrinks the box in BOTH axes down to the badge instead of leaving
    // a full-width bar sitting over the map.
    return Align(
      alignment: Alignment.topLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleStatusPanel,
        child: _buildGlassPanel(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF4F46E5).withValues(alpha: 0.28),
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
                      size: 17,
                    ),
                  ),
                  // The wording is what makes the panel wide, so it is the
                  // part that slides away — clipped and faded together, which
                  // is why both transitions ride the same curve.
                  Flexible(
                    child: _foldAway(
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.roboto(
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
                              style: AppFonts.roboto(
                                fontSize: 10.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Points up while open (tap sends it up), down once folded.
                  RotationTransition(
                    turns: Tween<double>(begin: 0, end: 0.5)
                        .animate(_statusPanelCurve),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              if (chips.isNotEmpty)
                _foldAway(
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chips,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendPanel(List<LatLng> routeCoordinates) {
    final items = <Widget>[];

    if (widget.pickupPoint != null) {
      items.add(
        _buildLegendChip(
          icon: Icons.trip_origin_rounded,
          label: _compactPointLabel(widget.pickupPoint!, 'পিকআপ'),
          tint: const Color(0xFF4F46E5),
        ),
      );
    }
    if (widget.dropPoint != null) {
      items.add(
        _buildLegendChip(
          icon: Icons.flag_rounded,
          label: _compactPointLabel(widget.dropPoint!, 'গন্তব্য'),
          tint: const Color(0xFF059669),
        ),
      );
    }
    if (widget.driverLocation != null) {
      items.add(
        _buildLegendChip(
          icon: Icons.directions_car_rounded,
          label: widget.driverName?.trim().isNotEmpty == true
              ? widget.driverName!.trim()
              : 'ড্রাইভার লাইভ',
          tint: const Color(0xFF0EA5E9),
        ),
      );
    }
    if (widget.passengerLocation != null) {
      items.add(
        _buildLegendChip(
          icon: Icons.person_pin_circle_rounded,
          label: widget.passengerName?.trim().isNotEmpty == true
              ? widget.passengerName!.trim()
              : 'যাত্রী লাইভ',
          tint: const Color(0xFFF59E0B),
        ),
      );
    }
    if (routeCoordinates.isEmpty &&
        widget.nearbyDrivers != null &&
        widget.nearbyDrivers!.isNotEmpty) {
      items.add(
        _buildLegendChip(
          icon: Icons.groups_rounded,
          label: 'আশেপাশে ${_visibleNearbyDrivers.length} জন ড্রাইভার',
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
                color:
                    Colors.white.withValues(alpha: isHighlighted ? 0.18 : 0.7),
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

  Widget _buildGlassPanel(
      {required EdgeInsetsGeometry padding, required Widget child}) {
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
            style: AppFonts.roboto(
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
              style: AppFonts.roboto(
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
        return coords
            .map((c) {
              if (c is List && c.length >= 2) {
                return LatLng(
                  (c[1] as num).toDouble(),
                  (c[0] as num).toDouble(),
                );
              }
              return null;
            })
            .whereType<LatLng>()
            .toList();
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
              return coords
                  .map((c) {
                    if (c is List && c.length >= 2) {
                      return LatLng(
                        (c[1] as num).toDouble(),
                        (c[0] as num).toDouble(),
                      );
                    }
                    return null;
                  })
                  .whereType<LatLng>()
                  .toList();
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

    // Pickup marker: the rider's own face pins the pickup when we have it —
    // a photo says "this is where I am" better than any glyph.
    if (widget.pickupPoint != null) {
      final hasAvatar =
          widget.riderAvatar != null && widget.riderAvatar!.isNotEmpty;
      markers.add(
        Marker(
          point: LatLng(
              widget.pickupPoint!.latitude, widget.pickupPoint!.longitude),
          width: hasAvatar ? 64 : 116,
          height: hasAvatar ? 78 : 80,
          alignment: hasAvatar ? Alignment.topCenter : Alignment.center,
          child: hasAvatar
              ? _buildAvatarPin(
                  avatarUrl: widget.riderAvatar!,
                  ringColor: const Color(0xFF6366F1),
                  fallbackIcon: Icons.person_rounded,
                )
              : _buildPickupMarker(),
        ),
      );
    }

    // Drop marker
    if (widget.dropPoint != null) {
      markers.add(
        Marker(
          point:
              LatLng(widget.dropPoint!.latitude, widget.dropPoint!.longitude),
          width: 90,
          height: 76,
          child: _buildDropMarker(),
        ),
      );
    }

    // Driver marker. While the trip runs the big name card gets out of the
    // way and the vehicle itself moves down the street; before that, the
    // card tells the waiting rider who is coming.
    if (widget.driverLocation != null) {
      final hasDriverInfo =
          widget.driverName != null && widget.driverName!.isNotEmpty;
      final asVehicle = widget.streetFocus || !hasDriverInfo;
      markers.add(
        Marker(
          point: LatLng(widget.driverLocation!.latitude,
              widget.driverLocation!.longitude),
          width: asVehicle ? 54 : 180,
          height: asVehicle ? 54 : 82,
          child: asVehicle
              ? _buildVehicleMarker()
              : _buildProfileMarker(
                  name: widget.driverName!,
                  avatarUrl: widget.driverAvatar,
                  subtitle: widget.driverVehicleInfo ?? 'ড্রাইভার',
                  gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                  icon: Icons.directions_car_rounded,
                ),
        ),
      );
    }

    // Live passenger location (shown on driver map)
    if (widget.passengerLocation != null) {
      final hasPassengerInfo =
          widget.passengerName != null && widget.passengerName!.isNotEmpty;
      markers.add(
        Marker(
          point: LatLng(widget.passengerLocation!.latitude,
              widget.passengerLocation!.longitude),
          width: hasPassengerInfo ? 160 : 40,
          height: hasPassengerInfo ? 72 : 50,
          child: hasPassengerInfo
              ? _buildProfileMarker(
                  name: widget.passengerName!,
                  avatarUrl: widget.passengerAvatar,
                  subtitle: 'যাত্রী (লাইভ)',
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
            border: Border.all(
                color: gradientColors.first.withValues(alpha: 0.4), width: 1.5),
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
                        child: AppNetworkImage(
                          avatarUrl,
                          width: 28,
                          height: 28,
                          errorWidget:
                              Icon(icon, size: 14, color: Colors.white),
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
                      style: AppFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: AppFonts.roboto(
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
              colors: [
                gradientColors.first,
                gradientColors.first.withValues(alpha: 0)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  /// A circular photo pin: the face in a ringed circle with a pointer tail.
  Widget _buildAvatarPin({
    required String avatarUrl,
    required Color ringColor,
    required IconData fallbackIcon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: AppNetworkImage(
              avatarUrl,
              errorWidget: Container(
                color: const Color(0xFFF1F5F9),
                child: Icon(fallbackIcon,
                    size: 22, color: const Color(0xFF64748B)),
              ),
            ),
          ),
        ),
        // Pointer tail so the pin reads as "exactly here", not "around here".
        CustomPaint(
          size: const Size(12, 7),
          painter: _PinTailPainter(ringColor),
        ),
      ],
    );
  }

  /// The moving vehicle during the trip: bundled artwork in a white puck,
  /// rotated to the live heading so it drives down the street, not sideways.
  Widget _buildVehicleMarker() {
    final vehicle = RideVehicle.byKey(widget.vehicleType);
    final heading = widget.driverHeading;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF059669), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(7),
      child: heading == null
          ? vehicle.artwork(size: 34)
          : Transform.rotate(
              angle: heading * (math.pi / 180),
              child: vehicle.artwork(size: 34),
            ),
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
            style: AppFonts.roboto(
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
            style: AppFonts.roboto(
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

/// The two basemaps behind the layers button.
///
/// Both are free raster services that need no API key, which is why this map
/// has never had one. Street stays the default because the route line reads
/// most clearly on it; satellite is there because riders here navigate by
/// buildings and landmarks, not by street names.
///
/// A third OpenStreetMap style was considered and dropped: it would duplicate
/// what Voyager already shows, and OSM's tile policy asks apps not to send it
/// production traffic.
enum _MapStyle {
  standard(
    label: 'স্ট্রিট',
    icon: Icons.layers_rounded,
    tileUrl:
        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    subdomains: ['a', 'b', 'c', 'd'],
    supportsRetina: true,
  ),
  satellite(
    label: 'স্যাটেলাইট',
    icon: Icons.satellite_alt_rounded,
    // Note the {y}/{x} order — Esri serves row before column, the reverse of
    // every {z}/{x}/{y} slippy-map service.
    tileUrl:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    subdomains: [],
    supportsRetina: false,
    // Roads, place names and boundaries painted back over the imagery — raw
    // satellite with no labels is beautiful and useless for picking a pickup.
    labelOverlayUrl:
        'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
  );

  const _MapStyle({
    required this.label,
    required this.icon,
    required this.tileUrl,
    required this.subdomains,
    required this.supportsRetina,
    this.labelOverlayUrl,
  });

  final String label;
  final IconData icon;
  final String tileUrl;
  final List<String> subdomains;
  final bool supportsRetina;
  final String? labelOverlayUrl;

  /// The tooltip names where the button GOES, not where it is — a button
  /// labelled with the current state reads like it is already selected.
  String get nextLabel {
    final next = _MapStyle.values[(index + 1) % _MapStyle.values.length];
    return next.label;
  }
}

/// The little triangle under an avatar pin.
class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // flutter_map exports its own Path<LatLng>, which shadows dart:ui's.
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PinTailPainter oldDelegate) => oldDelegate.color != color;
}
