part of 'rideshare_driver_panel.dart';

// ignore_for_file: unused_element

/// Incoming ride requests: the list, the empty state, and one request card
/// with its countdown and route preview.
extension _RsDriverRequestsSection on _RideshareDriverPanelState {
  Widget _buildRideRequestsCard() {
    final isOnline = _driverProfile?.isOnline == true;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _slate200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: const BoxDecoration(
            color: _slate50,
            borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            border: Border(bottom: BorderSide(color: _slate200)),
          ),
          child: Row(children: [
            const Icon(Icons.hail_rounded, size: 16, color: _indigo),
            const SizedBox(width: 8),
            Text(t('rideshare_ride_requests', fallback: 'রাইড রিকোয়েস্ট'),
                style: AppFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _slate800)),
            const Spacer(),
            if (isOnline && _availableRequests.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: _emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('${_availableRequests.length}',
                    style: AppFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _emerald)),
              ),
            if (isOnline)
              GestureDetector(
                onTap: _loadAvailableRequests,
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: _slate100, borderRadius: BorderRadius.circular(6)),
                  child: Text(t('rideshare_refresh', fallback: 'রিফ্রেশ'),
                      style: AppFonts.roboto(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _slate500)),
                ),
              ),
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isOnline ? _emerald.withValues(alpha: 0.12) : _slate100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                  isOnline
                      ? t('rideshare_online_label', fallback: 'অনলাইন')
                      : t('rideshare_offline_status', fallback: 'অফলাইন'),
                  style: AppFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isOnline ? _emerald : _slate500)),
            ),
          ]),
        ),
        if (!isOnline)
          _buildEmptyRequests(
              Icons.wifi_off_rounded,
              t('rideshare_you_are_offline', fallback: 'আপনি অফলাইনে আছেন'),
              t('rideshare_go_online_desc',
                  fallback:
                      'Go online using the switch above to receive ride requests.'))
        else if (_availableRequests.isEmpty)
          _buildEmptyRequests(
              Icons.search_rounded,
              t('rideshare_no_requests_yet', fallback: 'এখনো কোনো রিকোয়েস্ট নেই'),
              t('rideshare_requests_auto_appear',
                  fallback:
                      'New ride requests will automatically appear here.'))
        else
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
                children: _availableRequests.map(_buildRequestCard).toList()),
          ),
      ]),
    );
  }

  Widget _buildEmptyRequests(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration:
              const BoxDecoration(color: _slate100, shape: BoxShape.circle),
          child: Icon(icon, size: 28, color: _slate400),
        ),
        const SizedBox(height: 12),
        Text(title,
            style: AppFonts.roboto(
                fontSize: 13, fontWeight: FontWeight.w700, color: _slate800)),
        const SizedBox(height: 4),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: AppFonts.roboto(fontSize: 12, color: _slate500)),
      ]),
    );
  }

  Widget _buildRequestCard(Ride ride) {
    final countdown = ride.targetedCountdownSeconds();
    final isTargeted = ride.targetedDriver != null;
    final isExpired = _isRequestExpired(ride);
    final isSkipping = _skippingRideIds.contains(ride.id);
    final isBusy = _isAcceptingRide || isSkipping;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTargeted && !isExpired ? const Color(0xFFFDE68A) : _slate200,
          width: isTargeted && !isExpired ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isTargeted && !isExpired
                ? const Color(0xFFD97706).withValues(alpha: 0.10)
                : _emerald.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        // ── Header strip ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isTargeted && !isExpired
                ? const Color(0xFFFFFBEB)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            border: Border(
              bottom: BorderSide(color: _slate200, width: 0.8),
            ),
          ),
          child: Row(children: [
            // Vehicle icon circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _indigo.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(ride.vehicleIcon,
                    style: const TextStyle(fontSize: 19)),
              ),
            ),
            const SizedBox(width: 10),

            // Rider info
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIdentityRow(
                  name: ride.riderName,
                  isVerified: ride.riderIsVerified,
                  isPro: ride.riderIsPro,
                  completedTrips: ride.riderCompletedTrips,
                  textStyle: AppFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _slate800),
                ),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.route_rounded, size: 11, color: _slate400),
                  const SizedBox(width: 4),
                  Text(
                    '${ride.distanceKm.toStringAsFixed(1)} km · ${ride.etaDisplay}',
                    style: AppFonts.roboto(fontSize: 11, color: _slate500),
                  ),
                  const SizedBox(width: 6),
                  _buildPaymentBadge(ride.paymentMethod),
                ]),
              ],
            )),

            // Right side: countdown + fare
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (isTargeted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isExpired ? _slate100 : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isExpired ? _slate300 : const Color(0xFFFCD34D),
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      isExpired ? Icons.timer_off_rounded : Icons.timer_rounded,
                      size: 10,
                      color: isExpired ? _slate500 : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isExpired
                          ? t('rideshare_expired', fallback: 'মেয়াদ শেষ')
                          : '${countdown}s',
                      style: AppFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isExpired ? _slate500 : const Color(0xFFD97706),
                      ),
                    ),
                  ]),
                ),
              if (isTargeted) const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: [_emerald, _emeraldDark]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _emerald.withValues(alpha: 0.30),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '৳${ride.fareEstimate.toStringAsFixed(0)}',
                  style: AppFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ),
            ]),
          ]),
        ),

        // ── Route ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: _buildRouteWidget(ride),
        ),

        // ── Stats row ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Row(children: [
            _buildMini(t('rideshare_fare', fallback: 'ভাড়া'),
                '৳${ride.fareEstimate.toStringAsFixed(0)}', _indigo),
            const SizedBox(width: 6),
            _buildMini(t('rideshare_distance', fallback: 'দূরত্ব'),
                '${ride.distanceKm.toStringAsFixed(1)} km', _slate800),
            const SizedBox(width: 6),
            _buildMini(t('rideshare_eta', fallback: 'সময়'), ride.etaDisplay,
                _slate800),
          ]),
        ),

        // ── Action buttons ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Row(children: [
            // Skip button
            SizedBox(
              width: 90,
              height: 44,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: isBusy ? null : () => _skipRide(ride),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSkipping ? _slate100 : _slate50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _slate200),
                    ),
                    child: Center(
                      child: isSkipping
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: AdsyLoadingIndicator(
                                  strokeWidth: 2, color: _slate400))
                          : Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.skip_next_rounded,
                                  size: 15, color: _slate500),
                              const SizedBox(width: 4),
                              Text(t('rideshare_skip', fallback: 'স্কিপ'),
                                  style: AppFonts.roboto(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _slate500)),
                            ]),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Accept button
            Expanded(
              child: SizedBox(
                height: 44,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: isBusy || isExpired ? null : () => _acceptRide(ride),
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: !isBusy && !isExpired
                            ? const LinearGradient(
                                colors: [_emerald, _emeraldDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isBusy || isExpired ? _slate100 : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: !isBusy && !isExpired
                            ? [
                                BoxShadow(
                                  color: _emerald.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: _isAcceptingRide
                            ? Row(mainAxisSize: MainAxisSize.min, children: [
                                const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: AdsyLoadingIndicator(
                                        strokeWidth: 2, color: Colors.white)),
                                const SizedBox(width: 8),
                                Text(tr('নেওয়া হচ্ছে...'),
                                    style: AppFonts.roboto(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ])
                            : Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(
                                  isExpired
                                      ? Icons.timer_off_rounded
                                      : Icons.check_circle_rounded,
                                  size: 17,
                                  color: isExpired ? _slate500 : Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isExpired
                                      ? t('rideshare_expired',
                                          fallback: tr('মেয়াদ শেষ'))
                                      : t('rideshare_accept_ride',
                                          fallback: tr('রাইড নিন')),
                                  style: AppFonts.roboto(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isExpired ? _slate500 : Colors.white,
                                  ),
                                ),
                              ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMini(String label, String value, Color vc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _slate50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _slate200),
        ),
        child: Column(children: [
          Text(label,
              style: AppFonts.roboto(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _slate400,
                  letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(value,
              style: AppFonts.roboto(
                  fontSize: 13, fontWeight: FontWeight.w800, color: vc)),
        ]),
      ),
    );
  }

  Widget _buildRouteWidget(Ride ride) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _slate200),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: _indigo,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: _indigo.withValues(alpha: 0.35),
                      blurRadius: 4,
                      offset: const Offset(0, 1)),
                ],
              ),
            ),
            Container(
              width: 1.5,
              height: 18,
              margin: const EdgeInsets.symmetric(vertical: 2),
              color: const Color(0xFFE2E8F0),
            ),
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: _emerald,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                      color: _emerald.withValues(alpha: 0.35),
                      blurRadius: 4,
                      offset: const Offset(0, 1)),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: _indigo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('PICK',
                    style: AppFonts.roboto(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: _indigo,
                        letterSpacing: 0.5)),
              ),
              Expanded(
                child: Text(ride.pickupAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _slate800)),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: _emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('DROP',
                    style: AppFonts.roboto(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: _emerald,
                        letterSpacing: 0.5)),
              ),
              Expanded(
                child: Text(ride.dropAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _slate800)),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ── ACTIVE RIDE ────────────────────────────────────────────────────────────
}
