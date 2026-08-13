part of 'rideshare_vehicles_screen.dart';

// ignore_for_file: unused_element

/// The add/edit vehicle sheet and the small form primitives it is built
/// from.
///
/// Split out of rideshare_vehicles_screen.dart to keep the screen file about
/// listing vehicles and this one about editing them.
extension _RsVehicleFormSection on _RideshareVehiclesScreenState {
  Future<void> _showVehicleForm({Vehicle? vehicle}) async {
    final formKey = GlobalKey<FormState>();
    final brandController = TextEditingController(text: vehicle?.brand ?? '');
    final modelController =
        TextEditingController(text: vehicle?.modelName ?? '');
    final colorController = TextEditingController(text: vehicle?.color ?? '');
    final regController = TextEditingController(
      text: vehicle?.registrationNumber ?? '',
    );
    final seatController = TextEditingController(
      text: (vehicle?.seatCapacity ?? 1).toString(),
    );

    String selectedType = vehicle?.vehicleType ?? 'bike';
    bool isActive = vehicle?.isActive ?? true;
    bool isDefault = vehicle?.isDefault ?? _vehicles.isEmpty;
    bool isSaving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              if (isSaving || !(formKey.currentState?.validate() ?? false)) {
                return;
              }

              setSheetState(() => isSaving = true);
              final seatCapacity =
                  int.tryParse(seatController.text.trim()) ?? 1;

              final result = vehicle == null
                  ? await RideshareService.createVehicle(
                      vehicleType: selectedType,
                      registrationNumber: regController.text.trim(),
                      brand: brandController.text.trim(),
                      modelName: modelController.text.trim(),
                      color: colorController.text.trim(),
                      seatCapacity: seatCapacity,
                      isDefault: isDefault,
                    )
                  : await RideshareService.updateVehicle(
                      vehicle.id,
                      vehicleType: selectedType,
                      registrationNumber: regController.text.trim(),
                      brand: brandController.text.trim(),
                      modelName: modelController.text.trim(),
                      color: colorController.text.trim(),
                      seatCapacity: seatCapacity,
                      isActive: isActive,
                      isDefault: isDefault,
                    );

              if (!mounted || !context.mounted) return;

              setSheetState(() => isSaving = false);
              if (result.success) {
                Navigator.of(context).pop(true);
              } else {
                _showMessage(result.message, isError: true);
              }
            }

            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: vehicle == null ? 0.82 : 0.88,
              minChildSize: 0.52,
              maxChildSize: 0.94,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(top: 16, bottom: bottomInset),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(22)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: Container(
                                  width: 42,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: _line,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                vehicle == null
                                    ? 'Add vehicle'
                                    : 'Edit vehicle',
                                style: AppFonts.roboto(
                                  color: _textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t('rideshare_vehicle_accuracy_note',
                                    fallback:
                                        'Keep your vehicle details accurate so ride assignment stays smooth.'),
                                style: AppFonts.roboto(
                                  color: _textSecondary,
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildSectionLabel(tr('গাড়ির ধরন')),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: selectedType,
                                decoration: _inputDecoration(),
                                style: AppFonts.roboto(
                                  color: _textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                items: [
                                  DropdownMenuItem(
                                      value: 'bike',
                                      child: Text(t('rideshare_vehicle_bike',
                                          fallback: 'Bike'))),
                                  DropdownMenuItem(
                                      value: 'car',
                                      child: Text(t('rideshare_vehicle_car',
                                          fallback: 'Car'))),
                                  DropdownMenuItem(
                                      value: 'cng',
                                      child: Text(t('rideshare_vehicle_cng',
                                          fallback: 'Auto'))),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setSheetState(() => selectedType = value);
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildSectionLabel(tr('ব্র্যান্ড')),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: brandController,
                                decoration: _inputDecoration(
                                    hint: 'Honda, Toyota, Bajaj'),
                                style: AppFonts.roboto(
                                    fontSize: 13, color: _textPrimary),
                              ),
                              const SizedBox(height: 12),
                              _buildSectionLabel(tr('মডেল')),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: modelController,
                                decoration: _inputDecoration(
                                    hint: 'Civic, Discover, Auto'),
                                style: AppFonts.roboto(
                                    fontSize: 13, color: _textPrimary),
                              ),
                              const SizedBox(height: 12),
                              _buildSectionLabel(tr('রং')),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: colorController,
                                decoration: _inputDecoration(
                                    hint: 'Red, Black, Silver'),
                                style: AppFonts.roboto(
                                    fontSize: 13, color: _textPrimary),
                              ),
                              const SizedBox(height: 12),
                              _buildSectionLabel(tr('রেজিস্ট্রেশন নম্বর')),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: regController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: _inputDecoration(
                                    hint: 'DHAKA METRO-GA-12-3456'),
                                style: AppFonts.roboto(
                                    fontSize: 13, color: _textPrimary),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Registration number is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildSectionLabel(tr('সিট সংখ্যা')),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: seatController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(hint: '1'),
                                style: AppFonts.roboto(
                                    fontSize: 13, color: _textPrimary),
                                validator: (value) {
                                  final seats =
                                      int.tryParse(value?.trim() ?? '');
                                  if (seats == null || seats < 1) {
                                    return 'Enter a valid seat count';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildToggleTile(
                                title: tr('ডিফল্ট গাড়ি করুন'),
                                subtitle:
                                    tr('রাইড ম্যাচিংয়ে এই গাড়িটি আগে ব্যবহার হবে।'),
                                value: isDefault,
                                onChanged: (value) {
                                  setSheetState(() => isDefault = value);
                                },
                              ),
                              if (vehicle != null) ...[
                                const SizedBox(height: 10),
                                _buildToggleTile(
                                  title: tr('গাড়ি সক্রিয়'),
                                  subtitle:
                                      tr('নিষ্ক্রিয় গাড়ি ডিসপ্যাচ থেকে লুকানো থাকবে।'),
                                  value: isActive,
                                  onChanged: (value) {
                                    setSheetState(() => isActive = value);
                                  },
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: isSaving ? null : submit,
                                  child: isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: AdsyLoadingIndicator(
                                            strokeWidth: 2.4,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(
                                          vehicle == null
                                              ? 'Save vehicle'
                                              : 'Update vehicle',
                                          style: AppFonts.roboto(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    brandController.dispose();
    modelController.dispose();
    colorController.dispose();
    regController.dispose();
    seatController.dispose();

    if (saved == true) {
      _showMessage(vehicle == null
          ? 'Vehicle added successfully.'
          : 'Vehicle updated successfully.');
      await _loadVehicles();
    }
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppFonts.roboto(color: _textMuted, fontSize: 13),
      filled: true,
      fillColor: _surfaceSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _danger, width: 1.4),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppFonts.roboto(
        color: _textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.roboto(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppFonts.roboto(
                    color: _textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: value,
            activeThumbColor: _primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  IconData _vehicleIcon(String type) {
    switch (type) {
      case 'bike':
        return Icons.two_wheeler_rounded;
      case 'car':
        return Icons.directions_car_filled_rounded;
      case 'cng':
        return Icons.electric_rickshaw_rounded;
      default:
        return Icons.directions_car_filled_rounded;
    }
  }

  String _vehicleTypeLabel(String type) {
    switch (type) {
      case 'bike':
        return 'Bike';
      case 'car':
        return 'Car';
      case 'cng':
        // Rider-facing name only; the API key stays 'cng'.
        return 'Auto';
      default:
        return type;
    }
  }

  Color _vehicleColorValue(String colorName) {
    switch (colorName.trim().toLowerCase()) {
      case 'black':
        return const Color(0xFF111827);
      case 'white':
        return const Color(0xFFF8FAFC);
      case 'gray':
      case 'grey':
      case 'silver':
        return const Color(0xFF94A3B8);
      case 'red':
        return const Color(0xFFEF4444);
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'green':
        return const Color(0xFF10B981);
      case 'yellow':
        return const Color(0xFFF59E0B);
      case 'orange':
        return const Color(0xFFF97316);
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'brown':
        return const Color(0xFF92400E);
      default:
        return _textMuted;
    }
  }
}
