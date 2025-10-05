import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/translation_service.dart';
import '../models/user_profile.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TranslationService _translationService = TranslationService();
  final _formKey = GlobalKey<FormState>();
  
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
    if (_originalProfile == null || _userProfile == null) return;
    
    final currentJson = json.encode(_userProfile!.toJson());
    final originalJson = json.encode(_originalProfile!.toJson());
    
    setState(() {
      _formDirty = currentJson != originalJson;
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
      body: SingleChildScrollView(
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
          child: Container(
            constraints: BoxConstraints(
              maxWidth: screenWidth < 896 ? double.infinity : 896,
            ),
            margin: EdgeInsets.symmetric(
              horizontal: isSmallMobile ? 8 : 16,
            ),
            padding: EdgeInsets.symmetric(
              vertical: isSmallMobile ? 16 : 24,
            ),
            child: Column(
              children: [
                // Header
                _buildHeader(isSmallMobile),
                
                SizedBox(height: isSmallMobile ? 24 : 32),
                
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
        ),
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

  // Continue with build methods in next part...
  // (The file is too long, I'll create helper methods in separate sections)
  
  Widget _buildHeader(bool isSmallMobile) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallMobile ? 12 : 16,
            vertical: isSmallMobile ? 8 : 12,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            t('settings'),
            style: TextStyle(
              fontSize: isSmallMobile ? 20 : 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: isSmallMobile ? 8 : 12),
        Text(
          'Manage your account settings and preferences',
          style: TextStyle(
            fontSize: isSmallMobile ? 13 : 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Additional build methods will be in part 2
  // This is getting very long, so I'll split it intelligently

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
    return Text('Profile form will be implemented');
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
            onPressed: _isLoading ? null : () {}, // Will implement save
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
}
