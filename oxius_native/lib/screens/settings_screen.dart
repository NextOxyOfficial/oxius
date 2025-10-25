import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/translation_service.dart';
import '../services/user_state_service.dart';
import '../models/user_profile.dart';
import '../widgets/footer.dart';
import '../widgets/mobile_drawer.dart';
import 'debug_screen.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TranslationService _translationService = TranslationService();
  final _formKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  String _activeTab = 'profile';
  UserProfile? _userProfile;
  UserProfile? _originalProfile;
  bool _isLoading = false;
  bool _passwordLoading = false;
  bool _showDeleteImageModal = false;
  bool _showDeleteBannerModal = false;
  bool _isProcessing = false;
  bool _formDirty = false;
  bool _showStickyButton = true;
  double _lastScrollPosition = 0;
  
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _professionController = TextEditingController();
  final _companyController = TextEditingController();
  final _websiteController = TextEditingController();
  final _aboutController = TextEditingController();
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _whatsappController.dispose();
    _professionController.dispose();
    _companyController.dispose();
    _websiteController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  String t(String key) {
    return _translationService.t(key, fallback: key);
  }

  void _handleScroll() {
    final currentScroll = _scrollController.position.pixels;
    
    if (currentScroll < 100) {
      setState(() => _showStickyButton = true);
    } else if (currentScroll < _lastScrollPosition) {
      setState(() => _showStickyButton = true);
    } else if (currentScroll > _lastScrollPosition) {
      setState(() => _showStickyButton = false);
    }
    
    _lastScrollPosition = currentScroll;
  }

  void _checkFormChanges() {
    if (_originalProfile == null) return;
    
    // Compare controller values with original profile data
    final hasChanges = 
        _firstNameController.text != (_originalProfile!.firstName ?? '') ||
        _lastNameController.text != (_originalProfile!.lastName ?? '') ||
        _phoneController.text != (_originalProfile!.phone ?? '') ||
        _addressController.text != (_originalProfile!.address ?? '') ||
        _cityController.text != (_originalProfile!.city ?? '') ||
        _stateController.text != (_originalProfile!.state ?? '') ||
        _zipController.text != (_originalProfile!.zip ?? '') ||
        _facebookController.text != (_originalProfile!.faceLink ?? '') ||
        _instagramController.text != (_originalProfile!.instagramLink ?? '') ||
        _whatsappController.text != (_originalProfile!.whatsappLink ?? '') ||
        _professionController.text != (_originalProfile!.profession ?? '') ||
        _companyController.text != (_originalProfile!.company ?? '') ||
        _websiteController.text != (_originalProfile!.website ?? '') ||
        _aboutController.text != (_originalProfile!.about ?? '') ||
        (_userProfile?.image != _originalProfile!.image) ||
        (_userProfile?.storeBanner != _originalProfile!.storeBanner);
    
    setState(() {
      _formDirty = hasChanges;
    });
  }

  Future<void> _loadUserProfile() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final profile = await SettingsService.getUserProfile(user.email);
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _originalProfile = UserProfile.fromJson(json.decode(json.encode(profile.toJson())));
          _populateControllers();
        });
      }
    } catch (e) {
      _showSnackBar('Error loading profile', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateControllers() {
    if (_userProfile == null) return;
    
    _emailController.text = _userProfile!.email ?? '';
    _firstNameController.text = _userProfile!.firstName ?? '';
    _lastNameController.text = _userProfile!.lastName ?? '';
    _phoneController.text = _userProfile!.phone ?? '';
    _addressController.text = _userProfile!.address ?? '';
    _cityController.text = _userProfile!.city ?? '';
    _stateController.text = _userProfile!.state ?? '';
    _zipController.text = _userProfile!.zip ?? '';
    _facebookController.text = _userProfile!.faceLink ?? '';
    _instagramController.text = _userProfile!.instagramLink ?? '';
    _whatsappController.text = _userProfile!.whatsappLink ?? '';
    _professionController.text = _userProfile!.profession ?? '';
    _companyController.text = _userProfile!.company ?? '';
    _websiteController.text = _userProfile!.website ?? '';
    _aboutController.text = _userProfile!.about ?? '';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  int _getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    if (password.length < 8) return 1;
    if (password.length >= 8 && password.length < 12) return 2;
    if (password.length >= 12 && 
        RegExp(r'[A-Z]').hasMatch(password) && 
        RegExp(r'[0-9]').hasMatch(password)) {
      return 3;
    }
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isSmallMobile = screenWidth < 640;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const MobileDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.grey[800]),
      ),
      body: Column(
        children: [
          
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey[50]!,
                      Colors.grey[100]!,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Settings Content
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: screenWidth < 896 ? double.infinity : 896,
                      ),
                      margin: EdgeInsets.symmetric(
                        horizontal: isSmallMobile ? 4 : 8,
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallMobile ? 16 : 24,
                      ),
                      child: Column(
                        children: [
                          // User Info Summary
                          if (_userProfile != null) _buildUserInfoSummary(isSmallMobile),
                          
                          SizedBox(height: isSmallMobile ? 16 : 24),
                          
                          // Settings Navigation & Content
                          _buildSettingsContent(isSmallMobile, isMobile),
                          
                          // Spacer for sticky button
                          if (_activeTab == 'profile') SizedBox(height: isSmallMobile ? 96 : 64),
                        ],
                      ),
                    ),
                    
                    // Footer
                    AppFooter(
                      showMobileNav: isMobile,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _activeTab == 'profile' && _formDirty
          ? AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: _showStickyButton ? Offset.zero : const Offset(0, 2),
              child: _buildStickyButton(isSmallMobile),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Build methods
  
  Widget _buildUserInfoSummary(bool isSmallMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Profile Image
        Container(
          width: isSmallMobile ? 64 : 80,
          height: isSmallMobile ? 64 : 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: ClipOval(
            child: _userProfile!.image != null
                ? Image.network(
                    _userProfile!.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderAvatar(),
                  )
                : _buildPlaceholderAvatar(),
          ),
        ),
        const SizedBox(width: 12),
        // User Info
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${_userProfile!.firstName ?? ''} ${_userProfile!.lastName ?? ''}'.trim(),
                  style: TextStyle(
                    fontSize: isSmallMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_userProfile!.kyc == true) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.verified,
                    color: Colors.green[600],
                    size: 20,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _userProfile!.email,
              style: TextStyle(
                fontSize: isSmallMobile ? 13 : 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholderAvatar() {
    // Safely get first character of names
    String getInitial(String? name) {
      if (name == null || name.isEmpty) return '';
      return name.substring(0, 1);
    }
    
    final firstInitial = getInitial(_userProfile!.firstName);
    final lastInitial = getInitial(_userProfile!.lastName);
    final initials = '$firstInitial$lastInitial'.toUpperCase();
    
    return Container(
      color: Colors.green[50],
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              )
            : Icon(
                Icons.person,
                size: 32,
                color: Colors.green[300],
              ),
      ),
    );
  }

  Widget _buildSettingsContent(bool isSmallMobile, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Navigation
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[100]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('profile', 'Profile', Icons.person, isSmallMobile),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('password', 'Password', Icons.lock, isSmallMobile),
                ),
                if (kDebugMode) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabButton('debug', 'Debug', Icons.bug_report, isSmallMobile),
                  ),
                ],
              ],
            ),
          ),
          
          // Tab Content
          Container(
            padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
            child: _activeTab == 'profile'
                ? _buildProfileTab(isSmallMobile, isMobile)
                : _activeTab == 'password'
                    ? _buildPasswordTab(isSmallMobile)
                    : _buildDebugTab(isSmallMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label, IconData icon, bool isSmallMobile) {
    final isActive = _activeTab == tab;
    return InkWell(
      onTap: () => setState(() => _activeTab = tab),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isSmallMobile ? 10 : 12,
          horizontal: isSmallMobile ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isSmallMobile ? 16 : 18,
              color: isActive ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallMobile ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(bool isSmallMobile, bool isMobile) {
    if (_userProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: 16,
        ),
        child: Form(
          key: _profileFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF10B981),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Profile Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Profile Image Upload
              _buildImageUploadSection(),
              const SizedBox(height: 16),

              // Store Banner Upload
              _buildBannerUploadSection(),
              const SizedBox(height: 16),

              // Personal Information
              _buildPersonalInfoSection(),
              const SizedBox(height: 16),

              // Address Information
              _buildAddressSection(),
              const SizedBox(height: 16),

              // Social Media
              _buildSocialMediaSection(),
              const SizedBox(height: 16),

              // About Me
              _buildAboutSection(),
              const SizedBox(height: 100), // Space for sticky button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Image',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Current image or placeholder
              if (_userProfile?.image != null && _userProfile!.image!.isNotEmpty)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          _userProfile!.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFF3F4F6),
                              child: const Icon(
                                Icons.person_outline,
                                size: 40,
                                color: Color(0xFF9CA3AF),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showDeleteImageDialog(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 40,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              const SizedBox(width: 16),

              // Upload button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Profile Picture',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'JPG, PNG or GIF. Max size 5MB',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _pickProfileImage,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.upload_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Choose Image',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Store/For Sale Banner',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),

          // Current banner or placeholder
          if (_userProfile?.storeBanner != null && _userProfile!.storeBanner!.isNotEmpty)
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _userProfile!.storeBanner!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showDeleteBannerDialog(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Color(0xFF9CA3AF),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No banner uploaded',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),

          // Upload button and description
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickBannerImage,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Upload Banner Image',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Recommended: 1600×400px • Max 10MB • JPG, PNG',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    final bool isKycVerified = _userProfile?.kyc ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            
            if (isMobile) {
              return Column(
                children: [
                  _buildTextField(
                    label: 'First Name',
                    controller: _firstNameController,
                    enabled: !isKycVerified,
                    onChanged: (_) => _checkFormChanges(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Last Name',
                    controller: _lastNameController,
                    enabled: !isKycVerified,
                    onChanged: (_) => _checkFormChanges(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Email',
                    controller: _emailController,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Phone',
                    controller: _phoneController,
                    enabled: !isKycVerified,
                    onChanged: (_) => _checkFormChanges(),
                  ),
                ],
              );
            }
            
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'First Name',
                        controller: _firstNameController,
                        enabled: !isKycVerified,
                        onChanged: (_) => _checkFormChanges(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: 'Last Name',
                        controller: _lastNameController,
                        enabled: !isKycVerified,
                        onChanged: (_) => _checkFormChanges(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Email',
                        controller: _emailController,
                        enabled: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: 'Phone',
                        controller: _phoneController,
                        enabled: !isKycVerified,
                        onChanged: (_) => _checkFormChanges(),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    final bool isKycVerified = _userProfile?.kyc ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Address Information',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Address',
          controller: _addressController,
          enabled: !isKycVerified,
          onChanged: (_) => _checkFormChanges(),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            
            if (isMobile) {
              return Column(
                children: [
                  _buildTextField(
                    label: 'City',
                    controller: _cityController,
                    enabled: !isKycVerified,
                    onChanged: (_) => _checkFormChanges(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'State',
                    controller: _stateController,
                    enabled: !isKycVerified,
                    onChanged: (_) => _checkFormChanges(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Zip',
                    controller: _zipController,
                    enabled: !isKycVerified,
                    onChanged: (_) => _checkFormChanges(),
                  ),
                ],
              );
            }
            
            return Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'City',
                    controller: _cityController,
                    enabled: !isKycVerified,
                    onChanged: (_) => _checkFormChanges(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'State',
                    controller: _stateController,
                    enabled: !isKycVerified,
                    onChanged: (_) => _checkFormChanges(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Zip',
                    controller: _zipController,
                    enabled: !isKycVerified,
                    onChanged: (_) => _checkFormChanges(),
                  ),
                ),
              ],
            );
          },
        ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Social Media & Professional',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            
            if (isMobile) {
              return Column(
                children: [
                  _buildTextField(
                    label: 'Facebook URL',
                    controller: _facebookController,
                    prefixIcon: Icons.facebook,
                    prefixIconColor: const Color(0xFF1877F2),
                    onChanged: (_) => _checkFormChanges(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Instagram URL',
                    controller: _instagramController,
                    prefixIcon: Icons.camera_alt,
                    prefixIconColor: const Color(0xFFE4405F),
                    onChanged: (_) => _checkFormChanges(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'WhatsApp #',
                    controller: _whatsappController,
                    prefixIcon: Icons.phone,
                    prefixIconColor: const Color(0xFF25D366),
                    onChanged: (_) => _checkFormChanges(),
                  ),
                ],
              );
            }
            
            return Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Facebook URL',
                    controller: _facebookController,
                    prefixIcon: Icons.facebook,
                    prefixIconColor: const Color(0xFF1877F2),
                    onChanged: (_) => _checkFormChanges(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Instagram URL',
                    controller: _instagramController,
                    prefixIcon: Icons.camera_alt,
                    prefixIconColor: const Color(0xFFE4405F),
                    onChanged: (_) => _checkFormChanges(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'WhatsApp #',
                    controller: _whatsappController,
                    prefixIcon: Icons.phone,
                    prefixIconColor: const Color(0xFF25D366),
                    onChanged: (_) => _checkFormChanges(),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            
            if (isMobile) {
              return Column(
                children: [
                  _buildTextField(
                    label: 'Profession',
                    controller: _professionController,
                    onChanged: (_) => _checkFormChanges(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Company Name',
                    controller: _companyController,
                    onChanged: (_) => _checkFormChanges(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Website',
                    controller: _websiteController,
                    onChanged: (_) => _checkFormChanges(),
                  ),
                ],
              );
            }
            
            return Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Profession',
                    controller: _professionController,
                    onChanged: (_) => _checkFormChanges(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Company Name',
                    controller: _companyController,
                    onChanged: (_) => _checkFormChanges(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Website',
                    controller: _websiteController,
                    onChanged: (_) => _checkFormChanges(),
                  ),
                ),
              ],
            );
          },
        ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Me',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _aboutController,
            maxLines: 5,
            minLines: 5,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF111827),
            ),
            decoration: InputDecoration(
              hintText: 'Tell us about yourself, your profession, and services...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF9CA3AF),
              ),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            onChanged: (_) => _checkFormChanges(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    IconData? prefixIcon,
    Color? prefixIconColor,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, size: 15, color: prefixIconColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPasswordTab(bool isSmallMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock,
                color: Colors.green[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'পাসওয়ার্ড পরিবর্তন',
              style: TextStyle(
                fontSize: isSmallMobile ? 18 : 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Choose a strong password that\'s at least 8 characters long with letters, numbers, and symbols.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Old Password
        Text(
          'পুরাতন পাসওয়ার্ড',
          style: TextStyle(
            fontSize: isSmallMobile ? 13 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _oldPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: '********',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF10B981)),
            ),
            suffixIcon: Icon(Icons.key, color: Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 16),
        // New Password
        Text(
          'নতুন পাসওয়ার্ড',
          style: TextStyle(
            fontSize: isSmallMobile ? 13 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          onChanged: (value) => setState(() {}),
          decoration: InputDecoration(
            hintText: '********',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF10B981)),
            ),
            suffixIcon: Icon(Icons.shield, color: Colors.grey[600]),
          ),
        ),
        if (_newPasswordController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildPasswordStrength(),
        ],
        const SizedBox(height: 24),
        // Submit Button
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _passwordLoading ? null : _handlePasswordChange,
            icon: _passwordLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check),
            label: const Text('Save Password'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrength() {
    final strength = _getPasswordStrength(_newPasswordController.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password strength',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: strength >= 1 ? _getStrengthColor(strength) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: strength >= 2 ? _getStrengthColor(strength) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: strength >= 3 ? _getStrengthColor(strength) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.amber;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handlePasswordChange() async {
    if (_oldPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      _showSnackBar('Both password fields are required', isError: true);
      return;
    }

    setState(() => _passwordLoading = true);

    try {
      final result = await SettingsService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (result['success']) {
        _showSnackBar(result['message']);
        _oldPasswordController.clear();
        _newPasswordController.clear();
      } else {
        _showSnackBar(result['message'], isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to change password', isError: true);
    } finally {
      setState(() => _passwordLoading = false);
    }
  }

  Widget _buildStickyButton(bool isSmallMobile) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallMobile ? 16 : 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.edit, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Profile has unsaved changes',
                style: TextStyle(
                  fontSize: isSmallMobile ? 13 : 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: (_isLoading || !_formDirty) ? null : _handleProfileSubmit,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check, size: 18),
            label: Text(isSmallMobile ? 'Save' : 'Save Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallMobile ? 16 : 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Image and banner upload methods
  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    try {
      final File imageFile = File(image.path);
      final bytes = await imageFile.readAsBytes();
      
      // Decode the image
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        _showSnackBar('Failed to process image', isError: true);
        return;
      }

      // Resize to max 1024x1024 while maintaining aspect ratio
      img.Image resized = img.copyResize(
        originalImage,
        width: originalImage.width > originalImage.height ? 1024 : null,
        height: originalImage.height >= originalImage.width ? 1024 : null,
      );

      // Encode as JPEG with 85% quality
      final compressed = img.encodeJpg(resized, quality: 85);
      
      // Convert to base64
      final base64Image = 'data:image/jpeg;base64,${base64Encode(compressed)}';
      
      setState(() {
        _userProfile = _userProfile?.copyWith(image: base64Image);
        _checkFormChanges();
      });
      
      _showSnackBar('Profile image uploaded successfully');
    } catch (e) {
      _showSnackBar('Failed to upload image', isError: true);
    }
  }

  Future<void> _pickBannerImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    try {
      final File imageFile = File(image.path);
      final bytes = await imageFile.readAsBytes();
      
      // Decode the image
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        _showSnackBar('Failed to process banner image', isError: true);
        return;
      }

      // Resize to max 1920x600 while maintaining aspect ratio
      img.Image resized;
      if (originalImage.width > 1920) {
        resized = img.copyResize(originalImage, width: 1920);
      } else if (originalImage.height > 600) {
        resized = img.copyResize(originalImage, height: 600);
      } else {
        resized = originalImage;
      }

      // Encode as JPEG with 90% quality
      final compressed = img.encodeJpg(resized, quality: 90);
      
      // Convert to base64
      final base64Image = 'data:image/jpeg;base64,${base64Encode(compressed)}';
      
      setState(() {
        _userProfile = _userProfile?.copyWith(storeBanner: base64Image);
        _checkFormChanges();
      });
      
      _showSnackBar('Banner image uploaded successfully');
    } catch (e) {
      _showSnackBar('Failed to upload banner', isError: true);
    }
  }

  void _showDeleteImageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Confirm Deletion'),
          ],
        ),
        content: const Text('Are you sure you want to delete profile image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProfileImage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteBannerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Confirm Deletion'),
          ],
        ),
        content: const Text('Are you sure you want to delete the banner image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBannerImage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProfileImage() async {
    setState(() => _isProcessing = true);
    
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      final success = await SettingsService.deleteProfileImage(user.email);
      
      if (success) {
        setState(() {
          _userProfile = _userProfile?.copyWith(image: '');
          _checkFormChanges();
        });
        _showSnackBar('Image removed successfully');
      } else {
        _showSnackBar('Failed to remove image', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error removing image', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteBannerImage() async {
    setState(() => _isProcessing = true);
    
    try {
      setState(() {
        _userProfile = _userProfile?.copyWith(storeBanner: '');
        _checkFormChanges();
      });
      _showSnackBar('Banner removed successfully');
    } catch (e) {
      _showSnackBar('Error removing banner', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleProfileSubmit() async {
    if (_userProfile == null) return;

    setState(() => _isLoading = true);

    try {
      // Collect form data
      final Map<String, dynamic> profileData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zip': _zipController.text.trim(),
        'face_link': _facebookController.text.trim(),
        'instagram_link': _instagramController.text.trim(),
        'whatsapp_link': _whatsappController.text.trim(),
        'profession': _professionController.text.trim(),
        'company': _companyController.text.trim(),
        'website': _websiteController.text.trim(),
        'about': _aboutController.text.trim(),
      };

      // Handle images
      if (_userProfile!.image != null && _userProfile!.image!.startsWith('data:image')) {
        profileData['image'] = _userProfile!.image;
      }
      
      if (_userProfile!.storeBanner != null && _userProfile!.storeBanner!.startsWith('data:image')) {
        profileData['store_banner'] = _userProfile!.storeBanner;
      }

      final result = await SettingsService.updateProfile(
        _emailController.text.trim(),
        profileData,
      );

      if (result['success']) {
        _showSnackBar('Profile updated successfully');
        
        // Reload profile to get updated data from server
        await _loadUserProfile();
        
        setState(() {
          _formDirty = false;
        });
      } else {
        _showSnackBar(result['message'] ?? 'Failed to update profile', isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to update profile', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
