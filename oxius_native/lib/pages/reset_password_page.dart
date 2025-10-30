import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/user_state_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  int _currentStep = 1;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  int _resendCooldown = 0;
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
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 1: return 'Enter your phone number to receive a reset code';
      case 2: return 'Enter the verification code we sent you';
      case 3: return 'Create a new secure password';
      default: return '';
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
    return password.length >= 8 && password == _confirmPasswordController.text && RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[0-9]').hasMatch(password);
  }

  void _clearMessages() => setState(() { _errorMessage = null; _successMessage = null; });
  bool _validateContact() => RegExp(r'^(?:\+?88)?01[3-9]\d{8}$').hasMatch(_phoneController.text);

  Future<void> _handleSendOtp() async {
    _clearMessages();
    if (!_validateContact()) { setState(() => _errorMessage = 'Please enter a valid phone number (e.g., 01XXXXXXXXX)'); return; }
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.sendOtp(method: 'phone', phone: _phoneController.text.trim());
      if (mounted) {
        setState(() { _maskedContact = result['masked_phone'] ?? ''; _successMessage = result['message'] ?? 'Code sent successfully'; _currentStep = 2; _isLoading = false; });
        _startResendCooldown();
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString().replaceFirst('Exception: ', ''); _isLoading = false; });
    }
  }

  Future<void> _handleVerifyOtp() async {
    _clearMessages();
    if (_otpController.text.length != 6) { setState(() => _errorMessage = 'Please enter a valid 6-digit code'); return; }
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.verifyOtp(method: 'phone', phone: _phoneController.text.trim(), otp: _otpController.text);
      if (mounted) setState(() { _resetToken = result['token'] ?? ''; _successMessage = result['message'] ?? 'Code verified successfully'; _currentStep = 3; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString().replaceFirst('Exception: ', ''); _isLoading = false; });
    }
  }

  Future<void> _handleResetPassword() async {
    _clearMessages();
    if (!_isPasswordValid) {
      if (_newPasswordController.text.length < 8) setState(() => _errorMessage = 'Password must be at least 8 characters long.');
      else if (!RegExp(r'[A-Z]').hasMatch(_newPasswordController.text)) setState(() => _errorMessage = 'Password must contain at least one uppercase letter.');
      else if (!RegExp(r'[0-9]').hasMatch(_newPasswordController.text)) setState(() => _errorMessage = 'Password must contain at least one number.');
      else if (_newPasswordController.text != _confirmPasswordController.text) setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.resetPassword(token: _resetToken, newPassword: _newPasswordController.text);
      if (mounted) {
        if (result['auto_login'] == true && result['tokens'] != null) {
          final userState = UserStateService();
          if (result['user'] != null) {
            final user = User.fromJson(result['user'] as Map<String, dynamic>);
            userState.updateUser(user);
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(result['message'] ?? 'Password reset successful!', style: GoogleFonts.roboto()))]), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(result['message'] ?? 'Password reset successful!', style: GoogleFonts.roboto()))]), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted) Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString().replaceFirst('Exception: ', ''); _isLoading = false; });
    }
  }

  Future<void> _handleResendOtp() async { if (_resendCooldown > 0) return; _otpController.clear(); await _handleSendOtp(); }
  void _startResendCooldown() { setState(() => _resendCooldown = 60); Future.doWhile(() async { await Future.delayed(const Duration(seconds: 1)); if (!mounted) return false; setState(() => _resendCooldown--); return _resendCooldown > 0; }); }
  void _goToPreviousStep() { _clearMessages(); setState(() { if (_currentStep == 2) { _currentStep = 1; _otpController.clear(); } else if (_currentStep == 3) { _currentStep = 2; _newPasswordController.clear(); _confirmPasswordController.clear(); } }); }

  @override
  Widget build(BuildContext context) => Scaffold(body: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.grey.shade50, Colors.grey.shade100])), child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12), child: Column(children: [const SizedBox(height: 8), _buildHeader(), const SizedBox(height: 32), _buildProgressIndicator(), const SizedBox(height: 32), _buildFormCard(), const SizedBox(height: 20), _buildNavigation()])))));

  Widget _buildHeader() => Container(padding: const EdgeInsets.all(16), child: Column(children: [Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Color(0xFFDEEAFF), shape: BoxShape.circle), child: Icon(Icons.lock_rounded, size: 32, color: Colors.blue.shade600)), const SizedBox(height: 16), Text('Reset Password', style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade900)), const SizedBox(height: 8), Text(_getStepDescription(), style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center)]));
  Widget _buildProgressIndicator() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildStepCircle(1), _buildStepLine(1), _buildStepCircle(2), _buildStepLine(2), _buildStepCircle(3)]);
  Widget _buildStepCircle(int step) { final isActive = _currentStep >= step; return Container(width: 32, height: 32, decoration: BoxDecoration(color: isActive ? Colors.blue.shade600 : Colors.grey.shade200, shape: BoxShape.circle), child: Center(child: Text('$step', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600, color: isActive ? Colors.white : Colors.grey.shade600)))); }
  Widget _buildStepLine(int step) { final isActive = _currentStep > step; return Container(width: 64, height: 4, color: isActive ? Colors.blue.shade600 : Colors.grey.shade200); }
  Widget _buildFormCard() => Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (_errorMessage != null) ...[_buildMessageBox(_errorMessage!, isError: true), const SizedBox(height: 20)], if (_successMessage != null) ...[_buildMessageBox(_successMessage!, isError: false), const SizedBox(height: 20)], if (_currentStep == 1) _buildStep1(), if (_currentStep == 2) _buildStep2(), if (_currentStep == 3) _buildStep3()]));
  Widget _buildMessageBox(String message, {required bool isError}) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8), border: Border.all(color: isError ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC))), child: Row(children: [Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A), size: 20), const SizedBox(width: 12), Expanded(child: Text(message, style: GoogleFonts.roboto(color: isError ? const Color(0xFF991B1B) : const Color(0xFF166534), fontSize: 13)))]));
  Widget _buildStep1() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('Phone Number', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)), const SizedBox(height: 8), TextField(controller: _phoneController, keyboardType: TextInputType.phone, style: GoogleFonts.roboto(fontSize: 14), decoration: InputDecoration(hintText: '01XXXXXXXXX', hintStyle: GoogleFonts.roboto(color: Colors.grey.shade400), prefixIcon: Icon(Icons.phone_rounded, color: Colors.grey.shade400), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blue.shade500, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))), const SizedBox(height: 24), SizedBox(height: 48, child: ElevatedButton(onPressed: _isLoading ? null : _handleSendOtp, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), disabledBackgroundColor: Colors.grey.shade300), child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : Text('Send Reset Code', style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w600))))]);
  Widget _buildStep2() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('We sent a 6-digit code to $_maskedContact', style: GoogleFonts.roboto(fontSize: 13, color: Colors.grey.shade600), textAlign: TextAlign.center), const SizedBox(height: 20), Text('Verification Code', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)), const SizedBox(height: 8), TextField(controller: _otpController, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center, style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 8), decoration: InputDecoration(hintText: '000000', hintStyle: GoogleFonts.roboto(color: Colors.grey.shade400, letterSpacing: 8), counterText: '', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blue.shade500, width: 2)), contentPadding: const EdgeInsets.symmetric(vertical: 16)), onChanged: (value) { if (value.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(value)) { _otpController.text = value.replaceAll(RegExp(r'[^0-9]'), ''); _otpController.selection = TextSelection.fromPosition(TextPosition(offset: _otpController.text.length)); } }), const SizedBox(height: 24), SizedBox(height: 48, child: ElevatedButton(onPressed: (_isLoading || _otpController.text.length != 6) ? null : _handleVerifyOtp, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), disabledBackgroundColor: Colors.grey.shade300), child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : Text('Verify Code', style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w600)))), const SizedBox(height: 16), TextButton(onPressed: _resendCooldown > 0 ? null : _handleResendOtp, child: Text(_resendCooldown > 0 ? 'Resend in ${_resendCooldown}s' : 'Resend Code', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600, color: _resendCooldown > 0 ? Colors.grey.shade400 : Colors.blue.shade600)))]);
  Widget _buildStep3() { final strength = _getPasswordStrength(); return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('New Password', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)), const SizedBox(height: 8), TextField(controller: _newPasswordController, obscureText: !_showPassword, style: GoogleFonts.roboto(fontSize: 14), decoration: InputDecoration(hintText: 'Enter new password', hintStyle: GoogleFonts.roboto(color: Colors.grey.shade400), prefixIcon: Icon(Icons.lock_rounded, color: Colors.grey.shade400), suffixIcon: IconButton(icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade400), onPressed: () => setState(() => _showPassword = !_showPassword)), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blue.shade500, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)), onChanged: (_) => setState(() {})), const SizedBox(height: 16), Text('Confirm Password', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)), const SizedBox(height: 8), TextField(controller: _confirmPasswordController, obscureText: !_showConfirmPassword, style: GoogleFonts.roboto(fontSize: 14), decoration: InputDecoration(hintText: 'Confirm new password', hintStyle: GoogleFonts.roboto(color: Colors.grey.shade400), prefixIcon: Icon(Icons.lock_rounded, color: Colors.grey.shade400), suffixIcon: IconButton(icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade400), onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword)), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blue.shade500, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)), onChanged: (_) => setState(() {})), const SizedBox(height: 16), Row(children: [Expanded(child: Container(height: 8, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: strength == 'weak' ? 0.33 : strength == 'medium' ? 0.66 : strength == 'strong' ? 1.0 : 0.0, child: Container(decoration: BoxDecoration(color: strength == 'weak' ? Colors.red.shade500 : strength == 'medium' ? Colors.yellow.shade600 : strength == 'strong' ? Colors.green.shade500 : Colors.transparent, borderRadius: BorderRadius.circular(4)))))), const SizedBox(width: 12), Text(strength ?? 'Enter password', style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, color: strength == 'weak' ? Colors.red.shade600 : strength == 'medium' ? Colors.yellow.shade700 : strength == 'strong' ? Colors.green.shade600 : Colors.grey.shade400))]), const SizedBox(height: 12), _buildPasswordRequirement('At least 8 characters', _newPasswordController.text.length >= 8), _buildPasswordRequirement('One uppercase letter', RegExp(r'[A-Z]').hasMatch(_newPasswordController.text)), _buildPasswordRequirement('One number', RegExp(r'[0-9]').hasMatch(_newPasswordController.text)), const SizedBox(height: 24), SizedBox(height: 48, child: ElevatedButton(onPressed: (_isLoading || !_isPasswordValid) ? null : _handleResetPassword, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), disabledBackgroundColor: Colors.grey.shade300), child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : Text('Reset Password', style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w600))))]); }
  Widget _buildPasswordRequirement(String text, bool isMet) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [Icon(Icons.check, size: 16, color: isMet ? Colors.green.shade600 : Colors.grey.shade400), const SizedBox(width: 8), Text(text, style: GoogleFonts.roboto(fontSize: 12, color: isMet ? Colors.green.shade700 : Colors.grey.shade500))]));
  Widget _buildNavigation() => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [if (_currentStep > 1) TextButton.icon(onPressed: _goToPreviousStep, icon: const Icon(Icons.arrow_back, size: 18), label: Text('Back', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600)), style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700)) else const SizedBox.shrink(), TextButton(onPressed: () => Navigator.of(context).pushReplacementNamed('/login'), child: Text('Back to Login', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue.shade600)))]));
}
