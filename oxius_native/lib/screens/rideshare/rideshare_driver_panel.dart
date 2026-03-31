import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/rideshare_models.dart';
import '../../services/rideshare_service.dart';
import 'rideshare_map_widget.dart';

class RideshareDriverPanel extends StatefulWidget {
  const RideshareDriverPanel({super.key});

  @override
  State<RideshareDriverPanel> createState() => _RideshareDriverPanelState();
}

class _RideshareDriverPanelState extends State<RideshareDriverPanel> {
  // State
  DriverProfile? _driverProfile;
  Ride? _activeRide;
  List<Ride> _availableRequests = [];
  DriverEarningsSummary? _earnings;
  
  // Loading states
  bool _isLoading = true;
  bool _isTogglingOnline = false;
  bool _isAcceptingRide = false;
  bool _isUpdatingStatus = false;
  
  // Location tracking
  StreamSubscription<Position>? _locationSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_driverProfile?.isOnline == true && _activeRide == null) {
        _loadAvailableRequests();
      }
    });
  }

  Future<void> _loadDriverData() async {
    setState(() => _isLoading = true);
    
    final results = await Future.wait([
      RideshareService.getDriverProfile(),
      RideshareService.getActiveRide(),
      RideshareService.getDriverEarningsSummary(),
    ]);
    
    final profileResult = results[0] as RideshareApiResult<DriverProfile>;
    final activeRideResult = results[1] as RideshareApiResult<Ride?>;
    final earningsResult = results[2] as RideshareApiResult<DriverEarningsSummary>;
    
    if (mounted) {
      setState(() {
        _driverProfile = profileResult.data;
        _activeRide = activeRideResult.data;
        _earnings = earningsResult.data;
        _isLoading = false;
      });
      
      if (_driverProfile?.isOnline == true) {
        _startLocationTracking();
        if (_activeRide == null) {
          _loadAvailableRequests();
        }
      }
    }
  }

  Future<void> _loadAvailableRequests() async {
    final result = await RideshareService.listAvailableRideRequests();
    if (mounted && result.success) {
      setState(() => _availableRequests = result.data ?? []);
    }
  }

  Future<void> _toggleOnline() async {
    if (_driverProfile == null) return;
    
    setState(() => _isTogglingOnline = true);
    
    final newStatus = !_driverProfile!.isOnline;
    final result = await RideshareService.toggleDriverOnline(newStatus);
    
    if (mounted) {
      setState(() => _isTogglingOnline = false);
      
      if (result.success && result.data != null) {
        setState(() => _driverProfile = result.data);
        
        if (newStatus) {
          _startLocationTracking();
          _loadAvailableRequests();
          _showSuccess('You are now online');
        } else {
          _stopLocationTracking();
          setState(() => _availableRequests = []);
          _showSuccess('You are now offline');
        }
      } else {
        _showError(result.message);
      }
    }
  }

  void _startLocationTracking() async {
    _locationSubscription?.cancel();
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        _showError('Location permission required for driver mode');
        return;
      }
      
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((position) {
        _updateDriverLocation(position);
      });
    } catch (e) {
      _showError('Failed to start location tracking: $e');
    }
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  Future<void> _updateDriverLocation(Position position) async {
    await RideshareService.updateDriverLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      rideId: _activeRide?.id,
      heading: position.heading,
      speedKph: position.speed * 3.6, // Convert m/s to km/h
      accuracyMeters: position.accuracy,
    );
  }

  Future<void> _acceptRide(Ride ride) async {
    setState(() => _isAcceptingRide = true);
    
    final result = await RideshareService.acceptRide(ride.id);
    
    if (mounted) {
      setState(() => _isAcceptingRide = false);
      
      if (result.success && result.data != null) {
        setState(() {
          _activeRide = result.data;
          _availableRequests = [];
        });
        _showSuccess('Ride accepted!');
      } else {
        _showError(result.message);
        _loadAvailableRequests(); // Refresh list
      }
    }
  }

  Future<void> _updateRideStatus(String status, {double? finalFare}) async {
    if (_activeRide == null) return;
    
    setState(() => _isUpdatingStatus = true);
    
    final result = await RideshareService.updateRideStatus(
      _activeRide!.id,
      status,
      finalFare: finalFare,
    );
    
    if (mounted) {
      setState(() => _isUpdatingStatus = false);
      
      if (result.success && result.data != null) {
        if (status == 'completed' || status == 'cancelled') {
          setState(() => _activeRide = null);
          _loadAvailableRequests();
          _loadDriverData(); // Refresh earnings
          _showSuccess(status == 'completed' ? 'Ride completed!' : 'Ride cancelled');
        } else {
          setState(() => _activeRide = result.data);
        }
      } else {
        _showError(result.message);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_driverProfile == null) {
      return _buildNoDriverProfile();
    }

    if (!_driverProfile!.isApproved) {
      return _buildPendingApproval();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildStatusCard(),
          const SizedBox(height: 12),
          _buildEarningsCard(),
          const SizedBox(height: 12),
          if (_activeRide != null)
            _buildActiveRideCard()
          else if (_driverProfile!.isOnline)
            _buildAvailableRequestsCard(),
        ],
      ),
    );
  }

  Widget _buildNoDriverProfile() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.badge_outlined,
                size: 48,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Become a Driver',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Register as a driver to start accepting ride requests and earn money.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to driver registration
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Register as Driver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApproval() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 48,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Approval Pending',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your driver registration is under review. You will be notified once approved.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isOnline = _driverProfile!.isOnline;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isOnline
            ? const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isOnline ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isOnline ? null : Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOnline 
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              size: 24,
              color: isOnline ? Colors.white : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'You are Online' : 'You are Offline',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isOnline ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  isOnline 
                      ? 'Accepting ride requests'
                      : 'Go online to receive requests',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isOnline 
                        ? Colors.white.withOpacity(0.8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isTogglingOnline ? null : _toggleOnline,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 32,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isOnline 
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isOnline ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.white : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                  child: _isTogglingOnline
                      ? const Padding(
                          padding: EdgeInsets.all(5),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildEarningItem(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Earnings',
              value: '৳${(_earnings?.totalEarnings ?? 0).toStringAsFixed(0)}',
              color: const Color(0xFF10B981),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFE2E8F0),
          ),
          Expanded(
            child: _buildEarningItem(
              icon: Icons.directions_car_rounded,
              label: 'Total Trips',
              value: '${_earnings?.totalTrips ?? 0}',
              color: const Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveRideCard() {
    final ride = _activeRide!;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_car_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active Ride',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ride.statusDisplay,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Passenger info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFF1F5F9),
                      backgroundImage: ride.riderAvatar != null
                          ? NetworkImage(ride.riderAvatar!)
                          : null,
                      child: ride.riderAvatar == null
                          ? const Icon(Icons.person_rounded, color: Color(0xFF64748B))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.riderName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Passenger',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (ride.riderPhone != null)
                      IconButton(
                        onPressed: () {
                          // TODO: Call passenger
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_rounded,
                            size: 20,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                
                // Route info
                _buildRouteInfo(ride),
                
                const SizedBox(height: 16),
                
                // Stats
                Row(
                  children: [
                    _buildStatItem('Fare', '৳${ride.fareEstimate.toStringAsFixed(0)}'),
                    _buildStatDivider(),
                    _buildStatItem('Distance', '${ride.distanceKm.toStringAsFixed(1)} km'),
                    _buildStatDivider(),
                    _buildStatItem('ETA', ride.etaDisplay),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action buttons
                _buildRideActionButtons(ride),
              ],
            ),
          ),
          
          // Map
          Container(
            height: 200,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: RideshareMapWidget(
              pickupPoint: ride.pickupPoint,
              dropPoint: ride.dropPoint,
              routeGeometry: ride.routeGeometry,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(Ride ride) {
    return Column(
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
                    'Pickup',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
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
                height: 20,
                color: const Color(0xFFE2E8F0),
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
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drop',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
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

  Widget _buildRideActionButtons(Ride ride) {
    if (_isUpdatingStatus) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    switch (ride.status) {
      case 'accepted':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateRideStatus('cancelled'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _updateRideStatus('driver_arriving'),
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text('Start Navigation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
        
      case 'driver_arriving':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateRideStatus('in_progress'),
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text('Start Ride'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
        
      case 'in_progress':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showCompleteRideDialog(),
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text('Complete Ride'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  void _showCompleteRideDialog() {
    final fareController = TextEditingController(
      text: _activeRide!.fareEstimate.toStringAsFixed(0),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Complete Ride',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the final fare amount:',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: fareController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '৳ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final fare = double.tryParse(fareController.text);
              _updateRideStatus('completed', finalFare: fare);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableRequestsCard() {
    if (_availableRequests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              'Waiting for Requests',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'New ride requests will appear here',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Available Requests',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        ..._availableRequests.map((ride) => _buildRequestCard(ride)),
      ],
    );
  }

  Widget _buildRequestCard(Ride ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header with fare
          Row(
            children: [
              Text(
                ride.vehicleIcon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.riderName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '${ride.distanceKm.toStringAsFixed(1)} km • ${ride.etaDisplay}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '৳${ride.fareEstimate.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          
          // Route
          _buildRouteInfo(ride),
          
          const SizedBox(height: 16),
          
          // Accept button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAcceptingRide ? null : () => _acceptRide(ride),
              icon: _isAcceptingRide
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 20),
              label: Text(_isAcceptingRide ? 'Accepting...' : 'Accept Ride'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
