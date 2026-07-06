import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oxius_native/utils/app_fonts.dart';

import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/geo_service.dart';
import '../services/translation_service.dart';
import '../services/user_state_service.dart';
import '../utils/image_compressor.dart';
import '../utils/network_error_handler.dart';
import '../widgets/profile_completion_sheet.dart';
import '../widgets/social_login_buttons.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';
import 'package:oxius_native/widgets/common/dob_picker.dart';

class RegisterPage extends StatefulWidget {
  final String? referralCode;

  const RegisterPage({super.key, this.referralCode});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const _pageBackgroundColor = Color(0xFFF3F7FC);
  static const _surfaceColor = Color(0xFFFFFFFF);
  static const _cardBorderColor = Color(0xFFDCE6F2);
  static const _primaryColor = Color(0xFF1D4ED8);
  static const _primaryDarkColor = Color(0xFF163B8C);
  static const _primarySoftColor = Color(0xFFEAF2FF);
  static const _headingTextColor = Color(0xFF0F172A);
  static const _bodyTextColor = Color(0xFF475569);
  static const _mutedTextColor = Color(0xFF64748B);
  static const _dangerColor = Color(0xFFDC2626);
  static const _dangerSurfaceColor = Color(0xFFFEF2F2);

  bool _isLoading = false;
  String? _errorMessage;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  final TranslationService _i18n = TranslationService();
  String _t(String key, String fallback) =>
      _i18n.translate(key, fallback: fallback);

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _ageController = TextEditingController();
  final _zipController = TextEditingController();
  final _addressController = TextEditingController();
  final _referralController = TextEditingController();

  String? _profileImageBase64;
  File? _profileImageFile;
  Uint8List? _profileImageBytes;
  String? _profileImageName;
  DateTime? _selectedDateOfBirth;
  String _gender = '';
  final String _country = 'Bangladesh';
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedUpazila;

  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _upazilas = [];
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    if (widget.referralCode != null) {
      _referralController.text = widget.referralCode!;
    }
    _loadRegions();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateOfBirthController.dispose();
    _ageController.dispose();
    _zipController.dispose();
    _addressController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    try {
      final regions = await GeoService.getRegions(_country);
      if (mounted) {
        setState(() => _regions = regions);
      }
    } catch (e) {
      debugPrint('Error loading regions: $e');
    }
  }

  Future<void> _loadCities(String region) async {
    try {
      final cities = await GeoService.getCities(region);
      if (mounted) {
        setState(() {
          _cities = cities;
          _selectedCity = null;
          _upazilas = [];
          _selectedUpazila = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading cities: $e');
    }
  }

  Future<void> _loadUpazilas(String city) async {
    try {
      final upazilas = await GeoService.getUpazilas(city);
      if (mounted) {
        setState(() {
          _upazilas = upazilas;
          _selectedUpazila = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading upazilas: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      // Compress before storing for upload (fallback to original bytes)
      final Uint8List? compressed = await ImageCompressor.compressToBytes(
        pickedFile,
        targetSize: 80 * 1024,
      );
      final bytes = compressed ?? await pickedFile.readAsBytes();
      final mimeType = compressed != null
          ? 'image/jpeg'
          : (pickedFile.mimeType ?? 'image/jpeg');

      setState(() {
        _profileImageBytes = bytes;
        _profileImageName = pickedFile.name;
        _profileImageBase64 = 'data:$mimeType;base64,${base64Encode(bytes)}';
        if (!kIsWeb) {
          try {
            _profileImageFile = File(pickedFile.path);
          } catch (_) {
            _profileImageFile = null;
          }
        }
      });
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _t('reg_image_failed', 'ছবি নেওয়া গেল না। আবার চেষ্টা করুন।')),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _profileImageFile = null;
      _profileImageBase64 = null;
      _profileImageBytes = null;
      _profileImageName = null;
    });
  }

  bool _validateForm() {
    _errors.clear();
    var isValid = true;

    if (_firstNameController.text.trim().isEmpty) {
      _errors['first_name'] = _t('reg_err_first', 'প্রথম নাম দিন');
      isValid = false;
    }

    if (_lastNameController.text.trim().isEmpty) {
      _errors['last_name'] = _t('reg_err_last', 'শেষ নাম দিন');
      isValid = false;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _errors['email'] = _t('reg_err_email_req', 'ইমেইল দিন');
      isValid = false;
    } else if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _errors['email'] = _t('reg_err_email_invalid', 'সঠিক একটা ইমেইল দিন');
      isValid = false;
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _errors['phone'] = _t('reg_err_phone_req', 'ফোন নম্বর দিন');
      isValid = false;
    } else if (!RegExp(r'^(?:\+?88)?01[3-9]\d{8}$').hasMatch(phone)) {
      _errors['phone'] = _t('reg_err_phone_invalid', 'ফোন নম্বরটা ঠিক নেই');
      isValid = false;
    }

    if (_passwordController.text.isEmpty) {
      _errors['password'] = _t('reg_err_pw_req', 'পাসওয়ার্ড দিন');
      isValid = false;
    } else if (_passwordController.text.length < 6) {
      _errors['password'] =
          _t('reg_err_pw_len', 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে');
      isValid = false;
    }

    if (_confirmPasswordController.text.isEmpty) {
      _errors['confirm_password'] =
          _t('reg_err_cpw_req', 'পাসওয়ার্ড আবার দিন');
      isValid = false;
    } else if (_confirmPasswordController.text != _passwordController.text) {
      _errors['confirm_password'] =
          _t('reg_err_pw_mismatch', 'দুটো পাসওয়ার্ড এক হয়নি');
      isValid = false;
    }

    if (_selectedDateOfBirth == null) {
      _errors['date_of_birth'] = _t('reg_err_dob', 'জন্ম তারিখ দিন');
      isValid = false;
    }

    final age = _ageController.text.trim();
    if (age.isEmpty) {
      _errors['age'] = _t('reg_err_age_req', 'বয়স দরকার');
      isValid = false;
    } else if (!RegExp(r'^\d+$').hasMatch(age)) {
      _errors['age'] = _t('reg_err_age_invalid', 'বয়সটা ঠিক নেই');
      isValid = false;
    }

    if (_gender.isEmpty) {
      _errors['gender'] = _t('reg_err_gender', 'জেন্ডার বাছুন');
      isValid = false;
    }

    setState(() {});
    return isValid;
  }

  int _calculateAge(DateTime dateOfBirth) {
    final today = DateTime.now();
    var age = today.year - dateOfBirth.year;
    final birthdayThisYear =
        DateTime(today.year, dateOfBirth.month, dateOfBirth.day);
    if (today.isBefore(birthdayThisYear)) {
      age--;
    }
    return age;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDobPicker(
      context,
      initial: _selectedDateOfBirth,
      accent: _primaryColor,
    );

    if (picked == null) return;

    setState(() {
      _selectedDateOfBirth = picked;
      _dateOfBirthController.text = _formatDate(picked);
      _ageController.text = _calculateAge(picked).toString();
      _errors.remove('date_of_birth');
      _errors.remove('age');
    });
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final formData = <String, dynamic>{
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'name':
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'email': _emailController.text.trim(),
        'username': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'date_of_birth': _dateOfBirthController.text,
        'age': int.parse(_ageController.text),
        'gender': _gender,
        'country': _country,
        'state': _selectedRegion ?? '',
        'city': _selectedCity ?? '',
        'upazila': _selectedUpazila ?? '',
        'zip': _zipController.text.trim(),
        'address': _addressController.text.trim(),
        'refer': _referralController.text.trim(),
      };

      if (_profileImageBase64 != null) {
        formData['image'] = _profileImageBase64!;
      }

      final result = await AuthService.register(formData);

      if (mounted && result != null) {
        final loginResult = await AuthService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (mounted && loginResult != null) {
          final userState = UserStateService();
          userState.updateUser(loginResult.user);
          ProfileCompletionSheet.markPendingIfNeeded(loginResult.user);

          AdsyToast.success(context, _t('reg_welcome', 'AdsyClub-এ স্বাগতম!'));

          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = NetworkErrorHandler.isNetworkError(e)
              ? NetworkErrorHandler.getErrorMessage(e)
              : e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSocialRegister(String provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // The register page intentionally creates the account if it's new —
      // no extra confirmation needed here.
      final outcome =
          await AuthService.socialLogin(provider, createIfMissing: true);

      if (outcome.cancelled) {
        if (mounted) setState(() => _isLoading = false);
        return;
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

        await FCMService.syncTokenWithBackend();
        ProfileCompletionSheet.markPendingIfNeeded(authResponse.user);

        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = NetworkErrorHandler.isNetworkError(e)
              ? NetworkErrorHandler.getErrorMessage(e)
              : _t('reg_social_failed',
                      '{provider} দিয়ে সাইন আপ করা গেল না। আবার চেষ্টা করুন।')
                  .replaceFirst('{provider}', provider);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 420;

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
              top: 340,
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
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: _buildAuthCard(isMobile),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthCard(bool isMobile) {
    // Flat, plain-page layout (no wrapping card) — matches the login screen.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(),
          const SizedBox(height: 22),
          _buildSocialQuickSignup(),
          const SizedBox(height: 20),
          _buildRegistrationCard(isMobile),
          const SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );
  }

  /// Highlighted social sign-up section shown at the very top of the register
  /// screen so users see the one-tap options the moment they land on the page.
  Widget _buildSocialQuickSignup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCFE0FF)),
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: _primaryColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('reg_quick_title', 'সেকেন্ডেই সাইন আপ'),
                    style: AppFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _headingTextColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _t('reg_quick_sub',
                        'Google বা Facebook দিয়ে সাইন আপ করুন'),
                    style: AppFonts.roboto(
                      fontSize: 11.5,
                      color: _bodyTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SocialLoginButtons(
          enabled: !_isLoading,
          onProvider: _handleSocialRegister,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Divider(color: Color(0xFFD8E1EA), thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _t('reg_or_email', 'অথবা ইমেইল দিয়ে সাইন আপ করুন'),
                style: AppFonts.roboto(
                  fontSize: 10.5,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const Expanded(
              child: Divider(color: Color(0xFFD8E1EA), thickness: 1),
            ),
          ],
        ),
      ],
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
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _headingTextColor,
              size: 20,
            ),
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/login'),
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
              const Icon(Icons.person_add_alt_1_rounded,
                  size: 16, color: _primaryColor),
              const SizedBox(width: 6),
              Text(
                _t('reg_secure_badge', 'নিরাপদ সাইনআপ'),
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

  Widget _buildRegistrationCard(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _t('reg_details_title', 'রেজিস্ট্রেশনের তথ্য'),
          style: AppFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _headingTextColor,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _t('reg_details_sub',
              'নিচের ফর্মটা পূরণ করে এক ধাপেই অ্যাকাউন্ট খুলুন।'),
          style: AppFonts.roboto(
            fontSize: 12.5,
            color: _bodyTextColor,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        if (_errorMessage != null) ...[
          _buildErrorBanner(),
          const SizedBox(height: 16),
        ],
        _buildPhotoCard(isMobile),
        const SizedBox(height: 18),
        _buildSectionHeader(
          _t('reg_personal', 'ব্যক্তিগত তথ্য'),
          _t('reg_personal_sub',
              'অ্যাকাউন্ট খুলতে আর নিরাপদ রাখতে এই তথ্যগুলো লাগবে।'),
        ),
        const SizedBox(height: 12),
        _buildTwoColumnRow(
          isMobile: isMobile,
          left: _buildTextField(
            label: _t('reg_first_name', 'নামের প্রথম অংশ'),
            hintText: _t('reg_first_name_hint', 'প্রথম নাম লিখুন'),
            controller: _firstNameController,
            icon: Icons.person_outline_rounded,
            error: _errors['first_name'],
          ),
          right: _buildTextField(
            label: _t('reg_last_name', 'নামের শেষ অংশ'),
            hintText: _t('reg_last_name_hint', 'শেষ নাম লিখুন'),
            controller: _lastNameController,
            icon: Icons.badge_outlined,
            error: _errors['last_name'],
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: _t('reg_email', 'ইমেইল অ্যাড্রেস'),
          hintText: _t('reg_email_hint', 'আপনার ইমেইল লিখুন'),
          controller: _emailController,
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          error: _errors['email'],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: _t('reg_phone', 'ফোন নম্বর'),
          hintText: _t('reg_phone_hint', 'আপনার ফোন নম্বর লিখুন'),
          controller: _phoneController,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          error: _errors['phone'],
        ),
        const SizedBox(height: 12),
        _buildTwoColumnRow(
          isMobile: isMobile,
          left: _buildDateField(
            label: _t('reg_dob', 'জন্ম তারিখ'),
            hintText: _t('reg_dob_hint', 'জন্ম তারিখ বাছুন'),
            controller: _dateOfBirthController,
            icon: Icons.event_outlined,
            error: _errors['date_of_birth'],
            onTap: _pickDateOfBirth,
          ),
          right: _buildAgeDisplay(),
        ),
        const SizedBox(height: 12),
        _buildDropdownField(
          label: _t('reg_gender', 'জেন্ডার'),
          hintText: _t('reg_gender_hint', 'জেন্ডার বাছুন'),
          icon: Icons.wc_rounded,
          value: _gender.isEmpty ? null : _gender,
          // Stored/submitted value stays canonical English; only the label is
          // shown in Bangla so the backend keeps getting Male/Female/Others.
          items: const ['Male', 'Female', 'Others'],
          displayLabels: {
            'Male': _t('reg_male', 'পুরুষ'),
            'Female': _t('reg_female', 'মহিলা'),
            'Others': _t('reg_others', 'অন্যান্য'),
          },
          onChanged: (value) => setState(() => _gender = value ?? ''),
          error: _errors['gender'],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: _t('reg_password', 'পাসওয়ার্ড'),
          hintText: _t('reg_password_hint', 'একটা পাসওয়ার্ড বানান'),
          controller: _passwordController,
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isVisible: _showPassword,
          onToggleVisibility: () =>
              setState(() => _showPassword = !_showPassword),
          error: _errors['password'],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: _t('reg_confirm_password', 'পাসওয়ার্ড আবার দিন'),
          hintText: _t('reg_confirm_password_hint', 'পাসওয়ার্ডটা আবার লিখুন'),
          controller: _confirmPasswordController,
          icon: Icons.verified_user_outlined,
          isPassword: true,
          isVisible: _showConfirmPassword,
          onToggleVisibility: () =>
              setState(() => _showConfirmPassword = !_showConfirmPassword),
          error: _errors['confirm_password'],
        ),
        const SizedBox(height: 18),
        _buildSectionHeader(
          _t('reg_location', 'ঠিকানা ও রেফারেল'),
          _t('reg_location_sub',
              'এগুলো দেওয়া বাধ্যতামূলক না, তবে দিলে প্রোফাইলটা আরও সুন্দর হবে।'),
        ),
        const SizedBox(height: 12),
        _buildDropdownField(
          label: _t('reg_region', 'বিভাগ / অঞ্চল'),
          hintText: _t('reg_region_hint', 'আপনার অঞ্চল বাছুন'),
          icon: Icons.map_outlined,
          value: _selectedRegion,
          items: _regions.map((item) => item['name_eng'] as String).toList(),
          onChanged: (value) {
            setState(() => _selectedRegion = value);
            if (value != null) {
              _loadCities(value);
            }
          },
        ),
        const SizedBox(height: 12),
        _buildTwoColumnRow(
          isMobile: isMobile,
          left: _buildDropdownField(
            label: _t('reg_city', 'জেলা / শহর'),
            hintText: _t('reg_city_hint', 'শহর বাছুন'),
            icon: Icons.location_city_outlined,
            value: _selectedCity,
            items: _cities.map((item) => item['name_eng'] as String).toList(),
            onChanged: (value) {
              setState(() => _selectedCity = value);
              if (value != null) {
                _loadUpazilas(value);
              }
            },
          ),
          right: _buildDropdownField(
            label: _t('reg_area', 'এলাকা / উপজেলা'),
            hintText: _t('reg_area_hint', 'এলাকা বাছুন'),
            icon: Icons.pin_drop_outlined,
            value: _selectedUpazila,
            items: _upazilas.map((item) => item['name_eng'] as String).toList(),
            onChanged: (value) => setState(() => _selectedUpazila = value),
          ),
        ),
        const SizedBox(height: 12),
        _buildTwoColumnRow(
          isMobile: isMobile,
          left: _buildTextField(
            label: _t('reg_postal', 'পোস্টাল কোড'),
            hintText: _t('reg_postal_hint', 'পোস্টাল কোড লিখুন'),
            controller: _zipController,
            icon: Icons.markunread_mailbox_outlined,
          ),
          right: _buildTextField(
            label: _t('reg_referral', 'রেফারেল কোড'),
            hintText: _t('reg_referral_hint', 'রেফারেল কোড থাকলে দিন'),
            controller: _referralController,
            icon: Icons.card_giftcard_outlined,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: _t('reg_address', 'পুরো ঠিকানা'),
          hintText: _t('reg_address_hint', 'আপনার ঠিকানা লিখুন'),
          controller: _addressController,
          icon: Icons.home_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primarySoftColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD7E5FF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 18, color: _primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _t('reg_info_note',
                      'সাইন আপ করলে আপনি নিশ্চিত করছেন যে আপনার তথ্য সঠিক এবং আপনার অ্যাকাউন্টের তথ্য নিরাপদ রাখা হবে।'),
                  style: AppFonts.roboto(
                    fontSize: 11.8,
                    color: _primaryDarkColor,
                    height: 1.45,
                  ),
                ),
              ),
            ],
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
              onPressed: _isLoading ? null : _handleSubmit,
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
                      child: AdsyLoadingIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rocket_launch_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _t('reg_create_account', 'অ্যাকাউন্ট খুলুন'),
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
      ],
    );
  }

  Widget _buildPhotoCard(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhotoPreview(),
                const SizedBox(height: 12),
                _buildPhotoActions(),
              ],
            )
          : Row(
              children: [
                _buildPhotoPreview(),
                const SizedBox(width: 14),
                Expanded(child: _buildPhotoActions()),
              ],
            ),
    );
  }

  Widget _buildPhotoPreview() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: _surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD6E4FF), width: 2),
            ),
            child: ClipOval(
              child: _profileImageBytes != null
                  ? Image.memory(
                      _profileImageBytes!,
                      key: ValueKey(_profileImageName ?? 'image-memory'),
                      fit: BoxFit.cover,
                    )
                  : _profileImageFile != null
                      ? Image.file(
                          _profileImageFile!,
                          key: ValueKey(_profileImageFile!.path),
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.person_rounded,
                          size: 38,
                          color: _primaryColor,
                        ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('reg_photo_title', 'প্রোফাইল ছবি'),
          style: AppFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _headingTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _t('reg_photo_sub',
              'ইচ্ছে হলে একটা পরিষ্কার ছবি দিন, প্রোফাইলটা সম্পূর্ণ দেখাবে।'),
          style: AppFonts.roboto(
            fontSize: 12,
            color: _bodyTextColor,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: _pickImage,
              style: FilledButton.styleFrom(
                backgroundColor: _primarySoftColor,
                foregroundColor: _primaryDarkColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _profileImageBytes != null || _profileImageFile != null
                    ? _t('reg_change_photo', 'ছবি বদলান')
                    : _t('reg_upload_photo', 'ছবি আপলোড করুন'),
                style: AppFonts.roboto(
                    fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            if (_profileImageBytes != null || _profileImageFile != null)
              TextButton(
                onPressed: _removeImage,
                style: TextButton.styleFrom(
                  foregroundColor: _dangerColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                child: Text(
                  'Remove',
                  style: AppFonts.roboto(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _dangerSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: _dangerColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage ?? '',
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

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _headingTextColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: AppFonts.roboto(
            fontSize: 11.8,
            color: _bodyTextColor,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTwoColumnRow({
    required bool isMobile,
    required Widget left,
    required Widget right,
  }) {
    if (isMobile) {
      return Column(
        children: [
          left,
          const SizedBox(height: 12),
          right,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
    String? error,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: isPassword ? 1 : maxLines,
          obscureText: isPassword ? !isVisible : false,
          readOnly: readOnly,
          style: AppFonts.roboto(
            fontSize: 13.5,
            color: _headingTextColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppFonts.roboto(color: _mutedTextColor, fontSize: 13),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 54, minHeight: 44),
            prefixIcon: _buildFieldIcon(icon),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _bodyTextColor,
                      size: 18,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: _surfaceColor,
            errorText: error,
            errorMaxLines: 2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: _cardBorderColor),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: _primaryColor, width: 1.8),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: _dangerColor),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: _dangerColor, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
    required VoidCallback onTap,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          style: AppFonts.roboto(
            fontSize: 13.5,
            color: _headingTextColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppFonts.roboto(color: _mutedTextColor, fontSize: 13),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 54, minHeight: 44),
            prefixIcon: _buildFieldIcon(icon),
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.calendar_month_outlined,
                color: _bodyTextColor,
                size: 18,
              ),
              onPressed: onTap,
            ),
            filled: true,
            fillColor: _surfaceColor,
            errorText: error,
            errorMaxLines: 2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: _cardBorderColor),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: _primaryColor, width: 1.8),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: _dangerColor),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: _dangerColor, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hintText,
    required IconData icon,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    String? error,
    Map<String, String>? displayLabels,
  }) {
    // De-duplicate items: the geo data can return the same name twice (e.g. two
    // "Dhaka" rows), which makes DropdownButton assert "2 or more items with the
    // same value". Also drop a selected value that isn't in the list (else it
    // asserts "zero items with this value").
    final seen = <String>{};
    final uniqueItems = <String>[];
    for (final item in items) {
      final trimmed = item.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) continue;
      uniqueItems.add(trimmed);
    }
    final effectiveValue =
        (value != null && seen.contains(value.trim())) ? value.trim() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: effectiveValue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _bodyTextColor),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppFonts.roboto(color: _mutedTextColor, fontSize: 13),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 54, minHeight: 44),
            prefixIcon: _buildFieldIcon(icon),
            filled: true,
            fillColor: _surfaceColor,
            errorText: error,
            errorMaxLines: 2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: _cardBorderColor),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: _primaryColor, width: 1.8),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: _dangerColor),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: _dangerColor, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: uniqueItems
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    displayLabels?[item] ?? item,
                    style: AppFonts.roboto(
                        fontSize: 13.5, color: _headingTextColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
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

  Widget _buildFieldIcon(IconData icon) {
    return Icon(icon, color: _primaryColor, size: 18);
  }

  // Age is auto-derived from the date of birth — show it as plain text (no
  // input box) since the user never types here.
  Widget _buildAgeDisplay() {
    final age = _ageController.text.trim();
    final hasAge = age.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(_t('reg_age', 'বয়স')),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: Row(
            children: [
              const Icon(Icons.cake_outlined, color: _primaryColor, size: 18),
              const SizedBox(width: 10),
              Text(
                hasAge
                    ? _t('reg_age_years', '{age} বছর')
                        .replaceFirst('{age}', age)
                    : _t('reg_age_auto', 'অটো'),
                style: AppFonts.roboto(
                  fontSize: 14,
                  fontWeight: hasAge ? FontWeight.w700 : FontWeight.w500,
                  color: hasAge ? _headingTextColor : _mutedTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        child: Text(
          _t('reg_have_account', 'আগে থেকেই অ্যাকাউন্ট আছে? লগইন করুন'),
          style: AppFonts.roboto(
            fontSize: 12.5,
            color: _primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
