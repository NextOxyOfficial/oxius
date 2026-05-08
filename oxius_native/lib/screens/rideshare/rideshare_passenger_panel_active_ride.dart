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
                        _buildSearchStatusCard(ride),
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

  // ── Search Status Card ───────────────────────────────────────────────────────

  Widget _buildSearchStatusCard(Ride ride) {
    final now = DateTime.now();
    final secondsRemaining = _targetedRemainingSeconds(ride, now: now);
    final targetedDriverName = _currentTargetedDriverName(ride);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _noDriversInRange ? Icons.location_off_rounded : Icons.radar_rounded,
                size: 18,
                color: _noDriversInRange ? const Color(0xFFDC2626) : const Color(0xFFD97706),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _searchStatusMessage,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _noDriversInRange ? const Color(0xFFDC2626) : const Color(0xFF92400E),
                  ),
                ),
              ),
              if (targetedDriverName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _formatDuration(secondsRemaining),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (_noDriversInRange) ...[
            Text(
              'আপনার এলাকায় কোনো ড্রাইভার পাওয়া যাচ্ছে না। শহর এলাকা থেকে চেষ্টা করুন।',
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFDC2626), height: 1.4),
            ),
            const SizedBox(height: 4),
          ],
          if (targetedDriverName.isNotEmpty) ...[
            Text(
              'Current driver: $targetedDriverName',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF92400E)),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
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
