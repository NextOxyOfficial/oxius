import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/gold_sponsor_service.dart';
import '../../models/gold_sponsor_models.dart';

class BecomeGoldSponsorScreen extends StatefulWidget {
  const BecomeGoldSponsorScreen({super.key});

  @override
  State<BecomeGoldSponsorScreen> createState() => _BecomeGoldSponsorScreenState();
}

class _BecomeGoldSponsorScreenState extends State<BecomeGoldSponsorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _businessDescController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _profileUrlController = TextEditingController();
  
  XFile? _logoFile;
  String? _logoFileName;
  
  final List<_Banner> _banners = [];
  final int _maxBanners = 5;
  
  int _selectedPackageId = 1;
  bool _isLoading = false;
  bool _isLoadingPackages = true;
  bool _isLoadingBalance = true;
  double _userBalance = 0;
  String? _error;
  bool _success = false;
  
  List<SponsorshipPackage> _packages = [];

  @override
  void initState() {
    super.initState();
    _loadUserBalance();
    _loadPackages();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessDescController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _profileUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadUserBalance() async {
    setState(() => _isLoadingBalance = true);
    try {
      // Validate token and refresh user data from backend
      final isValid = await AuthService.validateToken();
      
      if (isValid) {
        // Get updated user data
        final user = AuthService.currentUser;
        if (user != null) {
          setState(() {
            _userBalance = user.balance.toDouble();
          });
        }
      } else {
        print('Token validation failed');
      }
    } catch (e) {
      print('Error loading balance: $e');
    } finally {
      setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoadingPackages = true);
    try {
      final packages = await GoldSponsorService.getPackages();
      if (mounted) {
        setState(() {
          _packages = packages;
          if (_packages.isNotEmpty) {
            _selectedPackageId = _packages.first.id;
          }
        });
      }
    } catch (e) {
      print('Error loading packages: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load packages. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPackages = false);
      }
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _logoFile = pickedFile;
        _logoFileName = pickedFile.name;
      });
    }
  }

  void _addBanner() {
    if (_banners.length < _maxBanners) {
      setState(() {
        _banners.add(_Banner());
      });
    }
  }

  void _removeBanner(int index) {
    setState(() {
      _banners.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check balance
    final selectedPackage = _packages.firstWhere(
      (p) => p.id == _selectedPackageId,
      orElse: () => _packages.first,
    );
    if (_userBalance < selectedPackage.price) {
      setState(() {
        _error = 'Insufficient balance! You need ৳${selectedPackage.price} but only have ৳${_userBalance.toStringAsFixed(0)}';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = false;
    });

    try {
      // Prepare banner data with XFile objects
      final List<Map<String, dynamic>>? bannerData = _banners.isNotEmpty
          ? _banners.map((banner) {
              return {
                'title': banner.title,
                'link_url': banner.linkUrl,
                'file': banner.file, // Pass XFile directly
              };
            }).toList()
          : null;

      // Submit to backend API
      final result = await GoldSponsorService.submitApplication(
        businessName: _businessNameController.text.trim(),
        businessDescription: _businessDescController.text.trim(),
        contactEmail: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        profileUrl: _profileUrlController.text.trim().isEmpty ? null : _profileUrlController.text.trim(),
        packageId: _selectedPackageId,
        logoFile: _logoFile, // Pass XFile directly
        banners: bannerData,
      );
      
      if (mounted) {
        if (result['success'] == true) {
          // Reload user balance to show updated amount
          await _loadUserBalance();
          
          setState(() {
            _success = true;
            _error = null;
          });
          
          // Show success and go back
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Success! Your new balance is ৳${_userBalance.toStringAsFixed(0)}'),
              backgroundColor: Colors.green,
            ),
          );
          
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        } else {
          setState(() {
            _error = result['error'] ?? 'Failed to submit application';
            _success = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to submit application: $e';
        _success = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Gold Sponsor'),
        backgroundColor: Colors.amber.shade500,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade50, Colors.yellow.shade50],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade600, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Gold Sponsor Benefits',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join our exclusive Gold Sponsors and showcase your business to thousands of potential customers. Gold Sponsors receive premium visibility and additional benefits.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Business Name
              TextFormField(
                controller: _businessNameController,
                decoration: InputDecoration(
                  labelText: 'Business Name *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              
              const SizedBox(height: 16),
              
              // Business Description
              TextFormField(
                controller: _businessDescController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: 'Business Description *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  helperText: 'Max 200 characters',
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              
              const SizedBox(height: 16),
              
              // Contact Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Contact Email *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (!value!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              
              const SizedBox(height: 16),
              
              // Website
              TextFormField(
                controller: _websiteController,
                decoration: InputDecoration(
                  labelText: 'Website URL',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Profile URL
              TextFormField(
                controller: _profileUrlController,
                decoration: InputDecoration(
                  labelText: 'Profile URL',
                  helperText: 'Users will be redirected here when clicking "Visit Sponsor\'s Profile"',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Logo Upload
              Text('Business Logo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _logoFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? Image.network(_logoFile!.path, fit: BoxFit.cover)
                                : Image.file(File(_logoFile!.path), fit: BoxFit.cover),
                          )
                        : Icon(Icons.business, size: 32, color: Colors.grey.shade400),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickLogo,
                          icon: const Icon(Icons.upload, size: 18),
                          label: const Text('Choose File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.grey.shade800,
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        if (_logoFileName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _logoFileName!,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                'Recommended: 250x250px, PNG or JPG',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              
              const SizedBox(height: 24),
              
              // Banners Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Promotional Banners (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('${_banners.length}/$_maxBanners', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 8),
              
              if (_banners.isNotEmpty)
                ...List.generate(_banners.length, (index) => _buildBannerItem(index)),
              
              if (_banners.length < _maxBanners)
                OutlinedButton.icon(
                  onPressed: _addBanner,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Banner'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    side: BorderSide(color: Colors.amber.shade300, width: 2, style: BorderStyle.solid),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Balance Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Current Balance:', style: TextStyle(color: Colors.blue.shade800)),
                    _isLoadingBalance
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            '৳${_userBalance.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                          ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Package Selection
              Text('Select Sponsorship Package *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              
              if (_isLoadingPackages)
                const Center(child: CircularProgressIndicator())
              else if (_packages.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'No packages available at the moment.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...List.generate(_packages.length, (index) => _buildPackageCard(_packages[index])),
              
              const SizedBox(height: 24),
              
              // Error Message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              
              // Success Message
              if (_success)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Application submitted successfully!',
                          style: TextStyle(color: Colors.green.shade700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading || _success ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade500,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerItem(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Banner ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w500)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _removeBanner(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Banner Title (Optional)',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onChanged: (value) => _banners[index].title = value,
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Link URL (Optional)',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onChanged: (value) => _banners[index].linkUrl = value,
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                setState(() {
                  _banners[index].file = pickedFile;
                  _banners[index].fileName = pickedFile.name;
                });
              }
            },
            icon: const Icon(Icons.image, size: 18),
            label: Text(_banners[index].fileName ?? 'Choose Image'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey.shade800,
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(SponsorshipPackage package) {
    final isSelected = _selectedPackageId == package.id;
    final hasEnoughBalance = _userBalance >= package.price;
    
    return GestureDetector(
      onTap: hasEnoughBalance ? () => setState(() => _selectedPackageId = package.id) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.amber.shade500 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<int>(
              value: package.id,
              groupValue: _selectedPackageId,
              onChanged: hasEnoughBalance ? (value) => setState(() => _selectedPackageId = value!) : null,
              activeColor: Colors.amber.shade600,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    package.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  if (!hasEnoughBalance)
                    Text(
                      'Need ৳${(package.price - _userBalance).toStringAsFixed(0)} more',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '৳${package.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade700,
                  ),
                ),
                Text(
                  hasEnoughBalance ? '✓ Available' : '⚠️ Insufficient',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasEnoughBalance ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner {
  String? title;
  String? linkUrl;
  XFile? file;
  String? fileName;

  _Banner();
}
