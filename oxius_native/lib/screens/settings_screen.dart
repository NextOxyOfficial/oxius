import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import '../models/geo_location.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';
import '../services/geo_location_service.dart';
import '../services/settings_service.dart';
import '../services/translation_service.dart';
import '../services/user_state_service.dart';
import '../utils/app_fonts.dart';
import '../utils/image_compressor.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/dob_picker.dart';

enum _SettingsTab { profile, privacy, security }

enum _ProfileMediaTab { photo, banner }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _pageBackgroundColor = Color(0xFFF8FAFC);
  static const _surfaceColor = Color(0xFFFFFFFF);
  static const _softSurfaceColor = Color(0xFFF8FAFF);
  static const _surfaceMutedColor = Color(0xFFF1F5F9);
  static const _cardBorderColor = Color(0xFFE2E8F0);
  // Single blue accent shared with the rest of the app — no indigo/purple
  // gradients (those read as "AI generated").
  static const _primaryColor = Color(0xFF2563EB);
  static const _primaryDarkColor = Color(0xFF1D4ED8);
  static const _primarySoftColor = Color(0xFFEFF6FF);
  static const _headingTextColor = Color(0xFF1E293B);
  static const _bodyTextColor = Color(0xFF475569);
  static const _mutedTextColor = Color(0xFF64748B);
  static const _dangerColor = Color(0xFFDC2626);
  static const _warningColor = Color(0xFFF59E0B);

  final TranslationService _i18n = TranslationService();
  String _t(String key, String fallback) =>
      _i18n.translate(key, fallback: fallback);

  final _profileFormKey = GlobalKey<FormState>();
  final _securityFormKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _professionController = TextEditingController();
  final _companyController = TextEditingController();
  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _languagesController = TextEditingController();
  final _educationController = TextEditingController();
  final _skillsController = TextEditingController();
  final _addressController = TextEditingController();
  final _zipController = TextEditingController();
  final _aboutController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final GeoLocationService _geoService;

  _SettingsTab _activeTab = _SettingsTab.profile;
  _ProfileMediaTab _activeMediaTab = _ProfileMediaTab.photo;
  UserProfile? _userProfile;
  UserProfile? _originalProfile;

  List<Region> _divisions = [];
  List<City> _cities = [];
  List<Upazila> _upazilas = [];
  String? _selectedDivision;
  String? _selectedCity;
  String? _selectedUpazila;

  // Date of birth + gender — editable here so users can reach 100% profile
  // completion (these are required at registration but were missing from
  // settings, so social-login / older users had no way to add them).
  DateTime? _selectedDob;
  String _gender = '';
  static const List<String> _genderOptions = ['Male', 'Female', 'Other'];

  bool _isInitialLoading = true;
  bool _isLoadingDivisions = false;
  bool _isLoadingCities = false;
  bool _isLoadingUpazilas = false;
  bool _isSavingProfile = false;
  bool _isSavingPrivacy = false;
  bool _isChangingPassword = false;
  bool _isUploadingMedia = false;
  bool _isDeletingAccount = false;
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  int _mediaRefreshTick = 0;

  @override
  void initState() {
    super.initState();
    _geoService = GeoLocationService(baseUrl: '${AppConfig.mediaBaseUrl}/api');
    _attachControllerListeners();
    _initialize();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _professionController.dispose();
    _companyController.dispose();
    _websiteController.dispose();
    _tiktokController.dispose();
    _youtubeController.dispose();
    _linkedinController.dispose();
    _languagesController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _zipController.dispose();
    _aboutController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _attachControllerListeners() {
    for (final controller in [
      _firstNameController,
      _lastNameController,
      _emailController,
      _phoneController,
      _professionController,
      _companyController,
      _websiteController,
      _tiktokController,
      _youtubeController,
      _linkedinController,
      _languagesController,
      _educationController,
      _skillsController,
      _facebookController,
      _instagramController,
      _whatsappController,
      _addressController,
      _zipController,
      _aboutController,
    ]) {
      controller.addListener(_handleDraftChanged);
    }
  }

  void _handleDraftChanged() {
    if (!mounted || _originalProfile == null) {
      return;
    }
    setState(() {});
  }

  Future<void> _initialize() async {
    await _loadDivisions();
    await _loadUserProfile();
  }

  Future<void> _handleRefresh() async {
    await _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = AuthService.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _isInitialLoading = true);
    }

    try {
      final profile = await SettingsService.getUserProfile(user.email);
      if (!mounted) {
        return;
      }

      if (profile != null) {
        _userProfile = profile;
        _originalProfile = profile;
        await _populateControllers(profile);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(
            _t('settings_load_failed', 'সেটিংস আনা গেল না'),
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  Future<void> _populateControllers(UserProfile profile) async {
    _emailController.text = profile.email;
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _phoneController.text = profile.phone ?? '';
    _professionController.text = profile.profession ?? '';
    _companyController.text = profile.company ?? '';
    _websiteController.text = profile.website ?? '';
    _facebookController.text = profile.faceLink ?? '';
    _instagramController.text = profile.instagramLink ?? '';
    _whatsappController.text = profile.whatsappLink ?? '';
    _tiktokController.text = profile.tiktokLink ?? '';
    _youtubeController.text = profile.youtubeLink ?? '';
    _linkedinController.text = profile.linkedinLink ?? '';
    _languagesController.text = profile.languages ?? '';
    _educationController.text = profile.education ?? '';
    _skillsController.text = profile.skills ?? '';
    _addressController.text = profile.address ?? '';
    _zipController.text = profile.zip ?? '';
    _aboutController.text = profile.about ?? '';
    _selectedDob = _parseDob(profile.dateOfBirth);
    _gender = (profile.gender ?? '').trim();

    _selectedDivision = _normalizeNullable(profile.state);
    _selectedCity = _normalizeNullable(profile.city);
    _selectedUpazila = _normalizeNullable(profile.upazila);

    if (_selectedDivision != null) {
      await _loadCities(_selectedDivision!, resetSelection: false);
    }
    if (_selectedCity != null) {
      await _loadUpazilas(_selectedCity!, resetSelection: false);
    }

    if (mounted) {
      setState(() {});
    }
  }

  DateTime? _parseDob(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }

  String? _formatDob(DateTime? d) {
    if (d == null) return null;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _pickDob() async {
    final picked = await showDobPicker(
      context,
      initial: _selectedDob,
      accent: _primaryColor,
    );
    if (picked != null && mounted) {
      setState(() => _selectedDob = picked);
    }
  }

  int _calculateAge(DateTime dob) {
    final today = DateTime.now();
    var age = today.year - dob.year;
    final birthdayThisYear = DateTime(today.year, dob.month, dob.day);
    if (today.isBefore(birthdayThisYear)) age--;
    return age;
  }

  Future<void> _loadDivisions() async {
    if (mounted) {
      setState(() => _isLoadingDivisions = true);
    }
    try {
      final divisions = await _geoService.fetchRegions();
      if (!mounted) {
        return;
      }
      setState(() => _divisions = divisions);
    } catch (_) {
      if (mounted) {
        _showSnackBar(
            _t('settings_divisions_load_failed', 'বিভাগ আনা গেল না'),
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDivisions = false);
      }
    }
  }

  Future<void> _loadCities(String divisionName,
      {bool resetSelection = true}) async {
    if (mounted) {
      setState(() {
        _isLoadingCities = true;
        _cities = [];
        if (resetSelection) {
          _selectedCity = null;
          _upazilas = [];
          _selectedUpazila = null;
        }
      });
    }

    try {
      final cities = await _geoService.fetchCities(regionName: divisionName);
      if (!mounted) {
        return;
      }
      setState(() => _cities = cities);
    } catch (_) {
      if (mounted) {
        _showSnackBar(
            _t('settings_cities_load_failed', 'শহর আনা গেল না'),
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCities = false);
      }
    }
  }

  Future<void> _loadUpazilas(String cityName,
      {bool resetSelection = true}) async {
    if (mounted) {
      setState(() {
        _isLoadingUpazilas = true;
        _upazilas = [];
        if (resetSelection) {
          _selectedUpazila = null;
        }
      });
    }

    try {
      final upazilas = await _geoService.fetchUpazilas(cityName: cityName);
      if (!mounted) {
        return;
      }
      setState(() => _upazilas = upazilas);
    } catch (_) {
      if (mounted) {
        _showSnackBar(
            _t('settings_upazilas_load_failed', 'উপজেলা আনা গেল না'),
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUpazilas = false);
      }
    }
  }

  bool get _isKycLocked => _userProfile?.kyc ?? false;

  bool get _hasProfileChanges {
    final original = _originalProfile;
    if (original == null) {
      return false;
    }

    return _normalized(_firstNameController.text) !=
            _normalized(original.firstName) ||
        _normalized(_lastNameController.text) !=
            _normalized(original.lastName) ||
        _normalized(_phoneController.text) != _normalized(original.phone) ||
        _normalized(_professionController.text) !=
            _normalized(original.profession) ||
        _normalized(_companyController.text) != _normalized(original.company) ||
        _normalized(_websiteController.text) != _normalized(original.website) ||
        _normalized(_facebookController.text) !=
            _normalized(original.faceLink) ||
        _normalized(_instagramController.text) !=
            _normalized(original.instagramLink) ||
        _normalized(_whatsappController.text) !=
            _normalized(original.whatsappLink) ||
        _normalized(_addressController.text) != _normalized(original.address) ||
        _normalized(_zipController.text) != _normalized(original.zip) ||
        _normalized(_aboutController.text) != _normalized(original.about) ||
        _normalized(_selectedDivision) != _normalized(original.state) ||
        _normalized(_selectedCity) != _normalized(original.city) ||
        _normalized(_selectedUpazila) != _normalized(original.upazila) ||
        _normalized(_formatDob(_selectedDob)) !=
            _normalized(original.dateOfBirth) ||
        _normalized(_gender) != _normalized(original.gender);
  }

  bool get _hasPrivacyChanges {
    final original = _originalProfile;
    final current = _userProfile;
    if (original == null || current == null) {
      return false;
    }

    return (current.emailPublic ?? false) != (original.emailPublic ?? false) ||
        (current.phonePublic ?? false) != (original.phonePublic ?? false) ||
        (current.professionPublic ?? true) !=
            (original.professionPublic ?? true) ||
        (current.companyPublic ?? true) != (original.companyPublic ?? true) ||
        (current.websitePublic ?? true) != (original.websitePublic ?? true) ||
        (current.facebookPublic ?? true) != (original.facebookPublic ?? true) ||
        (current.instagramPublic ?? true) !=
            (original.instagramPublic ?? true) ||
        (current.whatsappPublic ?? true) != (original.whatsappPublic ?? true) ||
        (current.aboutPublic ?? true) != (original.aboutPublic ?? true) ||
        (current.whoCanMessage ?? 'everyone') !=
            (original.whoCanMessage ?? 'everyone');
  }

  int get _passwordStrength {
    final password = _newPasswordController.text;
    if (password.isEmpty) {
      return 0;
    }

    var score = 0;
    if (password.length >= 8) {
      score++;
    }
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(password) ||
        RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      score++;
    }
    return score;
  }

  String _normalized(String? value) => value?.trim() ?? '';

  String? _normalizeNullable(String? value) {
    final normalized = _normalized(value);
    return normalized.isEmpty ? null : normalized;
  }

  String _maskEmail(String email, bool isPublic) {
    if (isPublic || email.trim().isEmpty) {
      return email;
    }

    final parts = email.split('@');
    if (parts.length != 2) {
      return email;
    }

    final username = parts[0];
    if (username.length <= 2) {
      return '${username}XX@${parts[1]}';
    }

    return '${username.substring(0, 2)}${'X' * (username.length - 2)}@${parts[1]}';
  }

  String _maskPhone(String phone, bool isPublic) {
    if (isPublic || phone.trim().isEmpty) {
      return phone;
    }

    if (phone.length <= 5) {
      return phone;
    }

    return '${phone.substring(0, 3)}${'X' * (phone.length - 5)}${phone.substring(phone.length - 2)}';
  }

  bool get _areProfessionalFieldsPublic {
    final profile = _userProfile;
    if (profile == null) {
      return true;
    }

    return (profile.professionPublic ?? true) &&
        (profile.companyPublic ?? true) &&
        (profile.websitePublic ?? true) &&
        (profile.facebookPublic ?? true) &&
        (profile.instagramPublic ?? true) &&
        (profile.whatsappPublic ?? true) &&
        (profile.aboutPublic ?? true);
  }

  String _visibilityPreview(
    String? value,
    bool isPublic, {
    required String emptyLabel,
  }) {
    final normalized = _normalized(value);
    if (normalized.isEmpty) {
      return emptyLabel;
    }

    return isPublic
        ? normalized
        : _t('settings_hidden_on_profile',
            'বিজনেস নেটওয়ার্ক প্রোফাইলে দেখানো হবে না');
  }

  Future<void> _refreshUserCaches() async {
    await AuthService.refreshUserData();
    await UserStateService().refreshUserData();
  }

  Future<void> _applyUpdatedProfile(
    Map<String, dynamic> data, {
    required String successMessage,
  }) async {
    final updated = UserProfile.fromJson(data);
    _userProfile = updated;
    _originalProfile = updated;
    await _populateControllers(updated);
    await _refreshUserCaches();

    if (mounted) {
      setState(() {});
      _showSnackBar(successMessage);
    }
  }

  String _mediaUrl(String? url) {
    final value = (url ?? '').trim();
    if (value.isEmpty) {
      return '';
    }

    final separator = value.contains('?') ? '&' : '?';
    return '$value${separator}v=$_mediaRefreshTick';
  }

  Future<ImageSource?> _selectImageSource({
    required String title,
  }) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: Container(
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _cardBorderColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: AppFonts.roboto(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _headingTextColor,
                        ),
                      ),
                    ),
                  ),
                  _buildImageSourceAction(
                    icon: Icons.photo_library_outlined,
                    label: _t('settings_choose_from_gallery',
                        'গ্যালারি থেকে সিলেক্ট করুন'),
                    onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                  ),
                  _buildImageSourceAction(
                    icon: Icons.camera_alt_outlined,
                    label: _t('settings_take_photo', 'ছবি তুলুন'),
                    onTap: () => Navigator.of(context).pop(ImageSource.camera),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSourceAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _primarySoftColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: _primaryColor),
      ),
      title: Text(
        label,
        style: AppFonts.roboto(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: _headingTextColor,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (isError) {
      AdsyToast.error(context, message);
    } else {
      AdsyToast.success(context, message);
    }
  }

  Future<void> _saveProfile() async {
    if (_userProfile == null || !_hasProfileChanges) {
      return;
    }
    if (!_profileFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      final payload = {
        'phone': _phoneController.text.trim(),
        'profession': _professionController.text.trim(),
        'company': _companyController.text.trim(),
        'website': _websiteController.text.trim(),
        'face_link': _facebookController.text.trim(),
        'instagram_link': _instagramController.text.trim(),
        'whatsapp_link': _whatsappController.text.trim(),
        'tiktok_link': _tiktokController.text.trim(),
        'youtube_link': _youtubeController.text.trim(),
        'linkedin_link': _linkedinController.text.trim(),
        'languages': _languagesController.text.trim(),
        'education': _educationController.text.trim(),
        'skills': _skillsController.text.trim(),
        'about': _aboutController.text.trim(),
        if (_formatDob(_selectedDob) != null)
          'date_of_birth': _formatDob(_selectedDob),
        if (_gender.isNotEmpty) 'gender': _gender,
        'email_public': _userProfile?.emailPublic ?? false,
        'phone_public': _userProfile?.phonePublic ?? false,
        'professional_details_public': _areProfessionalFieldsPublic,
        'profession_public': _userProfile?.professionPublic ?? true,
        'company_public': _userProfile?.companyPublic ?? true,
        'website_public': _userProfile?.websitePublic ?? true,
        'facebook_public': _userProfile?.facebookPublic ?? true,
        'instagram_public': _userProfile?.instagramPublic ?? true,
        'whatsapp_public': _userProfile?.whatsappPublic ?? true,
        'about_public': _userProfile?.aboutPublic ?? true,
        'who_can_message': _userProfile?.whoCanMessage ?? 'everyone',
      };

      if (!_isKycLocked) {
        payload.addAll({
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'address': _addressController.text.trim(),
          'state': _selectedDivision ?? '',
          'city': _selectedCity ?? '',
          'upazila': _selectedUpazila ?? '',
          'zip': _zipController.text.trim(),
        });
      }

      final result =
          await SettingsService.updateProfile(_userProfile!.email, payload);
      if ((result['success'] ?? false) == true &&
          result['data'] is Map<String, dynamic>) {
        await _applyUpdatedProfile(
          Map<String, dynamic>.from(result['data']),
          successMessage: _t('settings_profile_updated', 'প্রোফাইল আপডেট হয়েছে'),
        );
      } else {
        _showSnackBar(
            result['message'] ??
                _t('settings_profile_update_failed',
                    'প্রোফাইল আপডেট করা গেল না'),
            isError: true);
      }
    } catch (_) {
      _showSnackBar(
          _t('settings_profile_update_failed', 'প্রোফাইল আপডেট করা গেল না'),
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _savePrivacy() async {
    if (_userProfile == null || !_hasPrivacyChanges) {
      return;
    }

    setState(() => _isSavingPrivacy = true);

    try {
      final payload = {
        'email_public': _userProfile?.emailPublic ?? false,
        'phone_public': _userProfile?.phonePublic ?? false,
        'professional_details_public': _areProfessionalFieldsPublic,
        'profession_public': _userProfile?.professionPublic ?? true,
        'company_public': _userProfile?.companyPublic ?? true,
        'website_public': _userProfile?.websitePublic ?? true,
        'facebook_public': _userProfile?.facebookPublic ?? true,
        'instagram_public': _userProfile?.instagramPublic ?? true,
        'whatsapp_public': _userProfile?.whatsappPublic ?? true,
        'about_public': _userProfile?.aboutPublic ?? true,
        'who_can_message': _userProfile?.whoCanMessage ?? 'everyone',
      };

      final result =
          await SettingsService.updateProfile(_userProfile!.email, payload);
      if ((result['success'] ?? false) == true &&
          result['data'] is Map<String, dynamic>) {
        await _applyUpdatedProfile(
          Map<String, dynamic>.from(result['data']),
          successMessage: _t('settings_privacy_updated',
              'বিজনেস নেটওয়ার্ক প্রাইভেসি আপডেট হয়েছে'),
        );
      } else {
        _showSnackBar(
            result['message'] ??
                _t('settings_privacy_update_failed',
                    'প্রাইভেসি আপডেট করা গেল না'),
            isError: true);
      }
    } catch (_) {
      _showSnackBar(
          _t('settings_privacy_update_failed', 'প্রাইভেসি আপডেট করা গেল না'),
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSavingPrivacy = false);
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_securityFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final result = await SettingsService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if ((result['success'] ?? false) == true) {
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() {});
        _showSnackBar(result['message'] ??
            _t('settings_password_changed', 'পাসওয়ার্ড বদলে গেছে'));
      } else {
        _showSnackBar(
            result['message'] ??
                _t('settings_password_change_failed',
                    'পাসওয়ার্ড বদলানো গেল না'),
            isError: true);
      }
    } catch (_) {
      _showSnackBar(
          _t('settings_password_change_failed', 'পাসওয়ার্ড বদলানো গেল না'),
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final passwordController = TextEditingController();
    bool showPassword = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: _dangerColor, size: 24),
              const SizedBox(width: 8),
              Text(
                _t('settings_delete_account', 'অ্যাকাউন্ট ডিলিট'),
                style: AppFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _dangerColor),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('settings_delete_account_warning',
                    'এতে আপনার অ্যাকাউন্ট আর সব ডেটা একদম মুছে যাবে। এটা আর ফেরানো যাবে না।'),
                style: AppFonts.roboto(
                    fontSize: 14, color: _bodyTextColor, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                _t('settings_delete_confirm_password',
                    'নিশ্চিত করতে পাসওয়ার্ড দিন:'),
                style: AppFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _headingTextColor),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  hintText: _t('settings_current_password_hint',
                      'আপনার বর্তমান পাসওয়ার্ড'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(
                        showPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setDialogState(() => showPassword = !showPassword),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_t('settings_cancel', 'ক্যান্সেল'),
                  style: AppFonts.roboto(fontWeight: FontWeight.w600)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: _dangerColor),
              child: Text(_t('settings_delete', 'ডিলিট'),
                  style: AppFonts.roboto(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) {
      passwordController.dispose();
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      _showSnackBar(
          _t('settings_password_required', 'পাসওয়ার্ড দিতে হবে'),
          isError: true);
      passwordController.dispose();
      return;
    }

    setState(() => _isDeletingAccount = true);

    try {
      final result = await SettingsService.deleteAccount(
        password: passwordController.text,
      );

      if ((result['success'] ?? false) == true) {
        // Logout and navigate to login (clears entire stack so the deleted
        // account cannot be returned to via back navigation).
        await AuthService.logout();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        }
      } else {
        _showSnackBar(
            result['message'] ??
                _t('settings_delete_account_failed',
                    'অ্যাকাউন্ট ডিলিট করা গেল না'),
            isError: true);
      }
    } catch (_) {
      _showSnackBar(
          _t('settings_delete_account_failed_retry',
              'অ্যাকাউন্ট ডিলিট করা গেল না। আবার চেষ্টা করুন।'),
          isError: true);
    } finally {
      passwordController.dispose();
      if (mounted) {
        setState(() => _isDeletingAccount = false);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    await _pickAndUploadImage(
      fieldName: 'image',
      successMessage: _t('settings_profile_photo_updated', 'প্রোফাইল ছবি আপডেট হয়েছে'),
      targetWidth: 1080,
      quality: 94,
      maxFileSizeBytes: 6 * 1024 * 1024,
      enableCropper: true,
    );
  }

  Future<void> _pickBannerImage() async {
    await _pickAndUploadImage(
      fieldName: 'store_banner',
      successMessage: _t('settings_banner_updated', 'ব্যানার আপডেট হয়েছে'),
      targetWidth: 1400,
      quality: 82,
      maxFileSizeBytes: 8 * 1024 * 1024,
      enableCropper: true,
    );
  }

  Future<void> _pickAndUploadImage({
    required String fieldName,
    required String successMessage,
    required int targetWidth,
    required int quality,
    required int maxFileSizeBytes,
    required bool enableCropper,
  }) async {
    if (_userProfile == null || _isUploadingMedia) {
      return;
    }

    final picker = ImagePicker();
    final source = await _selectImageSource(
      title: fieldName == 'image'
          ? _t('settings_profile_photo', 'প্রোফাইল ছবি')
          : _t('settings_banner_image', 'ব্যানার ছবি'),
    );

    if (source == null) {
      return;
    }

    final image = await picker.pickImage(
      source: source,
      maxWidth: fieldName == 'image' ? 2048 : 2400,
      maxHeight: fieldName == 'image' ? 2048 : 1800,
      imageQuality: fieldName == 'image' ? 96 : 94,
    );

    if (image == null) {
      return;
    }

    final bytes = await _prepareUploadBytes(
      image: image,
      enableCropper: enableCropper,
      fieldName: fieldName,
    );

    if (bytes == null) {
      return;
    }

    setState(() => _isUploadingMedia = true);

    try {
      if (bytes.length > maxFileSizeBytes) {
        _showSnackBar(
            _t('settings_image_too_large', 'ছবিটা অনেক বড়'),
            isError: true);
        return;
      }

      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        _showSnackBar(
            _t('settings_image_process_failed', 'ছবিটা প্রসেস করা গেল না'),
            isError: true);
        return;
      }

      final shouldResize = decoded.width > targetWidth;
      final resized =
          shouldResize ? img.copyResize(decoded, width: targetWidth) : decoded;
      final compressed = img.encodeJpg(resized, quality: quality);
      final payload = 'data:image/jpeg;base64,${base64Encode(compressed)}';

      final previousImageUrl = fieldName == 'image'
          ? _userProfile?.image
          : _userProfile?.storeBanner;
      final result = await SettingsService.updateProfile(
        _userProfile!.email,
        {fieldName: payload},
      );

      if ((result['success'] ?? false) == true &&
          result['data'] is Map<String, dynamic>) {
        final updatedData = Map<String, dynamic>.from(result['data']);
        final cacheStamp = DateTime.now().millisecondsSinceEpoch.toString();
        final rawValue = updatedData[fieldName]?.toString();
        if (rawValue != null && rawValue.trim().isNotEmpty) {
          updatedData[fieldName] = AppConfig.getAbsoluteUrl(rawValue);
          final separator =
              updatedData[fieldName].toString().contains('?') ? '&' : '?';
          updatedData[fieldName] =
              '${updatedData[fieldName]}${separator}v=$cacheStamp';
        }
        if (previousImageUrl != null && previousImageUrl.isNotEmpty) {
          await CachedNetworkImage.evictFromCache(previousImageUrl);
        }
        if (mounted) {
          setState(
              () => _mediaRefreshTick = DateTime.now().millisecondsSinceEpoch);
        }
        await _applyUpdatedProfile(
          updatedData,
          successMessage: successMessage,
        );
      } else {
        _showSnackBar(
            result['message'] ??
                _t('settings_image_upload_failed', 'ছবি আপলোড করা গেল না'),
            isError: true);
      }
    } catch (_) {
      _showSnackBar(
          _t('settings_image_upload_failed', 'ছবি আপলোড করা গেল না'),
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  Future<Uint8List?> _prepareUploadBytes({
    required XFile image,
    required bool enableCropper,
    required String fieldName,
  }) async {
    // Compress before upload (fallback to original bytes on failure)
    final compressed = await ImageCompressor.compressToBytes(
      image,
      targetSize: 80 * 1024,
    );
    if (compressed != null) {
      return compressed;
    }
    return image.readAsBytes();
  }

  Future<void> _removeProfileImage() async {
    if (_userProfile == null || _isUploadingMedia) {
      return;
    }

    final confirmed = await _confirmAction(
      title: _t('settings_remove_photo_title', 'প্রোফাইল ছবি সরাবেন?'),
      message: _t('settings_remove_photo_message',
          'নতুন ছবি না দেওয়া পর্যন্ত আপনার প্রোফাইলে ডিফল্ট ছবি থাকবে।'),
      actionLabel: _t('settings_remove', 'সরান'),
    );
    if (!confirmed) {
      return;
    }

    setState(() => _isUploadingMedia = true);

    try {
      final success =
          await SettingsService.deleteProfileImage(_userProfile!.email);
      if (success) {
        if (mounted) {
          setState(
              () => _mediaRefreshTick = DateTime.now().millisecondsSinceEpoch);
        }
        await _loadUserProfile();
        await _refreshUserCaches();
        _showSnackBar(_t('settings_photo_removed', 'প্রোফাইল ছবি সরানো হয়েছে'));
      } else {
        _showSnackBar(
            _t('settings_photo_remove_failed', 'প্রোফাইল ছবি সরানো গেল না'),
            isError: true);
      }
    } catch (_) {
      _showSnackBar(
          _t('settings_photo_remove_failed', 'প্রোফাইল ছবি সরানো গেল না'),
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  Future<void> _removeBannerImage() async {
    if (_userProfile == null || _isUploadingMedia) {
      return;
    }

    final confirmed = await _confirmAction(
      title: _t('settings_remove_banner_title', 'ব্যানার ছবি সরাবেন?'),
      message: _t('settings_remove_banner_message',
          'এতে প্রোফাইল হেডার থেকে আপনার ব্যানারটি সরে যাবে।'),
      actionLabel: _t('settings_remove', 'সরান'),
    );
    if (!confirmed) {
      return;
    }

    setState(() => _isUploadingMedia = true);

    try {
      final result = await SettingsService.updateProfile(
        _userProfile!.email,
        {'store_banner': ''},
      );

      if ((result['success'] ?? false) == true &&
          result['data'] is Map<String, dynamic>) {
        if (mounted) {
          setState(
              () => _mediaRefreshTick = DateTime.now().millisecondsSinceEpoch);
        }
        await _applyUpdatedProfile(
          Map<String, dynamic>.from(result['data']),
          successMessage: _t('settings_banner_removed', 'ব্যানার সরানো হয়েছে'),
        );
      } else {
        _showSnackBar(
            result['message'] ??
                _t('settings_banner_remove_failed', 'ব্যানার সরানো গেল না'),
            isError: true);
      }
    } catch (_) {
      _showSnackBar(
          _t('settings_banner_remove_failed', 'ব্যানার সরানো গেল না'),
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: AppFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _headingTextColor,
            ),
          ),
          content: Text(
            message,
            style: AppFonts.roboto(
                fontSize: 14, color: _bodyTextColor, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                _t('settings_cancel', 'ক্যান্সেল'),
                style: AppFonts.roboto(
                    fontWeight: FontWeight.w600, color: _mutedTextColor),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: _dangerColor),
              child: Text(
                actionLabel,
                style: AppFonts.roboto(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildTabSelector(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.topCenter,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      centerTitle: false,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _surfaceMutedColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: _headingTextColor,
            ),
          ),
        ),
      ),
      titleSpacing: 4,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _primarySoftColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: _primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _t('settings_title', 'সেটিংস'),
            style: AppFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _headingTextColor,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: _cardBorderColor,
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: _primarySoftColor,
      child: const Icon(Icons.person_rounded, color: _primaryColor, size: 28),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _surfaceMutedColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
                child: _buildTabChip(_SettingsTab.profile,
                    _t('settings_tab_profile', 'প্রোফাইল'),
                    Icons.badge_rounded)),
            const SizedBox(width: 6),
            Expanded(
                child: _buildTabChip(_SettingsTab.privacy,
                    _t('settings_tab_privacy', 'প্রাইভেসি'),
                    Icons.privacy_tip_rounded)),
            const SizedBox(width: 6),
            Expanded(
                child: _buildTabChip(_SettingsTab.security,
                    _t('settings_tab_security', 'সিকিউরিটি'),
                    Icons.lock_rounded)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(_SettingsTab tab, String label, IconData icon) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          // Native segmented control: the active segment is a white pill
          // with a soft lift; inactive segments sit flat on the muted track.
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: isActive ? _primaryColor : _mutedTextColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.roboto(
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? _primaryColor : _mutedTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const Center(child: AdsyLoadingIndicator(color: _primaryColor));
    }

    if (_userProfile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _cardBorderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_outlined,
                    size: 42, color: _primaryColor),
                const SizedBox(height: 14),
                Text(
                  _t('settings_unable_to_load', 'সেটিংস আনা গেল না'),
                  style: AppFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _headingTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _t('settings_unable_to_load_message',
                      'আবার একবার চেষ্টা করুন। সমস্যা থাকলে লগইন আর ইন্টারনেট কানেকশন দেখে নিন।'),
                  textAlign: TextAlign.center,
                  style: AppFonts.roboto(
                      fontSize: 13, color: _bodyTextColor, height: 1.5),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _loadUserProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _t('settings_retry', 'আবার চেষ্টা করুন'),
                    style: AppFonts.roboto(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    switch (_activeTab) {
      case _SettingsTab.profile:
        return _buildProfileTab();
      case _SettingsTab.privacy:
        return _buildPrivacyTab();
      case _SettingsTab.security:
        return _buildSecurityTab();
    }
  }

  Widget _buildProfileTab() {
    return _buildRefreshableTab(
      key: const ValueKey('profile-tab'),
      child: Form(
        key: _profileFormKey,
        child: Column(
          children: [
            _buildProfileHero(),
            if (_isKycLocked) ...[
              _buildInfoNotice(
                icon: Icons.verified_user_rounded,
                color: _warningColor,
                title: _t('settings_kyc_lock_title', 'KYC লক চালু আছে'),
                message: _t('settings_kyc_lock_message',
                    'KYC ভেরিফিকেশনের পর নাম আর ঠিকানা লক হয়ে যায়। বাকি তথ্য এডিট করা যাবে।'),
              ),
              const SizedBox(height: 10),
            ],
            _buildSectionCard(
              title: _t('settings_identity_contact', 'পরিচয় ও যোগাযোগ'),
              subtitle: _t('settings_identity_contact_sub',
                  'অ্যাকাউন্টের বেসিক তথ্য।'),
              icon: Icons.person_outline_rounded,
              child: Column(
                children: [
                  _buildResponsivePair(
                    left: _buildTextField(
                      controller: _firstNameController,
                      label: _t('settings_first_name', 'নামের প্রথম অংশ'),
                      hintText:
                          _t('settings_first_name_hint', 'নামের প্রথম অংশ লিখুন'),
                      icon: Icons.badge_outlined,
                      enabled: !_isKycLocked,
                      validator: (value) => _normalized(value).isEmpty
                          ? _t('settings_first_name_required',
                              'নামের প্রথম অংশ দিতে হবে')
                          : null,
                    ),
                    right: _buildTextField(
                      controller: _lastNameController,
                      label: _t('settings_last_name', 'নামের শেষ অংশ'),
                      hintText:
                          _t('settings_last_name_hint', 'নামের শেষ অংশ লিখুন'),
                      icon: Icons.person_outline_rounded,
                      enabled: !_isKycLocked,
                      validator: (value) => _normalized(value).isEmpty
                          ? _t('settings_last_name_required',
                              'নামের শেষ অংশ দিতে হবে')
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildResponsivePair(
                    left: _buildTextField(
                      controller: _emailController,
                      label: _t('settings_email', 'ইমেইল'),
                      hintText: _t('settings_email_hint',
                          'অ্যাকাউন্টের মূল ইমেইল'),
                      icon: Icons.alternate_email_rounded,
                      enabled: false,
                    ),
                    right: _buildTextField(
                      controller: _phoneController,
                      label: _t('settings_phone', 'ফোন নম্বর'),
                      hintText: '01XXXXXXXXX',
                      icon: Icons.phone_outlined,
                      enabled: !_isKycLocked,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildSectionCard(
              title: _t('settings_personal_details', 'ব্যক্তিগত তথ্য'),
              subtitle:
                  _t('settings_personal_details_sub', 'জন্ম তারিখ ও লিঙ্গ।'),
              icon: Icons.cake_outlined,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildDobField()),
                      const SizedBox(width: 10),
                      Expanded(flex: 2, child: _buildAgeDisplay()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildGenderField(),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildSectionCard(
              title: _t('settings_location_details', 'ঠিকানার তথ্য'),
              subtitle:
                  _t('settings_location_details_sub', 'ঠিকানা ও এলাকার তথ্য।'),
              icon: Icons.map_outlined,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _addressController,
                    label: _t('settings_address', 'ঠিকানা'),
                    hintText: _t('settings_address_hint',
                        'বাসা, রোড, এলাকা, ল্যান্ডমার্ক'),
                    icon: Icons.home_outlined,
                    enabled: !_isKycLocked,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  _buildResponsivePair(
                    left: _buildDropdownField(
                      label: _t('settings_division', 'বিভাগ'),
                      hintText: _t('settings_division_hint', 'বিভাগ সিলেক্ট করুন'),
                      icon: Icons.flag_outlined,
                      value: _selectedDivision,
                      items: _divisions.map((item) => item.nameEng).toList(),
                      isLoading: _isLoadingDivisions,
                      enabled: !_isKycLocked,
                      onChanged: (value) {
                        setState(() => _selectedDivision = value);
                        if (value != null) {
                          _loadCities(value);
                        }
                      },
                    ),
                    right: _buildDropdownField(
                      label: _t('settings_city', 'শহর'),
                      hintText: _t('settings_city_hint', 'শহর সিলেক্ট করুন'),
                      icon: Icons.location_city_outlined,
                      value: _selectedCity,
                      items: _cities.map((item) => item.nameEng).toList(),
                      isLoading: _isLoadingCities,
                      enabled: !_isKycLocked && _selectedDivision != null,
                      onChanged: (value) {
                        setState(() => _selectedCity = value);
                        if (value != null) {
                          _loadUpazilas(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildResponsivePair(
                    left: _buildDropdownField(
                      label: _t('settings_upazila', 'উপজেলা / এলাকা'),
                      hintText: _t('settings_upazila_hint', 'উপজেলা সিলেক্ট করুন'),
                      icon: Icons.place_outlined,
                      value: _selectedUpazila,
                      items: _upazilas.map((item) => item.nameEng).toList(),
                      isLoading: _isLoadingUpazilas,
                      enabled: !_isKycLocked && _selectedCity != null,
                      onChanged: (value) =>
                          setState(() => _selectedUpazila = value),
                    ),
                    right: _buildTextField(
                      controller: _zipController,
                      label: _t('settings_postal_code', 'পোস্টাল কোড'),
                      hintText:
                          _t('settings_postal_code_hint', 'জিপ / পোস্টাল কোড'),
                      icon: Icons.markunread_mailbox_outlined,
                      enabled: !_isKycLocked,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildSectionCard(
              title: _t('settings_professional_details', 'পেশাগত তথ্য'),
              subtitle: _t('settings_professional_details_sub',
                  'বিজনেস আর সোশ্যাল লিংক।'),
              icon: Icons.work_outline_rounded,
              child: Column(
                children: [
                  _buildResponsivePair(
                    left: _buildTextField(
                      controller: _professionController,
                      label: _t('settings_profession', 'পেশা'),
                      hintText: _t('settings_profession_hint',
                          'ডিজাইনার, দোকানদার, কনসালট্যান্ট...'),
                      icon: Icons.work_outline_rounded,
                    ),
                    right: _buildTextField(
                      controller: _companyController,
                      label: _t('settings_company', 'কোম্পানি / ব্র্যান্ড'),
                      hintText: _t('settings_company_hint',
                          'বিজনেস বা ব্র্যান্ডের নাম'),
                      icon: Icons.apartment_rounded,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _websiteController,
                    label: _t('settings_website', 'ওয়েবসাইট'),
                    hintText: 'https://yourwebsite.com',
                    icon: Icons.language_rounded,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 10),
                  _buildResponsivePair(
                    left: _buildTextField(
                      controller: _facebookController,
                      label: _t('settings_facebook', 'ফেসবুক'),
                      hintText: _t('settings_facebook_hint',
                          'ফেসবুক প্রোফাইল বা পেজের লিংক'),
                      icon: Icons.facebook_rounded,
                      keyboardType: TextInputType.url,
                    ),
                    right: _buildTextField(
                      controller: _instagramController,
                      label: _t('settings_instagram', 'ইনস্টাগ্রাম'),
                      hintText: _t('settings_instagram_hint',
                          'ইনস্টাগ্রাম প্রোফাইলের লিংক'),
                      icon: Icons.camera_alt_outlined,
                      keyboardType: TextInputType.url,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _whatsappController,
                    label: _t('settings_whatsapp', 'হোয়াটসঅ্যাপ'),
                    hintText: _t('settings_whatsapp_hint',
                        'হোয়াটসঅ্যাপ নম্বর বা wa.me লিংক'),
                    icon: Icons.chat_bubble_outline_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildResponsivePair(
                    left: _buildTextField(
                      controller: _tiktokController,
                      label: _t('settings_tiktok', 'টিকটক'),
                      hintText: _t('settings_tiktok_hint',
                          'টিকটক প্রোফাইলের লিংক'),
                      icon: Icons.music_note_rounded,
                      keyboardType: TextInputType.url,
                    ),
                    right: _buildTextField(
                      controller: _youtubeController,
                      label: _t('settings_youtube', 'ইউটিউব'),
                      hintText: _t('settings_youtube_hint',
                          'ইউটিউব চ্যানেলের লিংক'),
                      icon: Icons.play_circle_outline_rounded,
                      keyboardType: TextInputType.url,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _linkedinController,
                    label: _t('settings_linkedin', 'লিংকডইন'),
                    hintText: _t(
                        'settings_linkedin_hint', 'লিংকডইন প্রোফাইলের লিংক'),
                    icon: Icons.work_outline_rounded,
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildSectionCard(
              title: _t('settings_more_info', 'অতিরিক্ত তথ্য'),
              subtitle: _t('settings_more_info_sub',
                  'পড়াশোনা, ভাষা আর দক্ষতা — প্রোফাইলে দেখা যাবে।'),
              icon: Icons.school_outlined,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _educationController,
                    label: _t('settings_education', 'পড়াশোনা'),
                    hintText: _t('settings_education_hint',
                        'যেমন: BBA — Dhaka University'),
                    icon: Icons.school_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _languagesController,
                    label: _t('settings_languages', 'ভাষা'),
                    hintText: _t('settings_languages_hint',
                        'কমা দিয়ে লিখুন — যেমন: বাংলা, English'),
                    icon: Icons.translate_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _skillsController,
                    label: _t('settings_skills', 'দক্ষতা'),
                    hintText: _t('settings_skills_hint',
                        'কমা দিয়ে লিখুন — যেমন: Graphic Design, Marketing'),
                    icon: Icons.workspace_premium_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildSectionCard(
              title: _t('settings_about_you', 'আপনার সম্পর্কে'),
              subtitle: _t('settings_about_you_sub', 'সংক্ষিপ্ত পরিচিতি।'),
              icon: Icons.edit_note_rounded,
              child: _buildTextField(
                controller: _aboutController,
                label: _t('settings_bio', 'বায়ো / পরিচিতি'),
                hintText: _t('settings_bio_hint',
                    'আপনার কাজ, বিজনেস আর প্রোফাইলে মানুষ কী পাবে সেটা লিখুন।'),
                icon: Icons.subject_rounded,
                maxLines: 5,
              ),
            ),
            const SizedBox(height: 14),
            _buildPrimaryButton(
              label: _hasProfileChanges
                  ? _t('settings_save_profile', 'প্রোফাইল সেভ করুন')
                  : _t('settings_profile_up_to_date', 'প্রোফাইল আপডেটেড আছে'),
              icon: Icons.save_rounded,
              isBusy: _isSavingProfile,
              enabled: _hasProfileChanges && !_isSavingProfile,
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHero() {
    final profile = _userProfile!;
    final isPhotoTab = _activeMediaTab == _ProfileMediaTab.photo;

    return _buildSectionCard(
      title: _t('settings_profile_media', 'প্রোফাইল ছবি ও ব্যানার'),
      subtitle: _t('settings_profile_media_sub',
          'ছবি আর ব্যানার একজায়গায় ঠিক করুন।'),
      icon: Icons.photo_library_outlined,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _surfaceMutedColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMediaTabChip(
                    tab: _ProfileMediaTab.photo,
                    label: _t('settings_photo', 'ছবি'),
                    icon: Icons.person_rounded,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMediaTabChip(
                    tab: _ProfileMediaTab.banner,
                    label: _t('settings_banner', 'ব্যানার'),
                    icon: Icons.photo_size_select_large_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isPhotoTab
                ? _buildCompactMediaPanel(
                    key: const ValueKey('profile-photo-panel'),
                    title: _t('settings_profile_photo', 'প্রোফাইল ছবি'),
                    subtitle: _t('settings_profile_photo_sub',
                        'অ্যাপ আর প্রোফাইলে দেখা যাবে।'),
                    preview: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primarySoftColor,
                      ),
                      child: ClipOval(
                        child:
                            profile.image != null && profile.image!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: _mediaUrl(profile.image),
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) =>
                                        _buildAvatarFallback(),
                                  )
                                : _buildAvatarFallback(),
                      ),
                    ),
                    primaryLabel:
                        profile.image != null && profile.image!.isNotEmpty
                            ? _t('settings_change_photo', 'ছবি বদলান')
                            : _t('settings_upload_photo', 'ছবি আপলোড করুন'),
                    primaryAction: _pickProfileImage,
                    secondaryLabel:
                        profile.image != null && profile.image!.isNotEmpty
                            ? _t('settings_remove', 'সরান')
                            : null,
                    secondaryAction:
                        profile.image != null && profile.image!.isNotEmpty
                            ? _removeProfileImage
                            : null,
                  )
                : _buildCompactMediaPanel(
                    key: const ValueKey('profile-banner-panel'),
                    title: _t('settings_business_banner', 'বিজনেস ব্যানার'),
                    subtitle: _t('settings_business_banner_sub',
                        'আপনার পাবলিক প্রোফাইলের চওড়া কভার।'),
                    preview: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: _primarySoftColor,
                        image: profile.storeBanner != null &&
                                profile.storeBanner!.isNotEmpty
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                    _mediaUrl(profile.storeBanner)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profile.storeBanner != null &&
                              profile.storeBanner!.isNotEmpty
                          ? null
                          : const Center(
                              child: Icon(Icons.add_photo_alternate_outlined,
                                  size: 24, color: _primaryColor),
                            ),
                    ),
                    primaryLabel: profile.storeBanner != null &&
                            profile.storeBanner!.isNotEmpty
                        ? _t('settings_change_banner', 'ব্যানার বদলান')
                        : _t('settings_upload_banner', 'ব্যানার আপলোড করুন'),
                    primaryAction: _pickBannerImage,
                    secondaryLabel: profile.storeBanner != null &&
                            profile.storeBanner!.isNotEmpty
                        ? _t('settings_remove', 'সরান')
                        : null,
                    secondaryAction: profile.storeBanner != null &&
                            profile.storeBanner!.isNotEmpty
                        ? _removeBannerImage
                        : null,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTabChip({
    required _ProfileMediaTab tab,
    required String label,
    required IconData icon,
  }) {
    final isActive = _activeMediaTab == tab;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _activeMediaTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _surfaceColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: isActive ? _primaryColor : _mutedTextColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.roboto(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isActive ? _headingTextColor : _mutedTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMediaPanel({
    required Key key,
    required String title,
    required String subtitle,
    required Widget preview,
    required String primaryLabel,
    required VoidCallback primaryAction,
    String? secondaryLabel,
    VoidCallback? secondaryAction,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _softSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppFonts.roboto(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _headingTextColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppFonts.roboto(
                    fontSize: 12, color: _bodyTextColor, height: 1.4),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: _isUploadingMedia ? null : primaryAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primarySoftColor,
                      foregroundColor: _primaryDarkColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      primaryLabel,
                      style: AppFonts.roboto(
                          fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (secondaryLabel != null && secondaryAction != null)
                    TextButton(
                      onPressed: _isUploadingMedia ? null : secondaryAction,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                      ),
                      child: Text(
                        secondaryLabel,
                        style: AppFonts.roboto(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _dangerColor),
                      ),
                    ),
                ],
              ),
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 132, child: Center(child: preview)),
                const SizedBox(width: 14),
                Expanded(child: details),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: preview),
              const SizedBox(height: 10),
              details,
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrivacyTab() {
    final profile = _userProfile!;
    final emailPublic = profile.emailPublic ?? false;
    final phonePublic = profile.phonePublic ?? false;
    final professionPublic = profile.professionPublic ?? true;
    final companyPublic = profile.companyPublic ?? true;
    final websitePublic = profile.websitePublic ?? true;
    final facebookPublic = profile.facebookPublic ?? true;
    final instagramPublic = profile.instagramPublic ?? true;
    final whatsappPublic = profile.whatsappPublic ?? true;
    final aboutPublic = profile.aboutPublic ?? true;
    final phonePreview = _maskPhone(profile.phone ?? '', phonePublic);

    final whoCanMessage = profile.whoCanMessage ?? 'everyone';

    return _buildRefreshableTab(
      key: const ValueKey('privacy-tab'),
      child: Column(
        children: [
          _buildSectionCard(
            title: _t('settings_who_can_message', 'কে মেসেজ পাঠাতে পারবে'),
            subtitle: _t('settings_who_can_message_sub',
                'AdsyConnect-এ কারা আপনাকে নতুন মেসেজ পাঠাতে পারবে ঠিক করুন।'),
            icon: Icons.forum_outlined,
            child: Column(
              children: [
                _buildMessagePrivacyOption(
                  value: 'everyone',
                  groupValue: whoCanMessage,
                  icon: Icons.public_rounded,
                  title: _t('settings_msg_everyone', 'সবাই'),
                  description: _t('settings_msg_everyone_desc',
                      'যেকোনো ব্যবহারকারী আপনাকে মেসেজ পাঠাতে পারবে।'),
                ),
                _buildMessagePrivacyOption(
                  value: 'followers',
                  groupValue: whoCanMessage,
                  icon: Icons.group_outlined,
                  title: _t('settings_msg_followers', 'যারা ফলো করে'),
                  description: _t('settings_msg_followers_desc',
                      'শুধু আপনাকে ফলো করা ব্যবহারকারীরা মেসেজ পাঠাতে পারবে।'),
                ),
                _buildMessagePrivacyOption(
                  value: 'following',
                  groupValue: whoCanMessage,
                  icon: Icons.person_add_alt_1_outlined,
                  title: _t('settings_msg_following', 'যাদের ফলো করেন'),
                  description: _t('settings_msg_following_desc',
                      'শুধু আপনি যাদের ফলো করেন তারাই মেসেজ পাঠাতে পারবে।'),
                ),
                _buildMessagePrivacyOption(
                  value: 'mutual',
                  groupValue: whoCanMessage,
                  icon: Icons.handshake_outlined,
                  title: _t('settings_msg_mutual', 'শুধু মিউচুয়াল'),
                  description: _t('settings_msg_mutual_desc',
                      'দুজন দুজনকে ফলো করলে তবেই মেসেজ পাঠানো যাবে।'),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildSectionCard(
            title: _t('settings_contact_visibility', 'যেভাবে যোগাযোগের তথ্য দেখাবেন'),
            subtitle: _t('settings_contact_visibility_sub',
                'বিজনেস নেটওয়ার্ক প্রোফাইলে আপনার যোগাযোগের তথ্য কীভাবে দেখাবে ঠিক করুন।'),
            icon: Icons.visibility_outlined,
            child: Column(
              children: [
                _buildPrivacyTile(
                  icon: Icons.alternate_email_rounded,
                  title: _t('settings_show_email', 'ইমেইল দেখান'),
                  description: _t('settings_show_email_desc',
                      'বিজনেস নেটওয়ার্ক প্রোফাইলে আপনার পুরো ইমেইল সবাইকে দেখতে দিন।'),
                  previewLabel: _maskEmail(profile.email, emailPublic),
                  value: emailPublic,
                  onChanged: (value) {
                    setState(() {
                      _userProfile = _userProfile?.copyWith(emailPublic: value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildPrivacyTile(
                  icon: Icons.phone_outlined,
                  title: _t('settings_show_phone', 'ফোন নম্বর দেখান'),
                  description: _t('settings_show_phone_desc',
                      'প্রোফাইলে আসা মানুষ আর সম্ভাব্য কাস্টমারদের আপনার নম্বর দেখান।'),
                  previewLabel: phonePreview.isEmpty
                      ? _t('settings_no_phone', 'এখনও ফোন নম্বর দেওয়া হয়নি')
                      : phonePreview,
                  value: phonePublic,
                  onChanged: (value) {
                    setState(() {
                      _userProfile = _userProfile?.copyWith(phonePublic: value);
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildSectionCard(
            title: _t('settings_professional_fields', 'পেশাগত প্রোফাইল ফিল্ড'),
            subtitle: _t('settings_professional_fields_sub',
                'প্রতিটি বিজনেস তথ্যের দৃশ্যমানতা আলাদা করে ঠিক করুন।'),
            icon: Icons.work_outline_rounded,
            child: Column(
              children: [
                _buildPrivacyTile(
                  icon: Icons.badge_outlined,
                  title: _t('settings_show_profession', 'পেশা দেখান'),
                  description: _t('settings_show_profession_desc',
                      'নামের নিচে আপনার পেশা বা পদ দেখান।'),
                  previewLabel: _visibilityPreview(
                    profile.profession,
                    professionPublic,
                    emptyLabel:
                        _t('settings_no_profession', 'এখনও পেশা দেওয়া হয়নি'),
                  ),
                  value: professionPublic,
                  onChanged: (value) {
                    setState(() {
                      _userProfile =
                          _userProfile?.copyWith(professionPublic: value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildPrivacyTile(
                  icon: Icons.business_rounded,
                  title: _t('settings_show_company', 'কোম্পানি / ব্র্যান্ড দেখান'),
                  description: _t('settings_show_company_desc',
                      'প্রোফাইল সামারিতে আপনার কোম্পানি বা ব্র্যান্ড দেখান।'),
                  previewLabel: _visibilityPreview(
                    profile.company,
                    companyPublic,
                    emptyLabel:
                        _t('settings_no_company', 'এখনও কোম্পানি দেওয়া হয়নি'),
                  ),
                  value: companyPublic,
                  onChanged: (value) {
                    setState(() {
                      _userProfile =
                          _userProfile?.copyWith(companyPublic: value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildPrivacyTile(
                  icon: Icons.language_rounded,
                  title: _t('settings_show_website', 'ওয়েবসাইট দেখান'),
                  description: _t('settings_show_website_desc',
                      'প্রোফাইল থেকেই সরাসরি আপনার বিজনেস ওয়েবসাইট খুলতে দিন।'),
                  previewLabel: _visibilityPreview(
                    profile.website,
                    websitePublic,
                    emptyLabel:
                        _t('settings_no_website', 'এখনও ওয়েবসাইট দেওয়া হয়নি'),
                  ),
                  value: websitePublic,
                  onChanged: (value) {
                    setState(() {
                      _userProfile =
                          _userProfile?.copyWith(websitePublic: value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildPrivacyTile(
                  icon: Icons.facebook_rounded,
                  title: _t('settings_show_facebook', 'ফেসবুক লিংক দেখান'),
                  description: _t('settings_show_facebook_desc',
                      'আপনার ফেসবুক পেজ বা প্রোফাইলের লিংক সবাইকে দেখান।'),
                  previewLabel: _visibilityPreview(
                    profile.faceLink,
                    facebookPublic,
                    emptyLabel: _t(
                        'settings_no_facebook', 'এখনও ফেসবুক লিংক দেওয়া হয়নি'),
                  ),
                  value: facebookPublic,
                  onChanged: (value) {
                    setState(() {
                      _userProfile =
                          _userProfile?.copyWith(facebookPublic: value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildPrivacyTile(
                  icon: Icons.camera_alt_outlined,
                  title: _t('settings_show_instagram', 'ইনস্টাগ্রাম লিংক দেখান'),
                  description: _t('settings_show_instagram_desc',
                      'যোগাযোগ অংশে আপনার ইনস্টাগ্রাম প্রোফাইলের লিংক দেখান।'),
                  previewLabel: _visibilityPreview(
                    profile.instagramLink,
                    instagramPublic,
                    emptyLabel: _t('settings_no_instagram',
                        'এখনও ইনস্টাগ্রাম লিংক দেওয়া হয়নি'),
                  ),
                  value: instagramPublic,
                  onChanged: (value) {
                    setState(() {
                      _userProfile =
                          _userProfile?.copyWith(instagramPublic: value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildPrivacyTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: _t('settings_show_whatsapp', 'হোয়াটসঅ্যাপ লিংক দেখান'),
                  description: _t('settings_show_whatsapp_desc',
                      'বিজনেস নেটওয়ার্ক প্রোফাইল থেকে সরাসরি হোয়াটসঅ্যাপে যোগাযোগ করতে দিন।'),
                  previewLabel: _visibilityPreview(
                    profile.whatsappLink,
                    whatsappPublic,
                    emptyLabel: _t('settings_no_whatsapp',
                        'এখনও হোয়াটসঅ্যাপ দেওয়া হয়নি'),
                  ),
                  value: whatsappPublic,
                  onChanged: (value) {
                    setState(() {
                      _userProfile =
                          _userProfile?.copyWith(whatsappPublic: value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildPrivacyTile(
                  icon: Icons.subject_rounded,
                  title: _t('settings_show_bio', 'বায়ো / পরিচিতি দেখান'),
                  description: _t('settings_show_bio_desc',
                      'আপনার প্রোফাইল সামারি আর বিজনেস পরিচিতি দেখাবে কিনা ঠিক করুন।'),
                  previewLabel: _visibilityPreview(
                    profile.about,
                    aboutPublic,
                    emptyLabel: _t('settings_no_bio', 'এখনও বায়ো দেওয়া হয়নি'),
                  ),
                  value: aboutPublic,
                  onChanged: (value) {
                    setState(() {
                      _userProfile = _userProfile?.copyWith(aboutPublic: value);
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildPrimaryButton(
            label: _hasPrivacyChanges
                ? _t('settings_apply_privacy', 'প্রাইভেসি সেটিংস সেভ করুন')
                : _t('settings_privacy_up_to_date', 'প্রাইভেসি আপডেটেড আছে'),
            icon: Icons.shield_outlined,
            isBusy: _isSavingPrivacy,
            enabled: _hasPrivacyChanges && !_isSavingPrivacy,
            onPressed: _savePrivacy,
          ),
        ],
      ),
    );
  }

  // A single selectable "who can message me" choice — radio-style row.
  Widget _buildMessagePrivacyOption({
    required String value,
    required String groupValue,
    required IconData icon,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    final selected = value == groupValue;
    const accent = Color(0xFF3B82F6);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _userProfile = _userProfile?.copyWith(whoCanMessage: value);
          });
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.06) : _softSurfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? accent : Colors.grey.shade500),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? accent
                                : const Color(0xFF1F2937))),
                    const SizedBox(height: 2),
                    Text(description,
                        style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                            height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? accent : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyTile({
    required IconData icon,
    required String title,
    required String description,
    required String previewLabel,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _headingTextColor),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppFonts.roboto(
                      fontSize: 12.5, color: _bodyTextColor, height: 1.35),
                ),
                const SizedBox(height: 8),
                Text(
                  previewLabel,
                  style: AppFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _primaryDarkColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            activeThumbColor: _primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return _buildRefreshableTab(
      key: const ValueKey('security-tab'),
      child: Form(
        key: _securityFormKey,
        child: Column(
          children: [
            _buildSectionCard(
              title: _t('settings_change_password', 'পাসওয়ার্ড বদলান'),
              subtitle:
                  _t('settings_change_password_sub', 'অন্তত ৮ অক্ষর দিন।'),
              icon: Icons.password_rounded,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _oldPasswordController,
                    label: _t('settings_current_password', 'বর্তমান পাসওয়ার্ড'),
                    hintText: _t('settings_current_password_input',
                        'বর্তমান পাসওয়ার্ড দিন'),
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    isVisible: _showOldPassword,
                    onToggleVisibility: () =>
                        setState(() => _showOldPassword = !_showOldPassword),
                    validator: (value) => _normalized(value).isEmpty
                        ? _t('settings_current_password_required',
                            'বর্তমান পাসওয়ার্ড দিতে হবে')
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _buildResponsivePair(
                    left: _buildTextField(
                      controller: _newPasswordController,
                      label: _t('settings_new_password', 'নতুন পাসওয়ার্ড'),
                      hintText: _t('settings_new_password_hint',
                          'একটা শক্ত পাসওয়ার্ড দিন'),
                      icon: Icons.lock_reset_rounded,
                      isPassword: true,
                      isVisible: _showNewPassword,
                      onToggleVisibility: () =>
                          setState(() => _showNewPassword = !_showNewPassword),
                      validator: (value) {
                        if (_normalized(value).isEmpty) {
                          return _t('settings_new_password_required',
                              'নতুন পাসওয়ার্ড দিতে হবে');
                        }
                        if ((value ?? '').length < 8) {
                          return _t('settings_min_8_chars',
                              'অন্তত ৮ অক্ষর দিতে হবে');
                        }
                        return null;
                      },
                    ),
                    right: _buildTextField(
                      controller: _confirmPasswordController,
                      label:
                          _t('settings_confirm_password', 'পাসওয়ার্ড নিশ্চিত করুন'),
                      hintText: _t('settings_confirm_password_hint',
                          'নতুন পাসওয়ার্ডটা আবার দিন'),
                      icon: Icons.verified_user_outlined,
                      isPassword: true,
                      isVisible: _showConfirmPassword,
                      onToggleVisibility: () => setState(
                          () => _showConfirmPassword = !_showConfirmPassword),
                      validator: (value) {
                        if (_normalized(value).isEmpty) {
                          return _t('settings_confirm_password_required',
                              'পাসওয়ার্ডটা নিশ্চিত করুন');
                        }
                        if ((value ?? '') != _newPasswordController.text) {
                          return _t('settings_passwords_no_match',
                              'পাসওয়ার্ড মিলছে না');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPasswordStrengthCard(),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildPrimaryButton(
              label: _t('settings_change_password', 'পাসওয়ার্ড বদলান'),
              icon: Icons.lock_reset_rounded,
              isBusy: _isChangingPassword,
              enabled: !_isChangingPassword,
              onPressed: _changePassword,
            ),
            const SizedBox(height: 28),
            // Danger zone
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _dangerColor.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _dangerColor.withValues(alpha: 0.06),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: _dangerColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _t('settings_danger_zone', 'ডেঞ্জার জোন'),
                          style: AppFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _dangerColor),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('settings_delete_account', 'অ্যাকাউন্ট ডিলিট'),
                          style: AppFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _headingTextColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _t('settings_delete_account_desc',
                              'আপনার অ্যাকাউন্ট আর সব ডেটা একদম মুছে যাবে। এটা আর ফেরানো যাবে না।'),
                          style: AppFonts.roboto(
                              fontSize: 13, color: _bodyTextColor, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isDeletingAccount
                                ? null
                                : _showDeleteAccountDialog,
                            icon: _isDeletingAccount
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: AdsyLoadingIndicator(strokeWidth: 2))
                                : const Icon(Icons.delete_forever_rounded,
                                    size: 18),
                            label: Text(
                              _isDeletingAccount
                                  ? _t('settings_deleting', 'ডিলিট হচ্ছে...')
                                  : _t('settings_delete_my_account',
                                      'আমার অ্যাকাউন্ট ডিলিট করুন'),
                              style: AppFonts.roboto(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _dangerColor,
                              side: BorderSide(color: _dangerColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildRefreshableTab({
    required Key key,
    required Widget child,
  }) {
    return AdsyRefreshIndicator(
      key: key,
      color: _primaryColor,
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Screen-side padding kept tight (2px) per design.
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthCard() {
    final labels = [
      _t('settings_pw_too_weak', 'খুব দুর্বল'),
      _t('settings_pw_fair', 'মোটামুটি'),
      _t('settings_pw_strong', 'শক্ত'),
      _t('settings_pw_excellent', 'দারুণ'),
    ];
    final colors = [
      const Color(0xFFE5E7EB),
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981)
    ];
    final currentScore = _passwordStrength;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('settings_password_strength', 'পাসওয়ার্ডের শক্তি'),
            style: AppFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _headingTextColor),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (index) {
              final isActive = currentScore > index;
              final color =
                  currentScore == 0 ? colors[0] : colors[currentScore];
              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: isActive ? color : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            labels[currentScore],
            style: AppFonts.roboto(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: currentScore == 0 ? _mutedTextColor : colors[currentScore],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _primarySoftColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: _primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _headingTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppFonts.roboto(
                          fontSize: 12, color: _bodyTextColor, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoNotice({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _headingTextColor),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppFonts.roboto(
                      fontSize: 12.5, color: _bodyTextColor, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsivePair({required Widget left, required Widget right}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        if (!isWide) {
          return Column(
            children: [
              left,
              const SizedBox(height: 10),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 10),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  String? get _matchedGender {
    for (final o in _genderOptions) {
      if (o.toLowerCase() == _gender.trim().toLowerCase()) return o;
    }
    return null;
  }

  Widget _buildGenderField() {
    return _buildDropdownField(
      label: _t('settings_gender', 'লিঙ্গ'),
      hintText: _t('settings_gender_hint', 'লিঙ্গ সিলেক্ট করুন'),
      icon: Icons.wc_outlined,
      value: _matchedGender,
      items: _genderOptions,
      isLoading: false,
      enabled: true,
      onChanged: (value) => setState(() => _gender = value ?? ''),
    );
  }

  Widget _buildDobField() {
    final display = _formatDob(_selectedDob) ?? '';
    return InkWell(
      onTap: _pickDob,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: _t('settings_dob', 'জন্ম তারিখ'),
          labelStyle: AppFonts.roboto(
              fontSize: 13, fontWeight: FontWeight.w600, color: _bodyTextColor),
          prefixIcon: const Icon(Icons.cake_outlined,
              color: _primaryColor, size: 20),
          suffixIcon: const Icon(Icons.calendar_today_rounded,
              color: _mutedTextColor, size: 18),
          filled: true,
          fillColor: _softSurfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _cardBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _cardBorderColor),
          ),
        ),
        child: Text(
          display.isEmpty
              ? _t('settings_dob_hint', 'জন্ম তারিখ সিলেক্ট করুন')
              : display,
          style: AppFonts.roboto(
            fontSize: 14,
            color: display.isEmpty ? _mutedTextColor : _headingTextColor,
          ),
        ),
      ),
    );
  }

  // Auto-derived age (no input box) — updates when the date of birth changes.
  Widget _buildAgeDisplay() {
    final age = _selectedDob != null ? _calculateAge(_selectedDob!) : null;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: _t('settings_age', 'বয়স'),
        labelStyle: AppFonts.roboto(
            fontSize: 13, fontWeight: FontWeight.w600, color: _bodyTextColor),
        prefixIcon: const Icon(Icons.event_available_outlined,
            color: _primaryColor, size: 20),
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
      child: Text(
        age != null ? '$age ${_t('settings_years', 'বছর')}' : '—',
        style: AppFonts.roboto(
          fontSize: 14,
          fontWeight: age != null ? FontWeight.w700 : FontWeight.w500,
          color: age != null ? _headingTextColor : _mutedTextColor,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: isPassword && !isVisible ? 1 : maxLines,
      obscureText: isPassword && !isVisible,
      keyboardType: keyboardType,
      validator: validator,
      style: AppFonts.roboto(fontSize: 14, color: _headingTextColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: AppFonts.roboto(fontSize: 13, color: _mutedTextColor),
        labelStyle: AppFonts.roboto(
            fontSize: 13, fontWeight: FontWeight.w600, color: _bodyTextColor),
        prefixIcon: Icon(icon,
            color: enabled ? _primaryColor : _mutedTextColor, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  isVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _mutedTextColor,
                ),
              )
            : null,
        filled: true,
        fillColor: enabled ? _softSurfaceColor : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _cardBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _cardBorderColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _dangerColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _dangerColor, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hintText,
    required IconData icon,
    required String? value,
    required List<String> items,
    required bool isLoading,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) {
    final uniqueItems = <String>[];
    final seenItems = <String>{};

    for (final item in items) {
      final normalizedItem = item.trim();
      if (normalizedItem.isEmpty || !seenItems.add(normalizedItem)) {
        continue;
      }
      uniqueItems.add(normalizedItem);
    }

    final normalizedValue = value?.trim();
    final effectiveValue =
        normalizedValue != null && seenItems.contains(normalizedValue)
            ? normalizedValue
            : null;

    return DropdownButtonFormField<String>(
      initialValue: effectiveValue,
      items: uniqueItems
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: AppFonts.roboto(fontSize: 14, color: _headingTextColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: enabled && !isLoading ? onChanged : null,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: AdsyLoadingIndicator(strokeWidth: 2, color: _primaryColor),
            )
          : Icon(Icons.keyboard_arrow_down_rounded,
              color: enabled ? _mutedTextColor : const Color(0xFF94A3B8)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: AppFonts.roboto(fontSize: 13, color: _mutedTextColor),
        labelStyle: AppFonts.roboto(
            fontSize: 13, fontWeight: FontWeight.w600, color: _bodyTextColor),
        prefixIcon: Icon(icon,
            color: enabled ? _primaryColor : _mutedTextColor, size: 20),
        filled: true,
        fillColor: enabled ? _softSurfaceColor : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _cardBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _cardBorderColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      borderRadius: BorderRadius.circular(14),
      dropdownColor: Colors.white,
      menuMaxHeight: 340,
      style: AppFonts.roboto(fontSize: 14, color: _headingTextColor),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required bool isBusy,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: enabled ? _primaryColor : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: enabled && !isBusy ? onPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor:
                    enabled ? Colors.white : const Color(0xFF94A3B8),
                disabledForegroundColor: const Color(0xFF94A3B8),
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: isBusy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: AdsyLoadingIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Colors.white, size: 16),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
  }
}
