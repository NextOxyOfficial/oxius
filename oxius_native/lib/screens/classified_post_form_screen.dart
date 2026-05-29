import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../models/classified_post.dart';
import '../models/classified_post_form.dart';
import '../models/geo_location.dart';
import '../services/classified_post_service.dart';
import '../services/geo_location_service.dart';
import '../services/api_service.dart';
import '../widgets/geo_selector_dialog.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

const _indigo = Color(0xFF6366F1);
const _violet = Color(0xFF8B5CF6);
const _emerald = Color(0xFF10B981);
const _slate50 = Color(0xFFF8FAFC);
const _slate100 = Color(0xFFF1F5F9);
const _slate200 = Color(0xFFE2E8F0);
const _slate300 = Color(0xFFCBD5E1);
const _slate400 = Color(0xFF94A3B8);
const _slate500 = Color(0xFF64748B);
const _slate700 = Color(0xFF334155);
const _slate800 = Color(0xFF1E293B);

class ClassifiedPostFormScreen extends StatefulWidget {
  final String? postId;
  final String? categoryId;

  const ClassifiedPostFormScreen({
    Key? key,
    this.postId,
    this.categoryId,
  }) : super(key: key);

  @override
  State<ClassifiedPostFormScreen> createState() =>
      _ClassifiedPostFormScreenState();
}

class _ClassifiedPostFormScreenState extends State<ClassifiedPostFormScreen> {
  late final ClassifiedPostService _postService;
  late final GeoLocationService _geoService;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _negotiable = false;
  bool _acceptedPrivacy = false;

  List<CategoryDetails> _categories = [];
  String? _selectedCategoryId;

  GeoLocation? _location;
  List<dynamic> _selectedImages =
      []; // Mix of URLs, File objects, and XFile objects

  String?
      _actualPostId; // Store the actual UUID for updates (different from slug)

  bool get _isEditMode => widget.postId != null;

  @override
  void initState() {
    super.initState();
    _postService = ClassifiedPostService(baseUrl: ApiService.baseUrl);
    _geoService = GeoLocationService(baseUrl: ApiService.baseUrl);
    _selectedCategoryId = widget.categoryId;
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    try {
      // Load categories
      _categories = await _postService.fetchAllCategories();

      // Load saved location
      _location = await _geoService.getSavedLocation();

      // Load existing post data if editing
      if (_isEditMode) {
        await _loadPostData();
      }
    } catch (e) {
      _showError('Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPostData() async {
    try {
      print('Loading post data for ID: ${widget.postId}');
      final postData = await _postService.fetchPostForEdit(widget.postId!);

      if (postData == null) {
        print('ERROR: Post data is null!');
        _showError('Failed to load post data');
        return;
      }

      print('Post data loaded: ${postData.title}');
      print('Post ID (UUID): ${postData.id}');
      print('Category ID: ${postData.categoryId}');
      print('Images count: ${postData.medias.length}');

      if (mounted) {
        setState(() {
          // Store the actual UUID for updates (important!)
          _actualPostId = postData.id;

          _titleController.text = postData.title;
          _instructionsController.text = postData.instructions;
          _priceController.text =
              postData.price > 0 ? postData.price.toString() : '';
          _negotiable = postData.negotiable;
          _selectedCategoryId = postData.categoryId;
          _acceptedPrivacy = postData.acceptedPrivacy;
          _selectedImages = List<dynamic>.from(postData.medias);

          // Load location
          if (postData.state != null ||
              postData.city != null ||
              postData.upazila != null) {
            _location = GeoLocation(
              country: postData.country,
              state: postData.state,
              city: postData.city,
              upazila: postData.upazila,
            );
          }
        });
      }
    } catch (e) {
      _showError('Failed to load post data: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isNotEmpty && mounted) {
        setState(() {
          for (var image in images) {
            if (_selectedImages.length < 5) {
              // Store XFile directly for cross-platform compatibility
              _selectedImages.add(image);
            }
          }
        });
      }
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  Widget _buildImageWidget(dynamic image) {
    // Handle URL strings (from existing posts)
    if (image is String) {
      return Image.network(image, fit: BoxFit.cover);
    }

    // Handle XFile (from image picker)
    if (image is XFile) {
      if (kIsWeb) {
        // On web, use Image.network with the file path
        return Image.network(image.path, fit: BoxFit.cover);
      } else {
        // On mobile, convert XFile to File
        return Image.file(File(image.path), fit: BoxFit.cover);
      }
    }

    // Handle File objects (shouldn't happen on web, but kept for backwards compatibility)
    if (image is File) {
      return Image.file(image, fit: BoxFit.cover);
    }

    // Fallback
    return const Icon(Icons.image, size: 40, color: Colors.grey);
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// Convert images to base64 strings for API submission
  Future<List<String>> _convertImagesToBase64() async {
    List<String> base64Images = [];

    for (var image in _selectedImages) {
      try {
        // If it's already a URL string (existing image), skip conversion
        if (image is String) {
          // Keep existing URLs as-is (backend will handle them)
          continue;
        }

        // Convert XFile to base64
        if (image is XFile) {
          final bytes = await image.readAsBytes();
          final base64String = base64Encode(bytes);

          // Get file extension
          final extension = image.path.split('.').last.toLowerCase();
          String mimeType = 'image/jpeg';
          if (extension == 'png')
            mimeType = 'image/png';
          else if (extension == 'jpg' || extension == 'jpeg')
            mimeType = 'image/jpeg';
          else if (extension == 'gif')
            mimeType = 'image/gif';
          else if (extension == 'webp') mimeType = 'image/webp';

          // Format as data URL
          final dataUrl = 'data:$mimeType;base64,$base64String';
          base64Images.add(dataUrl);
        }
        // Convert File to base64 (mobile platforms)
        else if (image is File) {
          final bytes = await image.readAsBytes();
          final base64String = base64Encode(bytes);

          // Get file extension
          final extension = image.path.split('.').last.toLowerCase();
          String mimeType = 'image/jpeg';
          if (extension == 'png')
            mimeType = 'image/png';
          else if (extension == 'jpg' || extension == 'jpeg')
            mimeType = 'image/jpeg';
          else if (extension == 'gif')
            mimeType = 'image/gif';
          else if (extension == 'webp') mimeType = 'image/webp';

          // Format as data URL
          final dataUrl = 'data:$mimeType;base64,$base64String';
          base64Images.add(dataUrl);
        }
      } catch (e) {
        print('Error converting image to base64: $e');
      }
    }

    return base64Images;
  }

  Future<void> _showLocationSelector() async {
    final selectedLocation = await showModalBottomSheet<GeoLocation>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => GeoSelectorDialog(
        initialLocation: _location,
        onLocationSelected: (location) {},
      ),
    );

    if (selectedLocation != null && mounted) {
      setState(() => _location = selectedLocation);
      await _geoService.saveLocation(selectedLocation);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      _showError('Please select a category');
      return;
    }

    if (!_acceptedPrivacy) {
      _showError('Please accept the terms and conditions');
      return;
    }

    if (_location == null ||
        (!_location!.allOverBangladesh &&
            (_location!.state == null ||
                _location!.city == null ||
                _location!.upazila == null))) {
      _showError('Please select your location');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Convert images to base64 before submission
      print('Converting ${_selectedImages.length} images to base64...');
      final base64Images = await _convertImagesToBase64();
      print('Converted ${base64Images.length} images successfully');

      // Build location string from geo data
      String locationString = '';
      if (_location!.allOverBangladesh) {
        locationString = 'All Over Bangladesh';
      } else {
        final locationParts = <String>[];
        if (_location!.upazila != null && _location!.upazila!.isNotEmpty) {
          locationParts.add(_location!.upazila!);
        }
        if (_location!.city != null && _location!.city!.isNotEmpty) {
          locationParts.add(_location!.city!);
        }
        if (_location!.state != null && _location!.state!.isNotEmpty) {
          locationParts.add(_location!.state!);
        }
        locationString = locationParts.join(', ');
      }

      final form = ClassifiedPostForm(
        // Use actual UUID for updates, widget.postId might be a slug
        id: _isEditMode ? (_actualPostId ?? widget.postId) : null,
        categoryId: _selectedCategoryId,
        title: _titleController.text.trim(),
        instructions: _instructionsController.text.trim(),
        price: _negotiable ? 0 : (double.tryParse(_priceController.text) ?? 0),
        negotiable: _negotiable,
        country: _location!.country,
        state: _location!.state,
        city: _location!.city,
        upazila: _location!.upazila,
        location: locationString,
        medias: base64Images,
        acceptedPrivacy: _acceptedPrivacy,
      );

      print('Form created, submitting to API...');
      Map<String, dynamic>? response;

      if (_isEditMode) {
        // Use actual UUID for update API call
        final postIdForUpdate = _actualPostId ?? widget.postId!;
        print('Updating post with UUID: $postIdForUpdate');
        response = await _postService.updatePost(postIdForUpdate, form);
      } else {
        response = await _postService.createPost(form);
      }

      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Post updated successfully!'
                : 'Post created successfully!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        _showError('Failed to ${_isEditMode ? 'update' : 'create'} post');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: _slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_indigo, _violet]),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isEditMode ? 'Edit Post' : 'Create Post',
              style: GoogleFonts.inter(
                color: _slate800,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_rounded, color: _slate800, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: AdsyLoadingIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_indigo),
                strokeWidth: 2,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(isMobile),
                  _buildFormShell(isMobile),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _indigo.withValues(alpha: 0.12),
            _violet.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _indigo.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_indigo, _violet]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isEditMode
                  ? Icons.edit_note_rounded
                  : Icons.add_business_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditMode
                      ? 'Update Your Post'
                      : 'Create New Classified Post',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w700,
                    color: _slate800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Add clear details, pricing, location and photos to attract the right buyers fast',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _slate500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormShell(bool isMobile) {
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildSectionCard(
              title: 'Basic Details',
              icon: Icons.description_outlined,
              child: Column(
                children: [
                  _buildCategorySelector(),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _titleController,
                    label: 'Post Title',
                    hint: 'Enter a descriptive title',
                    required: true,
                    maxLength: 100,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _instructionsController,
                    label: 'Description',
                    hint: 'Provide detailed information',
                    maxLines: 5,
                    maxLength: 5000,
                  ),
                ],
              ),
            ),
            _buildSectionCard(
              title: 'Pricing',
              icon: Icons.sell_outlined,
              child: _buildPriceSection(),
            ),
            _buildSectionCard(
              title: 'Location',
              icon: Icons.location_on_outlined,
              child: _buildLocationSelector(),
            ),
            _buildSectionCard(
              title: 'Photos',
              icon: Icons.photo_library_outlined,
              child: _buildImageUploadSection(),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _slate200),
                    ),
                    child: _buildPrivacyCheckbox(),
                  ),
                  const SizedBox(height: 16),
                  _buildSubmitButton(),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _slate200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _indigo, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _slate800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Category',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _slate700,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategoryId,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _slate200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _slate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _indigo, width: 1.8),
            ),
            filled: true,
            fillColor: _slate50,
            hintText: 'Select a category',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: _slate400),
            prefixIcon:
                const Icon(Icons.grid_view_rounded, size: 18, color: _slate400),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _slate500, size: 18),
          dropdownColor: Colors.white,
          style: GoogleFonts.inter(
              fontSize: 13, color: _slate800, fontWeight: FontWeight.w500),
          items: _categories.map((category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.title),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedCategoryId = value),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _slate700,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
              fontSize: 13, color: _slate800, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: _slate400,
              fontSize: 12,
            ),
            filled: true,
            fillColor: _slate50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _slate200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _slate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _indigo, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            counterStyle: GoogleFonts.inter(fontSize: 10, color: _slate400),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a fixed price or mark the post as negotiable.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: _slate500,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => setState(() => _negotiable = !_negotiable),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _negotiable ? _emerald.withValues(alpha: 0.08) : _slate50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _negotiable ? _emerald : _slate300,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _negotiable ? _emerald : Colors.white,
                    border: Border.all(
                      color: _negotiable ? _emerald : _slate300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: _negotiable
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Price is negotiable',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _slate700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!_negotiable) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: GoogleFonts.inter(
                fontSize: 13, color: _slate800, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Enter price',
              prefixText: '৳ ',
              prefixStyle: GoogleFonts.inter(
                color: _slate800,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              hintStyle: GoogleFonts.inter(
                color: _slate400,
                fontSize: 13,
              ),
              filled: true,
              fillColor: _slate50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _slate200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _slate200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _indigo, width: 1.8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (value) {
              if (!_negotiable && (value == null || value.trim().isEmpty)) {
                return 'Please enter a price or mark as negotiable';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Select your location',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _slate700,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showLocationSelector,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _slate50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _slate200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: _emerald,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _location == null
                        ? 'Select your location'
                        : _location!.allOverBangladesh
                            ? 'All over Bangladesh'
                            : [
                                _location!.upazila,
                                _location!.city,
                                _location!.state
                              ]
                                .where((e) => e != null && e.isNotEmpty)
                                .join(', '),
                    style: TextStyle(
                      fontSize: 13,
                      color: _location == null ? _slate400 : _slate700,
                      fontWeight:
                          _location == null ? FontWeight.w400 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: _slate400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add up to 5 photos',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _slate700,
              ),
            ),
            Text(
              '${_selectedImages.length}/5',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _slate500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Image Grid
        if (_selectedImages.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                return _buildImageThumbnail(image, index);
              }),
              if (_selectedImages.length < 5) _buildAddImageButton(),
            ],
          )
        else
          _buildAddImageButton(),
      ],
    );
  }

  Widget _buildImageThumbnail(dynamic image, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 80,
            height: 80,
            color: _slate100,
            child: _buildImageWidget(image),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: _slate50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _slate300,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: _slate400,
              size: 28,
            ),
            const SizedBox(height: 3),
            Text(
              'Add',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: _slate500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyCheckbox() {
    return InkWell(
      onTap: () => setState(() => _acceptedPrivacy = !_acceptedPrivacy),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: _acceptedPrivacy ? _emerald : Colors.white,
              border: Border.all(
                color: _acceptedPrivacy ? _emerald : _slate300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: _acceptedPrivacy
                ? const Icon(Icons.check, color: Colors.white, size: 12)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _slate500,
                  height: 1.3,
                ),
                children: [
                  const TextSpan(text: 'I accept the '),
                  TextSpan(
                    text: 'Terms and Conditions',
                    style: const TextStyle(
                      color: _emerald,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      color: _emerald,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: _indigo,
          disabledBackgroundColor: _slate200,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 18,
                width: 18,
                child: AdsyLoadingIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isEditMode ? 'Update Post' : 'Create Post',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
