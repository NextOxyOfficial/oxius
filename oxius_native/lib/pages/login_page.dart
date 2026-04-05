import 'package:flutter/material.dart';
import 'package:oxius_native/utils/app_fonts.dart';
import '../services/auth_service.dart';
import '../services/user_state_service.dart';
import '../services/fcm_service.dart';
import '../utils/network_error_handler.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_and_conditions_screen.dart';

class LoginPageRedesigned extends StatefulWidget {
  const LoginPageRedesigned({super.key});

  @override
  State<LoginPageRedesigned> createState() => _LoginPageRedesignedState();
}

class _LoginPageRedesignedState extends State<LoginPageRedesigned> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const _pageBackgroundColor = Color(0xFFF3F7FC);
  static const _surfaceColor = Color(0xFFFFFFFF);
  static const _softSurfaceColor = Color(0xFFF8FBFF);
  static const _cardBorderColor = Color(0xFFDCE6F2);
  static const _primaryColor = Color(0xFF1D4ED8);
  static const _primaryDarkColor = Color(0xFF163B8C);
  static const _primarySoftColor = Color(0xFFEAF2FF);
  static const _headingTextColor = Color(0xFF0F172A);
  static const _bodyTextColor = Color(0xFF475569);
  static const _mutedTextColor = Color(0xFF64748B);
  static const _linkTextColor = _primaryColor;
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authResponse = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted && authResponse != null) {
        final userState = UserStateService();
        userState.updateUser(authResponse.user);

        await FCMService.syncTokenWithBackend();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login Successful!'),
              backgroundColor: _primaryColor,
              duration: Duration(seconds: 2),
            ),
          );
          
          await Future.delayed(const Duration(milliseconds: 300));
          
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Use NetworkErrorHandler for friendly offline/network error messages
        if (NetworkErrorHandler.isNetworkError(e)) {
          setState(() {
            _errorMessage = NetworkErrorHandler.getErrorMessage(e);
          });
        } else {
          // Authentication error (wrong credentials, etc.)
          setState(() {
            _errorMessage = 'Invalid email or password';
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: _pageBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _primaryColor.withValues(alpha: 0.12),
                      _primaryColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 310,
              left: -90,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0EA5E9).withValues(alpha: 0.10),
                      const Color(0xFF0EA5E9).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      _buildAuthCard(isMobile),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isMobile ? 14 : 18, 14, isMobile ? 14 : 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_surfaceColor, _softSurfaceColor],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _primaryDarkColor.withValues(alpha: 0.08),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(),
          const SizedBox(height: 14),
          _buildHeroCard(),
          const SizedBox(height: 18),
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE2E8F0).withValues(alpha: 0.0),
                  const Color(0xFFE2E8F0),
                  const Color(0xFFE2E8F0).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          _buildLoginCard(),
          const SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cardBorderColor),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: _headingTextColor, size: 20),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _primarySoftColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFCFE0FF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user_rounded, size: 16, color: _primaryColor),
              const SizedBox(width: 6),
              Text(
                'Secure login',
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

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_surfaceColor, _primarySoftColor],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _surfaceColor.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFD7E5FF)),
            ),
            child: Text(
              'Member access',
              style: AppFonts.roboto(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: _primaryDarkColor,
                letterSpacing: 0.25,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: _surfaceColor.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _primaryDarkColor.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 66,
                width: 66,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.storefront_rounded,
                    size: 52,
                    color: _primaryColor,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome back',
            textAlign: TextAlign.center,
            style: AppFonts.roboto(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: _headingTextColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to access your dashboard, messages and business activity in one place.',
            textAlign: TextAlign.center,
            style: AppFonts.roboto(
              fontSize: 12,
              color: _bodyTextColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: _primaryDarkColor.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Account sign in',
              style: AppFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _headingTextColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Use your registered email and password to continue to your workspace.',
              style: AppFonts.roboto(
                fontSize: 12.5,
                color: _bodyTextColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            if (_errorMessage.isNotEmpty) _buildErrorBanner(),
            _buildInputLabel('Email Address'),
            const SizedBox(height: 8),
            _buildEmailField(),
            const SizedBox(height: 16),
            _buildInputLabel('Password'),
            const SizedBox(height: 8),
            _buildPasswordField(),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/reset-password'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: _linkTextColor,
                ),
                child: Text(
                  'Forgot password?',
                  style: AppFonts.roboto(
                    fontSize: 12,
                    color: _linkTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [_primaryDarkColor, _primaryColor],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: Colors.white70,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.login_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Sign In',
                              style: AppFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Divider(color: const Color(0xFFD8E1EA), thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'NEW HERE?',
                    style: AppFonts.roboto(
                      fontSize: 10.5,
                      color: _mutedTextColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: const Color(0xFFD8E1EA), thickness: 1)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: _softSurfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorderColor),
              ),
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  foregroundColor: _headingTextColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create a new account',
                      style: AppFonts.roboto(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _headingTextColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18, color: _primaryColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage,
              style: AppFonts.roboto(
                fontSize: 11.5,
                color: const Color(0xFF991B1B),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: AppFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _bodyTextColor,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: AppFonts.roboto(
        fontSize: 13.5,
        color: _headingTextColor,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Enter your email',
        hintStyle: AppFonts.roboto(color: _mutedTextColor, fontSize: 13),
        prefixIconConstraints: const BoxConstraints(minWidth: 54, minHeight: 44),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10, right: 8),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primarySoftColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.alternate_email_rounded, color: _primaryColor, size: 18),
          ),
        ),
        filled: true,
        fillColor: _surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _cardBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryColor, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Email is required';
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: AppFonts.roboto(
        fontSize: 13.5,
        color: _headingTextColor,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Enter your password',
        hintStyle: AppFonts.roboto(color: _mutedTextColor, fontSize: 13),
        prefixIconConstraints: const BoxConstraints(minWidth: 54, minHeight: 44),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10, right: 8),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primarySoftColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline_rounded, color: _primaryColor, size: 18),
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: _bodyTextColor,
            size: 18,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: _surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _cardBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryColor, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password is required';
        return null;
      },
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          '© 2025 AdsyClub. All rights reserved.',
          style: AppFonts.roboto(
            fontSize: 10.5,
            color: _mutedTextColor,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
              child: Text(
                'Privacy',
                style: AppFonts.roboto(
                  fontSize: 10.5,
                  color: _bodyTextColor,
                ),
              ),
            ),
            const Text('•', style: TextStyle(color: _mutedTextColor)),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsAndConditionsScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
              child: Text(
                'Terms',
                style: AppFonts.roboto(
                  fontSize: 10.5,
                  color: _bodyTextColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
