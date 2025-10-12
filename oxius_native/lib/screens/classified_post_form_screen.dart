import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

class ClassifiedPostFormScreen extends StatefulWidget {
  final String? postId;
  final String? categoryId;
  
  const ClassifiedPostFormScreen({
    Key? key,
    this.postId,
    this.categoryId,
  }) : super(key: key);

  @override
  State<ClassifiedPostFormScreen> createState() => _ClassifiedPostFormScreenState();
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
  List<dynamic> _selectedImages = []; // Mix of URLs, File objects, and XFile objects
  
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
      final postData = await _postService.fetchPostForEdit(widget.postId!);
      if (postData != null && mounted) {
        setState(() {
          _titleController.text = postData.title;
          _instructionsController.text = postData.instructions;
          _priceController.text = postData.price > 0 ? postData.price.toString() : '';
          _negotiable = postData.negotiable;
          _selectedCategoryId = postData.categoryId;
          _acceptedPrivacy = postData.acceptedPrivacy;
          _selectedImages = List<dynamic>.from(postData.medias);
          
          // Load location
          if (postData.state != null || postData.city != null || postData.upazila != null) {
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
          if (extension == 'png') mimeType = 'image/png';
          else if (extension == 'jpg' || extension == 'jpeg') mimeType = 'image/jpeg';
          else if (extension == 'gif') mimeType = 'image/gif';
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
          if (extension == 'png') mimeType = 'image/png';
          else if (extension == 'jpg' || extension == 'jpeg') mimeType = 'image/jpeg';
          else if (extension == 'gif') mimeType = 'image/gif';
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
    final selectedLocation = await showDialog<GeoLocation>(
      context: context,
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
         (_location!.state == null || _location!.city == null || _location!.upazila == null))) {
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
        id: widget.postId,
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
        response = await _postService.updatePost(widget.postId!, form);
      } else {
        response = await _postService.createPost(form);
      }

      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Post updated successfully!' : 'Post created successfully!'),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        title: Text(
          _isEditMode ? 'Edit Post' : 'Create New Post',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category Selector
                    _buildCategorySelector(),
                    
                    const SizedBox(height: 14),
                    
                    // Title Field
                    _buildTextField(
                      controller: _titleController,
                      label: 'Post Title',
                      hint: 'Enter a descriptive title',
                      required: true,
                      maxLength: 100,
                    ),
                    
                    const SizedBox(height: 14),
                    
                    // Description Field
                    _buildTextField(
                      controller: _instructionsController,
                      label: 'Description',
                      hint: 'Provide detailed information',
                      maxLines: 5,
                      maxLength: 5000,
                    ),
                    
                    const SizedBox(height: 14),
                    
                    // Price Section
                    _buildPriceSection(),
                    
                    const SizedBox(height: 14),
                    
                    // Location Selector
                    _buildLocationSelector(),
                    
                    const SizedBox(height: 14),
                    
                    // Image Upload Section
                    _buildImageUploadSection(),
                    
                    const SizedBox(height: 14),
                    
                    // Privacy Checkbox
                    _buildPrivacyCheckbox(),
                    
                    const SizedBox(height: 20),
                    
                    // Submit Button
                    _buildSubmitButton(),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: InputBorder.none,
              hintText: 'Select a category',
              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280), size: 20),
            dropdownColor: Colors.white,
            items: _categories.map((category) {
              return DropdownMenuItem<String>(
                value: category.id,
                child: Text(
                  category.title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                ),
              );
            }).toList(),
            onChanged: widget.categoryId == null
                ? (value) => setState(() => _selectedCategoryId = value)
                : null,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a category';
              }
              return null;
            },
          ),
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            counterStyle: const TextStyle(fontSize: 11),
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
        const Text(
          'Price',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        
        // Negotiable Checkbox
        InkWell(
          onTap: () => setState(() => _negotiable = !_negotiable),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _negotiable ? const Color(0xFF10B981).withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _negotiable ? const Color(0xFF10B981) : const Color(0xFFD1D5DB),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _negotiable ? const Color(0xFF10B981) : Colors.white,
                    border: Border.all(
                      color: _negotiable ? const Color(0xFF10B981) : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: _negotiable
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Price is negotiable',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
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
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Enter price',
              prefixText: '৳ ',
              prefixStyle: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        Row(
          children: [
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _showLocationSelector,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _location == null
                        ? 'Select your location'
                        : _location!.allOverBangladesh
                            ? 'All over Bangladesh'
                            : [_location!.upazila, _location!.city, _location!.state]
                                .where((e) => e != null && e.isNotEmpty)
                                .join(', '),
                    style: TextStyle(
                      fontSize: 13,
                      color: _location == null ? const Color(0xFF9CA3AF) : const Color(0xFF374151),
                      fontWeight: _location == null ? FontWeight.w400 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
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
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            Text(
              '${_selectedImages.length}/5',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
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
            color: const Color(0xFFF3F4F6),
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
                color: Colors.red.withOpacity(0.9),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFD1D5DB),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: Colors.grey[400],
              size: 28,
            ),
            const SizedBox(height: 3),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
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
              color: _acceptedPrivacy ? const Color(0xFF10B981) : Colors.white,
              border: Border.all(
                color: _acceptedPrivacy ? const Color(0xFF10B981) : const Color(0xFFD1D5DB),
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
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  height: 1.3,
                ),
                children: [
                  TextSpan(text: 'I accept the '),
                  TextSpan(
                    text: 'Terms and Conditions',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFF10B981),
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
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        disabledBackgroundColor: const Color(0xFFE5E7EB),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              _isEditMode ? 'Update Post' : 'Create Post',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    );
  }
}
