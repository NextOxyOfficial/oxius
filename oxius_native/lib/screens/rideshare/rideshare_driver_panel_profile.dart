part of 'rideshare_driver_panel.dart';

// ignore_for_file: unused_element

/// The driver's own card: status chips, the online switch, cash dues and the
/// expandable profile form.
///
/// Split out of rideshare_driver_panel.dart, which had grown past 4,900 lines
/// and made every change a scroll hunt. Behaviour is unchanged — these are the
/// same methods on the same state object, reached through an extension.
extension _RsDriverProfileSection on _RideshareDriverPanelState {
  Widget _buildStatsRow() {
    final approval = _driverProfile?.approvalStatus ?? 'pending';
    final isApproved = _driverProfile?.isApproved == true;
    Color approvalColor;
    if (approval == 'approved') {
      approvalColor = _emerald;
    } else if (approval == 'suspended') {
      approvalColor = Colors.red.shade500;
    } else {
      approvalColor = const Color(0xFFD97706);
    }

    final approvalLabel = approval == 'approved'
        ? tr('এপ্রুভড')
        : approval == 'suspended'
            ? tr('সাসপেন্ডেড')
            : tr('অপেক্ষমাণ');
    // One line instead of three bordered boxes — the numbers speak, the
    // chrome does not.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
              isApproved
                  ? Icons.verified_rounded
                  : Icons.hourglass_top_rounded,
              size: 15,
              color: approvalColor),
          const SizedBox(width: 4),
          Text(approvalLabel,
              style: AppFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: approvalColor)),
          _buildStatDot(),
          Text('${_earnings?.totalTrips ?? 0}',
              style: AppFonts.roboto(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: _slate800)),
          const SizedBox(width: 4),
          Text(tr('ট্রিপ'),
              style:
                  AppFonts.roboto(fontSize: 12, color: _slate400)),
          _buildStatDot(),
          Text('৳${(_earnings?.totalEarnings ?? 0).toStringAsFixed(0)}',
              style: AppFonts.roboto(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: _slate800)),
          const SizedBox(width: 4),
          Text(tr('আয়'),
              style:
                  AppFonts.roboto(fontSize: 12, color: _slate400)),
        ],
      ),
    );
  }

  Widget _buildStatDot() {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
          color: Color(0xFFCBD5E1), shape: BoxShape.circle),
    );
  }

  Widget _buildLocationRequiredCard() {
    final isBusy =
        _isCheckingLocationPermission || _isRequestingLocationPermission;
    final needsUpgrade = _needsBackgroundLocationUpgrade;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  needsUpgrade
                      ? Icons.settings_accessibility_rounded
                      : Icons.location_disabled_rounded,
                  color: const Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      needsUpgrade
                          ? 'Finish location setup'
                          : t('rideshare_location_mandatory',
                              fallback: tr('লোকেশন শেয়ার করা লাগবে')),
                      style: AppFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      needsUpgrade
                          ? 'Choose Allow all the time in app settings so you keep receiving requests while the app is in the background.'
                          : t('rideshare_location_mandatory_driver_desc',
                              fallback:
                                  'You must enable location sharing to receive ride requests and go online as a driver.'),
                      style: AppFonts.roboto(
                        fontSize: 12,
                        color: const Color(0xFF7F1D1D),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isBusy
                  ? null
                  : () {
                      if (needsUpgrade) {
                        _openDriverLocationSettingsGuide();
                        return;
                      }
                      _requestLocationPermission();
                    },
              icon: isBusy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: AdsyLoadingIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      needsUpgrade
                          ? Icons.open_in_new_rounded
                          : Icons.my_location_rounded,
                      size: 16,
                    ),
              label: Text(
                isBusy
                    ? t('rideshare_checking', fallback: 'চেক হচ্ছে...')
                    : (needsUpgrade
                        ? 'Open settings'
                        : t('rideshare_enable_location',
                            fallback: tr('লোকেশন চালু করুন'))),
                style: AppFonts.roboto(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9EDF3)),
        ),
        child: Column(children: [
          Text(label,
              style: AppFonts.roboto(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _slate400)),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A))),
            ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _handleOnlineToggleTap() async {
    if (_driverProfile == null ||
        _isTogglingOnline ||
        _isCheckingLocationPermission) {
      return;
    }

    if (_driverProfile!.isOnline) {
      await _toggleOnline(skipPermissionCheck: true);
      return;
    }

    if (_needsBackgroundLocationUpgrade) {
      await _openDriverLocationSettingsGuide(goOnlineAfterSetup: true);
      return;
    }

    await _toggleOnline();
  }

  Widget _buildOnlineToggleCard() {
    final isOnline = _driverProfile?.isOnline == true;
    final isApproved = _driverProfile?.isApproved == true;
    final dueLimitReached = _driverProfile?.cashDueLimitReached == true;
    final locationSubtitle = !isApproved
        ? 'Complete approval to start driving'
        : dueLimitReached
            ? t('rideshare_pay_due_to_go_online',
                fallback: tr('অনলাইনে যেতে ক্যাশ বকেয়া দিন'))
            : isOnline
                ? t('rideshare_requests_will_appear',
                    fallback: tr('রিকোয়েস্ট নিচে দেখা যাবে'))
                : _needsBackgroundLocationUpgrade
                    ? 'Finish one-time location setup to stay online in background'
                    : !_hasForegroundLocationPermission
                        ? 'Tap once to enable location and go online'
                        : t('rideshare_go_online_for_requests',
                            fallback: tr('রিকোয়েস্ট পেতে অনলাইনে যান'));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: isOnline ? _emeraldDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOnline ? null : Border.all(color: const Color(0xFFE9EDF3)),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isOnline
                ? Colors.white.withValues(alpha: 0.18)
                : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              size: 18, color: isOnline ? Colors.white : _slate500),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              isOnline
                  ? t('rideshare_online_status',
                      fallback: tr('অনলাইন — রাইড নিচ্ছেন'))
                  : t('rideshare_offline_status', fallback: 'অফলাইন'),
              style: AppFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isOnline ? Colors.white : _slate800)),
          Text(locationSubtitle,
              style: AppFonts.roboto(
                  fontSize: 11,
                  color: isOnline
                      ? Colors.white.withValues(alpha: 0.8)
                      : _slate500)),
        ])),
        GestureDetector(
          onTap: (isApproved &&
                  !_isTogglingOnline &&
                  !_isCheckingLocationPermission)
              ? _handleOnlineToggleTap
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 50,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isOnline
                  ? Colors.white.withValues(alpha: 0.35)
                  : (isApproved ? _slate300 : _slate200),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              alignment:
                  isOnline ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    color: isOnline ? Colors.white : _slate400,
                    shape: BoxShape.circle),
                child: _isTogglingOnline
                    ? Padding(
                        padding: const EdgeInsets.all(4),
                        child: AdsyLoadingIndicator(
                            strokeWidth: 2,
                            color: isOnline ? _emerald : _slate500),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildCashDueCard() {
    final profile = _driverProfile;
    if (profile == null || profile.outstandingCashDueAmount <= 0) {
      return const SizedBox.shrink();
    }

    final dueCount = profile.outstandingCashDueCount;
    final dueAmount = profile.outstandingCashDueAmount;
    final limitReached = profile.cashDueLimitReached;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              limitReached ? const Color(0xFFF59E0B) : const Color(0xFFFCD34D),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('rideshare_cash_due_title',
                          fallback: tr('ক্যাশ বকেয়া আছে')),
                      style: AppFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '৳${dueAmount.toStringAsFixed(0)} pending across $dueCount cash ride${dueCount > 1 ? 's' : ''}.',
                      style: AppFonts.roboto(
                          fontSize: 12, color: const Color(0xFF92400E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            limitReached
                ? t('rideshare_cash_due_limit_msg',
                    fallback:
                        'You reached the maximum unpaid cash rides. Pay this due from your Adsy balance to go online again.')
                : t('rideshare_cash_due_warning_msg',
                    fallback:
                        'You can keep driving for now, but clear this due from your Adsy balance before it reaches the limit.'),
            style: AppFonts.roboto(
                fontSize: 12, color: const Color(0xFF78350F), height: 1.35),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final walletBalance = AuthService.currentUser?.balance ?? 0.0;
              final hasEnough = walletBalance >= dueAmount;
              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (hasEnough && !_isPayingCashDues)
                          ? () => _payOutstandingCashDues(
                              goOnlineAfterPayment: limitReached)
                          : null,
                      icon: _isPayingCashDues
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: AdsyLoadingIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.account_balance_wallet_rounded,
                              size: 18),
                      label: Text(
                        _isPayingCashDues
                            ? t('rideshare_paying', fallback: 'পেমেন্ট হচ্ছে...')
                            : hasEnough
                                ? t('rideshare_pay_due_btn',
                                    fallback: tr('বকেয়া মিটিয়ে দিন'))
                                : '${t("rideshare_insufficient_balance", fallback: "Insufficient balance")} (৳${walletBalance.toStringAsFixed(0)})',
                        style: AppFonts.roboto(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            hasEnough ? const Color(0xFFD97706) : _slate400,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  if (!hasEnough) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/deposit-withdraw'),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          t('rideshare_add_funds_wallet',
                              fallback: tr('Adsy ওয়ালেটে টাকা যোগ করুন')),
                          style: AppFonts.roboto(fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                          side: const BorderSide(color: Color(0xFF6366F1)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final isNew = !_hasSubmittedIdentity(_driverProfile);
    final isPending = _driverProfile?.isPending == true;
    final isApproved = _driverProfile?.isApproved == true;
    final isSuspended = _driverProfile?.isSuspended == true;
    final licenseLocked = _licenseLocked;
    final nidLocked = _nidLocked;
    final hasSubmittedIdentity = _hasSubmittedIdentity(_driverProfile);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _slate200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            onTap: () =>
                _rebuild(() => _isProfileExpanded = !_isProfileExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: const BoxDecoration(
                color: _slate50,
                borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
                border: Border(bottom: BorderSide(color: _slate200)),
              ),
              child: Row(children: [
                const Icon(Icons.badge_rounded, size: 16, color: _indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isNew
                        ? t('rideshare_become_driver',
                            fallback: tr('ড্রাইভার হোন'))
                        : t('rideshare_driver_profile',
                            fallback: tr('ড্রাইভার প্রোফাইল')),
                    style: AppFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _slate800),
                  ),
                ),
                if (isSuspended) ...[
                  _buildBadge(t('rideshare_suspended', fallback: 'সাসপেন্ডেড'),
                      Colors.red.shade600),
                  const SizedBox(width: 6),
                ],
                if (isPending) ...[
                  _buildBadge(
                      t('rideshare_under_review', fallback: 'যাচাই চলছে'),
                      const Color(0xFFD97706)),
                  const SizedBox(width: 6),
                ],
                if (isApproved) ...[
                  _buildBadge(
                      t('rideshare_approved', fallback: 'এপ্রুভড'), _emerald),
                  const SizedBox(width: 6),
                ],
                GestureDetector(
                  onTap: _openVehicles,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _slate200),
                    ),
                    child: const Icon(Icons.two_wheeler_rounded,
                        size: 16, color: _indigo),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _isProfileExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: _slate500,
                ),
              ]),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _isProfileExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: _buildExpandedProfileContent(
            isNew: isNew,
            isPending: isPending,
            isSuspended: isSuspended,
            licenseLocked: licenseLocked,
            nidLocked: nidLocked,
          ),
          secondChild: _buildCollapsedProfileSummary(
            hasSubmittedIdentity: hasSubmittedIdentity,
            licenseLocked: licenseLocked,
            nidLocked: nidLocked,
            additionalDocumentCount: _additionalDocuments.length,
          ),
        ),
      ]),
    );
  }

  Widget _buildExpandedProfileContent({
    required bool isNew,
    required bool isPending,
    required bool isSuspended,
    required bool licenseLocked,
    required bool nidLocked,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isPending)
          _buildNoticeBanner(
            icon: Icons.hourglass_top_rounded,
            msg: t('rideshare_profile_under_review',
                fallback:
                    'Your profile is under review. You\'ll be notified once approved.'),
            bgColor: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
            iconColor: const Color(0xFFD97706),
            textColor: const Color(0xFF92400E),
          ),
        if (isSuspended)
          _buildNoticeBanner(
            icon: Icons.block_rounded,
            msg: t('rideshare_account_suspended',
                fallback:
                    'Your driver account has been suspended. Contact support.'),
            bgColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFFECACA),
            iconColor: Colors.red.shade600,
            textColor: Colors.red.shade800,
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Instructions
            if (isNew) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _indigo.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _indigo.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _driverProfile == null
                          ? Icons.info_rounded
                          : Icons.check_circle_rounded,
                      size: 16,
                      color: _indigo,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _driverProfile == null
                            ? t('rideshare_apply_instructions',
                                fallback:
                                    'Submit your identity details to apply as a driver. Admin will review and approve.')
                            : t('rideshare_identity_instructions',
                                fallback:
                                    'Fill in your identity details once. After submission, license and NID stay locked.'),
                        style: AppFonts.roboto(
                            fontSize: 12, height: 1.4, color: _indigo),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            // Identity Section Header
            Row(
              children: [
                Icon(Icons.verified_user_rounded, size: 16, color: _indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('rideshare_identity_section',
                        fallback: tr('পরিচয় যাচাই')),
                    style: AppFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _slate800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // License Field
            _buildField(
              _licenseController,
              t('rideshare_license_number', fallback: 'লাইসেন্স নম্বর'),
              t('rideshare_license_hint', fallback: 'ড্রাইভিং লাইসেন্স নম্বর'),
              Icons.credit_card_rounded,
              readOnly: licenseLocked,
              helperText: licenseLocked
                  ? t('rideshare_license_locked',
                      fallback: tr('জমা দেওয়া লাইসেন্স নম্বর আর বদলানো যাবে না।'))
                  : null,
            ),
            const SizedBox(height: 12),
            // NID Field
            _buildField(
              _nidController,
              t('rideshare_nid_label', fallback: 'জাতীয় পরিচয়পত্র (NID)'),
              t('rideshare_nid_hint', fallback: 'এনআইডি নম্বর'),
              Icons.perm_identity_rounded,
              readOnly: nidLocked,
              helperText: nidLocked
                  ? t('rideshare_nid_locked',
                      fallback: tr('জমা দেওয়া এনআইডি আর বদলানো যাবে না।'))
                  : null,
            ),
            const SizedBox(height: 20),
            // Driver Details Section Header
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 16, color: _slate800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('rideshare_details_section',
                        fallback: tr('ড্রাইভার তথ্য')),
                    style: AppFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _slate800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Driver Details Label
            Text(
              t('rideshare_driver_details', fallback: 'অভিজ্ঞতা ও নোট'),
              style: AppFonts.roboto(
                  fontSize: 11, fontWeight: FontWeight.w600, color: _slate600),
            ),
            const SizedBox(height: 6),
            // Driver Details TextField
            TextField(
              controller: _driverDetailsController,
              minLines: 3,
              maxLines: 5,
              style: AppFonts.roboto(
                  fontSize: 13, color: _slate800, height: 1.5),
              decoration: InputDecoration(
                hintText: t('rideshare_driver_details_hint',
                    fallback:
                        'Describe your driving experience, favorite routes, vehicle details, or any special notes...'),
                hintStyle: AppFonts.roboto(fontSize: 12, color: _slate400),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Icon(Icons.description_rounded,
                      size: 16, color: _slate400),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 42, minHeight: 42),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                filled: true,
                fillColor: _slate50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _slate200, width: 1)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _slate200, width: 1)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _indigo, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            // Documents Section Header
            Row(
              children: [
                Icon(Icons.folder_copy_rounded, size: 16, color: _slate800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('rideshare_documents_section',
                        fallback: tr('অতিরিক্ত ডকুমেন্ট')),
                    style: AppFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _slate800),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_additionalDocuments.length}/10',
                    style: AppFonts.roboto(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _indigo),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            // Documents Helper Text
            Text(
              t('rideshare_documents_hint',
                  fallback:
                      'Upload additional documents to support your application (licenses, certifications, insurance, etc.)'),
              style: AppFonts.roboto(
                  fontSize: 11, color: _slate500, height: 1.4),
            ),
            const SizedBox(height: 12),
            // Upload Button
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _pickAdditionalDocuments,
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: Text(
                  t('rideshare_upload_btn',
                      fallback: tr('লাইসেন্স ডকুমেন্টের ছবি দিন')),
                  style: AppFonts.roboto(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ),
            // Document List
            if (_additionalDocumentLabels.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                t('rideshare_uploaded_docs', fallback: 'আপলোড করা ডকুমেন্ট'),
                style: AppFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _slate600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    List.generate(_additionalDocumentLabels.length, (index) {
                  final label = _additionalDocumentLabels[index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _slate200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Document thumbnail/preview
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _indigo.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: _additionalDocuments[index]
                                  .startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(_additionalDocuments[index]
                                      .split(',')[1]),
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.insert_drive_file_rounded,
                                  size: 28, color: _indigo),
                        ),
                        const SizedBox(height: 6),
                        // Document name/label
                        SizedBox(
                          width: 60,
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.roboto(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: _slate800),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Remove button
                        GestureDetector(
                          onTap: () => _removeAdditionalDocument(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 20),
            // Service Settings Section Header
            Row(
              children: [
                Icon(Icons.settings_rounded, size: 16, color: _slate800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('rideshare_service_section',
                        fallback: tr('সার্ভিস সেটিংস')),
                    style: AppFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _slate800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Service Radius
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _slate50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Icon(Icons.radar_rounded, size: 14, color: _indigo),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        t('rideshare_service_radius',
                            fallback: tr('সার্ভিস রেডিয়াস')),
                        style: AppFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _slate800),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _indigo.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_serviceRadius.toStringAsFixed(0)} km',
                        style: AppFonts.roboto(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _indigo),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 10),
                      activeTrackColor: _indigo,
                      inactiveTrackColor: _slate300,
                      thumbColor: _indigo,
                      overlayColor: _indigo.withValues(alpha: 0.15),
                    ),
                    child: Slider(
                      value: _serviceRadius,
                      min: 1,
                      max: 30,
                      divisions: 29,
                      onChanged: (v) => _rebuild(() => _serviceRadius = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Max Ride Distance
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _slate50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Icon(Icons.route_rounded, size: 14, color: _indigo),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        t('rideshare_max_ride_distance',
                            fallback: tr('সর্বোচ্চ রাইড দূরত্ব')),
                        style: AppFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _slate800),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _indigo.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _maxRideDistance == 0
                            ? t('rideshare_no_limit', fallback: 'আনলিমিটেড')
                            : '${_maxRideDistance.toStringAsFixed(0)} km',
                        style: AppFonts.roboto(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _indigo),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 10),
                      activeTrackColor: _indigo,
                      inactiveTrackColor: _slate300,
                      thumbColor: _indigo,
                      overlayColor: _indigo.withValues(alpha: 0.15),
                    ),
                    child: Slider(
                      value: _maxRideDistance,
                      min: 0,
                      max: 300,
                      divisions: 30,
                      onChanged: (v) => _rebuild(() => _maxRideDistance = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Action Buttons
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isSavingProfile ? null : _saveProfile,
                    icon: _isSavingProfile
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: AdsyLoadingIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _isSavingProfile
                          ? t('rideshare_saving', fallback: 'সেভ হচ্ছে...')
                          : _driverProfile == null
                              ? t('rideshare_apply_driver',
                                  fallback: tr('ড্রাইভার হতে আবেদন করুন'))
                              : t('rideshare_save_profile',
                                  fallback: tr('সেভ করুন')),
                      style: AppFonts.roboto(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                width: 48,
                child: OutlinedButton(
                  onPressed: _openVehicles,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _indigo,
                    side: const BorderSide(color: _indigo),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.two_wheeler_rounded, size: 20),
                ),
              ),
            ]),
          ]),
        ),
      ],
    );
  }

  Widget _buildCollapsedProfileSummary({
    required bool hasSubmittedIdentity,
    required bool licenseLocked,
    required bool nidLocked,
    required int additionalDocumentCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildProfileSummaryPill(
                icon: Icons.credit_card_rounded,
                label: licenseLocked
                    ? t('rideshare_license_submitted',
                        fallback: tr('লাইসেন্স জমা হয়েছে'))
                    : t('rideshare_license_pending',
                        fallback: tr('লাইসেন্স বাকি')),
                color: licenseLocked ? _emerald : _slate500,
                highlighted: licenseLocked,
              ),
              _buildProfileSummaryPill(
                icon: Icons.perm_identity_rounded,
                label: nidLocked
                    ? t('rideshare_nid_submitted', fallback: 'এনআইডি জমা হয়েছে')
                    : t('rideshare_nid_pending', fallback: 'এনআইডি বাকি'),
                color: nidLocked ? _emerald : _slate500,
                highlighted: nidLocked,
              ),
              _buildProfileSummaryPill(
                icon: Icons.radar_rounded,
                label: '${_serviceRadius.toStringAsFixed(0)} km radius',
                color: _indigo,
                highlighted: true,
              ),
              _buildProfileSummaryPill(
                icon: Icons.route_rounded,
                label: _maxRideDistance == 0
                    ? t('rideshare_no_distance_limit',
                        fallback: tr('দূরত্বের সীমা নেই'))
                    : '${_maxRideDistance.toStringAsFixed(0)} km max ride',
                color: _indigo,
                highlighted: true,
              ),
              _buildProfileSummaryPill(
                icon: Icons.folder_copy_rounded,
                label: additionalDocumentCount > 0
                    ? '$additionalDocumentCount additional docs'
                    : 'No additional docs',
                color: additionalDocumentCount > 0 ? _emerald : _slate500,
                highlighted: additionalDocumentCount > 0,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasSubmittedIdentity
                ? tr('পরিচয়ের তথ্য একবার জমা দিলে আর বদলানো যায় না। স্ট্যাটাস দেখতে বা সার্ভিস রেডিয়াস বদলাতে এই অংশটি খুলুন।')
                : 'Open this section to complete your driver profile before going online.',
            style:
                AppFonts.roboto(fontSize: 11, color: _slate500, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSummaryPill({
    required IconData icon,
    required String label,
    required Color color,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: highlighted ? color.withValues(alpha: 0.08) : _slate50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: highlighted ? color.withValues(alpha: 0.22) : _slate200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppFonts.roboto(
                fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBanner({
    required IconData icon,
    required String msg,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor)),
      child: Row(children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg,
                style: AppFonts.roboto(fontSize: 11, color: textColor))),
      ]),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon, {
    bool readOnly = false,
    String? helperText,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        label,
        style: AppFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _slate600,
          letterSpacing: 0.3,
        ),
      ),
      const SizedBox(height: 7),
      TextField(
        controller: ctrl,
        readOnly: readOnly,
        style: AppFonts.roboto(
          fontSize: 13,
          color: _slate800,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          helperText: helperText,
          helperMaxLines: 2,
          helperStyle: AppFonts.roboto(
            fontSize: 11,
            color: _slate500,
            height: 1.3,
          ),
          hintStyle: AppFonts.roboto(fontSize: 13, color: _slate400),
          prefixIcon: Icon(icon, size: 16, color: _slate400),
          suffixIcon: readOnly
              ? Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(Icons.lock_rounded, size: 16, color: _slate400),
                )
              : null,
          prefixIconConstraints:
              const BoxConstraints(minWidth: 42, minHeight: 42),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          filled: true,
          fillColor: readOnly ? _slate100 : _slate50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _slate200, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _slate200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _indigo, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _slate200, width: 1),
          ),
        ),
      ),
    ]);
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: AppFonts.roboto(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

/// Day-by-day income, folded into the driver dashboard.
///
/// Collapsed it shows the last 7 days; "সব দেখুন" opens the full month. Rows
/// and hairlines, no cards — the same flat language as the rest of the panel.
extension _RsDriverEarningsBreakdown on _RideshareDriverPanelState {
  Widget _buildDailyEarningsSection() {
    final visible =
        _earningsExpanded ? _dailyEarnings : _dailyEarnings.take(7).toList();
    final monthTotal =
        _dailyEarnings.fold<double>(0, (sum, d) => sum + d.earnings);
    final monthTrips = _dailyEarnings.fold<int>(0, (sum, d) => sum + d.trips);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('আয়ের হিসাব'),
                  style: AppFonts.roboto(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _slate800,
                  ),
                ),
              ),
              Text(
                '${tr('গত ৩০ দিনে')} $monthTrips${tr('টি ট্রিপে ৳')}${monthTotal.toStringAsFixed(0)}',
                style: AppFonts.roboto(fontSize: 11.5, color: _slate400),
              ),
            ],
          ),
          SizedBox(height: 6),
          for (final day in visible) _buildEarningDayRow(day),
          Center(
            child: TextButton(
              onPressed: () =>
                  _rebuild(() => _earningsExpanded = !_earningsExpanded),
              child: Text(
                _earningsExpanded
                    ? tr('কম দেখুন')
                    : '${tr('সব দেখুন (')}${_dailyEarnings.length} ${tr('দিন)')}',
                style: AppFonts.roboto(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _indigo,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningDayRow(DriverDailyEarning day) {
    final weekdays = [tr('সোম'), tr('মঙ্গল'), tr('বুধ'), tr('বৃহঃ'), tr('শুক্র'), tr('শনি'), tr('রবি')];
    final months = [
      tr('জানু'), tr('ফেব্রু'), tr('মার্চ'), tr('এপ্রিল'), tr('মে'), tr('জুন'),
      tr('জুলাই'), tr('আগস্ট'), tr('সেপ্টে'), tr('অক্টো'), tr('নভে'), tr('ডিসে'),
    ];
    final now = DateTime.now();
    final isToday = day.date.year == now.year &&
        day.date.month == now.month &&
        day.date.day == now.day;
    final label = isToday
        ? tr('আজ')
        : '${weekdays[day.date.weekday - 1]}, ${day.date.day} ${months[day.date.month - 1]}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF6F8FA))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppFonts.roboto(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                color: _slate800,
              ),
            ),
          ),
          Text(
            '${day.trips} ${tr('ট্রিপ')}',
            style: AppFonts.roboto(fontSize: 12, color: _slate400),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 72,
            child: Text(
              '৳${day.earnings.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: AppFonts.roboto(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
