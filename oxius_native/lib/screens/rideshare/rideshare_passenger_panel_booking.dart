part of 'rideshare_passenger_panel.dart';

// ignore_for_file: unused_element
extension _RsBookingFormExtension on _RidesharePassengerPanelState {
  static const Color _kPurple = Color(0xFF6366F1);
  static const Color _kSlate = Color(0xFF64748B);

  // ── Booking View (step-based, map-first) ─────────────────────────────────────

  Widget _buildBookingView() {
    if (_isCheckingLocationPermission) {
      return const Center(
          child: AdsyLoadingIndicator(color: Color(0xFF6366F1)));
    }

    if (!_locationGranted) {
      return _buildLocationPermissionOverlay();
    }

    // Map-first full-screen stack
    return Stack(
      children: [
        // ── Full-screen map ────────────────────────────────────────────────
        Positioned.fill(
          child: RideshareMapWidget(
            pickupPoint: _pickupPoint,
            dropPoint: _dropPoint,
            routeGeometry: _bookingStep == 2 ? _estimate?.routeGeometry : null,
            nearbyDrivers: _nearbyDrivers,
            activeSelection: _bookingStep == 0
                ? 'drop'
                : (_bookingStep == 1 ? 'pickup' : ''),
            vehicleType: _selectedVehicleType,
            riderAvatar: AuthService.currentUser?.profilePicture,
            onMapTap: _onMapTap,
            onCenterChanged: _onPlannerMapCenterChanged,
            // Clear the status bar AND the shell's floating avatar, which
            // sits at padding.top + 10 and is 44 tall.
            topInset: MediaQuery.of(context).padding.top + 64,
          ),
        ),

        // ── Animated step bottom panel ─────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0.15, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic));
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_bookingStep),
              child: _buildCurrentStepPanel(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepPanel() {
    final Widget panel = switch (_bookingStep) {
      1 => _buildPickupStepPanel(),
      2 => _buildConfirmStepPanel(),
      _ => _buildDropStepPanel(),
    };
    // The stage slides in like a sheet advancing, not a hard swap.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(_bookingStep),
        child: panel,
      ),
    );
  }

  // ── Step 0: Drop-off ─────────────────────────────────────────────────────────

  Widget _buildDropStepPanel() {
    final dropSuggestions = _visibleSuggestionsForField(
      _dropController,
      _hideDropSuggestionsUntilEdit ? const <RidePoint>[] : _dropSuggestions,
      true,
    );
    final showingRecent =
        _dropSuggestions.isEmpty && dropSuggestions.isNotEmpty;

    return _buildStepSheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            t('rideshare_where_to', fallback: 'কোথায় যাবেন?'),
            style: AppFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // Drop input
          _buildSearchInput(
            controller: _dropController,
            hint: 'গন্তব্য লোকেশন...',
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFFEF4444),
            onChanged: (v) {
              _rebuild(() => _hideDropSuggestionsUntilEdit = false);
              _onDropSearch(v);
            },
            onTap: () => _rebuild(() {
              _activeInput = 'drop';
              _hideDropSuggestionsUntilEdit = false;
              // Reaching for the field means they want the full sheet back.
              _sheetCollapsed = false;
            }),
            isSearching: _isSearchingDrop,
          ),

          // Suggestions — all hidden while the sheet is pulled down.
          if (dropSuggestions.isNotEmpty && !_sheetCollapsed) ...[
            const SizedBox(height: 6),
            _buildLocationSuggestionsDropdown(
              suggestions: dropSuggestions,
              showingRecent: showingRecent,
              onSuggestionTap: _selectDropSuggestion,
            ),
          ] else if (_dropController.text.isEmpty && !_sheetCollapsed) ...[
            const SizedBox(height: 6),
            _buildQuickDestinationRow(
              icon: Icons.star_rounded,
              label: t('rideshare_saved_place',
                  fallback: 'সেভ করা জায়গা বেছে নিন'),
              onTap: _showCustomLocationSheet,
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ..._buildDestinationSuggestions(),
          ],

          // Next button — shown when drop is already selected (e.g. after going back)
          if (_dropPoint != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _rebuild(() {
                  _bookingStep = 1;
                  _activeInput = 'pickup';
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'পরবর্তী',
                        style: AppFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Step 1: Pickup ───────────────────────────────────────────────────────────

  Widget _buildPickupStepPanel() {
    final pickupSuggestions = _visibleSuggestionsForField(
      _pickupController,
      _pickupSuggestions,
      true,
    );
    final showingRecent =
        _pickupSuggestions.isEmpty && pickupSuggestions.isNotEmpty;

    return _buildStepSheetContainer(
      onBack: () => _rebuild(() {
        _bookingStep = 0;
        _activeInput = 'drop';
      }),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'পিকআপ লোকেশন?',
            style: AppFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'কোথা থেকে উঠবেন?',
            style: AppFonts.roboto(fontSize: 13, color: _kSlate),
          ),
          const SizedBox(height: 16),

          // Pickup input
          _buildSearchInput(
            controller: _pickupController,
            hint: 'পিকআপ লোকেশন...',
            icon: Icons.trip_origin_rounded,
            iconColor: _kPurple,
            onChanged: _onPickupSearch,
            onTap: () => _rebuild(() => _activeInput = 'pickup'),
            trailing: _buildCurrentLocationButton(),
            isSearching: _isSearchingPickup,
          ),

          // Suggestions
          if (pickupSuggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildLocationSuggestionsDropdown(
              suggestions: pickupSuggestions,
              showingRecent: showingRecent,
              onSuggestionTap: _selectPickupSuggestion,
            ),
          ],

          // Next button — shown when pickup is already selected (e.g. after going back)
          if (_pickupPoint != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _rebuild(() => _bookingStep = 2),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'পরবর্তী',
                        style: AppFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Step 2: Vehicle + Payment + Confirm ──────────────────────────────────────

  Widget _buildConfirmStepPanel() {
    return _buildStepSheetContainer(
      onBack: () => _rebuild(() {
        _bookingStep = 1;
        _activeInput = 'pickup';
      }),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route summary pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.trip_origin_rounded,
                    size: 14, color: _kPurple),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _pickupController.text,
                    style: AppFonts.roboto(
                        fontSize: 12,
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 14, color: _kSlate),
                ),
                const Icon(Icons.location_on_rounded,
                    size: 14, color: Color(0xFFEF4444)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _dropController.text,
                    style: AppFonts.roboto(
                        fontSize: 12,
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Vehicle selector
          _buildVehicleSelector(),
          const SizedBox(height: 14),

          // Payment
          _buildPaymentMethodSelector(),

          // Estimate
          if (_estimate != null || _isEstimating) ...[
            const SizedBox(height: 14),
            _buildEstimateCard(),
          ],
          const SizedBox(height: 14),

          // Book button
          _buildBookButton(),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Sheet Container ──────────────────────────────────────────────────────────

  Widget _buildStepSheetContainer(
      {required Widget child, VoidCallback? onBack}) {
    // A flick down folds the sheet so the map takes the screen; a flick up
    // (or touching the search field) brings it back. AnimatedSize makes the
    // fold glide instead of snap.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v > 250 && !_sheetCollapsed) {
          _rebuild(() => _sheetCollapsed = true);
          FocusScope.of(context).unfocus();
        } else if (v < -250 && _sheetCollapsed) {
          _rebuild(() => _sheetCollapsed = false);
        }
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 32,
                  offset: Offset(0, -8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onBack != null) ...[
                  GestureDetector(
                    onTap: onBack,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              size: 16, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ),
                  ),
                ],
                child,
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search Input ─────────────────────────────────────────────────────────────

  Widget _buildSearchInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required Function(String) onChanged,
    required VoidCallback onTap,
    Widget? trailing,
    bool isSearching = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onTap: onTap,
              autofocus: true,
              style: AppFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppFonts.roboto(
                    fontSize: 14, color: const Color(0xFFB0B8CC)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (isSearching)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: AdsyLoadingIndicator(
                  strokeWidth: 1.5,
                  color: Color(0xFF6366F1),
                ),
              ),
            )
          else if (trailing != null)
            trailing,
        ],
      ),
    );
  }

  // ── Location Permission Overlay ──────────────────────────────────────────────

  Widget _buildLocationPermissionOverlay() {
    return Stack(
      children: [
        Positioned.fill(
          child: RideshareMapWidget(
            pickupPoint: null,
            dropPoint: null,
            nearbyDrivers: const [],
            activeSelection: '',
            vehicleType: 'bike',
            onMapTap: (a, b) {},
            onCenterChanged: (_, __) {},
            topInset: MediaQuery.of(context).padding.top + 64,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildStepSheetContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: Color(0xFFEA580C), size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  t('rideshare_location_required_title',
                      fallback: 'লোকেশন অনুমতি লাগবে'),
                  style: AppFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  t('rideshare_enable_location_desc',
                      fallback:
                          'Enable location to book rides and auto-set pickup.'),
                  style: AppFonts.roboto(
                      fontSize: 13, color: _kSlate, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        _isLoadingLocation ? null : _requestLocationPermission,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: AdsyLoadingIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.my_location_rounded, size: 18),
                    label: Text(
                      _isLoadingLocation
                          ? t('rideshare_enabling', fallback: 'চালু হচ্ছে...')
                          : t('rideshare_enable_location',
                              fallback: 'লোকেশন চালু করুন'),
                      style: AppFonts.roboto(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Payment Method Selector ──────────────────────────────────────────────────

  Widget _buildPaymentMethodSelector() {
    final walletBalance = AuthService.currentUser?.balance ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.payment_rounded,
                size: 15, color: Color(0xFF6366F1)),
            const SizedBox(width: 6),
            Text(
              t('rideshare_payment_method', fallback: 'পেমেন্ট মেথড'),
              style: AppFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _rebuild(() => _selectedPaymentMethod = 'wallet'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedPaymentMethod == 'wallet'
                        ? const Color(0xFF6366F1).withValues(alpha: 0.08)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedPaymentMethod == 'wallet'
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFE2E8F0),
                      width: _selectedPaymentMethod == 'wallet' ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 16,
                            color: _selectedPaymentMethod == 'wallet'
                                ? const Color(0xFF6366F1)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            t('rideshare_wallet', fallback: 'ওয়ালেট'),
                            style: AppFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _selectedPaymentMethod == 'wallet'
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          if (_selectedPaymentMethod == 'wallet')
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.check_circle_rounded,
                                  size: 13, color: Color(0xFF6366F1)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '৳${walletBalance.toStringAsFixed(0)} ${t("rideshare_balance", fallback: "Balance")}',
                        style: AppFonts.roboto(
                            fontSize: 10.5, color: const Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/deposit-withdraw'),
                        child: Text(
                          t('rideshare_add_funds', fallback: '+ Add Funds'),
                          style: AppFonts.roboto(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => _rebuild(() => _selectedPaymentMethod = 'cash'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedPaymentMethod == 'cash'
                        ? const Color(0xFF10B981).withValues(alpha: 0.08)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedPaymentMethod == 'cash'
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE2E8F0),
                      width: _selectedPaymentMethod == 'cash' ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.payments_rounded,
                            size: 16,
                            color: _selectedPaymentMethod == 'cash'
                                ? const Color(0xFF10B981)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            t('rideshare_cash', fallback: 'ক্যাশ'),
                            style: AppFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _selectedPaymentMethod == 'cash'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          if (_selectedPaymentMethod == 'cash')
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.check_circle_rounded,
                                  size: 13, color: Color(0xFF10B981)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t('rideshare_pay_driver_directly',
                            fallback: 'ড্রাইভারকে সরাসরি দিন'),
                        style: AppFonts.roboto(
                            fontSize: 10.5, color: const Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t('rideshare_no_wallet_needed',
                            fallback: 'ওয়ালেট লাগবে না'),
                        style: AppFonts.roboto(
                            fontSize: 10, color: const Color(0xFFCBD5E1)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Location Inputs ──────────────────────────────────────────────────────────

  Widget _buildLocationInputs() {
    final pickupVisibleSuggestions = _visibleSuggestionsForField(
      _pickupController,
      _pickupSuggestions,
      _activeInput == 'pickup',
    );
    final dropVisibleSuggestions = _visibleSuggestionsForField(
      _dropController,
      _hideDropSuggestionsUntilEdit ? const <RidePoint>[] : _dropSuggestions,
      _activeInput == 'drop',
    );
    final showingDropSuggestions =
        _activeInput == 'drop' && dropVisibleSuggestions.isNotEmpty;
    final activeSuggestions = showingDropSuggestions
        ? dropVisibleSuggestions
        : pickupVisibleSuggestions;
    final showingRecent = showingDropSuggestions
        ? !_hideDropSuggestionsUntilEdit &&
            _dropSuggestions.isEmpty &&
            activeSuggestions.isNotEmpty
        : _pickupSuggestions.isEmpty && activeSuggestions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            Expanded(
              child: Column(
                children: [
                  _buildLocationInput(
                    controller: _pickupController,
                    label: t('rideshare_pickup_location',
                        fallback: 'পিকআপ লোকেশন'),
                    hint: t('rideshare_search_pickup',
                            fallback: 'পিকআপ খুঁজুন...')
                        .toString(),
                    isActive: _activeInput == 'pickup',
                    onTap: () => _rebuild(() => _activeInput = 'pickup'),
                    onChanged: _onPickupSearch,
                    trailing: _buildCurrentLocationButton(),
                  ),
                  const SizedBox(height: 12),
                  _buildLocationInput(
                    controller: _dropController,
                    label:
                        t('rideshare_drop_location', fallback: 'গন্তব্য লোকেশন'),
                    hint: t('rideshare_search_drop', fallback: 'গন্তব্য খুঁজুন...')
                        .toString(),
                    isActive: _activeInput == 'drop',
                    onTap: () => _rebuild(() {
                      _activeInput = 'drop';
                      _hideDropSuggestionsUntilEdit = false;
                    }),
                    onChanged: _onDropSearch,
                    onSubmitted: (_) => _dismissDropSuggestions(),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (activeSuggestions.isNotEmpty)
          _buildLocationSuggestionsDropdown(
            suggestions: activeSuggestions,
            showingRecent: showingRecent,
            onSuggestionTap: showingDropSuggestions
                ? _selectDropSuggestion
                : _selectPickupSuggestion,
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
    ValueChanged<String>? onSubmitted,
    Widget? trailing,
  }) {
    return GestureDetector(
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
                    style: AppFonts.roboto(
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
                    onSubmitted: onSubmitted,
                    textInputAction: onSubmitted != null
                        ? TextInputAction.search
                        : TextInputAction.next,
                    style: AppFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: AppFonts.roboto(
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
    );
  }

  Widget _buildLocationSuggestionsDropdown({
    required List<RidePoint> suggestions,
    required bool showingRecent,
    required Future<void> Function(RidePoint) onSuggestionTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 220),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showingRecent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Text(
                'Recent places',
                style: AppFonts.roboto(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                final subtitle = suggestion.displaySubtitle;
                final badgeLabel = suggestion.badgeLabel;
                final isRecentItem = showingRecent;
                return InkWell(
                  onTap: () => onSuggestionTap(suggestion),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isRecentItem
                                ? const Color(0xFFF8FAFC)
                                : suggestion.isCustomLocation
                                    ? const Color(0xFFFFEDD5)
                                    : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(
                            isRecentItem
                                ? Icons.history_rounded
                                : suggestion.isCustomLocation
                                    ? Icons.bookmark_added_rounded
                                    : Icons.location_on_outlined,
                            size: 18,
                            color: suggestion.isCustomLocation
                                ? const Color(0xFFEA580C)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      suggestion.displayTitle,
                                      style: AppFonts.roboto(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (badgeLabel.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEDD5),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                            color: const Color(0xFFFED7AA)),
                                      ),
                                      child: Text(
                                        badgeLabel,
                                        style: AppFonts.roboto(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF9A3412),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  subtitle,
                                  style: AppFonts.roboto(
                                    fontSize: 11.5,
                                    color: const Color(0xFF64748B),
                                    height: 1.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
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
      ),
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
                child: AdsyLoadingIndicator(
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
                    t('rideshare_current_location_btn', fallback: 'বর্তমান'),
                    style: AppFonts.roboto(
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

  Widget _buildCustomLocationPrompt() {
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: _showCustomLocationSheet,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '+ আপনার নিজের বাড়ি বা ব্যবসার লোকেশন অ্যাড করুন',
            style: AppFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF9A3412),
            ),
          ),
        ),
      ),
    );
  }

  // ── Vehicle Selector ─────────────────────────────────────────────────────────

  Widget _buildVehicleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          t('rideshare_select_for_trip', fallback: 'ট্রিপের জন্য একটি বেছে নিন'),
          style: AppFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        // One card per class, artwork-led, exactly the reference's row.
        Row(
          children: [
            for (var i = 0; i < RideVehicle.all.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              _buildVehicleOption(RideVehicle.all[i]),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleOption(RideVehicle vehicle) {
    final isSelected = _selectedVehicleType == vehicle.key;
    // The fare belongs to the class it was quoted for — showing the current
    // estimate under every card would price all three the same.
    final fare = isSelected && _estimate != null
        ? '৳${_estimate!.fare.toStringAsFixed(0)}'
        : '';
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedVehicleType == vehicle.key) return;
          _rebuild(() => _selectedVehicleType = vehicle.key);
          _loadNearbyDrivers();
          _requestEstimate();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFE9EDF3),
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  vehicle.capacity,
                  style: AppFonts.roboto(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              vehicle.artwork(size: 44),
              const SizedBox(height: 6),
              Text(
                vehicle.label,
                style: AppFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(
                height: 16,
                child: fare.isEmpty
                    ? null
                    : Text(
                        fare,
                        style: AppFonts.roboto(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The rider's own places, under the search field, before they type.
  ///
  /// "Set Destination On Map" used to sit here, which was a row that told the
  /// rider to go tap the map they were already looking at. These rows do
  /// something: each one is somewhere this rider has actually saved or been,
  /// and tapping it books straight to that point.
  List<Widget> _buildDestinationSuggestions() {
    final rows = <_SuggestionEntry>[];

    // Saved places first — a rider who bothered to save a place means it.
    for (final saved in _savedPlaces.take(3)) {
      rows.add(_SuggestionEntry(
        icon: Icons.bookmark_rounded,
        tint: const Color(0xFF6366F1),
        title: saved.name,
        subtitle: saved.subtitle,
        point: RidePoint(
          name: saved.name,
          title: saved.name,
          subtitle: saved.subtitle,
          latitude: saved.latitude,
          longitude: saved.longitude,
          isCustomLocation: true,
        ),
      ));
    }

    // Then where they have been, skipping anything already listed above.
    for (final recent in _recentPlaces) {
      if (rows.length >= 5) break;
      final duplicate = rows.any((row) =>
          row.point.latitude == recent.latitude &&
          row.point.longitude == recent.longitude);
      if (duplicate) continue;
      rows.add(_SuggestionEntry(
        icon: Icons.history_rounded,
        tint: const Color(0xFF64748B),
        title: recent.title?.trim().isNotEmpty == true
            ? recent.title!
            : recent.name,
        subtitle: recent.subtitle ?? '',
        point: recent,
      ));
    }

    if (rows.isEmpty) return const <Widget>[];

    return [
      const SizedBox(height: 14),
      Text(
        t('rideshare_suggestions', fallback: 'সাজেশন'),
        style: AppFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: const Color(0xFF94A3B8),
        ),
      ),
      const SizedBox(height: 2),
      for (final row in rows) _buildSuggestionRow(row),
    ];
  }

  Widget _buildSuggestionRow(_SuggestionEntry entry) {
    return InkWell(
      onTap: () => _selectDropSuggestion(entry.point),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: entry.tint.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(entry.icon, size: 16, color: entry.tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.roboto(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if (entry.subtitle.trim().isNotEmpty)
                    Text(
                      entry.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.roboto(
                        fontSize: 11.5,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.north_east_rounded,
                size: 15, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  /// One of the quiet helper rows under the destination field — the
  /// screenshot's "Choose a Saved Place" pattern.
  Widget _buildQuickDestinationRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppFonts.roboto(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ── Estimate Card ────────────────────────────────────────────────────────────

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
              child: AdsyLoadingIndicator(
                strokeWidth: 2,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              t('rideshare_calculating_fare', fallback: 'ভাড়া হিসাব হচ্ছে...'),
              style: AppFonts.roboto(
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
                  t('rideshare_estimated_fare', fallback: 'আনুমানিক ভাড়া')
                      .toUpperCase(),
                  style: AppFonts.roboto(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '৳${_estimate!.fare.toStringAsFixed(0)}',
                  style: AppFonts.roboto(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
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
                      style: AppFonts.roboto(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
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
                      style: AppFonts.roboto(
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

  // ── Book Button ──────────────────────────────────────────────────────────────

  Widget _buildBookButton() {
    final canBook =
        _pickupPoint != null && _dropPoint != null && _estimate != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
          onPressed: canBook && !_isCreatingRide ? _createRide : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                canBook ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
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
                  child: AdsyLoadingIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canBook
                          ? Icons.directions_car_rounded
                          : Icons.edit_location_alt_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      canBook
                          ? t('rideshare_book_ride_now',
                              fallback: 'রাইড কনফার্ম করুন')
                          : t('rideshare_enter_locations',
                              fallback: 'লোকেশন দিন'),
                      style: AppFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

/// One row of the "Suggestions" list: where it came from, and the point that
/// tapping it books.
class _SuggestionEntry {
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final RidePoint point;

  const _SuggestionEntry({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.point,
  });
}
