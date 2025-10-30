import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';
import '../services/geo_service.dart';
import '../services/user_state_service.dart';

class RegisterPage extends StatefulWidget {
  final String? referralCode;
  
  const RegisterPage({super.key, this.referralCode});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _currentStep = 1;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showPassword = false;
  
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _zipController = TextEditingController();
  final _addressController = TextEditingController();
  final _referralController = TextEditingController();
  
  // Form data
  String? _profileImageBase64;
  File? _profileImageFile;
  Uint8List? _profileImageBytes; // For platforms without file system
  String? _profileImageName;
  String _gender = '';
  String _country = 'Bangladesh';
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedUpazila;
  
  // Geo data
  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _upazilas = [];
  
  // Field errors
  Map<String, String?> _errors = {};

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
    _ageController.dispose();
    _zipController.dispose();
    _addressController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    try {
      final regions = await GeoService.getRegions(_country);
      setState(() => _regions = regions);
    } catch (e) {
      print('Error loading regions: $e');
    }
  }

  Future<void> _loadCities(String region) async {
    try {
      final cities = await GeoService.getCities(region);
      setState(() {
        _cities = cities;
        _selectedCity = null;
        _upazilas = [];
        _selectedUpazila = null;
      });
    } catch (e) {
      print('Error loading cities: $e');
    }
  }

  Future<void> _loadUpazilas(String city) async {
    try {
      final upazilas = await GeoService.getUpazilas(city);
      setState(() {
        _upazilas = upazilas;
        _selectedUpazila = null;
      });
    } catch (e) {
      print('Error loading upazilas: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      print('Starting image picker...');
      
      // Try file_picker first (works on most platforms)
      FilePickerResult? result;
      
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true, // Important: Load file data into memory
        );
      } catch (e) {
        print('FilePicker error: $e');
        // If file_picker fails, try image_picker as fallback
        try {
          final picker = ImagePicker();
          final XFile? pickedFile = await picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          );
          
          if (pickedFile != null) {
            final bytes = await pickedFile.readAsBytes();
            setState(() {
              _profileImageBytes = bytes;
              _profileImageName = pickedFile.name;
              _profileImageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
            });
            print('Image loaded via ImagePicker: ${bytes.length} bytes');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image selected successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            return;
          }
        } catch (imagePickerError) {
          print('ImagePicker also failed: $imagePickerError');
        }
      }
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('File selected: ${file.name}, Size: ${file.size} bytes');
        
        Uint8List? bytes;
        
        // Try to get bytes from the file
        if (file.bytes != null) {
          // Web or when withData: true
          bytes = file.bytes;
          print('Using file.bytes: ${bytes!.length}');
        } else if (file.path != null) {
          // Desktop/Mobile with file path
          try {
            bytes = await File(file.path!).readAsBytes();
            print('Read from file path: ${bytes.length}');
          } catch (e) {
            print('Error reading file: $e');
          }
        }
        
        if (bytes != null) {
          setState(() {
            _profileImageBytes = bytes;
            _profileImageName = file.name;
            _profileImageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes!)}';
            
            // Also try to set file if path exists
            if (file.path != null) {
              try {
                _profileImageFile = File(file.path!);
              } catch (e) {
                print('Could not create File object: $e');
              }
            }
          });
          
          print('Image loaded successfully: ${bytes.length} bytes');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image selected successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('Could not read image data');
        }
      } else {
        print('No file selected');
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image. Please try again.'),
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

  bool _validateStep2() {
    _errors.clear();
    bool isValid = true;

    if (_firstNameController.text.isEmpty) {
      _errors['first_name'] = 'First name is required';
      isValid = false;
    }
    if (_lastNameController.text.isEmpty) {
      _errors['last_name'] = 'Last name is required';
      isValid = false;
    }
    if (_emailController.text.isEmpty) {
      _errors['email'] = 'Email is required';
      isValid = false;
    }
    if (_phoneController.text.isEmpty) {
      _errors['phone'] = 'Phone is required';
      isValid = false;
    } else if (!RegExp(r'^(?:\+?88)?01[3-9]\d{8}$').hasMatch(_phoneController.text.trim())) {
      _errors['phone'] = 'Invalid phone number';
      isValid = false;
    }
    if (_passwordController.text.isEmpty) {
      _errors['password'] = 'Password is required';
      isValid = false;
    }
    if (_confirmPasswordController.text.isEmpty) {
      _errors['confirm_password'] = 'Confirm password is required';
      isValid = false;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      _errors['confirm_password'] = 'Passwords do not match';
      isValid = false;
    }
    if (_ageController.text.isEmpty) {
      _errors['age'] = 'Age is required';
      isValid = false;
    } else if (!RegExp(r'^\d+$').hasMatch(_ageController.text)) {
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

  void _nextStep() {
    if (_currentStep == 2 && !_validateStep2()) {
      return;
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  void _skipStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_validateStep2()) {
      setState(() => _currentStep = 2);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final formData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'email': _emailController.text.trim(),
        'username': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
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
        // Auto-login after registration
        final loginResult = await AuthService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (mounted && loginResult != null) {
          final userState = UserStateService();
          userState.updateUser(loginResult.user);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.celebration, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Welcome to AdsyClub! 🎉',
                      style: GoogleFonts.roboto(),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 4),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade700, Colors.purple.shade500, Colors.deepPurple.shade600],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildHeader(),
                const SizedBox(height: 24),
                _buildProgressIndicator(),
                const SizedBox(height: 24),
                _buildFormCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.person_add_rounded, size: 32, color: Colors.purple.shade600),
          ),
          const SizedBox(height: 16),
          Text('Create Account', style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Join our community today', style: GoogleFonts.roboto(fontSize: 14, color: Colors.white.withOpacity(0.9))),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(1, 'Photo'),
        _buildStepLine(1),
        _buildStepCircle(2, 'Info'),
        _buildStepLine(2),
        _buildStepCircle(3, 'Address'),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: isActive ? Colors.white : Colors.white.withOpacity(0.3), shape: BoxShape.circle),
          child: Center(child: Text('$step', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600, color: isActive ? Colors.purple.shade600 : Colors.white))),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.roboto(fontSize: 10, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Container(width: 40, height: 2, margin: const EdgeInsets.only(bottom: 16), color: isActive ? Colors.white : Colors.white.withOpacity(0.3));
  }

  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCA5A5))),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_errorMessage!, style: GoogleFonts.roboto(color: const Color(0xFF991B1B), fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (_currentStep == 1) _buildStep1(),
          if (_currentStep == 2) _buildStep2(),
          if (_currentStep == 3) _buildStep3(),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        Text('Profile Photo', style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 8),
        Text('Upload your profile picture (optional)', style: GoogleFonts.roboto(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.purple.shade200, width: 3),
                ),
                child: _profileImageBytes != null
                    ? ClipOval(
                        child: Image.memory(
                          _profileImageBytes!,
                          key: ValueKey(_profileImageName ?? 'image'),
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error displaying image: $error');
                            return Icon(Icons.error, size: 60, color: Colors.red.shade400);
                          },
                        ),
                      )
                    : _profileImageFile != null
                        ? ClipOval(
                            child: Image.file(
                              _profileImageFile!,
                              key: ValueKey(_profileImageFile!.path),
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error displaying image: $error');
                                return Icon(Icons.error, size: 60, color: Colors.red.shade400);
                              },
                            ),
                          )
                        : Icon(Icons.person, size: 60, color: Colors.grey.shade400),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.purple.shade600, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                ),
              ),
              if (_profileImageBytes != null || _profileImageFile != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _removeImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(onPressed: _skipStep, child: Text('Skip', style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade600))),
            ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Row(children: [Text('Continue', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600)), const SizedBox(width: 8), const Icon(Icons.arrow_forward, size: 18)]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Personal Information', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('First Name', _firstNameController, Icons.person_outline, error: _errors['first_name'])),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Last Name', _lastNameController, Icons.person_outline, error: _errors['last_name'])),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField('Email', _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress, error: _errors['email']),
        const SizedBox(height: 12),
        _buildTextField('Phone', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone, error: _errors['phone']),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField('Age', _ageController, Icons.calendar_today_outlined, keyboardType: TextInputType.number, error: _errors['age'])),
            const SizedBox(width: 12),
            Expanded(child: _buildGenderDropdown()),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField('Password', _passwordController, Icons.lock_outline, isPassword: true, error: _errors['password']),
        const SizedBox(height: 12),
        _buildTextField('Confirm Password', _confirmPasswordController, Icons.lock_outline, isPassword: true, error: _errors['confirm_password']),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(onPressed: _prevStep, icon: const Icon(Icons.arrow_back, size: 18), label: Text('Back', style: GoogleFonts.roboto(fontSize: 14)), style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700)),
            ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Row(children: [Text('Continue', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600)), const SizedBox(width: 8), const Icon(Icons.arrow_forward, size: 18)]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Address Information', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 16),
        _buildDropdown('Region/State', _regions, _selectedRegion, (value) {
          setState(() => _selectedRegion = value);
          if (value != null) _loadCities(value);
        }),
        const SizedBox(height: 12),
        _buildDropdown('City', _cities, _selectedCity, (value) {
          setState(() => _selectedCity = value);
          if (value != null) _loadUpazilas(value);
        }),
        const SizedBox(height: 12),
        _buildDropdown('Area/Upazila', _upazilas, _selectedUpazila, (value) => setState(() => _selectedUpazila = value)),
        const SizedBox(height: 12),
        _buildTextField('Zip/Postal Code', _zipController, Icons.markunread_mailbox_outlined),
        const SizedBox(height: 12),
        _buildTextField('Full Address', _addressController, Icons.home_outlined, maxLines: 2),
        const SizedBox(height: 12),
        _buildTextField('Referral Code (Optional)', _referralController, Icons.card_giftcard_outlined),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(onPressed: _prevStep, icon: const Icon(Icons.arrow_back, size: 18), label: Text('Back', style: GoogleFonts.roboto(fontSize: 14)), style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700)),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), disabledBackgroundColor: Colors.grey.shade300),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Row(children: [const Icon(Icons.check_circle, size: 20), const SizedBox(width: 8), Text('Complete', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600))]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
            child: Text('Already have an account? Sign In', style: GoogleFonts.roboto(fontSize: 13, color: Colors.purple.shade600, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPassword = false, TextInputType? keyboardType, int maxLines = 1, String? error}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword && !_showPassword,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.roboto(fontSize: 14),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: GoogleFonts.roboto(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            suffixIcon: isPassword
                ? IconButton(icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade400, size: 20), onPressed: () => setState(() => _showPassword = !_showPassword))
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.purple.shade500, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEF4444))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 4, left: 12), child: Text(error, style: GoogleFonts.roboto(fontSize: 12, color: Colors.red.shade600))),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _gender.isEmpty ? null : _gender,
          decoration: InputDecoration(
            hintText: 'Gender',
            hintStyle: GoogleFonts.roboto(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.wc_outlined, color: Colors.grey.shade400, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.purple.shade500, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: ['Male', 'Female', 'Others'].map((gender) => DropdownMenuItem(value: gender, child: Text(gender, style: GoogleFonts.roboto(fontSize: 14)))).toList(),
          onChanged: (value) => setState(() => _gender = value ?? ''),
        ),
        if (_errors['gender'] != null) Padding(padding: const EdgeInsets.only(top: 4, left: 12), child: Text(_errors['gender']!, style: GoogleFonts.roboto(fontSize: 12, color: Colors.red.shade600))),
      ],
    );
  }

  Widget _buildDropdown(String label, List<Map<String, dynamic>> items, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.roboto(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.purple.shade500, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items.map<DropdownMenuItem<String>>((item) => DropdownMenuItem<String>(value: item['name_eng'] as String, child: Text(item['name_eng'] as String, style: GoogleFonts.roboto(fontSize: 14)))).toList(),
      onChanged: onChanged,
    );
  }
}
