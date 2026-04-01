import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/rideshare_models.dart';
import '../../services/rideshare_service.dart';

class RideshareHistoryScreen extends StatefulWidget {
  final bool asDriver;
  
  const RideshareHistoryScreen({
    super.key,
    this.asDriver = false,
  });

  @override
  State<RideshareHistoryScreen> createState() => _RideshareHistoryScreenState();
}

class _RideshareHistoryScreenState extends State<RideshareHistoryScreen> {
  List<Ride> _rides = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await RideshareService.listRides(asDriver: widget.asDriver);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _rides = result.data ?? [];
        } else {
          _error = result.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.asDriver ? 'My Trips (Driver)' : 'Ride History',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadRides,
      child: _rides.isNotEmpty
          ? ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: _rides.length,
              itemBuilder: (context, index) => _buildRideCard(_rides[index]),
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.62,
                  child: Center(
                    child: _error != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadRides,
                                child: const Text('Retry'),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.history_rounded,
                                  size: 48,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No rides yet',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.asDriver
                                    ? 'Your completed trips will appear here'
                                    : 'Your ride history will appear here',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getStatusColor(ride.status).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Text(
                  ride.vehicleIcon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(ride.requestedAt),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        _formatTime(ride.requestedAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ride.status),
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
          
          // Route info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRouteRow(
                  icon: Icons.circle,
                  iconColor: const Color(0xFF6366F1),
                  label: 'Pickup',
                  address: ride.pickupAddress,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 2,
                        height: 16,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ],
                  ),
                ),
                _buildRouteRow(
                  icon: Icons.square_rounded,
                  iconColor: const Color(0xFF10B981),
                  label: 'Drop',
                  address: ride.dropAddress,
                ),
                
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                
                // Stats row
                Row(
                  children: [
                    _buildStatItem(
                      icon: Icons.straighten_rounded,
                      value: '${ride.distanceKm.toStringAsFixed(1)} km',
                    ),
                    const SizedBox(width: 16),
                    _buildStatItem(
                      icon: Icons.access_time_rounded,
                      value: ride.etaDisplay,
                    ),
                    const Spacer(),
                    Text(
                      '৳${(ride.finalFare ?? ride.fareEstimate).toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                
                // Driver/Rider info
                if (widget.asDriver && ride.riderName.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFF1F5F9),
                        backgroundImage: ride.riderAvatar != null
                            ? NetworkImage(ride.riderAvatar!)
                            : null,
                        child: ride.riderAvatar == null
                            ? const Icon(Icons.person_rounded, size: 16, color: Color(0xFF64748B))
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.riderName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Passenger',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                
                if (!widget.asDriver && ride.assignedDriver != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFF1F5F9),
                        backgroundImage: ride.assignedDriver!.userAvatar != null
                            ? NetworkImage(ride.assignedDriver!.userAvatar!)
                            : null,
                        child: ride.assignedDriver!.userAvatar == null
                            ? const Icon(Icons.person_rounded, size: 16, color: Color(0xFF64748B))
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.assignedDriver!.userName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            if (ride.vehicle != null)
                              Text(
                                '${ride.vehicle!.vehicleIcon} ${ride.vehicle!.registrationNumber}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
  }) {
    return Row(
      children: [
        Icon(icon, size: 10, color: iconColor),
        const SizedBox(width: 12),
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
                ),
              ),
              Text(
                address,
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
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'in_progress':
        return const Color(0xFF6366F1);
      case 'searching_driver':
      case 'accepted':
      case 'driver_arriving':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
  }
}
