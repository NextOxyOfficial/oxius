import 'package:flutter/material.dart';
import 'package:oxius_native/utils/app_fonts.dart';
import '../services/auth_service.dart';
import '../services/user_state_service.dart';
import '../services/translation_service.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  // Palette shared with the login / register screens.
  static const _pageBackgroundColor = Color(0xFFF3F4FB);
  static const _surfaceColor = Colors.white;
  static const _cardBorderColor = Color(0xFFDDE3F5);
  static const _primaryColor = Color(0xFF10B5A5);
  static const _primaryDarkColor = Color(0xFF0B8F84);
  static const _headingTextColor = Color(0xFF1E2749);
  static const _bodyTextColor = Color(0xFF4A5578);
  static const _mutedTextColor = Color(0xFF7C87A8);

  final TranslationService _i18n = TranslationService();
  String _t(String key, String fallback) =>
      _i18n.translate(key, fallback: fallback);

  int _currentStep = 1;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  int _resendCooldown = 0;
  // Reset method: 'phone' (SMS OTP) or 'email' (email OTP).
  String _method = 'phone';
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _maskedContact = '';
  final _otpController = TextEditingController();
  String _resetToken = '';
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 1:
        return _t('reset_step1_desc',
            'রিসেট কোড পেতে আপনার ফোন নম্বরটা দিন');
      case 2:
        return _t('reset_step2_desc',
            'আমরা যে কোডটা পাঠিয়েছি সেটা এখানে লিখুন');
      case 3:
        return _t('reset_step3_desc', 'একটা নতুন পাসওয়ার্ড বানান');
      default:
        return '';
    }
  }

  String? _getPasswordStrength() {
    final password = _newPasswordController.text;
    if (password.isEmpty) return null;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    if (score < 3) return 'weak';
    if (score < 5) return 'medium';
    return 'strong';
  }

  bool get _isPasswordValid {
    final password = _newPasswordController.text;
    return password.length >= 8 &&
        password == _confirmPasswordController.text &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  void _clearMessages() => setState(() {
        _errorMessage = null;
        _successMessage = null;
      });

  String get _contactValue => _method == 'email'
      ? _emailController.text.trim()
      : _phoneController.text.trim();

  bool _validateContact() => _method == 'email'
      ? RegExp(r'^[\w\.\+\-]+@[\w\-]+(\.[\w\-]+)+$')
          .hasMatch(_emailController.text.trim())
      : RegExp(r'^(?:\+?88)?01[3-9]\d{8}$').hasMatch(_phoneController.text);

  Future<void> _handleSendOtp() async {
    _clearMessages();
    if (!_validateContact()) {
      setState(() => _errorMessage = _method == 'email'
          ? _t('reset_invalid_email', 'একটা সঠিক ইমেইল দিন')
          : _t('reset_invalid_phone',
              'একটা সঠিক ফোন নম্বর দিন (যেমন: 01XXXXXXXXX)'));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.sendOtp(
          method: _method, phone: _contactValue);
      if (mounted) {
        setState(() {
          _maskedContact =
              result['masked_phone'] ?? result['masked_email'] ?? '';
          _successMessage = result['message'] ??
              _t('reset_code_sent', 'কোড পাঠানো হয়েছে');
          _currentStep = 2;
          _isLoading = false;
        });
        _startResendCooldown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    _clearMessages();
    if (_otpController.text.length != 6) {
      setState(() => _errorMessage =
          _t('reset_invalid_code', 'সঠিক ৬ ডিজিটের কোড দিন'));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.verifyOtp(
          method: _method,
          phone: _contactValue,
          otp: _otpController.text);
      if (mounted) {
        setState(() {
          _resetToken = result['token'] ?? '';
          _successMessage = result['message'] ??
              _t('reset_code_verified', 'কোড ঠিক আছে');
          _currentStep = 3;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResetPassword() async {
    _clearMessages();
    if (!_isPasswordValid) {
      if (_newPasswordController.text.length < 8) {
        setState(() => _errorMessage = _t(
            'reset_pw_min', 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে।'));
      } else if (!RegExp(r'[A-Z]').hasMatch(_newPasswordController.text)) {
        setState(() => _errorMessage = _t('reset_pw_upper',
            'পাসওয়ার্ডে অন্তত একটা বড় হাতের অক্ষর দিন।'));
      } else if (!RegExp(r'[0-9]').hasMatch(_newPasswordController.text)) {
        setState(() => _errorMessage = _t(
            'reset_pw_number', 'পাসওয়ার্ডে অন্তত একটা সংখ্যা দিন।'));
      } else if (_newPasswordController.text !=
          _confirmPasswordController.text) {
        setState(() => _errorMessage =
            _t('reset_pw_mismatch', 'দুটো পাসওয়ার্ড এক হয়নি।'));
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.resetPassword(
          token: _resetToken, newPassword: _newPasswordController.text);
      if (mounted) {
        final msg = result['message'] ??
            _t('reset_success', 'পাসওয়ার্ড বদলে গেছে!');
        _showSuccessSnack(msg);
        if (result['auto_login'] == true && result['tokens'] != null) {
          final userState = UserStateService();
          if (result['user'] != null) {
            final user = User.fromJson(result['user'] as Map<String, dynamic>);
            userState.updateUser(user);
          }
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false);
          }
        } else {
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted) Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: AppFonts.roboto()))
        ]),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  Future<void> _handleResendOtp() async {
    if (_resendCooldown > 0) return;
    _otpController.clear();
    await _handleSendOtp();
  }

  void _startResendCooldown() {
    if (!mounted) return;
    setState(() => _resendCooldown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  void _goToPreviousStep() {
    _clearMessages();
    setState(() {
      if (_currentStep == 2) {
        _currentStep = 1;
        _otpController.clear();
      } else if (_currentStep == 3) {
        _currentStep = 2;
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 26),
                  _buildHero(),
                  const SizedBox(height: 22),
                  _buildProgressIndicator(),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    _buildMessageBox(_errorMessage!, isError: true),
                    const SizedBox(height: 16),
                  ],
                  if (_successMessage != null) ...[
                    _buildMessageBox(_successMessage!, isError: false),
                    const SizedBox(height: 16),
                  ],
                  if (_currentStep == 1) _buildStep1(),
                  if (_currentStep == 2) _buildStep2(),
                  if (_currentStep == 3) _buildStep3(),
                  const SizedBox(height: 18),
                  _buildNavigation(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Material(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () {
              if (_currentStep > 1) {
                _goToPreviousStep();
              } else {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _cardBorderColor),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: _headingTextColor, size: 20),
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFBDE8E2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, size: 14, color: _primaryColor),
              const SizedBox(width: 6),
              Text(
                _t('reset_secure_badge', 'নিরাপদ রিসেট'),
                style: AppFonts.roboto(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _primaryDarkColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primaryColor, _primaryDarkColor],
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.30),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.lock_reset_rounded,
              color: Colors.white, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          _t('reset_title', 'পাসওয়ার্ড রিসেট'),
          style: AppFonts.roboto(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: _headingTextColor.withValues(alpha: 0.9),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _getStepDescription(),
          style: AppFonts.roboto(
            fontSize: 13.5,
            color: _bodyTextColor,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() => Row(
        children: [
          _buildStepCircle(1),
          _buildStepLine(1),
          _buildStepCircle(2),
          _buildStepLine(2),
          _buildStepCircle(3),
        ],
      );

  Widget _buildStepCircle(int step) {
    final isDone = _currentStep > step;
    final isActive = _currentStep >= step;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isActive ? _primaryColor : const Color(0xFFE6EAF6),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
            : Text('$step',
                style: AppFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : _mutedTextColor)),
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isActive ? _primaryColor : const Color(0xFFE6EAF6),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildMessageBox(String message, {required bool isError}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isError
                  ? const Color(0xFFFECACA)
                  : const Color(0xFFBBF7D0)),
        ),
        child: Row(children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
              color:
                  isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
              size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: AppFonts.roboto(
                      color: isError
                          ? const Color(0xFF991B1B)
                          : const Color(0xFF166534),
                      fontSize: 12.5,
                      height: 1.35))),
        ]),
      );

  // Segmented toggle: reset via phone SMS or via email OTP.
  Widget _methodTab(String value, IconData icon, String label) {
    final selected = _method == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _method = value;
          _errorMessage = null;
        }),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? _primaryColor : _mutedTextColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppFonts.roboto(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? _primaryDarkColor : _mutedTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF1F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _methodTab('phone', Icons.phone_iphone_rounded,
                    _t('reset_via_phone', 'ফোন নম্বর')),
                _methodTab('email', Icons.alternate_email_rounded,
                    _t('reset_via_email', 'ইমেইল')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_method == 'phone') ...[
            _fieldLabel(_t('reset_phone_label', 'ফোন নম্বর')),
            const SizedBox(height: 8),
            _field(
              controller: _phoneController,
              hint: '01XXXXXXXXX',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
          ] else ...[
            _fieldLabel(_t('reset_email_label', 'ইমেইল')),
            const SizedBox(height: 8),
            _field(
              controller: _emailController,
              hint: 'your@email.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
          const SizedBox(height: 20),
          _primaryButton(
            label: _t('reset_send_code', 'রিসেট কোড পাঠান'),
            onPressed: _isLoading ? null : _handleSendOtp,
          ),
        ],
      );

  Widget _buildStep2() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _maskedContact.isNotEmpty
                ? _t('reset_code_sent_to',
                        '{contact}-এ ৬ ডিজিটের কোড পাঠানো হয়েছে')
                    .replaceFirst('{contact}', _maskedContact)
                : _t('reset_code_sent_generic',
                    'আপনার ফোন/ইমেইলে ৬ ডিজিটের কোড পাঠানো হয়েছে'),
            style: AppFonts.roboto(fontSize: 12.5, color: _bodyTextColor),
          ),
          const SizedBox(height: 16),
          _fieldLabel(_t('reset_code_label', 'ভেরিফিকেশন কোড')),
          const SizedBox(height: 8),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: AppFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
                color: _headingTextColor),
            decoration: InputDecoration(
              hintText: '••••••',
              counterText: '',
              hintStyle:
                  AppFonts.roboto(color: _mutedTextColor, letterSpacing: 8),
              filled: true,
              fillColor: _surfaceColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _cardBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _primaryColor, width: 1.6),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(value)) {
                _otpController.text = value.replaceAll(RegExp(r'[^0-9]'), '');
                _otpController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _otpController.text.length));
              }
              setState(() {});
            },
          ),
          const SizedBox(height: 18),
          _primaryButton(
            label: _t('reset_verify_code', 'কোড ভেরিফাই করুন'),
            onPressed: (_isLoading || _otpController.text.length != 6)
                ? null
                : _handleVerifyOtp,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _resendCooldown > 0 ? null : _handleResendOtp,
              child: Text(
                _resendCooldown > 0
                    ? _t('reset_resend_in', '{s} সেকেন্ড পর আবার পাঠান')
                        .replaceFirst('{s}', '$_resendCooldown')
                    : _t('reset_resend', 'কোড আবার পাঠান'),
                style: AppFonts.roboto(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _resendCooldown > 0 ? _mutedTextColor : _primaryColor,
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildStep3() {
    final strength = _getPasswordStrength();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(_t('reset_new_password', 'নতুন পাসওয়ার্ড')),
        const SizedBox(height: 8),
        _field(
          controller: _newPasswordController,
          hint: _t('reset_new_password_hint', 'নতুন পাসওয়ার্ড দিন'),
          icon: Icons.lock_outline_rounded,
          obscure: !_showPassword,
          suffix: IconButton(
            icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _bodyTextColor,
                size: 18),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        _fieldLabel(_t('reset_confirm_password', 'পাসওয়ার্ড আবার দিন')),
        const SizedBox(height: 8),
        _field(
          controller: _confirmPasswordController,
          hint: _t('reset_confirm_password_hint', 'পাসওয়ার্ডটা আবার লিখুন'),
          icon: Icons.verified_user_outlined,
          obscure: !_showConfirmPassword,
          suffix: IconButton(
            icon: Icon(
                _showConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _bodyTextColor,
                size: 18),
            onPressed: () =>
                setState(() => _showConfirmPassword = !_showConfirmPassword),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFFE6EAF6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: strength == 'weak'
                    ? 0.33
                    : strength == 'medium'
                        ? 0.66
                        : strength == 'strong'
                            ? 1.0
                            : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: _strengthColor(strength),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(_strengthLabel(strength),
              style: AppFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: strength == null
                      ? _mutedTextColor
                      : _strengthColor(strength))),
        ]),
        const SizedBox(height: 12),
        _buildPasswordRequirement(
            _t('reset_req_length', 'কমপক্ষে ৮ অক্ষর'),
            _newPasswordController.text.length >= 8),
        _buildPasswordRequirement(
            _t('reset_req_upper', 'একটা বড় হাতের অক্ষর'),
            RegExp(r'[A-Z]').hasMatch(_newPasswordController.text)),
        _buildPasswordRequirement(_t('reset_req_number', 'একটা সংখ্যা'),
            RegExp(r'[0-9]').hasMatch(_newPasswordController.text)),
        const SizedBox(height: 20),
        _primaryButton(
          label: _t('reset_submit', 'পাসওয়ার্ড রিসেট করুন'),
          onPressed:
              (_isLoading || !_isPasswordValid) ? null : _handleResetPassword,
        ),
      ],
    );
  }

  Color _strengthColor(String? s) {
    switch (s) {
      case 'weak':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'strong':
        return const Color(0xFF10B981);
      default:
        return _mutedTextColor;
    }
  }

  String _strengthLabel(String? s) {
    switch (s) {
      case 'weak':
        return _t('reset_strength_weak', 'দুর্বল');
      case 'medium':
        return _t('reset_strength_medium', 'মোটামুটি');
      case 'strong':
        return _t('reset_strength_strong', 'শক্তিশালী');
      default:
        return _t('reset_strength_none', 'পাসওয়ার্ড দিন');
    }
  }

  Widget _buildPasswordRequirement(String text, bool isMet) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(children: [
          Icon(isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 15,
              color: isMet ? const Color(0xFF10B981) : _mutedTextColor),
          const SizedBox(width: 8),
          Text(text,
              style: AppFonts.roboto(
                  fontSize: 12,
                  color: isMet ? const Color(0xFF166534) : _bodyTextColor)),
        ]),
      );

  Widget _buildNavigation() => Center(
        child: TextButton(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed('/login'),
          child: Text(
            _t('reset_back_to_login', 'লগইনে ফিরে যান'),
            style: AppFonts.roboto(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
            ),
          ),
        ),
      );

  // ── Shared login-styled field + button ──

  Widget _fieldLabel(String label) => Text(
        label,
        style: AppFonts.roboto(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: _bodyTextColor,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      onChanged: onChanged,
      style: AppFonts.roboto(
          fontSize: 13.5,
          color: _headingTextColor,
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppFonts.roboto(color: _mutedTextColor, fontSize: 13),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 50, minHeight: 44),
        prefixIcon: Icon(icon, color: _primaryColor, size: 18),
        suffixIcon: suffix,
        filled: true,
        fillColor: _surfaceColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _cardBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    );
  }

  Widget _primaryButton(
      {required String label, required VoidCallback? onPressed}) {
    final disabled = onPressed == null;
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: disabled
              ? null
              : const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_primaryDarkColor, _primaryColor],
                ),
          color: disabled ? const Color(0xFFCBD5E1) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: AdsyLoadingIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(label,
                  style: AppFonts.roboto(
                      fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
