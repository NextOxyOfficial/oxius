part of 'rideshare_passenger_panel.dart';

// ignore_for_file: unused_element
extension _RsActiveRideExtension on _RidesharePassengerPanelState {
  // ── Driver Badge Builders ───────────────────────────────────────────────────

  Widget _buildVerifiedBadge() {
    return const Icon(
      Icons.verified,
      size: 15,
      color: Color(0xFF3B82F6),
    );
  }

  Widget _buildProBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Pro',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTripsBadge(int completedTrips) {
    final label = completedTrips == 1 ? '1 trip' : '$completedTrips trips';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0369A1),
        ),
      ),
    );
  }

  Widget _buildIdentityRow({
    required String name,
    required bool isVerified,
    required bool isPro,
    required int completedTrips,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        if (isVerified) _buildVerifiedBadge(),
        if (isPro) _buildProBadge(),
        _buildTripsBadge(completedTrips),
      ],
    );
  }

  // ── Payment Method Tile (used in early-completion modal) ────────────────────

  Widget _buildPaymentMethodTile(
    BuildContext context, {
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
          color: accent.withValues(alpha: 0.06),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), height: 1.35),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: accent),
          ],
        ),
      ),
    );
  }

  // ── Active Ride View ─────────────────────────────────────────────────────────

  Widget _buildActiveRideView() {
    final ride = _activeRide!;
    final canCancelRide =
      ride.passengerCanCancel &&
      !ride.isInProgress &&
      !ride.isAwaitingPassengerConfirmation &&
      !ride.isCompleted &&
      !ride.isCancelled;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
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
                  color: Colors.black.withValues(alpha: 0.04),
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

                      if (ride.isCancelled && _shouldShowCancellationReason(ride)) ...[
                        const SizedBox(height: 12),
                        _buildCancellationReasonCard(ride),
                      ],

                      if (ride.isSearching) ...[
                        const SizedBox(height: 12),
                        _SearchingDriverCard(
                          statusMessage: _searchStatusMessage,
                          noDriversInRange: _noDriversInRange,
                          targetedDriverName: _currentTargetedDriverName(ride),
                          secondsRemaining: _targetedRemainingSeconds(ride),
                          dispatchAttempt: _dispatchAttempt,
                        ),
                      ],
                      
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
                            _buildStatItem(t('rideshare_fare', fallback: 'Fare'), '৳${ride.payableFare.toStringAsFixed(0)}'),
                            _buildStatDivider(),
                            _buildStatItem(t('rideshare_distance', fallback: 'Distance'), '${_currentPassengerDistanceKm(ride).toStringAsFixed(1)} km'),
                            _buildStatDivider(),
                            _buildStatItem(t('rideshare_eta', fallback: 'ETA'), _currentPassengerEta(ride)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              ride.paymentMethod == 'cash'
                                  ? Icons.payments_rounded
                                  : Icons.account_balance_wallet_rounded,
                              size: 15,
                              color: ride.paymentMethod == 'cash'
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              t('rideshare_payment_method', fallback: 'Payment Method'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              ride.paymentMethod == 'cash'
                                  ? t('rideshare_cash', fallback: 'Cash')
                                  : t('rideshare_wallet', fallback: 'Wallet'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ride.paymentMethod == 'cash'
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF6366F1),
                              ),
                            ),
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

                      if (ride.isAwaitingPassengerConfirmation)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _confirmEarlyCompletion(false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6366F1),
                                  side: const BorderSide(color: Color(0xFF6366F1)),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  t('rideshare_continue_ride', fallback: 'Continue Ride'),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _confirmEarlyCompletion(true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  t('rideshare_confirm_payment', fallback: 'Confirm Payment'),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (canCancelRide)
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
                              _isCancellingRide
                                  ? 'Cancelling...'
                                  : (ride.isSearching ? t('rideshare_cancel_request', fallback: 'Cancel Request') : t('rideshare_cancel_ride', fallback: 'Cancel Ride')),
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
                        )
                      else if (ride.canReportDriver)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isReportingCancellation ? null : _reportDriverCancellation,
                            icon: _isReportingCancellation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.report_problem_rounded, size: 18),
                            label: Text(
                              _isReportingCancellation ? t('rideshare_submitting', fallback: 'Submitting...') : t('rideshare_report_driver_cancellation', fallback: 'Report Driver Cancellation'),
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEA580C),
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
          
          _buildMapSectionFrame(
            context: context,
            icon: ride.isInProgress ? Icons.navigation_rounded : Icons.radar_rounded,
            title: t('rideshare_live_trip_map', fallback: 'Live Trip Map'),
            subtitle: ride.isInProgress
                ? t('rideshare_live_trip_map_subtitle', fallback: 'Track the ride path, your driver and destination in one place.')
                : t('rideshare_driver_arrival_map_subtitle', fallback: 'Watch your driver approach in real time with the active route preview.'),
            badge: ride.isInProgress
                ? t('rideshare_live_badge', fallback: 'Live')
                : t('rideshare_tracking_badge', fallback: 'Tracking'),
            accentColor: ride.isInProgress ? const Color(0xFF0F766E) : const Color(0xFF6366F1),
            child: RideshareMapWidget(
              pickupPoint: ride.pickupPoint,
              dropPoint: ride.dropPoint,
              routeGeometry: _currentPassengerRouteGeometry(ride),
              driverLocation: _currentDriverPoint(ride),
              driverHeading: ride.latestDriverLocation?.heading,
              driverName: ride.assignedDriver?.userName,
              driverAvatar: ride.assignedDriver?.userAvatar,
              driverVehicleInfo: _driverMapVehicleInfo(ride),
              vehicleType: ride.requestedVehicleType,
              followDriver: ride.isDriverArriving || ride.isInProgress,
              onMapTap: null,
            ),
          ),
        ],
      ),
    );
  }

  String _passengerStatusLabel(Ride ride) {
    if (ride.isSearching) {
      return t('rideshare_finding_driver_status', fallback: 'Looking for a driver');
    }
    if (ride.isAccepted) {
      return t('rideshare_driver_assigned', fallback: 'Driver confirmed');
    }
    return ride.statusDisplay;
  }

  // ── Route Info ───────────────────────────────────────────────────────────────

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
                      t('rideshare_pickup', fallback: 'Pickup').toUpperCase(),
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
                      t('rideshare_drop', fallback: 'Drop').toUpperCase(),
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

  bool _shouldShowCancellationReason(Ride ride) {
    final reason = ride.cancellationReason?.trim() ?? '';
    if (reason.isEmpty) {
      return false;
    }
    final lower = reason.toLowerCase();
    return lower.contains('no drivers available') ||
        lower.contains('driver available') ||
        lower.contains('remote area');
  }

  Widget _buildCancellationReasonCard(Ride ride) {
    final reason = ride.cancellationReason?.trim() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row Helpers ────────────────────────────────────────────────────────

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

  // ── Driver Info Card ─────────────────────────────────────────────────────────

  Widget _buildDriverInfo(DriverProfile driver) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _openBusinessProfile(driver.userId),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFF1F5F9),
            backgroundImage: driver.userAvatar != null
                ? NetworkImage(driver.userAvatar!)
                : null,
            child: driver.userAvatar == null
                ? const Icon(Icons.person_rounded, color: Color(0xFF64748B))
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _openBusinessProfile(driver.userId),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIdentityRow(
                  name: driver.userName,
                  isVerified: driver.userIsVerified,
                  isPro: driver.userIsPro,
                  completedTrips: driver.totalTrips,
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
        ),
        if (_activeRide != null && _canChatWithDriver(_activeRide!)) ...[
          GestureDetector(
            onTap: () => _openDriverChat(_activeRide!),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
              ),
              child: Image.asset(
                'assets/images/chat_icon.png',
                width: 18,
                height: 18,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.chat_bubble_rounded,
                    size: 18,
                    color: Color(0xFF10B981),
                  );
                },
              ),
            ),
          ),
        ],
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
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
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
}

// ── Premium Searching Driver Card ───────────────────────────────────────────
// A self-contained StatefulWidget so it manages its own AnimationControllers
// without requiring TickerProviderStateMixin on the parent state class.

class _SearchingDriverCard extends StatefulWidget {
  const _SearchingDriverCard({
    required this.statusMessage,
    required this.noDriversInRange,
    required this.targetedDriverName,
    required this.secondsRemaining,
    required this.dispatchAttempt,
  });

  final String statusMessage;
  final bool noDriversInRange;
  final String targetedDriverName;
  final int secondsRemaining;
  final int dispatchAttempt;

  @override
  State<_SearchingDriverCard> createState() => _SearchingDriverCardState();
}

class _SearchingDriverCardState extends State<_SearchingDriverCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _pulseController2;
  late AnimationController _pulseController3;
  late AnimationController _spinController;
  late Animation<double> _pulse1;
  late Animation<double> _pulse1Opacity;
  late Animation<double> _pulse2;
  late Animation<double> _pulse2Opacity;
  late Animation<double> _pulse3;
  late Animation<double> _pulse3Opacity;
  late Animation<double> _spinAnimation;

  static const _kAmber = Color(0xFFF59E0B);
  static const _kAmberDark = Color(0xFFD97706);
  static const _kAmberLight = Color(0xFFFEF3C7);
  static const _kRed = Color(0xFFDC2626);
  static const _kRedLight = Color(0xFFFEE2E2);

  @override
  void initState() {
    super.initState();

    // Three staggered pulse rings (Uber-style radar)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseController3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Stagger: ring2 starts 600ms later, ring3 starts 1200ms later
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _pulseController2.forward(from: 0);
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _pulseController3.forward(from: 0);
    });

    _pulse1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulse1Opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulse2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController2, curve: Curves.easeOut),
    );
    _pulse2Opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController2, curve: Curves.easeOut),
    );
    _pulse3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController3, curve: Curves.easeOut),
    );
    _pulse3Opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController3, curve: Curves.easeOut),
    );

    // Spinning arc indicator
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _spinAnimation = Tween<double>(begin: 0, end: 1).animate(_spinController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pulseController2.dispose();
    _pulseController3.dispose();
    _spinController.dispose();
    super.dispose();
  }

  String _formatCountdown(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final isNoDriver = widget.noDriversInRange;
    final hasTargeted = widget.targetedDriverName.isNotEmpty;
    final accent = isNoDriver ? _kRed : _kAmber;
    final accentLight = isNoDriver ? _kRedLight : _kAmberLight;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header strip ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: accentLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                // Spinning arc + pulsing dot
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!isNoDriver)
                        RotationTransition(
                          turns: _spinAnimation,
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: accent,
                              value: 0.75,
                            ),
                          ),
                        )
                      else
                        Icon(Icons.location_off_rounded, size: 18, color: _kRed),
                      if (!isNoDriver)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      widget.statusMessage,
                      key: ValueKey(widget.statusMessage),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isNoDriver ? _kRed : _kAmberDark,
                      ),
                    ),
                  ),
                ),
                if (hasTargeted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accent.withValues(alpha: 0.3)),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _formatCountdown(widget.secondsRemaining),
                        key: ValueKey(widget.secondsRemaining),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: accent,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Animated radar + status body ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              children: [
                // Radar pulse animation
                if (!isNoDriver)
                  SizedBox(
                    width: 56,
                    height: 56,
                    // RepaintBoundary isolates the radar animation (3 pulse rings
                    // running concurrently at 60fps) from the rest of the bottom
                    // sheet. Without it, every animation frame invalidates the
                    // whole "Searching for driver" card including text + map.
                    child: RepaintBoundary(
                      child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulse ring 1
                        AnimatedBuilder(
                          animation: _pulse1,
                          builder: (context, _) => Opacity(
                            opacity: _pulse1Opacity.value,
                            child: Container(
                              width: 56 * _pulse1.value,
                              height: 56 * _pulse1.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _kAmber,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Pulse ring 2
                        AnimatedBuilder(
                          animation: _pulse2,
                          builder: (context, _) => Opacity(
                            opacity: _pulse2Opacity.value,
                            child: Container(
                              width: 56 * _pulse2.value,
                              height: 56 * _pulse2.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _kAmber,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Pulse ring 3
                        AnimatedBuilder(
                          animation: _pulse3,
                          builder: (context, _) => Opacity(
                            opacity: _pulse3Opacity.value,
                            child: Container(
                              width: 56 * _pulse3.value,
                              height: 56 * _pulse3.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _kAmber,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Center dot
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: _kAmber,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _kRedLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_off_rounded, size: 24, color: _kRed),
                  ),

                const SizedBox(width: 14),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isNoDriver) ...[
                        Text(
                          'এলাকায় ড্রাইভার নেই',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kRed,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'আপনার এলাকায় কোনো ড্রাইভার পাওয়া যাচ্ছে না। শহর এলাকা থেকে চেষ্টা করুন।',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: _kRed,
                            height: 1.45,
                          ),
                        ),
                      ] else if (hasTargeted) ...[
                        Text(
                          'ড্রাইভারকে অনুরোধ পাঠানো হয়েছে',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kAmberDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.person_rounded, size: 14, color: _kAmberDark),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.targetedDriverName,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'উত্তরের জন্য অপেক্ষা করুন...',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'ড্রাইভার খোঁজা হচ্ছে',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kAmberDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'আশেপাশের ড্রাইভারদের সাথে সংযোগ স্থাপন করা হচ্ছে...',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF92400E),
                            height: 1.4,
                          ),
                        ),
                        if (widget.dispatchAttempt > 0) ...[
                          const SizedBox(height: 3),
                          Text(
                            'ড্রাইভার অনুরোধ #${widget.dispatchAttempt}',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: const Color(0xFF92400E).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
