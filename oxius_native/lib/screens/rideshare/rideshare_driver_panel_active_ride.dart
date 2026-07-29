part of 'rideshare_driver_panel.dart';

// ignore_for_file: unused_element

/// The ride the driver is currently on: its card, the status pill, the action
/// buttons, and the early-completion / complete-ride flows.
extension _RsDriverActiveRideSection on _RideshareDriverPanelState {
  Widget _buildActiveRideCard() {
    final ride = _activeRide!;
    return Column(children: [
      Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _slate200)),
        child: Column(children: [
          // Gradient header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(children: [
              const Icon(Icons.directions_car_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      t('rideshare_active_ride', fallback: 'চলমান রাইড'),
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white))),
              _buildStatusPill(ride.statusDisplay),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              // যাত্রী row
              Row(children: [
                GestureDetector(
                  onTap: () => _openBusinessProfile(ride.riderId),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: _slate100,
                    backgroundImage: ride.riderAvatar != null
                        ? NetworkImage(ride.riderAvatar!)
                        : null,
                    child: ride.riderAvatar == null
                        ? const Icon(Icons.person_rounded,
                            size: 20, color: _slate500)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: GestureDetector(
                  onTap: () => _openBusinessProfile(ride.riderId),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIdentityRow(
                          name: ride.riderName,
                          isVerified: ride.riderIsVerified,
                          isPro: ride.riderIsPro,
                          completedTrips: ride.riderCompletedTrips,
                          textStyle: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _slate800,
                          ),
                        ),
                        Text(t('rideshare_passenger', fallback: 'যাত্রী'),
                            style: GoogleFonts.inter(
                                fontSize: 11, color: _slate500)),
                      ]),
                )),
                if (_canChatWithPassenger(ride))
                  GestureDetector(
                    onTap: () => _openPassengerChat(ride),
                    child: Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(9),
                        border:
                            Border.all(color: _emerald.withValues(alpha: 0.25)),
                      ),
                      child: Image.asset(
                        'assets/images/chat_icon.png',
                        width: 18,
                        height: 18,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.chat_bubble_rounded,
                          size: 18,
                          color: _emerald,
                        ),
                      ),
                    ),
                  ),
                if ((ride.riderPhone?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _callPassenger(ride),
                    child: Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(9),
                        border:
                            Border.all(color: _emerald.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(
                        Icons.phone_rounded,
                        size: 18,
                        color: _emerald,
                      ),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 12),
              _buildRouteWidget(ride),
              const SizedBox(height: 10),
              Row(children: [
                _buildMini(t('rideshare_fare', fallback: 'ভাড়া'),
                    '৳${ride.payableFare.toStringAsFixed(0)}', _indigo),
                const SizedBox(width: 6),
                _buildMini(
                    t('rideshare_distance', fallback: 'দূরত্ব'),
                    '${_currentDisplayedDistanceKm(ride).toStringAsFixed(1)} km',
                    _slate800),
                const SizedBox(width: 6),
                _buildMini(t('rideshare_eta', fallback: 'সময়'),
                    _currentDisplayedEta(ride), _slate800),
                const Spacer(),
                _buildPaymentBadge(ride.paymentMethod),
              ]),
              const SizedBox(height: 12),
              _buildRideActions(ride),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      _buildMapSectionFrame(
        context: context,
        icon:
            ride.isInProgress ? Icons.navigation_rounded : Icons.route_rounded,
        title: t('rideshare_command_map', fallback: 'ট্রিপ ম্যাপ'),
        subtitle: ride.isInProgress
            ? t('rideshare_command_map_progress_subtitle',
                fallback:
                    'Keep the passenger, route path and live driver position visible while you drive.')
            : t('rideshare_command_map_arrival_subtitle',
                fallback:
                    'Use the route preview to approach pickup with live passenger visibility.'),
        badge: ride.isInProgress
            ? t('rideshare_live_badge', fallback: 'লাইভ')
            : t('rideshare_en_route_badge', fallback: 'পথে'),
        accentColor: ride.isInProgress ? _emeraldDark : _indigo,
        child: RideshareMapWidget(
          pickupPoint: ride.pickupPoint,
          dropPoint: ride.dropPoint,
          routeGeometry: _currentDisplayedRouteGeometry(ride),
          driverLocation: _effectiveDriverCurrentPoint(),
          passengerLocation: _passengerLocation,
          passengerName: ride.riderName.isNotEmpty ? ride.riderName : null,
          passengerAvatar: ride.riderAvatar,
          vehicleType: ride.requestedVehicleType,
          followDriver: ride.isDriverArriving || ride.isInProgress,
        ),
      ),
    ]);
  }

  Widget _buildStatusPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }

  Widget _buildRideActions(Ride ride) {
    if (_isUpdatingStatus) {
      return const Center(
          child: AdsyLoadingIndicator(color: _indigo, strokeWidth: 2));
    }
    switch (ride.status) {
      case 'accepted':
        return Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateRideStatus('cancelled'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(t('cancel', fallback: 'বাতিল'),
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () => _advanceRideWithNavigation('driver_arriving'),
              icon: const Icon(Icons.navigation_rounded, size: 16),
              label: Text(
                  t('rideshare_start_navigation', fallback: 'নেভিগেশন শুরু করুন'),
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              style: FilledButton.styleFrom(
                backgroundColor: _indigo,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]);
      case 'driver_arriving':
        return Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateRideStatus('cancelled'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(t('cancel', fallback: 'বাতিল'),
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () => _advanceRideWithNavigation('in_progress'),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(t('rideshare_start_ride', fallback: 'রাইড শুরু করুন'),
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              style: FilledButton.styleFrom(
                backgroundColor: _emerald,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]);
      case 'in_progress':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateRideStatus('cancelled'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(t('cancel', fallback: 'বাতিল'),
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _showCompleteRideDialog,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(t('rideshare_complete', fallback: 'সম্পন্ন করুন'),
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  style: FilledButton.styleFrom(
                    backgroundColor: _emerald,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _requestEarlyCompletion,
              icon: const Icon(Icons.flag_circle_rounded, size: 18),
              label: Text(
                  t('rideshare_early_complete', fallback: 'আগেই শেষ করুন'),
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      case 'awaiting_passenger_confirmation':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                t('rideshare_awaiting_passenger_confirm',
                    fallback:
                        'Early completion payment awaiting passenger confirmation.'),
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF92400E)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _updateRideStatus('cancelled'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(t('rideshare_cancel_ride', fallback: 'রাইড বাতিল'),
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _requestEarlyCompletion() async {
    final ride = _activeRide;
    if (ride == null || _isUpdatingStatus) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
            t('rideshare_early_complete_confirm_title',
                fallback: 'আগেই শেষ করবেন?'),
            style:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          t('rideshare_early_complete_desc',
              fallback:
                  'This will calculate a partial fare based on distance covered and send a confirmation to the passenger.'),
          style: GoogleFonts.inter(fontSize: 13, color: _slate500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel', fallback: 'বাতিল'),
                style: GoogleFonts.inter(color: _slate500)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(t('rideshare_confirm', fallback: 'নিশ্চিত করুন'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _rebuild(() => _isUpdatingStatus = true);

    // Get live GPS coordinates for accurate distance calculation
    double? lat = _driverProfile?.currentLatitude;
    double? lng = _driverProfile?.currentLongitude;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {
      // Fallback: use last known position or profile coordinates
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          lat = last.latitude;
          lng = last.longitude;
        }
      } catch (_) {}
    }

    final result = await RideshareService.requestEarlyCompletion(
      ride.id,
      latitude: lat,
      longitude: lng,
    );
    if (!mounted) return;

    _rebuild(() => _isUpdatingStatus = false);
    if (result.success && result.data != null) {
      _rebuild(() => _activeRide = result.data);
      _syncRealtimeConnections();
      _showSuccess(t('rideshare_early_complete_requested',
          fallback: 'আগেই শেষ করতে যাত্রীর সম্মতি চাওয়া হয়েছে।'));
    } else {
      _showError(result.message);
    }
  }

  void _showCompleteRideDialog() {
    final ride = _activeRide;
    if (ride == null) return;
    final fare = ride.fareEstimate;
    final paymentMethod =
        ride.paymentMethod.isEmpty ? 'wallet' : ride.paymentMethod;
    final isCash = paymentMethod == 'cash';

    // Fee breakdown (5% platform fee)
    final double feePercent =
        ride.platformFeePercent > 0 ? ride.platformFeePercent : 5.0;
    final double platformFee = (fare * feePercent / 100);
    final double driverEarnings = fare - platformFee;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.flag_rounded, color: _emerald, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  t('rideshare_complete_ride', fallback: 'রাইড শেষ করুন'),
                  style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _slate800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // যাত্রী info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _slate200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _slate100,
                    backgroundImage: ride.riderAvatar != null
                        ? NetworkImage(ride.riderAvatar!)
                        : null,
                    child: ride.riderAvatar == null
                        ? const Icon(Icons.person_rounded,
                            size: 18, color: _slate500)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildIdentityRow(
                      name: ride.riderName,
                      isVerified: ride.riderIsVerified,
                      isPro: ride.riderIsPro,
                      completedTrips: ride.riderCompletedTrips,
                      textStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _slate800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Route summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _slate200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle,
                          size: 10, color: Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride.pickupAddress.isNotEmpty
                              ? ride.pickupAddress
                              : t('rideshare_pickup_location',
                                  fallback: 'পিকআপ লোকেশন'),
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF475569)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(width: 2, height: 12, color: _slate200),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.square_rounded,
                          size: 10, color: _emerald),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride.dropAddress.isNotEmpty
                              ? ride.dropAddress
                              : t('rideshare_drop_location',
                                  fallback: 'গন্তব্য লোকেশন'),
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF475569)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Stats + fare row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _slate200),
                    ),
                    child: Column(
                      children: [
                        Text('${ride.distanceKm.toStringAsFixed(1)} km',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF334155))),
                        Text(t('rideshare_distance', fallback: 'দূরত্ব'),
                            style: GoogleFonts.inter(
                                fontSize: 10, color: _slate400)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _slate200),
                    ),
                    child: Column(
                      children: [
                        Text(ride.etaDisplay,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF334155))),
                        Text('সময়কাল',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: _slate400)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text('৳${fare.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text(t('rideshare_fare', fallback: 'ভাড়া'),
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Payment method info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isCash ? const Color(0xFFFFFBEB) : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCash
                      ? const Color(0xFFFDE68A)
                      : const Color(0xFFC7D2FE),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCash
                        ? Icons.payments_rounded
                        : Icons.account_balance_wallet_rounded,
                    size: 18,
                    color: isCash
                        ? const Color(0xFFD97706)
                        : const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCash
                              ? t('rideshare_cash_payment',
                                  fallback: 'ক্যাশ পেমেন্ট')
                              : t('rideshare_wallet_payment',
                                  fallback: 'ওয়ালেট পেমেন্ট'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isCash
                                ? const Color(0xFF92400E)
                                : const Color(0xFF3730A3),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCash
                              ? 'Collect ৳${fare.toStringAsFixed(0)} from passenger then confirm.'
                              : '৳${fare.toStringAsFixed(0)} will be auto-deducted from passenger wallet.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isCash
                                ? const Color(0xFF78350F)
                                : const Color(0xFF4338CA),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Fee breakdown card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t('rideshare_trip_fare', fallback: 'ট্রিপ ভাড়া'),
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF475569))),
                      Text('৳${fare.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF334155))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${t('rideshare_platform_fee', fallback: 'প্ল্যাটফর্ম ফি')} (${feePercent.toStringAsFixed(0)}%)',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF64748B))),
                      Text('- ৳${platformFee.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFFDC2626))),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Divider(height: 1, color: Color(0xFFBBF7D0)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          t('rideshare_your_earnings',
                              fallback: 'আপনার আয়'),
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF166534))),
                      Text('৳${driverEarnings.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF16A34A))),
                    ],
                  ),
                  if (isCash) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 13, color: Color(0xFFD97706)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '৳${platformFee.toStringAsFixed(0)} ${t('rideshare_cash_fee_due_note', fallback: 'প্ল্যাটফর্ম ফি ক্যাশ বকেয়া হিসেবে যোগ হবে')}',
                              style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: const Color(0xFF92400E),
                                  height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: _slate300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(t('cancel', fallback: 'বাতিল'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateRideStatus('completed',
                          paymentMethod: paymentMethod);
                    },
                    icon: Icon(
                      isCash
                          ? Icons.payments_rounded
                          : Icons.check_circle_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isCash
                          ? t('rideshare_confirm_cash_received',
                              fallback: 'ক্যাশ পেয়েছি, নিশ্চিত করুন')
                          : t('rideshare_confirm_completion',
                              fallback: 'সম্পন্ন নিশ্চিত করুন'),
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isCash ? const Color(0xFFD97706) : _emerald,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
