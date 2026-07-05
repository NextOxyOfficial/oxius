import 'package:flutter/material.dart';
import 'package:oxius_native/utils/app_fonts.dart';
import '../services/auth_service.dart';
import '../services/user_state_service.dart';
import '../services/fcm_service.dart';
import '../utils/network_error_handler.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_and_conditions_screen.dart';
import '../services/translation_service.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';
import '../widgets/profile_completion_sheet.dart';
import '../screens/suspended_account_screen.dart';
import '../widgets/social_login_buttons.dart';

class LoginPageRedesigned extends StatefulWidget {
  const LoginPageRedesigned({super.key});

  @override
  State<LoginPageRedesigned> createState() => _LoginPageRedesignedState();
}

class _LoginPageRedesignedState extends State<LoginPageRedesigned> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final TranslationService _i18n = TranslationService();
  String _t(String key, String fallback) =>
      _i18n.translate(key, fallback: fallback);

  // Palette pulled from the login illustration (soft periwinkle/indigo with
  // teal accents on a pale blue sky).
  static const _pageBackgroundColor = Color(0xFFF0F3FC);
  static const _surfaceColor = Colors.white;
  static const _cardBorderColor = Color(0xFFDDE3F5);
  static const _primaryColor = Color(0xFF5B67E8);
  static const _primaryDarkColor = Color(0xFF4149C8);
  static const _headingTextColor = Color(0xFF1E2749);
  static const _bodyTextColor = Color(0xFF4A5578);
  static const _mutedTextColor = Color(0xFF7C87A8);
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

        // Suspended accounts go straight to the lock screen — no app access.
        if (authResponse.user.isSuspended) {
          if (mounted) {
            SuspendedAccountScreen.lock(context,
                reason: authResponse.user.suspensionReason);
          }
          return;
        }

        await FCMService.syncTokenWithBackend();

        // Queue the "complete your profile" sheet if the profile is incomplete.
        ProfileCompletionSheet.markPendingIfNeeded(authResponse.user);

        if (mounted) {
          AdsyToast.success(
              context, _t('login_success', 'লগইন হয়ে গেছে!'));

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
            _errorMessage = _t(
                'login_invalid_credentials', 'ইমেইল বা পাসওয়ার্ড ঠিক নেই');
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // On the LOGIN page we never silently register: ask the backend not to
      // create, and if there's no account, confirm with the user (+ terms).
      var outcome =
          await AuthService.socialLogin(provider, createIfMissing: false);

      if (outcome.cancelled) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (outcome.accountNotFound) {
        if (mounted) setState(() => _isLoading = false);
        final confirmed = await _confirmCreateSocialAccount();
        if (confirmed != true) {
          await AuthService.socialSignOut();
          return;
        }
        if (mounted) setState(() => _isLoading = true);
        outcome = await AuthService.socialLogin(
          provider,
          createIfMissing: true,
          reuseIdToken: outcome.idToken,
        );
      }

      if (outcome.errorMessage != null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = outcome.errorMessage!;
          });
        }
        return;
      }

      final authResponse = outcome.auth;
      if (authResponse == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        final userState = UserStateService();
        userState.updateUser(authResponse.user);

        if (authResponse.user.isSuspended) {
          if (mounted) {
            SuspendedAccountScreen.lock(context,
                reason: authResponse.user.suspensionReason);
          }
          return;
        }

        await FCMService.syncTokenWithBackend();
        ProfileCompletionSheet.markPendingIfNeeded(authResponse.user);

        if (mounted) {
          AdsyToast.success(
              context, _t('login_success', 'লগইন হয়ে গেছে!'));

          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = NetworkErrorHandler.isNetworkError(e)
              ? NetworkErrorHandler.getErrorMessage(e)
              : _t('login_social_failed',
                      '{provider} দিয়ে লগইন করা গেল না। আবার চেষ্টা করুন।')
                  .replaceFirst('{provider}', provider);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Login-page only: confirm creating a brand-new account for an unregistered
  /// email, gated on accepting the terms & privacy policy.
  Future<bool?> _confirmCreateSocialAccount() {
    bool agreed = false;
    const labelStyle =
        TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF334155));
    final linkStyle = TextStyle(
      fontSize: 13,
      height: 1.6,
      fontWeight: FontWeight.w700,
      color: _primaryColor,
      decorationColor: _primaryColor,
    );

    return showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          void toggle() => setLocal(() => agreed = !agreed);
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primaryColor.withValues(alpha: 0.10),
                    ),
                    child: Icon(Icons.person_add_alt_1_rounded,
                        color: _primaryColor, size: 30),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'নতুন অ্যাকাউন্ট খুলবেন?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'এই জিমেইল দিয়ে এখনো কোনো অ্যাকাউন্ট খোলা হয়নি। '
                    'নতুন একটি অ্যাকাউন্ট খুলে শুরু করতে চান?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, height: 1.55, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 18),
                  // Consent card — the শর্তাবলী / গোপনীয়তা নীতি words are tappable
                  // and open the real screens; the rest toggles the checkbox.
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: agreed,
                            onChanged: (v) => setLocal(() => agreed = v ?? false),
                            activeColor: _primaryColor,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: toggle,
                                child: const Text('আমি AdsyClub-এর ',
                                    style: labelStyle),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(ctx).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const TermsAndConditionsScreen(),
                                  ),
                                ),
                                child: Text('শর্তাবলী', style: linkStyle),
                              ),
                              GestureDetector(
                                onTap: toggle,
                                child: const Text(' ও ', style: labelStyle),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(ctx).push(
                                  MaterialPageRoute(
                                    builder: (_) => const PrivacyPolicyScreen(),
                                  ),
                                ),
                                child:
                                    Text('গোপনীয়তা নীতি', style: linkStyle),
                              ),
                              GestureDetector(
                                onTap: toggle,
                                child: const Text(' পড়েছি এবং সম্মত আছি।',
                                    style: labelStyle),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            foregroundColor: const Color(0xFF64748B),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('বাতিল',
                              style: TextStyle(
                                  fontSize: 14.5, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed:
                              agreed ? () => Navigator.pop(ctx, true) : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryColor,
                            disabledBackgroundColor: const Color(0xFFCBD5E1),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('অ্যাকাউন্ট খুলুন',
                              style: TextStyle(
                                  fontSize: 14.5, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Branded illustration banner. The artwork (941×1672) has a
                // tall near-white fade at the bottom; clip it away so only the
                // scene + a little fade shows and the form can sit right under.
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.58,
                    child: Image.asset(
                      'assets/images/login_bg.png',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (_, __, ___) => const SizedBox(height: 24),
                    ),
                  ),
                ),
                // Pull the form up onto the illustration's white fade tail.
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeading(),
                            const SizedBox(height: 20),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_errorMessage.isNotEmpty)
                                    _buildErrorBanner(),
                                  _buildEmailField(),
                                  const SizedBox(height: 12),
                                  _buildPasswordField(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/reset-password'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: _linkTextColor,
                                ),
                                child: Text(
                                  _t('login_forgot', 'পাসওয়ার্ড ভুলে গেছেন?'),
                                  style: AppFonts.roboto(
                                    fontSize: 12.5,
                                    color: _linkTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSignInButton(),
                            const SizedBox(height: 22),
                            _buildSocialDivider(),
                            const SizedBox(height: 14),
                            SocialLoginButtons(
                              enabled: !_isLoading,
                              onProvider: _handleSocialLogin,
                            ),
                            const SizedBox(height: 24),
                            _buildCreateAccountRow(),
                            const SizedBox(height: 14),
                            _buildFooter(),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Top bar (back button + secure chip) floating over the illustration.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
              child: _buildTopBar(),
            ),
          ),
        ],
      ),
    );
  }

  // Top bar: professional back button (top-left) + a reassurance chip.
  Widget _buildTopBar() {
    return Row(
      children: [
        Material(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => Navigator.of(context).pushReplacementNamed('/'),
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
            border: Border.all(color: const Color(0xFFCFE0FF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 14, color: _primaryColor),
              const SizedBox(width: 6),
              Text(
                _t('login_secure_badge', 'নিরাপদ লগইন'),
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

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('login_welcome', 'আবার স্বাগতম'),
          style: AppFonts.roboto(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: _headingTextColor.withValues(alpha: 0.85),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _t('login_subtitle',
              'চালিয়ে যেতে আপনার AdsyClub অ্যাকাউন্টে লগইন করুন'),
          style: AppFonts.roboto(
            fontSize: 13.5,
            color: _bodyTextColor,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_primaryDarkColor, _primaryColor],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 8),
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
              borderRadius: BorderRadius.circular(14),
            ),
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
              : Text(
                  _t('login_sign_in', 'লগইন করুন'),
                  style: AppFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSocialDivider() {
    return Row(
      children: [
        const Expanded(
            child: Divider(color: Color(0xFFD5DCF0), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _t('login_or_continue', 'অথবা লগইন করুন'),
            style: AppFonts.roboto(
              fontSize: 10.5,
              color: _mutedTextColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const Expanded(
            child: Divider(color: Color(0xFFD5DCF0), thickness: 1)),
      ],
    );
  }

  Widget _buildCreateAccountRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _t('login_new_here', 'AdsyClub-এ নতুন?'),
          style: AppFonts.roboto(
            fontSize: 13,
            color: _bodyTextColor,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/register'),
          child: Text(
            _t('login_create_account', 'অ্যাকাউন্ট খুলুন'),
            style: AppFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFDC2626), size: 18),
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
        hintText: _t('login_identifier_hint', 'ইমেইল বা ফোন নম্বর'),
        hintStyle: AppFonts.roboto(color: _mutedTextColor, fontSize: 13),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 50, minHeight: 44),
        prefixIcon: const Icon(Icons.person_outline_rounded,
            color: _primaryColor, size: 18),
        filled: true,
        fillColor: _surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
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
      validator: (value) {
        final v = (value ?? '').trim();
        if (v.isEmpty) {
          return _t('login_identifier_required', 'ইমেইল বা ফোন নম্বর দিন');
        }
        final isEmail =
            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v);
        // Accept BD phone: 01XXXXXXXXX, 8801XXXXXXXXX, +8801XXXXXXXXX.
        final digits = v.replaceAll(RegExp(r'\D'), '');
        final isPhone = RegExp(r'^(?:\+?88)?01[3-9]\d{8}$').hasMatch(v) ||
            (digits.length == 11 && digits.startsWith('01')) ||
            (digits.length == 13 && digits.startsWith('8801'));
        if (!isEmail && !isPhone) {
          return _t('login_identifier_invalid',
              'ঠিকঠাক ইমেইল বা ফোন নম্বর দিন');
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
        hintText: _t('login_password_hint', 'পাসওয়ার্ড'),
        hintStyle: AppFonts.roboto(color: _mutedTextColor, fontSize: 13),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 50, minHeight: 44),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: _primaryColor, size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: _bodyTextColor,
            size: 18,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: _surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return _t('login_password_required', 'পাসওয়ার্ড দিন');
        }
        return null;
      },
    );
  }

  Widget _buildFooter() {
    TextStyle tiny([Color? c]) => AppFonts.roboto(
          fontSize: 10.5,
          color: c ?? _mutedTextColor,
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('© 2026 AdsyClub', style: tiny()),
        Text('  •  ', style: tiny()),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
          ),
          child: Text(_t('login_privacy', 'প্রাইভেসি'),
              style: tiny(_bodyTextColor)),
        ),
        Text('  •  ', style: tiny()),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const TermsAndConditionsScreen()),
          ),
          child: Text(_t('login_terms', 'শর্তাবলী'),
              style: tiny(_bodyTextColor)),
        ),
      ],
    );
  }
}
