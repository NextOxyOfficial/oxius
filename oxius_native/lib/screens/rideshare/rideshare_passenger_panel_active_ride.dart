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
    return const AdsyProBadge();
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
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        height: 1.35),
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
    final canCancelRide = ride.passengerCanCancel &&
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(15)),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF1F5F9)),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (ride.isSearching)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: AdsyLoadingIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF0F172A),
                          ),
                        )
                      else
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: ride.isInProgress
                                ? const Color(0xFF10B981)
                                : const Color(0xFF0F172A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _passengerStatusLabel(ride),
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
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

                      if (ride.isCancelled &&
                          _shouldShowCancellationReason(ride)) ...[
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
                            _buildStatItem(
                                t('rideshare_fare', fallback: 'Fare'),
                                '৳${ride.payableFare.toStringAsFixed(0)}'),
                            _buildStatDivider(),
                            _buildStatItem(
                                t('rideshare_distance', fallback: 'Distance'),
                                '${_currentPassengerDistanceKm(ride).toStringAsFixed(1)} km'),
                            _buildStatDivider(),
                            _buildStatItem(t('rideshare_eta', fallback: 'ETA'),
                                _currentPassengerEta(ride)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
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
                              t('rideshare_payment_method',
                                  fallback: 'Payment Method'),
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
                                  side: const BorderSide(
                                      color: Color(0xFF6366F1)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  t('rideshare_continue_ride',
                                      fallback: 'Continue Ride'),
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _confirmEarlyCompletion(true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  t('rideshare_confirm_payment',
                                      fallback: 'Confirm Payment'),
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (canCancelRide)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                _isCancellingRide ? null : _confirmCancelRide,
                            icon: _isCancellingRide
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: AdsyLoadingIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : const Icon(Icons.cancel_outlined, size: 18),
                            label: Text(
                              _isCancellingRide
                                  ? 'Cancelling...'
                                  : (ride.isSearching
                                      ? t('rideshare_cancel_request',
                                          fallback: 'Cancel Request')
                                      : t('rideshare_cancel_ride',
                                          fallback: 'Cancel Ride')),
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
                            onPressed: _isReportingCancellation
                                ? null
                                : _reportDriverCancellation,
                            icon: _isReportingCancellation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: AdsyLoadingIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.report_problem_rounded,
                                    size: 18),
                            label: Text(
                              _isReportingCancellation
                                  ? t('rideshare_submitting',
                                      fallback: 'Submitting...')
                                  : t('rideshare_report_driver_cancellation',
                                      fallback: 'Report Driver Cancellation'),
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700),
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
            icon: ride.isInProgress
                ? Icons.navigation_rounded
                : Icons.radar_rounded,
            title: t('rideshare_live_trip_map', fallback: 'Live Trip Map'),
            subtitle: ride.isInProgress
                ? t('rideshare_live_trip_map_subtitle',
                    fallback:
                        'Track the ride path, your driver and destination in one place.')
                : t('rideshare_driver_arrival_map_subtitle',
                    fallback:
                        'Watch your driver approach in real time with the active route preview.'),
            badge: ride.isInProgress
                ? t('rideshare_live_badge', fallback: 'Live')
                : t('rideshare_tracking_badge', fallback: 'Tracking'),
            accentColor: ride.isInProgress
                ? const Color(0xFF0F766E)
                : const Color(0xFF6366F1),
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
      return t('rideshare_finding_driver_status',
          fallback: 'Looking for a driver');
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
                const SizedBox(height: 3),
                _buildDriverRatingPill(driver),
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
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
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
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  // ── Driver rating + reviews ───────────────────────────────────────────────

  /// The ★ pill on the driver card. Tapping it opens the reviews behind the
  /// number — a rating you cannot inspect is just a decoration.
  Widget _buildDriverRatingPill(DriverProfile driver) {
    final hasRatings = driver.ratingCount > 0;
    return GestureDetector(
      onTap: () => _showDriverReviewsSheet(driver),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded,
                size: 14, color: Color(0xFFF59E0B)),
            const SizedBox(width: 3),
            Text(
              hasRatings
                  ? '${driver.ratingAverage.toStringAsFixed(2)} '
                      '(${driver.ratingCount})'
                  : 'নতুন ড্রাইভার',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF92400E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDriverReviewsSheet(DriverProfile driver) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DriverReviewsSheet(driver: driver),
    );
  }

  // ── Completed ride: receipt + rating ──────────────────────────────────────

  Widget _buildRideSuccessView() {
    final ride = _completedRide!;
    final driver = ride.assignedDriver;
    final fare = ride.finalFare ?? ride.fareEstimate;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // The badge-check moment.
                Container(
                  width: 74,
                  height: 74,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 18),
                Text(
                  'রাইড সম্পন্ন হয়েছে!',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'আশা করি যাত্রাটি ভালো লেগেছে',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 22),
                // Receipt
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow('কোথা থেকে', ride.pickupAddress),
                      const SizedBox(height: 10),
                      _buildReceiptRow('গন্তব্য', ride.dropAddress),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildReceiptRow(
                              'মোট ভাড়া',
                              '৳${fare.toStringAsFixed(0)}',
                              emphasize: true,
                            ),
                          ),
                          if (driver != null)
                            Expanded(
                              child: _buildReceiptRow(
                                'ড্রাইভার',
                                driver.userName,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                // Rate the driver — the receipt is where the verdict happens.
                if (driver != null && !_rideRatingSubmitted) ...[
                  Text(
                    'ড্রাইভারকে রেটিং দিন',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final filled = i < _ratingStars;
                      return GestureDetector(
                        onTap: () => _rebuild(() => _ratingStars = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 36,
                            color: filled
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ratingCommentController,
                    maxLines: 2,
                    style: GoogleFonts.inter(
                        fontSize: 13.5, color: const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'অভিজ্ঞতা লিখুন (ঐচ্ছিক)',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _ratingStars > 0 && !_isSubmittingRating
                          ? _submitDriverRating
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: const Color(0xFF94A3B8),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmittingRating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: AdsyLoadingIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'রেটিং জমা দিন',
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ] else if (_rideRatingSubmitted) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 18, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(
                        'রেটিংয়ের জন্য ধন্যবাদ!',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _resetAfterCompletedRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'নতুন রাইড খুঁজুন',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value,
      {bool emphasize = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: emphasize ? 17 : 13,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Future<void> _submitDriverRating() async {
    final ride = _completedRide;
    if (ride == null || _ratingStars < 1) return;
    _rebuild(() => _isSubmittingRating = true);
    final result = await RideshareService.rateRide(
      rideId: ride.id,
      stars: _ratingStars,
      comment: _ratingCommentController.text.trim(),
    );
    if (!mounted) return;
    _rebuild(() {
      _isSubmittingRating = false;
      if (result.success) _rideRatingSubmitted = true;
    });
    if (!result.success) {
      AdsyToast.error(context, 'রেটিং জমা দেওয়া যায়নি — আবার চেষ্টা করুন');
    }
  }

  void _resetAfterCompletedRide() {
    _rebuild(() {
      _dismissedCompletedRideId = _completedRide?.id;
      _completedRide = null;
      _ratingStars = 0;
      _rideRatingSubmitted = false;
      _ratingCommentController.clear();
      _bookingStep = 0;
      _dropController.clear();
      _dropPoint = null;
      _estimate = null;
    });
  }
}

/// The reviews behind a driver's rating pill: aggregate on top, then the
/// individual verdicts, newest first, with a load-more tail.
class _DriverReviewsSheet extends StatefulWidget {
  final DriverProfile driver;
  const _DriverReviewsSheet({required this.driver});

  @override
  State<_DriverReviewsSheet> createState() => _DriverReviewsSheetState();
}

class _DriverReviewsSheetState extends State<_DriverReviewsSheet> {
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasNext = false;
  int _page = 1;
  double _average = 0;
  int _count = 0;
  final List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (more) {
      setState(() => _loadingMore = true);
    }
    final result = await RideshareService.fetchDriverReviews(
      widget.driver.userId,
      page: more ? _page + 1 : 1,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
      final data = result.data;
      if (result.success && data != null) {
        _average =
            double.tryParse(data['average']?.toString() ?? '') ?? _average;
        _count = int.tryParse(data['count']?.toString() ?? '') ?? _count;
        _page = int.tryParse(data['page']?.toString() ?? '') ?? _page;
        _hasNext = data['has_next'] == true;
        final rows = data['results'];
        if (rows is List) {
          if (!more) _reviews.clear();
          _reviews.addAll(
              rows.whereType<Map>().map((r) => Map<String, dynamic>.from(r)));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: height * 0.75),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF1F5F9),
                backgroundImage: widget.driver.userAvatar != null
                    ? NetworkImage(widget.driver.userAvatar!)
                    : null,
                child: widget.driver.userAvatar == null
                    ? const Icon(Icons.person_rounded,
                        color: Color(0xFF64748B))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.driver.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${widget.driver.totalTrips}টি সম্পন্ন রাইড',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 18, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(
                        _count > 0 ? _average.toStringAsFixed(2) : '—',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$_countটি রিভিউ',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: AdsyLoadingIndicator(color: Color(0xFF0F172A)),
                  )
                : _reviews.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Text(
                          'এখনো কোনো রিভিউ নেই',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(top: 6),
                        itemCount: _reviews.length + (_hasNext ? 1 : 0),
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: Color(0xFFF8FAFC)),
                        itemBuilder: (_, i) {
                          if (i >= _reviews.length) {
                            return Center(
                              child: TextButton(
                                onPressed: _loadingMore
                                    ? null
                                    : () => _load(more: true),
                                child: Text(
                                  _loadingMore ? 'লোড হচ্ছে…' : 'আরো দেখুন',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            );
                          }
                          final r = _reviews[i];
                          final stars =
                              int.tryParse(r['stars']?.toString() ?? '') ?? 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r['rater_name']?.toString() ?? 'যাত্রী',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (s) => Icon(
                                          s < stars
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          size: 13,
                                          color: s < stars
                                              ? const Color(0xFFF59E0B)
                                              : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if ((r['comment']?.toString() ?? '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    r['comment'].toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      height: 1.4,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
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
                            child: AdsyLoadingIndicator(
                              strokeWidth: 2.5,
                              color: accent,
                              value: 0.75,
                            ),
                          ),
                        )
                      else
                        Icon(Icons.location_off_rounded,
                            size: 18, color: _kRed),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                    child: const Icon(Icons.location_off_rounded,
                        size: 24, color: _kRed),
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
                            const Icon(Icons.person_rounded,
                                size: 14, color: _kAmberDark),
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
                              color: const Color(0xFF92400E)
                                  .withValues(alpha: 0.7),
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
