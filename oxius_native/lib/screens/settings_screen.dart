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
import '../services/geo_location_service.dart';
import '../services/settings_service.dart';
import '../services/user_state_service.dart';
import '../utils/app_fonts.dart';


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
  static const _primaryColor = Color(0xFF6366F1);
  static const _primaryDarkColor = Color(0xFF4F46E5);
  static const _primaryAccentColor = Color(0xFF8B5CF6);
  static const _primarySoftColor = Color(0xFFEEF2FF);
  static const _headingTextColor = Color(0xFF1E293B);
  static const _bodyTextColor = Color(0xFF475569);
  static const _mutedTextColor = Color(0xFF64748B);
  static const _dangerColor = Color(0xFFDC2626);
  static const _successColor = Color(0xFF059669);
  static const _warningColor = Color(0xFFF59E0B);

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

  bool _isInitialLoading = true;
  bool _isLoadingDivisions = false;
  bool _isLoadingCities = false;
  bool _isLoadingUpazilas = false;
  bool _isSavingProfile = false;
  bool _isSavingPrivacy = false;
  bool _isChangingPassword = false;
  bool _isUploadingMedia = false;
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
        _showSnackBar('Failed to load settings', isError: true);
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
    _addressController.text = profile.address ?? '';
    _zipController.text = profile.zip ?? '';
    _aboutController.text = profile.about ?? '';

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
        _showSnackBar('Failed to load divisions', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDivisions = false);
      }
    }
  }

  Future<void> _loadCities(String divisionName, {bool resetSelection = true}) async {
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
        _showSnackBar('Failed to load cities', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCities = false);
      }
    }
  }

  Future<void> _loadUpazilas(String cityName, {bool resetSelection = true}) async {
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
        _showSnackBar('Failed to load upazilas', isError: true);
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

    return _normalized(_firstNameController.text) != _normalized(original.firstName) ||
        _normalized(_lastNameController.text) != _normalized(original.lastName) ||
        _normalized(_phoneController.text) != _normalized(original.phone) ||
        _normalized(_professionController.text) != _normalized(original.profession) ||
        _normalized(_companyController.text) != _normalized(original.company) ||
        _normalized(_websiteController.text) != _normalized(original.website) ||
        _normalized(_facebookController.text) != _normalized(original.faceLink) ||
        _normalized(_instagramController.text) != _normalized(original.instagramLink) ||
        _normalized(_whatsappController.text) != _normalized(original.whatsappLink) ||
        _normalized(_addressController.text) != _normalized(original.address) ||
        _normalized(_zipController.text) != _normalized(original.zip) ||
        _normalized(_aboutController.text) != _normalized(original.about) ||
        _normalized(_selectedDivision) != _normalized(original.state) ||
        _normalized(_selectedCity) != _normalized(original.city) ||
        _normalized(_selectedUpazila) != _normalized(original.upazila);
  }

  bool get _hasPrivacyChanges {
    final original = _originalProfile;
    final current = _userProfile;
    if (original == null || current == null) {
      return false;
    }

    return (current.emailPublic ?? false) != (original.emailPublic ?? false) ||
        (current.phonePublic ?? false) != (original.phonePublic ?? false) ||
        (current.professionPublic ?? true) != (original.professionPublic ?? true) ||
        (current.companyPublic ?? true) != (original.companyPublic ?? true) ||
        (current.websitePublic ?? true) != (original.websitePublic ?? true) ||
        (current.facebookPublic ?? true) != (original.facebookPublic ?? true) ||
        (current.instagramPublic ?? true) != (original.instagramPublic ?? true) ||
        (current.whatsappPublic ?? true) != (original.whatsappPublic ?? true) ||
        (current.aboutPublic ?? true) != (original.aboutPublic ?? true);
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
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(password) || RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
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

    return isPublic ? normalized : 'Hidden on Business Network profile';
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
                    label: 'Choose from gallery',
                    onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                  ),
                  _buildImageSourceAction(
                    icon: Icons.camera_alt_outlined,
                    label: 'Take photo',
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppFonts.roboto(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? _dangerColor : _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
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
        'about': _aboutController.text.trim(),
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

      final result = await SettingsService.updateProfile(_userProfile!.email, payload);
      if ((result['success'] ?? false) == true && result['data'] is Map<String, dynamic>) {
        await _applyUpdatedProfile(
          Map<String, dynamic>.from(result['data']),
          successMessage: 'Profile updated successfully',
        );
      } else {
        _showSnackBar(result['message'] ?? 'Failed to update profile', isError: true);
      }
    } catch (_) {
      _showSnackBar('Failed to update profile', isError: true);
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
      };

      final result = await SettingsService.updateProfile(_userProfile!.email, payload);
      if ((result['success'] ?? false) == true && result['data'] is Map<String, dynamic>) {
        await _applyUpdatedProfile(
          Map<String, dynamic>.from(result['data']),
          successMessage: 'Business Network privacy updated',
        );
      } else {
        _showSnackBar(result['message'] ?? 'Failed to update privacy', isError: true);
      }
    } catch (_) {
      _showSnackBar('Failed to update privacy', isError: true);
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
        _showSnackBar(result['message'] ?? 'Password changed successfully');
      } else {
        _showSnackBar(result['message'] ?? 'Failed to change password', isError: true);
      }
    } catch (_) {
      _showSnackBar('Failed to change password', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    await _pickAndUploadImage(
      fieldName: 'image',
      successMessage: 'Profile photo updated',
      targetWidth: 1080,
      quality: 94,
      maxFileSizeBytes: 6 * 1024 * 1024,
      enableCropper: true,
    );
  }

  Future<void> _pickBannerImage() async {
    await _pickAndUploadImage(
      fieldName: 'store_banner',
      successMessage: 'Store banner updated',
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
      title: fieldName == 'image' ? 'Profile photo' : 'Banner image',
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
        _showSnackBar('Selected image is too large', isError: true);
        return;
      }

      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        _showSnackBar('Failed to process selected image', isError: true);
        return;
      }

        final shouldResize = decoded.width > targetWidth;
        final resized = shouldResize
          ? img.copyResize(decoded, width: targetWidth)
          : decoded;
      final compressed = img.encodeJpg(resized, quality: quality);
      final payload = 'data:image/jpeg;base64,${base64Encode(compressed)}';

      final previousImageUrl = fieldName == 'image' ? _userProfile?.image : _userProfile?.storeBanner;
      final result = await SettingsService.updateProfile(
        _userProfile!.email,
        {fieldName: payload},
      );

      if ((result['success'] ?? false) == true && result['data'] is Map<String, dynamic>) {
        final updatedData = Map<String, dynamic>.from(result['data']);
        final cacheStamp = DateTime.now().millisecondsSinceEpoch.toString();
        final rawValue = updatedData[fieldName]?.toString();
        if (rawValue != null && rawValue.trim().isNotEmpty) {
          updatedData[fieldName] = AppConfig.getAbsoluteUrl(rawValue);
          final separator = updatedData[fieldName].toString().contains('?') ? '&' : '?';
          updatedData[fieldName] = '${updatedData[fieldName]}${separator}v=$cacheStamp';
        }
        if (previousImageUrl != null && previousImageUrl.isNotEmpty) {
          await CachedNetworkImage.evictFromCache(previousImageUrl);
        }
        if (mounted) {
          setState(() => _mediaRefreshTick = DateTime.now().millisecondsSinceEpoch);
        }
        await _applyUpdatedProfile(
          updatedData,
          successMessage: successMessage,
        );
      } else {
        _showSnackBar(result['message'] ?? 'Failed to upload image', isError: true);
      }
    } catch (_) {
      _showSnackBar('Failed to upload image', isError: true);
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
    return image.readAsBytes();
  }

  Future<void> _removeProfileImage() async {
    if (_userProfile == null || _isUploadingMedia) {
      return;
    }

    final confirmed = await _confirmAction(
      title: 'Remove profile photo?',
      message: 'Your profile will fall back to the default avatar until you upload a new photo.',
      actionLabel: 'Remove',
    );
    if (!confirmed) {
      return;
    }

    setState(() => _isUploadingMedia = true);

    try {
      final success = await SettingsService.deleteProfileImage(_userProfile!.email);
      if (success) {
        if (mounted) {
          setState(() => _mediaRefreshTick = DateTime.now().millisecondsSinceEpoch);
        }
        await _loadUserProfile();
        await _refreshUserCaches();
        _showSnackBar('Profile photo removed');
      } else {
        _showSnackBar('Failed to remove profile photo', isError: true);
      }
    } catch (_) {
      _showSnackBar('Failed to remove profile photo', isError: true);
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
      title: 'Remove banner image?',
      message: 'This will clear your business banner from the profile header.',
      actionLabel: 'Remove',
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

      if ((result['success'] ?? false) == true && result['data'] is Map<String, dynamic>) {
        if (mounted) {
          setState(() => _mediaRefreshTick = DateTime.now().millisecondsSinceEpoch);
        }
        await _applyUpdatedProfile(
          Map<String, dynamic>.from(result['data']),
          successMessage: 'Banner removed',
        );
      } else {
        _showSnackBar(result['message'] ?? 'Failed to remove banner', isError: true);
      }
    } catch (_) {
      _showSnackBar('Failed to remove banner', isError: true);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            style: AppFonts.roboto(fontSize: 14, color: _bodyTextColor, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: AppFonts.roboto(fontWeight: FontWeight.w600, color: _mutedTextColor),
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
              gradient: const LinearGradient(
                colors: [_primaryColor, _primaryAccentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Settings',
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
            Expanded(child: _buildTabChip(_SettingsTab.profile, 'Profile', Icons.badge_rounded)),
            const SizedBox(width: 6),
            Expanded(child: _buildTabChip(_SettingsTab.privacy, 'Privacy', Icons.privacy_tip_rounded)),
            const SizedBox(width: 6),
            Expanded(child: _buildTabChip(_SettingsTab.security, 'Security', Icons.lock_rounded)),
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
          gradient: isActive
              ? const LinearGradient(
                  colors: [_primaryColor, _primaryAccentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : _mutedTextColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.roboto(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : _mutedTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator(color: _primaryColor));
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
                const Icon(Icons.settings_outlined, size: 42, color: _primaryColor),
                const SizedBox(height: 14),
                Text(
                  'Unable to load settings',
                  style: AppFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _headingTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try loading your account again. If the problem continues, check authentication and network status.',
                  textAlign: TextAlign.center,
                  style: AppFonts.roboto(fontSize: 13, color: _bodyTextColor, height: 1.5),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _loadUserProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Retry',
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
                title: 'KYC lock active',
                message: 'After KYC verification, name and address details are locked. Other profile details remain editable.',
              ),
              const SizedBox(height: 10),
            ],
            _buildSectionCard(
              title: 'Identity & contact',
              subtitle: 'Basic account details.',
              icon: Icons.person_outline_rounded,
              child: Column(
                children: [
                  _buildResponsivePair(
                    left: _buildTextField(
                      controller: _firstNameController,
                      label: 'First name',
                      hintText: 'Enter your first name',
                      icon: Icons.badge_outlined,
                      enabled: !_isKycLocked,
                      validator: (value) => _normalized(value).isEmpty ? 'First name is required' : null,
                    ),
                    right: _buildTextField(
                      controller: _lastNameController,
                      label: 'Last name',
                      hintText: 'Enter your last name',
                      icon: Icons.person_outline_rounded,
                      enabled: !_isKycLocked,
                      validator: (value) => _normalized(value).isEmpty ? 'Last name is required' : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildResponsivePair(
                    left: _buildTextField(
                      controller: _emailController,
                      label: 'Email address',
                      hintText: 'Primary account email',
                      icon: Icons.alternate_email_rounded,
                      enabled: false,
                    ),
                    right: _buildTextField(
                      controller: _phoneController,
                      label: 'Phone number',
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
              title: 'Location details',
              subtitle: 'Address and area info.',
              icon: Icons.map_outlined,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    hintText: 'House, road, area, landmark',
                    icon: Icons.home_outlined,
                    enabled: !_isKycLocked,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  _buildResponsivePair(
                    left: _buildDropdownField(
                      label: 'Division',
                      hintText: 'Select division',
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
                      label: 'City',
                      hintText: 'Select city',
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
                      label: 'Upazila / area',
                      hintText: 'Select upazila',
                      icon: Icons.place_outlined,
                      value: _selectedUpazila,
                      items: _upazilas.map((item) => item.nameEng).toList(),
                      isLoading: _isLoadingUpazilas,
                      enabled: !_isKycLocked && _selectedCity != null,
                      onChanged: (value) => setState(() => _selectedUpazila = value),
                    ),
                    right: _buildTextField(
                      controller: _zipController,
                      label: 'Postal code',
                      hintText: 'ZIP / postal code',
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
              title: 'Professional details',
              subtitle: 'Business and social links.',
              icon: Icons.work_outline_rounded,
              child: Column(
                children: [
                  _buildResponsivePair(
                    left: _buildTextField(
                      controller: _professionController,
                      label: 'Profession',
                      hintText: 'Designer, retailer, consultant...',
                      icon: Icons.work_outline_rounded,
                    ),
                    right: _buildTextField(
                      controller: _companyController,
                      label: 'Company / brand',
                      hintText: 'Business or brand name',
                      icon: Icons.apartment_rounded,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _websiteController,
                    label: 'Website',
                    hintText: 'https://yourwebsite.com',
                    icon: Icons.language_rounded,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 10),
                  _buildResponsivePair(
                    left: _buildTextField(
                      controller: _facebookController,
                      label: 'Facebook',
                      hintText: 'Facebook profile or page link',
                      icon: Icons.facebook_rounded,
                      keyboardType: TextInputType.url,
                    ),
                    right: _buildTextField(
                      controller: _instagramController,
                      label: 'Instagram',
                      hintText: 'Instagram profile link',
                      icon: Icons.camera_alt_outlined,
                      keyboardType: TextInputType.url,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _whatsappController,
                    label: 'WhatsApp',
                    hintText: 'WhatsApp number or wa.me link',
                    icon: Icons.chat_bubble_outline_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildSectionCard(
              title: 'About you',
              subtitle: 'Short profile summary.',
              icon: Icons.edit_note_rounded,
              child: _buildTextField(
                controller: _aboutController,
                label: 'Bio / about',
                hintText: 'Describe your work, business focus, and what people can expect from your profile.',
                icon: Icons.subject_rounded,
                maxLines: 5,
              ),
            ),
            const SizedBox(height: 14),
            _buildPrimaryButton(
              label: _hasProfileChanges ? 'Save profile changes' : 'Profile is up to date',
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
      title: 'Profile media',
      subtitle: 'Manage photo and banner in one place.',
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
                    label: 'Photo',
                    icon: Icons.person_rounded,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMediaTabChip(
                    tab: _ProfileMediaTab.banner,
                    label: 'Banner',
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
                    title: 'Profile photo',
                    subtitle: 'Shown in the app and profile.',
                    preview: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primarySoftColor,
                      ),
                      child: ClipOval(
                        child: profile.image != null && profile.image!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _mediaUrl(profile.image),
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => _buildAvatarFallback(),
                              )
                            : _buildAvatarFallback(),
                      ),
                    ),
                    primaryLabel: profile.image != null && profile.image!.isNotEmpty ? 'Change photo' : 'Upload photo',
                    primaryAction: _pickProfileImage,
                    secondaryLabel: profile.image != null && profile.image!.isNotEmpty ? 'Remove' : null,
                    secondaryAction: profile.image != null && profile.image!.isNotEmpty ? _removeProfileImage : null,
                  )
                : _buildCompactMediaPanel(
                    key: const ValueKey('profile-banner-panel'),
                    title: 'Business banner',
                    subtitle: 'Wide cover for your public profile.',
                    preview: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: _primarySoftColor,
                        image: profile.storeBanner != null && profile.storeBanner!.isNotEmpty
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(_mediaUrl(profile.storeBanner)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profile.storeBanner != null && profile.storeBanner!.isNotEmpty
                          ? null
                          : const Center(
                              child: Icon(Icons.add_photo_alternate_outlined, size: 24, color: _primaryColor),
                            ),
                    ),
                    primaryLabel: profile.storeBanner != null && profile.storeBanner!.isNotEmpty ? 'Change banner' : 'Upload banner',
                    primaryAction: _pickBannerImage,
                    secondaryLabel: profile.storeBanner != null && profile.storeBanner!.isNotEmpty ? 'Remove' : null,
                    secondaryAction: profile.storeBanner != null && profile.storeBanner!.isNotEmpty ? _removeBannerImage : null,
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
            Icon(icon, size: 16, color: isActive ? _primaryColor : _mutedTextColor),
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
                style: AppFonts.roboto(fontSize: 12, color: _bodyTextColor, height: 1.4),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      primaryLabel,
                      style: AppFonts.roboto(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (secondaryLabel != null && secondaryAction != null)
                    TextButton(
                      onPressed: _isUploadingMedia ? null : secondaryAction,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                      child: Text(
                        secondaryLabel,
                        style: AppFonts.roboto(fontSize: 12.5, fontWeight: FontWeight.w700, color: _dangerColor),
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

    return _buildRefreshableTab(
      key: const ValueKey('privacy-tab'),
      child: Column(
        children: [
          _buildSectionCard(
            title: 'Contact visibility',
            subtitle: 'Control how core contact details appear on your Business Network profile.',
            icon: Icons.visibility_outlined,
            child: Column(
              children: [
                _buildPrivacyTile(
                  icon: Icons.alternate_email_rounded,
                  title: 'Show email address',
                  description: 'Allow people to see your full email on your Business Network profile.',
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
                  title: 'Show phone number',
                  description: 'Display your contact number to network visitors and potential leads.',
                  previewLabel: phonePreview.isEmpty ? 'No phone added yet' : phonePreview,
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
            title: 'Professional profile fields',
            subtitle: 'Set visibility for each business detail separately.',
            icon: Icons.work_outline_rounded,
            child: Column(
              children: [
                _buildPrivacyTile(
                  icon: Icons.badge_outlined,
                  title: 'Show profession',
                  description: 'Display your profession or role under your name.',
                  previewLabel: _visibilityPreview(
                    profile.profession,
                    professionPublic,
                    emptyLabel: 'No profession added yet',
                  ),
                  value: professionPublic,
                  onChanged: (value) {
                    setState(() {
                      _userProfile = _userProfile?.copyWith(professionPublic: value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildPrivacyTile(
                  icon: Icons.business_rounded,
                  title: 'Show company / brand',
                  description: 'Keep your company or brand visible on the profile summary.',
                  previewLabel: _visibilityPreview(
                    profile.company,
                    companyPublic,
                    emptyLabel: 'No company added yet',
                  ),
                  value: companyPublic,
                  onChanged: (value) {
                    setState(() {
                      _userProfile = _userProfile?.copyWith(companyPublic: value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildPrivacyTile(
                  icon: Icons.language_rounded,
                  title: 'Show website',
                  description: 'Let visitors open your business website directly from the profile.',
                  previewLabel: _visibilityPreview(
                    profile.website,
                    websitePublic,
                    emptyLabel: 'No website added yet',
                  ),
                  value: websitePublic,
                  onChanged: (value) {
                    setState(() {
                      _userProfile = _userProfile?.copyWith(websitePublic: value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildPrivacyTile(
                  icon: Icons.facebook_rounded,
                  title: 'Show Facebook link',
                  description: 'Make your Facebook page or profile link public.',
                  previewLabel: _visibilityPreview(
                    profile.faceLink,
                    facebookPublic,
                    emptyLabel: 'No Facebook link added yet',
                  ),
                  value: facebookPublic,
                  onChanged: (value) {
                    setState(() {
                      _userProfile = _userProfile?.copyWith(facebookPublic: value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildPrivacyTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Show Instagram link',
                  description: 'Display your Instagram profile link in the contact section.',
                  previewLabel: _visibilityPreview(
                    profile.instagramLink,
                    instagramPublic,
                    emptyLabel: 'No Instagram link added yet',
                  ),
                  value: instagramPublic,
                  onChanged: (value) {
                    setState(() {
                      _userProfile = _userProfile?.copyWith(instagramPublic: value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildPrivacyTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Show WhatsApp link',
                  description: 'Allow direct WhatsApp contact from your Business Network profile.',
                  previewLabel: _visibilityPreview(
                    profile.whatsappLink,
                    whatsappPublic,
                    emptyLabel: 'No WhatsApp contact added yet',
                  ),
                  value: whatsappPublic,
                  onChanged: (value) {
                    setState(() {
                      _userProfile = _userProfile?.copyWith(whatsappPublic: value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildPrivacyTile(
                  icon: Icons.subject_rounded,
                  title: 'Show bio / about',
                  description: 'Control whether your profile summary and business intro are visible.',
                  previewLabel: _visibilityPreview(
                    profile.about,
                    aboutPublic,
                    emptyLabel: 'No bio added yet',
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
            label: _hasPrivacyChanges ? 'Apply privacy settings' : 'Privacy is up to date',
            icon: Icons.shield_outlined,
            isBusy: _isSavingPrivacy,
            enabled: _hasPrivacyChanges && !_isSavingPrivacy,
            onPressed: _savePrivacy,
          ),
        ],
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
                  style: AppFonts.roboto(fontSize: 15, fontWeight: FontWeight.w700, color: _headingTextColor),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppFonts.roboto(fontSize: 12.5, color: _bodyTextColor, height: 1.35),
                ),
                const SizedBox(height: 8),
                Text(
                  previewLabel,
                  style: AppFonts.roboto(fontSize: 12, fontWeight: FontWeight.w700, color: _primaryDarkColor),
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
              title: 'Change password',
              subtitle: 'Use at least 8 characters.',
              icon: Icons.password_rounded,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _oldPasswordController,
                    label: 'Current password',
                    hintText: 'Enter current password',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    isVisible: _showOldPassword,
                    onToggleVisibility: () => setState(() => _showOldPassword = !_showOldPassword),
                    validator: (value) => _normalized(value).isEmpty ? 'Current password is required' : null,
                  ),
                  const SizedBox(height: 10),
                  _buildResponsivePair(
                    left: _buildTextField(
                      controller: _newPasswordController,
                      label: 'New password',
                      hintText: 'Create a strong password',
                      icon: Icons.lock_reset_rounded,
                      isPassword: true,
                      isVisible: _showNewPassword,
                      onToggleVisibility: () => setState(() => _showNewPassword = !_showNewPassword),
                      validator: (value) {
                        if (_normalized(value).isEmpty) {
                          return 'New password is required';
                        }
                        if ((value ?? '').length < 8) {
                          return 'Minimum 8 characters required';
                        }
                        return null;
                      },
                    ),
                    right: _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm password',
                      hintText: 'Re-enter the new password',
                      icon: Icons.verified_user_outlined,
                      isPassword: true,
                      isVisible: _showConfirmPassword,
                      onToggleVisibility: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                      validator: (value) {
                        if (_normalized(value).isEmpty) {
                          return 'Please confirm the password';
                        }
                        if ((value ?? '') != _newPasswordController.text) {
                          return 'Passwords do not match';
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
              label: 'Change password',
              icon: Icons.lock_reset_rounded,
              isBusy: _isChangingPassword,
              enabled: !_isChangingPassword,
              onPressed: _changePassword,
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
    return RefreshIndicator(
      key: key,
      color: _primaryColor,
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
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
    final labels = ['Too weak', 'Fair', 'Strong', 'Excellent'];
    final colors = [const Color(0xFFE5E7EB), const Color(0xFFEF4444), const Color(0xFFF59E0B), const Color(0xFF10B981)];
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
            'Password strength',
            style: AppFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: _headingTextColor),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (index) {
              final isActive = currentScore > index;
              final color = currentScore == 0 ? colors[0] : colors[currentScore];
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
                      style: AppFonts.roboto(fontSize: 12, color: _bodyTextColor, height: 1.35),
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
                  style: AppFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: _headingTextColor),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppFonts.roboto(fontSize: 12.5, color: _bodyTextColor, height: 1.35),
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
        labelStyle: AppFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600, color: _bodyTextColor),
        prefixIcon: Icon(icon, color: enabled ? _primaryColor : _mutedTextColor, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    final effectiveValue = normalizedValue != null && seenItems.contains(normalizedValue)
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
              child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor),
            )
          : Icon(Icons.keyboard_arrow_down_rounded, color: enabled ? _mutedTextColor : const Color(0xFF94A3B8)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: AppFonts.roboto(fontSize: 13, color: _mutedTextColor),
        labelStyle: AppFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600, color: _bodyTextColor),
        prefixIcon: Icon(icon, color: enabled ? _primaryColor : _mutedTextColor, size: 20),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              gradient: enabled
                  ? const LinearGradient(
                      colors: [_primaryColor, _primaryAccentColor],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: enabled ? null : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: enabled && !isBusy ? onPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: enabled ? Colors.white : const Color(0xFF94A3B8),
                disabledForegroundColor: const Color(0xFF94A3B8),
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isBusy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
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