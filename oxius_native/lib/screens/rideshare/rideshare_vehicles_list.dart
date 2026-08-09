part of 'rideshare_vehicles_screen.dart';

// ignore_for_file: unused_element

/// The garage itself: the overview strip, one card per vehicle, and the
/// list/empty/error body around them.
extension _RsVehicleListSection on _RideshareVehiclesScreenState {
  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
    required Color tint,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: accent, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: AppFonts.roboto(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: AppFonts.roboto(
                      color: const Color(0xFFD6D9FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One quiet line above the list. The purple dashboard card this replaces
  /// restated the list below it in three boxes and a chip.
  Widget _buildOverview() {
    final defaultVehicle = _vehicles.cast<Vehicle?>().firstWhere(
          (vehicle) => vehicle?.isDefault == true,
          orElse: () => null,
        );
    final active = _vehicles.where((vehicle) => vehicle.isActive).length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _overviewPhrase('${_vehicles.length}', 'মোট গাড়ি'),
          _overviewDot(),
          _overviewPhrase('$active', 'সক্রিয়'),
          if (defaultVehicle != null) ...[
            _overviewDot(),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded,
                      size: 14, color: Color(0xFF059669)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      defaultVehicle.modelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.roboto(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _overviewPhrase(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: AppFonts.roboto(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A))),
        const SizedBox(width: 4),
        Text(label,
            style: AppFonts.roboto(
                fontSize: 12, color: const Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _overviewDot() {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
          color: Color(0xFFCBD5E1), shape: BoxShape.circle),
    );
  }


  Widget _buildVehicleCard(Vehicle vehicle) {
    final isDefault = vehicle.isDefault;
    final isActive = vehicle.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDefault ? _primary.withValues(alpha: 0.18) : _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _vehicleIcon(vehicle.vehicleType),
                    color: _primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.displayName,
                        style: AppFonts.roboto(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle.registrationNumber,
                        style: AppFonts.roboto(
                          color: _textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!vehicle.isVerified)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.hourglass_top_rounded,
                            size: 11, color: Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Text(
                          t('rideshare_vehicle_pending',
                              fallback: 'ভেরিফিকেশন পেন্ডিং'),
                          style: AppFonts.roboto(
                            color: const Color(0xFFD97706),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isDefault)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      t('rideshare_set_default', fallback: 'ডিফল্ট'),
                      style: AppFonts.roboto(
                        color: const Color(0xFF059669),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!vehicle.isVerified)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              color: const Color(0xFFFFFBEB),
              child: Text(
                t('rideshare_vehicle_pending_note',
                    fallback:
                        'অ্যাডমিন গাড়িটি যাচাই করলে তবেই রাইড রিকোয়েস্ট পাবেন — সাধারণত ২৪ ঘণ্টার মধ্যে হয়ে যায়।'),
                style: AppFonts.roboto(
                  color: const Color(0xFF92400E),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _buildMetaText(
                      icon: _vehicleIcon(vehicle.vehicleType),
                      label: _vehicleTypeLabel(vehicle.vehicleType),
                    ),
                    _buildMetaText(
                      icon: Icons.event_seat_rounded,
                      label: '${vehicle.seatCapacity} seats',
                    ),
                    if (vehicle.color.trim().isNotEmpty)
                      _buildMetaText(
                        icon: Icons.circle,
                        label: vehicle.color.trim(),
                        iconColor: _vehicleColorValue(vehicle.color),
                      ),
                    _buildMetaText(
                      icon: isActive
                          ? Icons.check_circle_rounded
                          : Icons.pause_circle_rounded,
                      label: isActive ? 'Active' : 'Inactive',
                      iconColor: isActive ? _success : _danger,
                      textColor: isActive ? _success : _danger,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textSecondary,
                          side: const BorderSide(color: _line),
                          backgroundColor: _surfaceSoft,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _showContactSupportDialog(),
                        icon: const Icon(Icons.support_agent_rounded, size: 18),
                        label: Text(
                          t('rideshare_edit_via_support',
                              fallback: 'সাপোর্টের মাধ্যমে এডিট'),
                          style: AppFonts.roboto(
                              fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: isDefault ? _surfaceSoft : _primary,
                          foregroundColor:
                              isDefault ? _textSecondary : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSubmitting || isDefault
                            ? null
                            : () => _setDefaultVehicle(vehicle),
                        icon: Icon(
                          isDefault
                              ? Icons.verified_rounded
                              : Icons.stars_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isDefault ? 'Selected' : 'Set Default',
                          style: AppFonts.roboto(
                              fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap:
                          _isSubmitting ? null : () => _deleteVehicle(vehicle),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _dangerSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: _danger),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaText({
    required IconData icon,
    required String label,
    Color? iconColor,
    Color? textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor ?? _primary),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppFonts.roboto(
            color: textColor ?? _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: AdsyLoadingIndicator(color: _primary),
      );
    }

    return AdsyRefreshIndicator(
      color: _primary,
      onRefresh: _loadVehicles,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 96),
        children: [
          // Show KYC Pending message
          if (_isKYCPending)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _warningSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      color: _warning,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('rideshare_kyc_under_review',
                        fallback: 'ড্রাইভার প্রোফাইল যাচাই চলছে'),
                    style: AppFonts.roboto(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('rideshare_kyc_pending_vehicle_desc',
                        fallback:
                            'Your driver registration is currently under review by our admin team. You\'ll be able to add vehicles once your profile is approved.'),
                    textAlign: TextAlign.center,
                    style: AppFonts.roboto(
                      color: _textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _warningSoft,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: _warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_rounded, color: _warning, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t('rideshare_kyc_timeline',
                                fallback: 'সাধারণত ২৪-৪৮ ঘণ্টায় এপ্রুভ হয়'),
                            style: AppFonts.roboto(
                              color: _warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (_needsDriverApproval)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _warningSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.pending_actions_rounded,
                      color: _warning,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('rideshare_driver_not_approved_title',
                        fallback: 'ড্রাইভার অনুমোদন এখনো মেলেনি'),
                    style: AppFonts.roboto(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      'rideshare_driver_not_approved_desc',
                      fallback:
                          'আপনার ড্রাইভার প্রোফাইল এখনো এপ্রুভড হয়নি। আগে ড্রাইভার রেজিস্ট্রেশন কমপ্লিট করে অ্যাডমিন অনুমোদন পেলে তারপর এখানে গাড়ি যোগ করতে পারবেন।',
                    ),
                    textAlign: TextAlign.center,
                    style: AppFonts.roboto(
                      color: _textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _warningSoft,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: _warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: _warning, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t(
                              'rideshare_driver_not_approved_hint',
                              fallback:
                                  'অনুমোদন হয়ে গেলে এই পেইজে আপনার গাড়ির তালিকা দেখা যাবে।',
                            ),
                            style: AppFonts.roboto(
                              color: _warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          // Show error message
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _dangerSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: _danger,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t('rideshare_load_error',
                        fallback: 'গাড়ির তালিকা আনা যায়নি'),
                    style: AppFonts.roboto(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppFonts.roboto(
                      color: _textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _loadVehicles,
                    child: Text(t('try_again', fallback: 'আবার চেষ্টা করুন'),
                        style: AppFonts.roboto(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            )
          else ...[
            _buildOverview(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('rideshare_your_vehicles', fallback: 'আপনার গাড়িগুলো'),
                        style: AppFonts.roboto(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t('rideshare_vehicles_manage_desc',
                            fallback:
                                'Manage which vehicles are active and ready for rides.'),
                        style: AppFonts.roboto(
                          color: _textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _warningSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tips_and_updates_outlined,
                          color: _warning, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        t('rideshare_keep_one_default',
                            fallback: 'একটি ডিফল্ট রাখুন'),
                        style: AppFonts.roboto(
                          color: _warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_vehicles.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _line),
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
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_car_filled_rounded,
                        color: Color(0xFF64748B),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('rideshare_no_vehicles',
                          fallback: 'এখনো কোনো গাড়ি যোগ হয়নি'),
                      style: AppFonts.roboto(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t('rideshare_no_vehicles_desc',
                          fallback:
                              'Add your Bike, Car, or Auto to start receiving rides with the right vehicle type.'),
                      textAlign: TextAlign.center,
                      style: AppFonts.roboto(
                        color: _textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._vehicles.map(_buildVehicleCard),
          ],
        ],
      ),
    );
  }

}
