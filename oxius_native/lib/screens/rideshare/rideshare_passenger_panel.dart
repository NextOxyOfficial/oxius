import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/rideshare_models.dart';
import '../../services/rideshare_service.dart';
import 'rideshare_map_widget.dart';

class RidesharePassengerPanel extends StatefulWidget {
  const RidesharePassengerPanel({super.key});

  @override
  State<RidesharePassengerPanel> createState() => _RidesharePassengerPanelState();
}

class _RidesharePassengerPanelState extends State<RidesharePassengerPanel> {
  // Controllers
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  
  // State
  RidePoint? _pickupPoint;
  RidePoint? _dropPoint;
  String _selectedVehicleType = 'bike';
  RideEstimate? _estimate;
  Ride? _activeRide;
  List<RidePoint> _pickupSuggestions = [];
  List<RidePoint> _dropSuggestions = [];
  List<NearbyDriver> _nearbyDrivers = [];
  
  // Loading states
  bool _isLoadingLocation = false;
  bool _isEstimating = false;
  bool _isCreatingRide = false;
  bool _isCancellingRide = false;
  bool _isLoadingActiveRide = true;
  
  // Focus
  String _activeInput = 'pickup'; // 'pickup' or 'drop'
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadActiveRide();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveRide() async {
    setState(() => _isLoadingActiveRide = true);
    final result = await RideshareService.getActiveRide();
    if (mounted) {
      setState(() {
        _activeRide = result.data;
        _isLoadingActiveRide = false;
      });
    }
  }

  Future<void> _loadActiveRideById(String rideId) async {
    setState(() => _isLoadingActiveRide = true);
    final result = await RideshareService.getRide(rideId);
    if (mounted) {
      setState(() {
        _activeRide = result.data;
        _isLoadingActiveRide = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          setState(() => _isLoadingLocation = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showError('Location permission permanently denied. Please enable in settings.');
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Reverse geocode
      final result = await RideshareService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (mounted && result.success && result.data != null) {
        setState(() {
          _pickupPoint = result.data;
          _pickupController.text = result.data!.name;
          _pickupSuggestions = [];
          _activeInput = 'drop';
        });
        _loadNearbyDrivers();
        _requestEstimate();
        _showSuccess('Location found');
      } else {
        _showError('Could not resolve location');
      }
    } catch (e) {
      _showError('Failed to get location: $e');
    }
    
    if (mounted) {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _onPickupSearch(String query) {
    _searchDebounce?.cancel();
    if (query.length < 3) {
      setState(() => _pickupSuggestions = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final result = await RideshareService.searchLocations(query);
      if (mounted && result.success) {
        setState(() => _pickupSuggestions = result.data ?? []);
      }
    });
  }

  void _onDropSearch(String query) {
    _searchDebounce?.cancel();
    if (query.length < 3) {
      setState(() => _dropSuggestions = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final result = await RideshareService.searchLocations(query);
      if (mounted && result.success) {
        setState(() => _dropSuggestions = result.data ?? []);
      }
    });
  }

  void _selectPickupSuggestion(RidePoint point) {
    setState(() {
      _pickupPoint = point;
      _pickupController.text = point.name;
      _pickupSuggestions = [];
      _activeInput = 'drop';
    });
    _loadNearbyDrivers();
    _requestEstimate();
  }

  void _selectDropSuggestion(RidePoint point) {
    setState(() {
      _dropPoint = point;
      _dropController.text = point.name;
      _dropSuggestions = [];
    });
    _requestEstimate();
  }

  Future<void> _loadNearbyDrivers() async {
    if (_pickupPoint == null) return;
    final result = await RideshareService.getNearbyDrivers(
      _pickupPoint!.latitude,
      _pickupPoint!.longitude,
      vehicleType: _selectedVehicleType,
    );
    if (mounted && result.success) {
      setState(() => _nearbyDrivers = result.data ?? []);
    }
  }

  Future<void> _requestEstimate() async {
    if (_pickupPoint == null || _dropPoint == null) return;
    
    setState(() => _isEstimating = true);
    
    final result = await RideshareService.estimateRide(
      pickupLatitude: _pickupPoint!.latitude,
      pickupLongitude: _pickupPoint!.longitude,
      dropLatitude: _dropPoint!.latitude,
      dropLongitude: _dropPoint!.longitude,
      vehicleType: _selectedVehicleType,
      pickupAddress: _pickupPoint!.name,
      dropAddress: _dropPoint!.name,
    );
    
    if (mounted) {
      setState(() {
        _estimate = result.data;
        _isEstimating = false;
      });
    }
  }

  Future<void> _createRide() async {
    if (_pickupPoint == null || _dropPoint == null) return;
    
    setState(() => _isCreatingRide = true);
    
    final result = await RideshareService.createRide(
      pickupLatitude: _pickupPoint!.latitude,
      pickupLongitude: _pickupPoint!.longitude,
      dropLatitude: _dropPoint!.latitude,
      dropLongitude: _dropPoint!.longitude,
      vehicleType: _selectedVehicleType,
      pickupAddress: _pickupPoint!.name,
      dropAddress: _dropPoint!.name,
    );
    
    if (mounted) {
      setState(() => _isCreatingRide = false);
      
      if (result.success && result.data != null) {
        setState(() => _activeRide = result.data);
        _showSuccess('Ride requested! Finding driver...');
      } else {
        final msg = result.message.toLowerCase();
        if (msg.contains('active ride') || msg.contains('already have')) {
          // Hide booking form with spinner. Use the ride_id from the error
          // response to fetch the specific ride directly — more reliable than
          // calling getActiveRide which can sometimes return null.
          setState(() => _isLoadingActiveRide = true);
          final rideId = result.errors is Map
              ? result.errors['ride_id']?.toString()
              : null;
          if (rideId != null && rideId.isNotEmpty) {
            _loadActiveRideById(rideId);
          } else {
            _loadActiveRide();
          }
        } else {
          _showError(result.message);
        }
      }
    }
  }

  Future<void> _confirmCancelRide() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Cancel Ride?',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to cancel this ride? You can book a new one after cancellation.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Ride',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: const Color(0xFF6366F1))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Yes, Cancel',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) _cancelRide();
  }

  Future<void> _cancelRide() async {
    if (_activeRide == null) return;
    
    setState(() => _isCancellingRide = true);
    
    final result = await RideshareService.cancelRide(
      _activeRide!.id,
      reason: 'Cancelled by passenger',
    );
    
    if (mounted) {
      setState(() => _isCancellingRide = false);
      
      if (result.success) {
        // Clear active ride AND reset the booking form so user starts fresh
        setState(() {
          _activeRide = null;
          _pickupPoint = null;
          _dropPoint = null;
          _estimate = null;
          _nearbyDrivers = [];
          _pickupSuggestions = [];
          _dropSuggestions = [];
          _activeInput = 'pickup';
        });
        _pickupController.clear();
        _dropController.clear();
        _showSuccess('Ride cancelled');
      } else {
        _showError(result.message);
      }
    }
  }

  void _onMapTap(double latitude, double longitude) async {
    final result = await RideshareService.reverseGeocode(latitude, longitude);
    if (!mounted || !result.success || result.data == null) return;
    
    final point = result.data!;
    setState(() {
      if (_activeInput == 'pickup') {
        _pickupPoint = point;
        _pickupController.text = point.name;
        _activeInput = 'drop';
        _loadNearbyDrivers();
      } else {
        _dropPoint = point;
        _dropController.text = point.name;
      }
    });
    _requestEstimate();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingActiveRide) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6366F1),
        ),
      );
    }

    // Active ride takes full priority — booking form is completely hidden
    if (_activeRide != null) {
      return RefreshIndicator(
        color: const Color(0xFF6366F1),
        onRefresh: _loadActiveRide,
        child: _buildActiveRideView(),
      );
    }

    // No active ride — show booking form
    return _buildBookingView();
  }

  Widget _buildActiveRideView() {
    final ride = _activeRide!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Status Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Gradient header with status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: ride.isSearching
                          ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                          : ride.isInProgress
                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: Row(
                    children: [
                      if (ride.isSearching)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _passengerStatusLabel(ride),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        ride.vehicleIcon,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Route info
                      _buildRouteInfo(ride),
                      
                      const SizedBox(height: 16),
                      
                      // Stats row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            _buildStatItem('Fare', '৳${ride.fareEstimate.toStringAsFixed(0)}'),
                            _buildStatDivider(),
                            _buildStatItem('Distance', '${ride.distanceKm.toStringAsFixed(1)} km'),
                            _buildStatDivider(),
                            _buildStatItem('ETA', ride.etaDisplay),
                          ],
                        ),
                      ),
                      
                      // Driver info (if assigned)
                      if (ride.assignedDriver != null) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        _buildDriverInfo(ride.assignedDriver!),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Cancel button
                      if (ride.isSearching || ride.isAccepted || ride.isDriverArriving)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isCancellingRide ? null : _confirmCancelRide,
                            icon: _isCancellingRide
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : const Icon(Icons.cancel_outlined, size: 18),
                            label: Text(
                              _isCancellingRide ? 'Cancelling...' : 'Cancel Ride',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade600,
                              side: BorderSide(color: Colors.red.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Map
          Container(
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: RideshareMapWidget(
              pickupPoint: ride.pickupPoint,
              dropPoint: ride.dropPoint,
              routeGeometry: ride.routeGeometry,
              driverLocation: ride.assignedDriver != null &&
                      ride.assignedDriver!.currentLatitude != null
                  ? RidePoint(
                      name: 'Driver',
                      latitude: ride.assignedDriver!.currentLatitude!,
                      longitude: ride.assignedDriver!.currentLongitude!,
                    )
                  : null,
              onMapTap: null,
            ),
          ),
        ],
      ),
    );
  }

  String _passengerStatusLabel(Ride ride) {
    if (ride.isAccepted) {
      return 'Trip Started';
    }
    return ride.statusDisplay;
  }

  Widget _buildRouteInfo(Ride ride) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PICKUP',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6366F1),
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      ride.pickupAddress,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 18,
                  color: const Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DROP',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      ride.dropAddress,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildDriverInfo(DriverProfile driver) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFF1F5F9),
          backgroundImage: driver.userAvatar != null
              ? NetworkImage(driver.userAvatar!)
              : null,
          child: driver.userAvatar == null
              ? const Icon(Icons.person_rounded, color: Color(0xFF64748B))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driver.userName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              if (driver.defaultVehicle != null)
                Text(
                  '${driver.defaultVehicle!.vehicleIcon} ${driver.defaultVehicle!.registrationNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
            ],
          ),
        ),
        if (driver.userPhone.isNotEmpty)
          GestureDetector(
            onTap: () async {
              final uri = Uri(scheme: 'tel', path: driver.userPhone);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.25),
                ),
              ),
              child: const Icon(
                Icons.phone_rounded,
                size: 20,
                color: Color(0xFF10B981),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBookingView() {
    return RefreshIndicator(
      color: const Color(0xFF6366F1),
      onRefresh: _loadActiveRide,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
        child: Column(
          children: [
            // Booking form card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.route_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book a Ride',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Enter locations to get started',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLocationInputs(),
                  const SizedBox(height: 16),
                  _buildVehicleSelector(),
                  if (_estimate != null || _isEstimating) ...[
                    const SizedBox(height: 16),
                    _buildEstimateCard(),
                  ],
                  const SizedBox(height: 16),
                  _buildBookButton(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: RideshareMapWidget(
                pickupPoint: _pickupPoint,
                dropPoint: _dropPoint,
                routeGeometry: _estimate?.routeGeometry,
                nearbyDrivers: _nearbyDrivers,
                activeSelection: _activeInput,
                onMapTap: _onMapTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInputs() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route indicator
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 50,
              color: const Color(0xFFE2E8F0),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        
        // Input fields
        Expanded(
          child: Column(
            children: [
              // Pickup input
              _buildLocationInput(
                controller: _pickupController,
                label: 'Pickup Location',
                hint: 'Search pickup...',
                isActive: _activeInput == 'pickup',
                onTap: () => setState(() => _activeInput = 'pickup'),
                onChanged: _onPickupSearch,
                suggestions: _pickupSuggestions,
                onSuggestionTap: _selectPickupSuggestion,
                trailing: _buildCurrentLocationButton(),
              ),
              const SizedBox(height: 12),
              
              // Drop input
              _buildLocationInput(
                controller: _dropController,
                label: 'Drop Location',
                hint: 'Search drop...',
                isActive: _activeInput == 'drop',
                onTap: () => setState(() => _activeInput = 'drop'),
                onChanged: _onDropSearch,
                suggestions: _dropSuggestions,
                onSuggestionTap: _selectDropSuggestion,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isActive,
    required VoidCallback onTap,
    required Function(String) onChanged,
    required List<RidePoint> suggestions,
    required Function(RidePoint) onSuggestionTap,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                width: isActive ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TextField(
                        controller: controller,
                        onChanged: onChanged,
                        onTap: onTap,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
        
        // Suggestions dropdown
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return InkWell(
                  onTap: () => onSuggestionTap(suggestion),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            suggestion.name,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentLocationButton() {
    return GestureDetector(
      onTap: _isLoadingLocation ? null : _useCurrentLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _isLoadingLocation
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.my_location_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Current',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVehicleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Type',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildVehicleOption('bike', '🏍️', 'Bike'),
            const SizedBox(width: 8),
            _buildVehicleOption('car', '🚗', 'Car'),
            const SizedBox(width: 8),
            _buildVehicleOption('cng', '🛺', 'CNG'),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleOption(String type, String icon, String label) {
    final isSelected = _selectedVehicleType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedVehicleType = type);
          _loadNearbyDrivers();
          _requestEstimate();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstimateCard() {
    if (_isEstimating) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Calculating fare...',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTIMATED FARE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '৳${_estimate!.fare.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.straighten_rounded,
                      size: 12,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_estimate!.distanceKm.toStringAsFixed(1)} km',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _estimate!.etaDisplay,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    final canBook = _pickupPoint != null && _dropPoint != null && _estimate != null;
    
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: canBook
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : null,
        child: ElevatedButton(
          onPressed: canBook && !_isCreatingRide ? _createRide : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canBook ? Colors.transparent : const Color(0xFFE2E8F0),
            foregroundColor: canBook ? Colors.white : const Color(0xFF94A3B8),
            disabledForegroundColor: const Color(0xFF94A3B8),
            disabledBackgroundColor: const Color(0xFFE2E8F0),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: _isCreatingRide
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canBook ? Icons.directions_car_rounded : Icons.edit_location_alt_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      canBook ? 'Book Ride Now' : 'Enter locations to book',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
