import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/sale_post_service.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../widgets/api_error_ui.dart';
import '../utils/image_compressor.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class CreateSalePostScreen extends StatefulWidget {
  const CreateSalePostScreen({super.key});

  @override
  State<CreateSalePostScreen> createState() => _CreateSalePostScreenState();
}

class _CreateSalePostScreenState extends State<CreateSalePostScreen> {
  final TranslationService _i18n = TranslationService();
  String _t(String key, String fallback) =>
      _i18n.translate(key, fallback: fallback);

  final _formKey = GlobalKey<FormState>();
  final SalePostService _salePostService =
      SalePostService(baseUrl: ApiService.baseUrl);
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Form data
  int? _selectedCategory;
  int? _selectedChildCategory;
  String? _selectedCondition;
  bool _isNegotiable = false;
  bool _allOverBangladesh = false;
  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedArea;
  bool _termsAccepted = false;

  // Delivery coverage: empty list = সারা বাংলাদেশ. Each entry is
  // {"division": "..."} or {"division": "...", "district": "..."}.
  bool _deliverAllBd = true;
  final List<Map<String, String>> _deliveryLocations = [];
  String? _dlDivision;
  String? _dlDistrict;
  List<dynamic> _dlDistricts = [];
  bool _dlLoadingDistricts = false;

  // Images
  final List<String?> _imageBase64List = List.filled(8, null);
  final List<Uint8List?> _imageBytesList = List.filled(8, null);

  // Loading states
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _checkSubmit = false;

  // Data lists
  List<dynamic> _categories = [];
  List<dynamic> _childCategories = [];
  List<Map<String, String>> _conditions = [];
  List<dynamic> _divisions = [];
  List<dynamic> _districts = [];
  List<dynamic> _areas = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // Load all initial data in parallel
      await Future.wait([
        _loadCategories(),
        _loadConditions(),
        _loadDivisions(),
      ]);
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      _showErrorSnackBar(
          _t('sale_form_load_failed', 'ফর্মের ডেটা লোড করা গেল না'));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _salePostService.fetchCategoriesForForm();
      setState(() => _categories = categories);
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadConditions() async {
    // Default conditions matching Vue
    setState(() {
      _conditions = [
        {
          'label': _t('sale_condition_brand_new', 'একদম নতুন'),
          'value': 'brand-new'
        },
        {
          'label': _t('sale_condition_like_new', 'নতুনের মতো'),
          'value': 'like-new'
        },
        {'label': _t('sale_condition_good', 'ভালো'), 'value': 'good'},
        {'label': _t('sale_condition_fair', 'মোটামুটি'), 'value': 'fair'},
        {
          'label': _t('sale_condition_for_parts', 'পার্টসের জন্য'),
          'value': 'for-parts'
        },
      ];
    });
  }

  Future<void> _loadDivisions() async {
    try {
      final divisions = await _salePostService.fetchDivisions();
      setState(() => _divisions = divisions);
    } catch (e) {
      debugPrint('Error loading divisions: $e');
    }
  }

  Future<void> _loadChildCategories(int parentId) async {
    try {
      final childCategories =
          await _salePostService.fetchChildCategories(parentId);
      setState(() {
        _childCategories = childCategories;
        _selectedChildCategory = null;
      });
    } catch (e) {
      debugPrint('Error loading child categories: $e');
    }
  }

  Future<void> _loadDistricts(String division) async {
    try {
      final districts = await _salePostService.fetchDistricts(division);
      setState(() {
        _districts = districts;
        _selectedDistrict = null;
        _selectedArea = null;
      });
    } catch (e) {
      debugPrint('Error loading districts: $e');
    }
  }

  Future<void> _loadAreas(String district) async {
    try {
      final areas = await _salePostService.fetchAreas(district);
      setState(() {
        _areas = areas;
        _selectedArea = null;
      });
    } catch (e) {
      debugPrint('Error loading areas: $e');
    }
  }

  Future<void> _pickImage() async {
    if (_imageBase64List.where((img) => img != null).length >= 8) {
      _showErrorSnackBar(_t('sale_max_images', 'সর্বোচ্চ ৮টা ছবি দেওয়া যাবে'));
      return;
    }

    try {
      debugPrint('Attempting to pick image...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      debugPrint('Image picked: ${image?.path}');

      if (image != null) {
        setState(() => _isUploadingImage = true);

        debugPrint('Starting image compression...');
        // Compress image using the utility class (target 80KB to match backend requirements)
        final String? compressedBase64 = await ImageCompressor.compressToBase64(
          image,
          targetSize: 80 * 1024, // 80KB target
          verbose: true, // Enable logging
        );

        debugPrint(
            'Compression result: ${compressedBase64 != null ? "Success (${compressedBase64.length} chars)" : "Failed"}');

        if (compressedBase64 != null) {
          final int emptyIndex =
              _imageBase64List.indexWhere((img) => img == null);
          debugPrint('Empty index found: $emptyIndex');

          if (emptyIndex != -1) {
            try {
              // Convert base64 to bytes for display
              final bytes = ImageCompressor.base64ToBytes(compressedBase64);

              if (bytes != null) {
                setState(() {
                  _imageBase64List[emptyIndex] = compressedBase64;
                  _imageBytesList[emptyIndex] = bytes;
                });
                debugPrint('Image added successfully at index $emptyIndex');
                _showSuccessSnackBar(
                    _t('sale_image_uploaded', 'ছবি আপলোড হয়ে গেছে!'));
              } else {
                debugPrint('Failed to decode base64 bytes');
                _showErrorSnackBar(
                    _t('sale_image_process_failed', 'ছবিটা প্রসেস করা গেল না'));
              }
            } catch (decodeError) {
              debugPrint('Error decoding base64: $decodeError');
              _showErrorSnackBar(
                  _t('sale_image_process_failed', 'ছবিটা প্রসেস করা গেল না'));
            }
          } else {
            debugPrint('No empty slot found for image');
          }
        } else {
          debugPrint('Image compression returned null');
          _showErrorSnackBar(
              _t('sale_image_compress_failed', 'ছবিটা কমপ্রেস করা গেল না'));
        }

        setState(() => _isUploadingImage = false);
      } else {
        debugPrint('No image selected');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      setState(() => _isUploadingImage = false);
      _showErrorSnackBar(
          '${_t('sale_image_upload_failed', 'ছবি আপলোড করা গেল না')}: ${e.toString()}');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageBase64List[index] = null;
      _imageBytesList[index] = null;
    });
  }

  Future<void> _submitForm() async {
    setState(() => _checkSubmit = true);

    // Validate form
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar(
          _t('sale_fill_required', 'দরকারি ঘরগুলো সব পূরণ করুন'));
      return;
    }

    // Validate category
    if (_selectedCategory == null) {
      _showErrorSnackBar(_t('sale_select_category', 'একটা ক্যাটাগরি বেছে নিন'));
      return;
    }

    // Validate condition
    if (_selectedCondition == null) {
      _showErrorSnackBar(_t('sale_select_condition', 'কন্ডিশন বেছে নিন'));
      return;
    }

    // Validate price
    if (!_isNegotiable &&
        (_priceController.text.isEmpty ||
            double.tryParse(_priceController.text) == null ||
            double.parse(_priceController.text) <= 0)) {
      _showErrorSnackBar(_t('sale_valid_price',
          'ঠিকঠাক একটা দাম লিখুন, নাহলে দামাদামিতে টিক দিন'));
      return;
    }

    // Validate location
    if (!_allOverBangladesh &&
        (_selectedDivision == null ||
            _selectedDistrict == null ||
            _selectedArea == null)) {
      _showErrorSnackBar(_t('sale_select_location', 'লোকেশন বেছে নিন'));
      return;
    }

    // Validate delivery coverage
    if (!_deliverAllBd && _deliveryLocations.isEmpty) {
      _showErrorSnackBar(_t('sale_dl_required',
          'ডেলিভারি লোকেশন যোগ করুন, নাহলে সারা বাংলাদেশ বেছে নিন'));
      return;
    }

    // Validate images
    final validImages = _imageBase64List.where((img) => img != null).toList();
    if (validImages.isEmpty) {
      _showErrorSnackBar(
          _t('sale_upload_one_image', 'অন্তত একটা ছবি দিতে হবে'));
      return;
    }

    // Validate terms
    if (!_termsAccepted) {
      _showErrorSnackBar(
          _t('sale_accept_terms', 'শর্তগুলোতে রাজি আছেন কিনা টিক দিন'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare data matching Vue format
      final Map<String, dynamic> postData = {
        'category': _selectedCategory,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'condition': _selectedCondition,
        'detailed_address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'negotiable': _isNegotiable,
        'division': _allOverBangladesh ? '' : _selectedDivision,
        'district': _allOverBangladesh ? '' : _selectedDistrict,
        'area': _allOverBangladesh ? '' : _selectedArea,
        // Empty list = deliver all over Bangladesh.
        'delivery_locations': _deliverAllBd ? [] : _deliveryLocations,
        'images': validImages,
      };

      // Add optional fields
      if (_selectedChildCategory != null) {
        postData['child_category'] = _selectedChildCategory;
      }

      if (_emailController.text.trim().isNotEmpty) {
        postData['email'] = _emailController.text.trim();
      }

      // Handle price
      if (_isNegotiable) {
        postData['price'] = _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text)
            : null;
      } else {
        postData['price'] = double.parse(_priceController.text);
      }

      // Create post
      final result = await _salePostService.createSalePost(postData);

      if (result != null && mounted) {
        _showSuccessSnackBar(_t('sale_post_created', 'আপনার পোস্ট হয়ে গেছে!'));
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        _showErrorSnackBar(_t('sale_post_failed', 'পোস্ট করা গেল না'));
      }
    } catch (e) {
      debugPrint('Error submitting form: $e');
      // Show the real backend reason (KYC / validation / limits) instead of a
      // generic "Failed to create post".
      if (mounted) ApiErrorUI.fromError(context, e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    AdsyToast.error(context, message);
  }

  void _showSuccessSnackBar(String message) {
    AdsyToast.success(context, message);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _categories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(_t('sale_create_post', 'নতুন পোস্ট')),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF111827),
          elevation: 0,
        ),
        body: const Center(
          child: AdsyLoadingIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _t('sale_create_sale_post', 'বিক্রির পোস্ট দিন'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              size: 22, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Theme(
        // One compact, professional input style for every field on this form:
        // soft slate borders (no default black), light fill, dense sizing.
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            prefixIconColor: const Color(0xFF94A3B8),
            counterStyle:
                const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF10B981), width: 1.4),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEDF1F5)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFCA5A5)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFDC2626), width: 1.4),
            ),
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Basic Details Section
              _buildSection(
                title: _t('sale_basic_details', 'মূল তথ্য'),
                subtitle: _t('sale_basic_details_sub',
                    'ভালো টাইটেল দিলে ক্রেতা সহজে খুঁজে পাবে'),
                icon: Icons.document_scanner_outlined,
                children: [
                  _buildCategoryDropdown(),
                  if (_childCategories.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildChildCategoryDropdown(),
                  ],
                  const SizedBox(height: 8),
                  _buildTitleField(),
                  const SizedBox(height: 8),
                  _buildDescriptionField(),
                ],
              ),

              // Pricing & Condition Section
              _buildSection(
                title: _t('sale_pricing_condition', 'দাম ও কন্ডিশন'),
                subtitle: _t('sale_pricing_sub',
                    'ন্যায্য দাম দিন — দামাদামির অপশনও রাখতে পারেন'),
                icon: Icons.attach_money_rounded,
                children: [
                  _buildConditionSelection(),
                  const SizedBox(height: 8),
                  _buildPriceField(),
                ],
              ),

              // Upload Photos Section
              _buildSection(
                title: _t('sale_upload_photos', 'ছবি আপলোড করুন'),
                subtitle: _t('sale_photos_sub',
                    'পরিষ্কার ছবি দিলে বিক্রির সম্ভাবনা অনেক বাড়ে'),
                icon: Icons.photo_camera_outlined,
                children: [
                  _buildImageUpload(),
                ],
              ),

              // Item location Section
              _buildSection(
                title: _t('sale_item_location', 'পণ্যটা কোথায় আছে'),
                subtitle: _t('sale_item_location_sub',
                    'ক্রেতা কাছাকাছি খোঁজে — সঠিক লোকেশন দিন'),
                icon: Icons.location_on_outlined,
                children: [
                  _buildLocationFields(),
                  const SizedBox(height: 8),
                  _buildAddressField(),
                ],
              ),

              // Delivery coverage Section
              _buildSection(
                title: _t(
                    'sale_delivery_coverage', 'কোথায় কোথায় ডেলিভারি দেবেন'),
                subtitle: _t('sale_delivery_coverage_sub',
                    'এক বা একাধিক বিভাগ/জেলা যোগ করতে পারবেন'),
                icon: Icons.local_shipping_outlined,
                children: [
                  _buildDeliveryCoverage(),
                ],
              ),

              // Contact Information Section
              _buildSection(
                title: _t('sale_contact_info', 'যোগাযোগের তথ্য'),
                subtitle: _t('sale_contact_sub',
                    'আগ্রহী ক্রেতা এই নাম্বারে যোগাযোগ করবে'),
                icon: Icons.phone_outlined,
                children: [
                  _buildPhoneField(),
                  const SizedBox(height: 8),
                  _buildEmailField(),
                ],
              ),

              const SizedBox(height: 8),

              // Terms Section
              _buildTermsSection(),

              const SizedBox(height: 16),

              // Submit Button
              _buildSubmitButton(),

              // Safe area bottom padding for devices with gesture navigation
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    // Flat section — no card box; a hairline under each section separates
    // them, matching the stripe style used across the app.
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 6),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF059669), size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF64748B)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: '${_t('sale_category', 'ক্যাটাগরি')} *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.category, size: 20),
      ),
      items: _categories.map<DropdownMenuItem<int>>((category) {
        return DropdownMenuItem<int>(
          value: category['id'],
          child: Text(category['name'] ?? ''),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
          _selectedChildCategory = null;
          _childCategories = [];
        });
        if (value != null) {
          _loadChildCategories(value);
        }
      },
      validator: (value) => value == null && _checkSubmit
          ? _t('sale_required', 'এটা দিতে হবে')
          : null,
    );
  }

  Widget _buildChildCategoryDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedChildCategory,
      decoration: InputDecoration(
        labelText: _t('sale_sub_category', 'সাব ক্যাটাগরি'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.subdirectory_arrow_right, size: 20),
      ),
      items: _childCategories.map<DropdownMenuItem<int>>((category) {
        return DropdownMenuItem<int>(
          value: category['id'],
          child: Text(category['name'] ?? ''),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedChildCategory = value),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: '${_t('sale_field_title', 'টাইটেল')} *',
        hintText: _t('sale_title_hint', 'কী বিক্রি করছেন?'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.title, size: 20),
        counterText: '${_titleController.text.length}/100',
      ),
      maxLength: 100,
      validator: (value) =>
          value == null || value.trim().isEmpty && _checkSubmit
              ? _t('sale_required', 'এটা দিতে হবে')
              : null,
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: '${_t('sale_description', 'ডিটেইলস')} *',
        hintText: _t('sale_description_hint', 'জিনিসটার খুঁটিনাটি সব লিখুন'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        counterText: '${_descriptionController.text.length}/1000',
      ),
      maxLines: 5,
      maxLength: 1000,
      validator: (value) =>
          value == null || value.trim().isEmpty && _checkSubmit
              ? _t('sale_required', 'এটা দিতে হবে')
              : null,
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildConditionSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_t('sale_condition', 'কন্ডিশন')} *',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _conditions.map((condition) {
            final isSelected = _selectedCondition == condition['value'];
            // Compact pill chips — no oversized material chip padding.
            return InkWell(
              onTap: () => setState(() =>
                  _selectedCondition = isSelected ? null : condition['value']),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  condition['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: '${_t('sale_price', 'দাম')} *',
              hintText: _t('sale_price_hint', 'যেমন: ১০০০'),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixText: '৳ ',
              prefixIcon: const Icon(Icons.monetization_on_outlined, size: 20),
            ),
            keyboardType: TextInputType.number,
            enabled: !_isNegotiable,
            validator: (value) {
              if (_isNegotiable) return null;
              if (_checkSubmit && (value == null || value.isEmpty)) {
                return _t('sale_required', 'এটা দিতে হবে');
              }
              final parsedValue = double.tryParse(value ?? '');
              if (_checkSubmit && parsedValue == null) {
                return _t('sale_invalid', 'ঠিক হয়নি');
              }
              if (_checkSubmit && parsedValue! <= 0) {
                return _t('sale_must_be_positive', '০ এর বেশি দিন');
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 10),
        // Compact negotiable toggle
        InkWell(
          onTap: () => setState(() => _isNegotiable = !_isNegotiable),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: _isNegotiable
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isNegotiable
                    ? const Color(0xFF6EE7B7)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isNegotiable
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 17,
                  color: _isNegotiable
                      ? const Color(0xFF059669)
                      : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 5),
                Text(
                  _t('sale_negotiable_short', 'দামাদামি চলবে'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _isNegotiable
                        ? const Color(0xFF065F46)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('sale_add_photos_hint',
              'জিনিসের ছবি দিন, ছবি ভালো হলে তাড়াতাড়ি বিক্রি হয় (সর্বোচ্চ ৮টা)'),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            // Display uploaded images
            for (int i = 0; i < 8; i++)
              if (_imageBytesList[i] != null)
                _buildImageThumbnail(i)
              else if (_imageBytesList.where((img) => img != null).length < 8 &&
                  i == _imageBytesList.where((img) => img != null).length)
                _buildUploadButton(),
          ],
        ),
        if (_isUploadingImage)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: AdsyLoadingIndicator(
                      strokeWidth: 2, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 8),
                Text(
                  _t('sale_processing_image', 'ছবি প্রসেস হচ্ছে...'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImageThumbnail(int index) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.memory(
              _imageBytesList[index]!,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: EdgeInsets.zero,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.red),
              ),
            ),
          ),
          // Main image badge
          if (index == 0)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _t('sale_main_photo', 'মেইন'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: _isUploadingImage ? null : _pickImage,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: const Color(0xFF10B981),
              width: 2,
              style: BorderStyle.solid),
          color: const Color(0xFF10B981).withValues(alpha: 0.05),
        ),
        child: _isUploadingImage
            ? const Center(
                child: AdsyLoadingIndicator(
                  color: Color(0xFF10B981),
                  strokeWidth: 2,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: const Color(0xFF10B981),
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t('sale_add_photo', 'ছবি দিন'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _dlPickDivision(String? division) async {
    setState(() {
      _dlDivision = division;
      _dlDistrict = null;
      _dlDistricts = [];
    });
    if (division == null) return;
    setState(() => _dlLoadingDistricts = true);
    try {
      final districts = await _salePostService.fetchDistricts(division);
      if (mounted) setState(() => _dlDistricts = districts);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _dlLoadingDistricts = false);
    }
  }

  void _dlAddLocation() {
    if (_dlDivision == null) {
      _showErrorSnackBar(
          _t('sale_dl_pick_division', 'আগে একটা বিভাগ বেছে নিন'));
      return;
    }
    final entry = <String, String>{
      'division': _dlDivision!,
      if (_dlDistrict != null && _dlDistrict!.isNotEmpty)
        'district': _dlDistrict!,
    };
    final exists = _deliveryLocations.any((e) =>
        e['division'] == entry['division'] &&
        (e['district'] ?? '') == (entry['district'] ?? ''));
    if (exists) {
      _showErrorSnackBar(
          _t('sale_dl_already_added', 'এই লোকেশন আগেই যোগ করা আছে'));
      return;
    }
    if (_deliveryLocations.length >= 10) {
      _showErrorSnackBar(
          _t('sale_dl_max', 'সর্বোচ্চ ১০টা লোকেশন যোগ করা যাবে'));
      return;
    }
    setState(() {
      _deliveryLocations.add(entry);
      _dlDivision = null;
      _dlDistrict = null;
      _dlDistricts = [];
    });
  }

  // Radio-style option card for the delivery-mode choice.
  Widget _deliveryModeOption({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    const green = Color(0xFF059669);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF6EE7B7) : const Color(0xFFE2E8F0),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio circle
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? green : const Color(0xFF94A3B8),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: green,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Icon(icon,
                size: 19, color: selected ? green : const Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? const Color(0xFF065F46)
                            : const Color(0xFF1F2937)),
                  ),
                  Text(
                    subtitle,
                    style:
                        const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCoverage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Delivery mode — proper radio pair
        _deliveryModeOption(
          selected: _deliverAllBd,
          icon: Icons.public_rounded,
          title: _t('sale_deliver_all_bd', 'সারা বাংলাদেশে ডেলিভারি'),
          subtitle: _t(
              'sale_deliver_all_bd_sub', 'দেশের যেকোনো জায়গায় পাঠাতে পারবেন'),
          onTap: () => setState(() => _deliverAllBd = true),
        ),
        const SizedBox(height: 8),
        _deliveryModeOption(
          selected: !_deliverAllBd,
          icon: Icons.pin_drop_rounded,
          title: _t('sale_deliver_custom', 'নির্দিষ্ট এলাকায় ডেলিভারি'),
          subtitle:
              _t('sale_deliver_custom_sub', 'এক বা একাধিক বিভাগ/জেলা বেছে দিন'),
          onTap: () => setState(() => _deliverAllBd = false),
        ),

        // Specific locations picker
        if (!_deliverAllBd) ...[
          const SizedBox(height: 12),

          // Added location chips
          if (_deliveryLocations.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _deliveryLocations.map((loc) {
                final label = loc['district'] != null
                    ? '${loc['district']}, ${loc['division']}'
                    : '${loc['division']} (${_t('sale_dl_whole_division', 'পুরো বিভাগ')})';
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: Color(0xFF059669)),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF065F46)),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () =>
                            setState(() => _deliveryLocations.remove(loc)),
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: Color(0xFF059669)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Division + optional district pickers
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _dlDivision,
                  isExpanded: true,
                  decoration: _dlInputDecoration(
                    _t('sale_division', 'বিভাগ'),
                  ),
                  items: _divisions.map<DropdownMenuItem<String>>((division) {
                    return DropdownMenuItem(
                      value: division['name_eng'],
                      child: Text(division['name_eng'] ?? '',
                          style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: _dlPickDivision,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _dlDistrict,
                  isExpanded: true,
                  decoration: _dlInputDecoration(
                    '${_t('sale_district', 'জেলা')} (${_t('sale_optional', 'অপশনাল')})',
                    loading: _dlLoadingDistricts,
                  ),
                  items: _dlDistricts.map<DropdownMenuItem<String>>((d) {
                    return DropdownMenuItem(
                      value: d['name_eng'],
                      child: Text(d['name_eng'] ?? '',
                          style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: _dlDivision == null
                      ? null
                      : (v) => setState(() => _dlDistrict = v),
                ),
              ),
            ],
          ),
          // Add button appears once a division is picked
          if (_dlDivision != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _dlAddLocation,
                icon: const Icon(Icons.add_location_alt_rounded, size: 17),
                label: Text(
                  _dlDistrict != null
                      ? _t('sale_dl_add_district', 'এই জেলা যোগ করুন')
                      : _t('sale_dl_add_division', 'পুরো বিভাগ যোগ করুন'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  // eShop-add-product style filled input, in marketplace green.
  InputDecoration _dlInputDecoration(String label, {bool loading = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.4),
      ),
      suffixIcon: loading
          ? const Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                width: 14,
                height: 14,
                child: AdsyLoadingIndicator(
                    strokeWidth: 2, color: Color(0xFF10B981)),
              ),
            )
          : null,
    );
  }

  Widget _buildLocationFields() {
    return Column(
      children: [
        CheckboxListTile(
          title: Text(_t('sale_all_over_bangladesh', 'সারা বাংলাদেশ')),
          value: _allOverBangladesh,
          onChanged: (value) {
            setState(() {
              _allOverBangladesh = value ?? false;
              if (_allOverBangladesh) {
                _selectedDivision = null;
                _selectedDistrict = null;
                _selectedArea = null;
              }
            });
          },
          activeColor: const Color(0xFF10B981),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (!_allOverBangladesh) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedDivision,
            decoration: InputDecoration(
              labelText: '${_t('sale_division', 'বিভাগ')} *',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.map_outlined, size: 18),
            ),
            items: _divisions.map<DropdownMenuItem<String>>((division) {
              return DropdownMenuItem<String>(
                value: division['name_eng'],
                child: Text(division['name_eng'] ?? ''),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDivision = value;
                _selectedDistrict = null;
                _selectedArea = null;
              });
              if (value != null) {
                _loadDistricts(value);
              }
            },
            validator: (value) =>
                !_allOverBangladesh && value == null && _checkSubmit
                    ? _t('sale_required', 'এটা দিতে হবে')
                    : null,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedDistrict,
            decoration: InputDecoration(
              labelText: '${_t('sale_district', 'জেলা')} *',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.location_city_outlined, size: 18),
            ),
            items: _districts.map<DropdownMenuItem<String>>((district) {
              return DropdownMenuItem<String>(
                value: district['name_eng'],
                child: Text(district['name_eng'] ?? ''),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDistrict = value;
                _selectedArea = null;
              });
              if (value != null) {
                _loadAreas(value);
              }
            },
            validator: (value) =>
                !_allOverBangladesh && value == null && _checkSubmit
                    ? _t('sale_required', 'এটা দিতে হবে')
                    : null,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedArea,
            decoration: InputDecoration(
              labelText: '${_t('sale_area', 'এলাকা')} *',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.place_outlined, size: 18),
            ),
            items: _areas.map<DropdownMenuItem<String>>((area) {
              return DropdownMenuItem<String>(
                value: area['name_eng'],
                child: Text(area['name_eng'] ?? ''),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedArea = value),
            validator: (value) =>
                !_allOverBangladesh && value == null && _checkSubmit
                    ? _t('sale_required', 'এটা দিতে হবে')
                    : null,
          ),
        ],
      ],
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      decoration: InputDecoration(
        labelText: '${_t('sale_detailed_address', 'পুরো ঠিকানা')} *',
        hintText: _t('sale_address_hint', 'ঠিকানাটা একটু খুলে লিখুন...'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.home_outlined, size: 20),
      ),
      maxLines: 3,
      validator: (value) =>
          value == null || value.trim().isEmpty && _checkSubmit
              ? _t('sale_required', 'এটা দিতে হবে')
              : null,
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: '${_t('sale_phone_number', 'ফোন নাম্বার')} *',
        hintText: '01XXXXXXXXX',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.phone, size: 20),
      ),
      keyboardType: TextInputType.phone,
      maxLength: 11,
      validator: (value) {
        if (_checkSubmit && (value == null || value.trim().isEmpty)) {
          return _t('sale_required', 'এটা দিতে হবে');
        }
        if (_checkSubmit && value!.length != 11) {
          return _t('sale_phone_11_digits', '১১ ডিজিটের নাম্বার দিন');
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: _t('sale_email_optional', 'ইমেইল (না দিলেও চলবে)'),
        hintText: 'your@email.com',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.email_outlined, size: 20),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildTermsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: CheckboxListTile(
        title: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
            children: [
              TextSpan(text: _t('sale_agree_prefix', 'আমি ')),
              TextSpan(
                text: _t('sale_terms_conditions', 'শর্তাবলী'),
                style: const TextStyle(
                    color: Color(0xFF10B981), fontWeight: FontWeight.w600),
              ),
              TextSpan(text: _t('sale_and', ' আর ')),
              TextSpan(
                text: _t('sale_privacy_policy', 'প্রাইভেসি পলিসি'),
                style: const TextStyle(
                    color: Color(0xFF10B981), fontWeight: FontWeight.w600),
              ),
              TextSpan(text: _t('sale_agree_suffix', ' মেনে নিচ্ছি')),
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        value: _termsAccepted,
        onChanged: (value) => setState(() => _termsAccepted = value ?? false),
        activeColor: const Color(0xFF10B981),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: AdsyLoadingIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _t('sale_post_your_ad', 'বিজ্ঞাপন পোস্ট করুন'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}
