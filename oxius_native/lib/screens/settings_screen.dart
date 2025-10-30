import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/translation_service.dart';
import '../services/user_state_service.dart';
import '../models/user_profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header (no AppBar)
            _buildModernHeader(),
            
            // Tab Bar
            _buildCompactTabBar(),
            
            // Content
            Expanded(
              child: _activeTab == 'profile'
                  ? _buildProfileContent()
                  : _buildPasswordContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: const Color(0xFF374151),
          ),
          const SizedBox(width: 12),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTabBar() {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactTab('profile', 'Profile', Icons.person_rounded),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildCompactTab('password', 'Password', Icons.lock_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTab(String tab, String label, IconData icon) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey.shade600,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image Section
          _buildCompactImageSection(),
          const SizedBox(height: 8),
          
          // Personal Info
          _buildCompactSection(
            'Personal Information',
            Icons.person_outline,
            [
              _buildCompactField('First Name', _firstNameController, Icons.person_rounded),
              _buildCompactField('Last Name', _lastNameController, Icons.person_rounded),
              _buildCompactField('Phone', _phoneController, Icons.phone_rounded),
              _buildCompactField('Profession', _professionController, Icons.work_outline_rounded),
              _buildCompactField('Company', _companyController, Icons.business_rounded),
              _buildCompactField('Website', _websiteController, Icons.link_rounded),
            ],
          ),
          const SizedBox(height: 8),
          
          // Address Info
          _buildCompactSection(
            'Address',
            Icons.location_on_outlined,
            [
              _buildCompactField('Address', _addressController, Icons.home_rounded),
              _buildCompactField('City', _cityController, Icons.location_city_rounded),
              _buildCompactField('State', _stateController, Icons.map_rounded),
              _buildCompactField('ZIP', _zipController, Icons.pin_drop_rounded),
            ],
          ),
          const SizedBox(height: 8),
          
          // Social Media
          _buildCompactSection(
            'Social Media',
            Icons.share_rounded,
            [
              _buildCompactField('Facebook', _facebookController, Icons.facebook),
              _buildCompactField('Instagram', _instagramController, Icons.camera_alt_rounded),
              _buildCompactField('WhatsApp', _whatsappController, Icons.chat_rounded),
            ],
          ),
          const SizedBox(height: 8),
          
          // About
          _buildCompactSection(
            'About Me',
            Icons.description_outlined,
            [
              _buildCompactField('About', _aboutController, Icons.text_fields, maxLines: 3),
            ],
          ),
          const SizedBox(height: 12),
          
          // Save Button
          _buildSaveButton(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPasswordContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          _buildCompactSection(
            'Change Password',
            Icons.lock_outline,
            [
              _buildCompactField('Current Password', _oldPasswordController, Icons.lock_rounded, isPassword: true),
              _buildCompactField('New Password', _newPasswordController, Icons.lock_rounded, isPassword: true),
            ],
          ),
          const SizedBox(height: 12),
          _buildChangePasswordButton(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCompactImageSection() {
    return Column(
      children: [
        // Profile Image Card
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Profile Image with gradient border
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: _userProfile?.image != null
                        ? CachedNetworkImage(
                            key: ValueKey(_userProfile!.image!),
                            imageUrl: _userProfile!.image!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(Icons.person, size: 28, color: Colors.grey),
                          )
                        : const Icon(Icons.person, size: 28, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_userProfile?.firstName ?? ''} ${_userProfile?.lastName ?? ''}'.trim(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userProfile?.email ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: _pickProfileImage,
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  color: const Color(0xFF10B981),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // Banner Upload Card
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.image_rounded, size: 14, color: Colors.grey.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Store Banner',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickBannerImage,
                child: Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _userProfile?.storeBanner != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                key: ValueKey(_userProfile!.storeBanner!),
                                imageUrl: _userProfile!.storeBanner!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorWidget: (context, url, error) => _buildBannerPlaceholder(),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildBannerPlaceholder(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBannerPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey.shade400),
        const SizedBox(height: 4),
        Text(
          'Upload Banner',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF10B981)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCompactField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF10B981)),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Save Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton(
        onPressed: _passwordLoading ? null : _changePassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: _passwordLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Change Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_userProfile == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final profileData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
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

      final result = await SettingsService.updateProfile(_userProfile!.email, profileData);

      if (result['success'] == true) {
        _showSnackBar('Profile updated successfully');
        await _loadUserProfile();
      } else {
        _showSnackBar(result['message'] ?? 'Failed to update profile', isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to update profile', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _changePassword() async {
    if (_oldPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      _showSnackBar('Please fill all fields', isError: true);
      return;
    }

    if (_newPasswordController.text.length < 8) {
      _showSnackBar('Password must be at least 8 characters', isError: true);
      return;
    }

    setState(() => _passwordLoading = true);

    try {
      final result = await SettingsService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (result['success'] == true) {
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _showSnackBar('Password changed successfully');
      } else {
        _showSnackBar(result['message'] ?? 'Failed to change password', isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to change password', isError: true);
    } finally {
      setState(() => _passwordLoading = false);
    }
  }

  // Old methods below - can be removed later
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
              ],
            ),
          ),
          
          // Tab Content
          Container(
            padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
            child: _activeTab == 'profile'
                ? _buildProfileTab(isSmallMobile, isMobile)
                : _buildPasswordTab(isSmallMobile),
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
    if (_userProfile == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    setState(() => _isProcessing = true);

    try {
      // Use XFile.readAsBytes() for web compatibility
      final bytes = await image.readAsBytes();
      
      // Check file size (max 5MB)
      if (bytes.length > 5 * 1024 * 1024) {
        _showSnackBar('Image too large. Max size is 5MB', isError: true);
        setState(() => _isProcessing = false);
        return;
      }
      
      // Decode the image
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        _showSnackBar('Failed to process image', isError: true);
        setState(() => _isProcessing = false);
        return;
      }

      // Resize to 300x300 for profile image
      img.Image resized = img.copyResize(originalImage, width: 300, height: 300);

      // Encode as JPEG with 85% quality
      final compressed = img.encodeJpg(resized, quality: 85);
      
      print('Profile image size: ${compressed.length} bytes');
      
      // Convert to base64
      final base64Image = base64Encode(compressed);
      final dataUri = 'data:image/jpeg;base64,$base64Image';
      
      print('Uploading profile image to server...');
      
      // Upload to server
      final result = await SettingsService.updateProfile(
        _userProfile!.email,
        {'image': dataUri},
      );

      print('Upload result: ${result['success']}');

      if (result['success'] == true) {
        // Clear image cache for the new profile image
        if (_userProfile?.image != null) {
          await CachedNetworkImage.evictFromCache(_userProfile!.image!);
        }
        
        setState(() {
          _userProfile = UserProfile.fromJson(result['data']);
          _originalProfile = UserProfile.fromJson(json.decode(json.encode(result['data'])));
        });
        
        // Force rebuild after a short delay to ensure cache is cleared
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {});
        }
        
        _showSnackBar('Profile image uploaded successfully');
      } else {
        final errorMsg = result['message'] ?? 'Failed to upload image';
        print('Upload failed: $errorMsg');
        _showSnackBar(errorMsg, isError: true);
      }
    } catch (e, stackTrace) {
      print('Profile image upload error: $e');
      print('Stack trace: $stackTrace');
      _showSnackBar('Failed to upload image: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickBannerImage() async {
    if (_userProfile == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    setState(() => _isProcessing = true);

    try {
      // Use XFile.readAsBytes() for web compatibility
      final bytes = await image.readAsBytes();
      
      // Check file size (max 5MB)
      if (bytes.length > 5 * 1024 * 1024) {
        _showSnackBar('Image too large. Max size is 5MB', isError: true);
        setState(() => _isProcessing = false);
        return;
      }
      
      // Decode the image
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        _showSnackBar('Failed to process banner image', isError: true);
        setState(() => _isProcessing = false);
        return;
      }

      // Resize to max 800x300 while maintaining aspect ratio
      img.Image resized;
      if (originalImage.width > 800) {
        resized = img.copyResize(originalImage, width: 800);
      } else if (originalImage.height > 300) {
        resized = img.copyResize(originalImage, height: 300);
      } else {
        resized = originalImage;
      }

      // Encode as JPEG with 80% quality for smaller size
      final compressed = img.encodeJpg(resized, quality: 80);
      
      print('Banner image size: ${compressed.length} bytes');
      
      // Convert to base64
      final base64Image = base64Encode(compressed);
      final dataUri = 'data:image/jpeg;base64,$base64Image';
      
      print('Uploading banner to server...');
      
      // Upload to server
      final result = await SettingsService.updateProfile(
        _userProfile!.email,
        {'store_banner': dataUri},
      );

      print('Upload result: ${result['success']}');

      if (result['success'] == true) {
        // Clear image cache for the new banner
        if (_userProfile?.storeBanner != null) {
          await CachedNetworkImage.evictFromCache(_userProfile!.storeBanner!);
        }
        
        setState(() {
          _userProfile = UserProfile.fromJson(result['data']);
          _originalProfile = UserProfile.fromJson(json.decode(json.encode(result['data'])));
        });
        
        // Force rebuild after a short delay to ensure cache is cleared
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {});
        }
        
        _showSnackBar('Banner uploaded successfully');
      } else {
        final errorMsg = result['message'] ?? 'Failed to upload banner';
        print('Upload failed: $errorMsg');
        _showSnackBar(errorMsg, isError: true);
      }
    } catch (e, stackTrace) {
      print('Banner upload error: $e');
      print('Stack trace: $stackTrace');
      _showSnackBar('Failed to upload banner: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isProcessing = false);
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
