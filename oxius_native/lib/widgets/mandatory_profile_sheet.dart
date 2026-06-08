import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/user_state_service.dart';

/// Blocking, non-dismissible sheet shown right after registration / first login
/// until the four mandatory identity fields (first name, last name, phone, date
/// of birth) are filled. The user cannot browse the app until they submit.
class MandatoryProfileSheet {
  static bool _showing = false;

  static Future<void> maybeShow(BuildContext context) async {
    if (_showing) return;
    final user = UserStateService().currentUser;
    if (user == null || user.mandatoryProfileComplete) return;
    _showing = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => const _MandatoryProfileForm(),
      );
    } finally {
      _showing = false;
    }
  }
}

class _MandatoryProfileForm extends StatefulWidget {
  const _MandatoryProfileForm();

  @override
  State<_MandatoryProfileForm> createState() => _MandatoryProfileFormState();
}

class _MandatoryProfileFormState extends State<_MandatoryProfileForm> {
  static const _primary = Color(0xFF1D4ED8);

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  DateTime? _dob;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = UserStateService().currentUser;
    _firstName.text = u?.firstName ?? '';
    _lastName.text = u?.lastName ?? '';
    _phone.text = u?.phone ?? '';
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _valid =>
      _firstName.text.trim().isNotEmpty &&
      _lastName.text.trim().isNotEmpty &&
      _phone.text.trim().length >= 6 &&
      _dob != null;

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: 'জন্ম তারিখ নির্বাচন করুন',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_valid || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final u = UserStateService().currentUser;
    try {
      final d = _dob!;
      final dob = '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      await SettingsService.updateProfile(u!.email, {
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'phone': _phone.text.trim(),
        'date_of_birth': dob,
      });
      await UserStateService().refreshUserData();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'সংরক্ষণ করা যায়নি। ইন্টারনেট দেখে আবার চেষ্টা করুন।');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return PopScope(
      canPop: false, // mandatory — can't be dismissed until submitted
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.assignment_ind_rounded,
                            color: _primary, size: 25),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'প্রোফাইল সম্পূর্ণ করুন',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'অ্যাপ ব্যবহার করতে নিচের তথ্যগুলো দিন',
                              style: TextStyle(
                                  fontSize: 12.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _textField('প্রথম নাম', _firstName, hint: 'আপনার প্রথম নাম'),
                  const SizedBox(height: 14),
                  _textField('শেষ নাম', _lastName, hint: 'আপনার শেষ নাম'),
                  const SizedBox(height: 14),
                  _textField('ফোন নম্বর', _phone,
                      hint: '01XXXXXXXXX', keyboard: TextInputType.phone),
                  const SizedBox(height: 14),
                  _dobField(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(
                            color: Color(0xFFDC2626), fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _valid && !_saving ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        disabledBackgroundColor: const Color(0xFFCBD5E1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : const Text('সংরক্ষণ করে চালিয়ে যান',
                              style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController c,
      {String? hint, TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label *',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155))),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: keyboard,
          onChanged: (_) => setState(() {}),
          decoration: _decoration(hint),
        ),
      ],
    );
  }

  Widget _dobField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('জন্ম তারিখ *',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155))),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickDob,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_rounded,
                    size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 10),
                Text(
                  _dob == null
                      ? 'তারিখ নির্বাচন করুন'
                      : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                  style: TextStyle(
                      fontSize: 14,
                      color: _dob == null
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(String? hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 1.5)),
      );
}
