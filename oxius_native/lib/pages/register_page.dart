import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oxius_native/utils/app_fonts.dart';

import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/geo_service.dart';
import '../services/user_state_service.dart';
import '../utils/network_error_handler.dart';
import '../widgets/profile_completion_sheet.dart';
import '../widgets/social_login_buttons.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

class RegisterPage extends StatefulWidget {
  final String? referralCode;

  const RegisterPage({super.key, this.referralCode});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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
  static const _dangerColor = Color(0xFFDC2626);
  static const _dangerSurfaceColor = Color(0xFFFEF2F2);

  bool _isLoading = false;
  String? _errorMessage;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

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

      final bytes = await pickedFile.readAsBytes();
      final mimeType = pickedFile.mimeType ?? 'image/jpeg';

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
            content: const Text('Failed to pick image. Please try again.'),
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
      _errors['first_name'] = 'First name is required';
      isValid = false;
    }

    if (_lastNameController.text.trim().isEmpty) {
      _errors['last_name'] = 'Last name is required';
      isValid = false;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _errors['email'] = 'Email is required';
      isValid = false;
    } else if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _errors['email'] = 'Enter a valid email address';
      isValid = false;
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _errors['phone'] = 'Phone is required';
      isValid = false;
    } else if (!RegExp(r'^(?:\+?88)?01[3-9]\d{8}$').hasMatch(phone)) {
      _errors['phone'] = 'Invalid phone number';
      isValid = false;
    }

    if (_passwordController.text.isEmpty) {
      _errors['password'] = 'Password is required';
      isValid = false;
    } else if (_passwordController.text.length < 6) {
      _errors['password'] = 'Password must be at least 6 characters';
      isValid = false;
    }

    if (_confirmPasswordController.text.isEmpty) {
      _errors['confirm_password'] = 'Confirm password is required';
      isValid = false;
    } else if (_confirmPasswordController.text != _passwordController.text) {
      _errors['confirm_password'] = 'Passwords do not match';
      isValid = false;
    }

    if (_selectedDateOfBirth == null) {
      _errors['date_of_birth'] = 'Date of birth is required';
      isValid = false;
    }

    final age = _ageController.text.trim();
    if (age.isEmpty) {
      _errors['age'] = 'Age is required';
      isValid = false;
    } else if (!RegExp(r'^\d+$').hasMatch(age)) {
      _errors['age'] = 'Invalid age';
      isValid = false;
    }

    if (_gender.isEmpty) {
      _errors['gender'] = 'Gender is required';
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
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateOfBirth ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select date of birth',
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

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.celebration_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Welcome to AdsyClub!',
                      style: AppFonts.roboto(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 4),
            ),
          );

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
      final authResponse = await AuthService.socialLogin(provider);

      // Null means the user cancelled the provider picker.
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
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = NetworkErrorHandler.isNetworkError(e)
              ? NetworkErrorHandler.getErrorMessage(e)
              : 'Could not sign up with $provider. Please try again.';
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 18),
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
          const SizedBox(height: 12),
          _buildSocialQuickSignup(),
          const SizedBox(height: 14),
          _buildRegistrationCard(isMobile),
          const SizedBox(height: 14),
          _buildFooter(),
        ],
      ),
    );
  }

  /// Highlighted social sign-up section shown at the very top of the register
  /// screen so users see the one-tap options the moment they land on the page.
  Widget _buildSocialQuickSignup() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF4FF), Color(0xFFF8FBFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCFE0FF)),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      'Sign up in seconds',
                      style: AppFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _headingTextColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Use your Google or Facebook account',
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
                  'OR REGISTER WITH EMAIL',
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
                'Secured signup',
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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Registration details',
            style: AppFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _headingTextColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fill out the form below to create your account in one step.',
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
            'Personal details',
            'These details are required to create and secure your account.',
          ),
          const SizedBox(height: 12),
          _buildTwoColumnRow(
            isMobile: isMobile,
            left: _buildTextField(
              label: 'First Name',
              hintText: 'Enter first name',
              controller: _firstNameController,
              icon: Icons.person_outline_rounded,
              error: _errors['first_name'],
            ),
            right: _buildTextField(
              label: 'Last Name',
              hintText: 'Enter last name',
              controller: _lastNameController,
              icon: Icons.badge_outlined,
              error: _errors['last_name'],
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Email Address',
            hintText: 'Enter your email',
            controller: _emailController,
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            error: _errors['email'],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Phone Number',
            hintText: 'Enter your phone number',
            controller: _phoneController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            error: _errors['phone'],
          ),
          const SizedBox(height: 12),
          _buildTwoColumnRow(
            isMobile: isMobile,
            left: _buildDateField(
              label: 'Date of Birth',
              hintText: 'Select birth date',
              controller: _dateOfBirthController,
              icon: Icons.event_outlined,
              error: _errors['date_of_birth'],
              onTap: _pickDateOfBirth,
            ),
            right: _buildTextField(
              label: 'Age',
              hintText: 'Auto-filled',
              controller: _ageController,
              icon: Icons.cake_outlined,
              keyboardType: TextInputType.number,
              readOnly: true,
              error: _errors['age'],
            ),
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Gender',
            hintText: 'Select gender',
            icon: Icons.wc_rounded,
            value: _gender.isEmpty ? null : _gender,
            items: const ['Male', 'Female', 'Others'],
            onChanged: (value) => setState(() => _gender = value ?? ''),
            error: _errors['gender'],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Password',
            hintText: 'Create a password',
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
            label: 'Confirm Password',
            hintText: 'Re-enter your password',
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
            'Location and referral',
            'These details are optional, but they help personalize your profile.',
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Region / State',
            hintText: 'Choose your region',
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
              label: 'City',
              hintText: 'Choose city',
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
              label: 'Area / Upazila',
              hintText: 'Choose area',
              icon: Icons.pin_drop_outlined,
              value: _selectedUpazila,
              items:
                  _upazilas.map((item) => item['name_eng'] as String).toList(),
              onChanged: (value) => setState(() => _selectedUpazila = value),
            ),
          ),
          const SizedBox(height: 12),
          _buildTwoColumnRow(
            isMobile: isMobile,
            left: _buildTextField(
              label: 'Postal Code',
              hintText: 'Enter postal code',
              controller: _zipController,
              icon: Icons.markunread_mailbox_outlined,
            ),
            right: _buildTextField(
              label: 'Referral Code',
              hintText: 'Optional referral code',
              controller: _referralController,
              icon: Icons.card_giftcard_outlined,
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Full Address',
            hintText: 'Enter your address',
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
                    'By continuing, you confirm that your information is accurate and your account credentials will be kept secure.',
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.rocket_launch_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Create Account',
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
      ),
    );
  }

  Widget _buildPhotoCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _softSurfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorderColor),
      ),
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
          'Profile photo',
          style: AppFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _headingTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Optional. Add a clear photo to make your profile look complete.',
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
                    ? 'Change Photo'
                    : 'Upload Photo',
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
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
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
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

  Widget _buildFooter() {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        child: Text(
          'Already have an account? Sign In',
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
