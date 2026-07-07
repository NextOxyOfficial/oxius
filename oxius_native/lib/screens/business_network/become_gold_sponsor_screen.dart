import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/gold_sponsor_service.dart';
import '../../services/geo_service.dart';
import '../../models/gold_sponsor_models.dart';
import '../../utils/image_compressor.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class BecomeGoldSponsorScreen extends StatefulWidget {
  const BecomeGoldSponsorScreen({super.key});

  @override
  State<BecomeGoldSponsorScreen> createState() =>
      _BecomeGoldSponsorScreenState();
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

  // Location targeting: empty list = shown all over Bangladesh.
  bool _targetAllBangladesh = true;
  final List<Map<String, String>> _locations = [];
  int _locSeq = 0;
  int _discountPercent = 0; // % off for tightly-targeted ads
  int _maxLocations = 10;
  int _maxDiscountDivisions = 2;

  // Geo data from the database (names match user addresses — no manual typing).
  List<String> _divisionOptions = [];
  final Map<String, List<String>> _citiesByDivision = {};
  final Map<String, List<String>> _areasByCity = {};

  Future<void> _loadDivisions() async {
    try {
      final rows = await GeoService.getRegions('Bangladesh');
      if (!mounted) return;
      setState(() => _divisionOptions = rows
          .map((r) => (r['name_eng'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList());
    } catch (_) {}
  }

  Future<void> _loadCitiesFor(String division) async {
    if (division.isEmpty || _citiesByDivision.containsKey(division)) return;
    try {
      final rows = await GeoService.getCities(division);
      if (!mounted) return;
      setState(() => _citiesByDivision[division] = rows
          .map((r) => (r['name_eng'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList());
    } catch (_) {}
  }

  Future<void> _loadAreasFor(String city) async {
    if (city.isEmpty || _areasByCity.containsKey(city)) return;
    try {
      final rows = await GeoService.getUpazilas(city);
      if (!mounted) return;
      setState(() => _areasByCity[city] = rows
          .map((r) => (r['name_eng'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList());
    } catch (_) {}
  }

  void _addLocationRow() {
    if (_locations.length >= _maxLocations) return;
    setState(() => _locations
        .add({'_id': '${_locSeq++}', 'division': '', 'city': '', 'area': ''}));
  }

  int get _distinctDivisionCount => _locations
      .map((l) => (l['division'] ?? '').trim().toLowerCase())
      .where((s) => s.isNotEmpty)
      .toSet()
      .length;

  bool get _discountEligible =>
      !_targetAllBangladesh &&
      _locations.isNotEmpty &&
      _distinctDivisionCount <= _maxDiscountDivisions;

  double get _selectedPackagePrice {
    final pkg = _packages.where((p) => p.id == _selectedPackageId);
    return pkg.isEmpty ? 0 : pkg.first.price.toDouble();
  }

  double get _effectivePrice => _discountEligible
      ? (_selectedPackagePrice * (100 - _discountPercent) / 100).roundToDouble()
      : _selectedPackagePrice;
  bool _success = false;

  List<SponsorshipPackage> _packages = [];

  @override
  void initState() {
    super.initState();
    _loadUserBalance();
    _loadPackages();
    _loadPricingConfig();
    _loadDivisions();
  }

  Future<void> _loadPricingConfig() async {
    final cfg = await GoldSponsorService.getPricingConfig();
    if (!mounted) return;
    setState(() {
      _discountPercent = cfg['discount'] ?? 0;
      _maxLocations = cfg['maxLocations'] ?? 10;
      _maxDiscountDivisions = cfg['maxDiscountDivisions'] ?? 2;
    });
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
        debugPrint('Token validation failed');
      }
    } catch (e) {
      debugPrint('Error loading balance: $e');
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
      debugPrint('Error loading packages: $e');
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

    // Guard: without packages, firstWhere's orElse (_packages.first) would
    // throw a StateError on the empty list and crash the submit.
    if (_packages.isEmpty || _selectedPackageId == null) {
      setState(() => _error = 'Please select a sponsorship package.');
      return;
    }

    // Check balance
    final selectedPackage = _packages.firstWhere(
      (p) => p.id == _selectedPackageId,
      orElse: () => _packages.first,
    );
    if (_userBalance < selectedPackage.price) {
      setState(() {
        _error =
            'Insufficient balance! You need ৳${selectedPackage.price} but only have ৳${_userBalance.toStringAsFixed(0)}';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = false;
    });

    try {
      // Compress logo before upload (fallback to original on failure)
      XFile? logoUpload = _logoFile;
      if (_logoFile != null) {
        final compressedLogo = await ImageCompressor.compressToBytes(
          _logoFile!,
          targetSize: 80 * 1024,
        );
        if (compressedLogo != null) {
          logoUpload = XFile.fromData(
            compressedLogo,
            name: 'logo.jpg',
            mimeType: 'image/jpeg',
          );
        }
      }

      // Prepare banner data with compressed XFile objects
      List<Map<String, dynamic>>? bannerData;
      if (_banners.isNotEmpty) {
        bannerData = [];
        for (final banner in _banners) {
          XFile? bannerFile = banner.file;
          if (bannerFile != null) {
            final compressedBanner = await ImageCompressor.compressToBytes(
              bannerFile,
              targetSize: 80 * 1024,
            );
            if (compressedBanner != null) {
              bannerFile = XFile.fromData(
                compressedBanner,
                name: 'banner.jpg',
                mimeType: 'image/jpeg',
              );
            }
          }
          bannerData.add({
            'title': banner.title,
            'link_url': banner.linkUrl,
            'file': bannerFile, // Pass XFile directly
          });
        }
      }

      // Submit to backend API
      final result = await GoldSponsorService.submitApplication(
        businessName: _businessNameController.text.trim(),
        businessDescription: _businessDescController.text.trim(),
        contactEmail: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        profileUrl: _profileUrlController.text.trim().isEmpty
            ? null
            : _profileUrlController.text.trim(),
        packageId: _selectedPackageId,
        logoFile: logoUpload, // Pass XFile directly
        banners: bannerData,
        locations: _targetAllBangladesh
            ? <Map<String, String>>[]
            : _locations
                .map((l) => {
                      'division': l['division'] ?? '',
                      'city': l['city'] ?? '',
                      'area': l['area'] ?? '',
                    })
                .toList(),
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
          if (mounted) {
            AdsyToast.success(context,
                'Success! Your new balance is ৳${_userBalance.toStringAsFixed(0)}');
          }

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
        title: const Text(
          'Become a Gold Sponsor',
          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star,
                            color: Colors.amber.shade600, size: 24),
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
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Business Name
              _fieldLabel('Business Name', required: true),
              TextFormField(
                controller: _businessNameController,
                style: const TextStyle(fontSize: 15, color: _ink),
                textCapitalization: TextCapitalization.words,
                decoration: _dec(hint: 'e.g. Rahim Traders'),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Business name is required'
                    : null,
              ),

              const SizedBox(height: 14),

              // Business Description
              _fieldLabel('Business Description', required: true),
              TextFormField(
                controller: _businessDescController,
                maxLines: 3,
                maxLength: 200,
                style: const TextStyle(fontSize: 15, color: _ink),
                decoration: _dec(
                    hint: 'What does your business do? (max 200 characters)'),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Description is required'
                    : null,
              ),

              const SizedBox(height: 14),

              // Contact Email
              _fieldLabel('Contact Email', required: true),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 15, color: _ink),
                decoration: _dec(hint: 'name@example.com'),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Email is required';
                  final ok =
                      RegExp(r'^[\w.+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$')
                          .hasMatch(v);
                  if (!ok) return 'Enter a valid email address';
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Phone Number
              _fieldLabel('Phone Number', required: true),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 15, color: _ink),
                decoration: _dec(hint: '01XXXXXXXXX'),
                validator: (value) {
                  final v = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
                  if (v.isEmpty) return 'Phone number is required';
                  if (!RegExp(r'^(\+?88)?01[3-9]\d{8}$').hasMatch(v)) {
                    return 'Enter a valid Bangladeshi phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Website
              _fieldLabel('Website URL'),
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                style: const TextStyle(fontSize: 15, color: _ink),
                decoration: _dec(hint: 'https://yourbusiness.com (optional)'),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return null;
                  if (!v.contains('.')) return 'Enter a valid URL';
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Profile URL
              _fieldLabel('Profile URL'),
              TextFormField(
                controller: _profileUrlController,
                keyboardType: TextInputType.url,
                style: const TextStyle(fontSize: 15, color: _ink),
                decoration: _dec(
                  hint: 'Link to your page or profile (optional)',
                  helper:
                      "Users will be redirected here when clicking 'Visit Sponsor\'s Profile'",
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return null;
                  if (!v.contains('.')) return 'Enter a valid URL';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Logo Upload
              const Text('Business Logo',
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: _ink)),
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
                                ? Image.network(_logoFile!.path,
                                    fit: BoxFit.cover)
                                : Image.file(File(_logoFile!.path),
                                    fit: BoxFit.cover),
                          )
                        : Icon(Icons.business,
                            size: 32, color: Colors.grey.shade400),
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
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
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
                  const Text('Promotional Banners (Optional)',
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                  Text('${_banners.length}/$_maxBanners',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 8),

              if (_banners.isNotEmpty)
                ...List.generate(
                    _banners.length, (index) => _buildBannerItem(index)),

              if (_banners.length < _maxBanners)
                OutlinedButton.icon(
                  onPressed: _addBanner,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Banner'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    side: BorderSide(
                        color: Colors.amber.shade300,
                        width: 2,
                        style: BorderStyle.solid),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),

              const SizedBox(height: 24),

              // Balance Card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        size: 19, color: _muted),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Your Current Balance',
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: _muted)),
                    ),
                    _isLoadingBalance
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: AdsyLoadingIndicator(strokeWidth: 2),
                          )
                        : Text(
                            '৳${_userBalance.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: _ink),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Package Selection
              const Text('Select Sponsorship Package *',
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: _ink)),
              const SizedBox(height: 12),

              if (_isLoadingPackages)
                const Center(child: AdsyLoadingIndicator())
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
                RadioGroup<int>(
                  groupValue: _selectedPackageId,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPackageId = value);
                    }
                  },
                  child: Column(
                    children: List.generate(_packages.length,
                        (index) => _buildPackageCard(_packages[index])),
                  ),
                ),

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
                        child: Text(_error!,
                            style: TextStyle(
                                color: Colors.red.shade700, fontSize: 14)),
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
                      Icon(Icons.check_circle,
                          color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Application submitted successfully!',
                          style: TextStyle(
                              color: Colors.green.shade700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              // Target locations
              _buildLocationSection(),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || _success ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: AdsyLoadingIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit Application',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static const Color _amber = Color(0xFFD97706);
  static const Color _ink = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _line = Color(0xFFE5E7EB);

  /// One decoration for every input so sizes/borders stay identical:
  /// white fill, neutral hairline, amber focus, red error.
  InputDecoration _dec({String? hint, String? helper}) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      helperText: helper,
      helperMaxLines: 2,
      hintStyle: const TextStyle(
          fontSize: 14.5,
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w400),
      helperStyle: const TextStyle(fontSize: 12, color: _muted),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: b(_line),
      enabledBorder: b(_line),
      focusedBorder: b(_amber, 1.4),
      errorBorder: b(const Color(0xFFEF4444)),
      focusedErrorBorder: b(const Color(0xFFEF4444), 1.4),
    );
  }

  /// Field label above the input — clearer than floating labels and the
  /// required mark stays visible while typing.
  Widget _fieldLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w600, color: _ink),
          children: required
              ? const [
                  TextSpan(
                      text: ' *', style: TextStyle(color: Color(0xFFEF4444)))
                ]
              : const [],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.location_on_rounded,
                    size: 18, color: _amber),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Where should your ad show?',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Show all over Bangladesh, or target specific divisions/cities — users see ads matching their address.',
            style: TextStyle(fontSize: 11.5, color: _muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _modeCard(
                  selected: _targetAllBangladesh,
                  icon: Icons.public_rounded,
                  label: 'All Bangladesh',
                  onTap: () => setState(() {
                    _targetAllBangladesh = true;
                    _locations.clear();
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modeCard(
                  selected: !_targetAllBangladesh,
                  icon: Icons.place_rounded,
                  label: 'Specific',
                  badge: _discountPercent > 0 ? '$_discountPercent% OFF' : null,
                  onTap: () => setState(() {
                    _targetAllBangladesh = false;
                    if (_locations.isEmpty) _addLocationRow();
                  }),
                ),
              ),
            ],
          ),
          if (!_targetAllBangladesh) ...[
            const SizedBox(height: 12),
            ..._locations
                .asMap()
                .entries
                .map((e) => _buildLocationRow(e.value, e.key + 1)),
            if (_locations.length < _maxLocations) _addLocationButton(),
          ],
          if (_selectedPackagePrice > 0) ...[
            const SizedBox(height: 12),
            _priceSummary(),
          ],
        ],
      ),
    );
  }

  Widget _modeCard({
    required bool selected,
    required IconData icon,
    required String label,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFFBEB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? _amber : _line, width: selected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 18,
                    color: selected ? _amber : const Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? _ink : _muted)),
                ),
              ],
            ),
            if (badge != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(999)),
                child: Text(badge,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669))),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _addLocationButton() {
    return InkWell(
      onTap: _addLocationRow,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _amber.withValues(alpha: 0.45), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 18, color: _amber),
            const SizedBox(width: 6),
            const Text('Add another location',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _amber)),
            const SizedBox(width: 8),
            Text('${_locations.length}/$_maxLocations',
                style:
                    const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }

  Widget _priceSummary() {
    final showFullNote =
        !_targetAllBangladesh && _distinctDivisionCount > _maxDiscountDivisions;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _discountEligible
            ? const Color(0xFFECFDF5)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _discountEligible ? const Color(0xFFA7F3D0) : _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('You pay',
                  style: TextStyle(fontSize: 12.5, color: _muted)),
              const Spacer(),
              if (_discountEligible) ...[
                Text('৳${_selectedPackagePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                        decoration: TextDecoration.lineThrough)),
                const SizedBox(width: 6),
                Text('৳${_effectivePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669))),
              ] else
                Text('৳${_selectedPackagePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
            ],
          ),
          if (_discountEligible)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                  '🎉 $_discountPercent% off · targeting ${_distinctDivisionCount <= 1 ? "1 division" : "$_distinctDivisionCount divisions"}',
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669))),
            )
          else if (_targetAllBangladesh)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text('Shown all over Bangladesh',
                  style: TextStyle(fontSize: 11.5, color: _muted)),
            ),
          if (showFullNote)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'ⓘ Discount applies to up to $_maxDiscountDivisions divisions. You\'re targeting $_distinctDivisionCount — full price.',
                style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(Map<String, String> loc, int number) {
    final division = loc['division'] ?? '';
    final city = loc['city'] ?? '';
    final cities = _citiesByDivision[division] ?? const <String>[];
    final areas = _areasByCity[city] ?? const <String>[];
    return Container(
      key: ValueKey(loc['_id']),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                child: Center(
                  child: Text('$number',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _amber)),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Target location',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _muted)),
              const Spacer(),
              InkWell(
                onTap: () => setState(() => _locations.remove(loc)),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded,
                      size: 17, color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _locDropdown(
            hint: 'Select division',
            value: division.isEmpty ? null : division,
            items: _divisionOptions,
            onChanged: (v) {
              setState(() {
                loc['division'] = v ?? '';
                loc['city'] = '';
                loc['area'] = '';
              });
              if (v != null) _loadCitiesFor(v);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _locDropdown(
                  hint: 'City (optional)',
                  value: city.isEmpty ? null : city,
                  items: cities,
                  enabled: division.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      loc['city'] = v ?? '';
                      loc['area'] = '';
                    });
                    if (v != null) _loadAreasFor(v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _locDropdown(
                  hint: 'Area (optional)',
                  value: (loc['area'] ?? '').isEmpty ? null : loc['area'],
                  items: areas,
                  enabled: city.isNotEmpty,
                  onChanged: (v) => setState(() => loc['area'] = v ?? ''),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _locDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    // Guard against a value that isn't in items yet (e.g. before they load).
    final safeValue = (value != null && items.contains(value)) ? value : null;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c, width: w));
    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          size: 20, color: Color(0xFF9CA3AF)),
      style: const TextStyle(fontSize: 13, color: _ink),
      hint: Text(hint,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
          overflow: TextOverflow.ellipsis),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF1F5F9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: border(_line),
        disabledBorder: border(_line),
        focusedBorder: border(_amber, 1.4),
      ),
      items: items
          .map((d) => DropdownMenuItem(
              value: d,
              child: Text(d,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: enabled ? onChanged : null,
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
              Text('Banner ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onChanged: (value) => _banners[index].title = value,
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Link URL (Optional)',
              isDense: true,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onChanged: (value) => _banners[index].linkUrl = value,
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final picker = ImagePicker();
              final pickedFile =
                  await picker.pickImage(source: ImageSource.gallery);
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
      onTap: hasEnoughBalance
          ? () => setState(() => _selectedPackageId = package.id)
          : null,
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
              enabled: hasEnoughBalance,
              activeColor: Colors.amber.shade600,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
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
