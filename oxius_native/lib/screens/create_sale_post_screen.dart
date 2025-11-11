import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/sale_post_service.dart';
import '../services/api_service.dart';
import '../utils/image_compressor.dart';

class CreateSalePostScreen extends StatefulWidget {
  const CreateSalePostScreen({Key? key}) : super(key: key);

  @override
  State<CreateSalePostScreen> createState() => _CreateSalePostScreenState();
}

class _CreateSalePostScreenState extends State<CreateSalePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final SalePostService _salePostService = SalePostService(baseUrl: ApiService.baseUrl);
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
  
  // Images
  List<String?> _imageBase64List = List.filled(8, null);
  List<Uint8List?> _imageBytesList = List.filled(8, null);
  
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
      print('Error loading initial data: $e');
      _showErrorSnackBar('Failed to load form data');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadCategories() async {
    try {
      final categories = await _salePostService.fetchCategoriesForForm();
      setState(() => _categories = categories);
    } catch (e) {
      print('Error loading categories: $e');
    }
  }
  
  Future<void> _loadConditions() async {
    // Default conditions matching Vue
    setState(() {
      _conditions = [
        {'label': 'Brand New', 'value': 'brand-new'},
        {'label': 'Like New', 'value': 'like-new'},
        {'label': 'Good', 'value': 'good'},
        {'label': 'Fair', 'value': 'fair'},
        {'label': 'For Parts', 'value': 'for-parts'},
      ];
    });
  }
  
  Future<void> _loadDivisions() async {
    try {
      final divisions = await _salePostService.fetchDivisions();
      setState(() => _divisions = divisions);
    } catch (e) {
      print('Error loading divisions: $e');
    }
  }
  
  Future<void> _loadChildCategories(int parentId) async {
    try {
      final childCategories = await _salePostService.fetchChildCategories(parentId);
      setState(() {
        _childCategories = childCategories;
        _selectedChildCategory = null;
      });
    } catch (e) {
      print('Error loading child categories: $e');
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
      print('Error loading districts: $e');
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
      print('Error loading areas: $e');
    }
  }
  
  Future<void> _pickImage() async {
    if (_imageBase64List.where((img) => img != null).length >= 8) {
      _showErrorSnackBar('Maximum 8 images allowed');
      return;
    }
    
    try {
      print('Attempting to pick image...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      
      print('Image picked: ${image?.path}');
      
      if (image != null) {
        setState(() => _isUploadingImage = true);
        
        print('Starting image compression...');
        // Compress image using the utility class (target 80KB to match backend requirements)
        final String? compressedBase64 = await ImageCompressor.compressToBase64(
          image,
          targetSize: 80 * 1024, // 80KB target
          verbose: true, // Enable logging
        );
        
        print('Compression result: ${compressedBase64 != null ? "Success (${compressedBase64.length} chars)" : "Failed"}');
        
        if (compressedBase64 != null) {
          final int emptyIndex = _imageBase64List.indexWhere((img) => img == null);
          print('Empty index found: $emptyIndex');
          
          if (emptyIndex != -1) {
            try {
              // Convert base64 to bytes for display
              final bytes = ImageCompressor.base64ToBytes(compressedBase64);
              
              if (bytes != null) {
                setState(() {
                  _imageBase64List[emptyIndex] = compressedBase64;
                  _imageBytesList[emptyIndex] = bytes;
                });
                print('Image added successfully at index $emptyIndex');
                _showSuccessSnackBar('Image uploaded successfully!');
              } else {
                print('Failed to decode base64 bytes');
                _showErrorSnackBar('Failed to process image');
              }
            } catch (decodeError) {
              print('Error decoding base64: $decodeError');
              _showErrorSnackBar('Failed to process image');
            }
          } else {
            print('No empty slot found for image');
          }
        } else {
          print('Image compression returned null');
          _showErrorSnackBar('Failed to compress image');
        }
        
        setState(() => _isUploadingImage = false);
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('Error picking image: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() => _isUploadingImage = false);
      _showErrorSnackBar('Failed to upload image: ${e.toString()}');
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
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }
    
    // Validate category
    if (_selectedCategory == null) {
      _showErrorSnackBar('Please select a category');
      return;
    }
    
    // Validate condition
    if (_selectedCondition == null) {
      _showErrorSnackBar('Please select a condition');
      return;
    }
    
    // Validate price
    if (!_isNegotiable && (_priceController.text.isEmpty || double.tryParse(_priceController.text) == null || double.parse(_priceController.text) <= 0)) {
      _showErrorSnackBar('Please enter a valid price or mark as negotiable');
      return;
    }
    
    // Validate location
    if (!_allOverBangladesh && (_selectedDivision == null || _selectedDistrict == null || _selectedArea == null)) {
      _showErrorSnackBar('Please select location details');
      return;
    }
    
    // Validate images
    final validImages = _imageBase64List.where((img) => img != null).toList();
    if (validImages.isEmpty) {
      _showErrorSnackBar('Please upload at least one image');
      return;
    }
    
    // Validate terms
    if (!_termsAccepted) {
      _showErrorSnackBar('Please accept the terms and conditions');
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
        postData['price'] = _priceController.text.isNotEmpty ? double.tryParse(_priceController.text) : null;
      } else {
        postData['price'] = double.parse(_priceController.text);
      }
      
      // Create post
      final result = await _salePostService.createSalePost(postData);
      
      if (result != null && mounted) {
        _showSuccessSnackBar('Post created successfully!');
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        _showErrorSnackBar('Failed to create post');
      }
    } catch (e) {
      print('Error submitting form: $e');
      _showErrorSnackBar('Failed to create post: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading && _categories.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text('Create Post'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF111827),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Create Sale Post',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(4),
          children: [
            const SizedBox(height: 4),
            // Basic Details Section
            _buildSection(
              title: 'Basic Details',
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
            
            const SizedBox(height: 4),
            
            // Pricing & Condition Section
            _buildSection(
              title: 'Pricing & Condition',
              icon: Icons.attach_money_rounded,
              children: [
                _buildConditionSelection(),
                const SizedBox(height: 8),
                _buildPriceField(),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Upload Photos Section
            _buildSection(
              title: 'Upload Photos',
              icon: Icons.photo_camera_outlined,
              children: [
                _buildImageUpload(),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Location Section
            _buildSection(
              title: 'Delivery to',
              icon: Icons.location_on_outlined,
              children: [
                _buildLocationFields(),
                const SizedBox(height: 8),
                _buildAddressField(),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Contact Information Section
            _buildSection(
              title: 'Contact Information',
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
    );
  }
  
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF10B981), size: 16),
              const SizedBox(width: 5),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category *',
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
      validator: (value) => value == null && _checkSubmit ? 'Required' : null,
    );
  }
  
  Widget _buildChildCategoryDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedChildCategory,
      decoration: InputDecoration(
        labelText: 'Sub Category',
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
        labelText: 'Title *',
        hintText: 'What are you selling?',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.title, size: 20),
        counterText: '${_titleController.text.length}/100',
      ),
      maxLength: 100,
      validator: (value) => value == null || value.trim().isEmpty && _checkSubmit ? 'Required' : null,
      onChanged: (value) => setState(() {}),
    );
  }
  
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description *',
        hintText: 'Describe your item in detail',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        counterText: '${_descriptionController.text.length}/1000',
      ),
      maxLines: 5,
      maxLength: 1000,
      validator: (value) => value == null || value.trim().isEmpty && _checkSubmit ? 'Required' : null,
      onChanged: (value) => setState(() {}),
    );
  }
  
  Widget _buildConditionSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Condition *',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _conditions.map((condition) {
            final isSelected = _selectedCondition == condition['value'];
            return FilterChip(
              label: Text(condition['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCondition = selected ? condition['value'] : null);
              },
              backgroundColor: Colors.grey.shade50,
              selectedColor: const Color(0xFF10B981).withOpacity(0.1),
              checkmarkColor: const Color(0xFF10B981),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
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
              labelText: 'Price *',
              hintText: 'e.g. 1000',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixText: '৳ ',
              prefixIcon: const Icon(Icons.monetization_on_outlined, size: 20),
            ),
            keyboardType: TextInputType.number,
            enabled: !_isNegotiable,
            validator: (value) {
              if (_isNegotiable) return null;
              if (_checkSubmit && (value == null || value.isEmpty)) return 'Required';
              final parsedValue = double.tryParse(value ?? '');
              if (_checkSubmit && parsedValue == null) return 'Invalid';
              if (_checkSubmit && parsedValue! <= 0) return 'Must be > 0';
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            Checkbox(
              value: _isNegotiable,
              onChanged: (value) => setState(() => _isNegotiable = value ?? false),
              activeColor: const Color(0xFF10B981),
            ),
            const Text('Negotiable', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add photos to showcase your listing (up to 8 images)',
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
              else if (_imageBytesList.where((img) => img != null).length < 8 && i == _imageBytesList.where((img) => img != null).length)
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 8),
                Text(
                  'Processing image...',
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
                padding: const EdgeInsets.all(4),
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
                child: const Text(
                  'Main',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
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
          border: Border.all(color: const Color(0xFF10B981), width: 2, style: BorderStyle.solid),
          color: const Color(0xFF10B981).withOpacity(0.05),
        ),
        child: _isUploadingImage
            ? const Center(
                child: CircularProgressIndicator(
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
                  const Text(
                    'Add Photo',
                    style: TextStyle(
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
  
  Widget _buildLocationFields() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('All over Bangladesh'),
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
            value: _selectedDivision,
            decoration: InputDecoration(
              labelText: 'Division *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
            validator: (value) => !_allOverBangladesh && value == null && _checkSubmit ? 'Required' : null,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedDistrict,
            decoration: InputDecoration(
              labelText: 'District *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
            validator: (value) => !_allOverBangladesh && value == null && _checkSubmit ? 'Required' : null,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedArea,
            decoration: InputDecoration(
              labelText: 'Area *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.place_outlined, size: 18),
            ),
            items: _areas.map<DropdownMenuItem<String>>((area) {
              return DropdownMenuItem<String>(
                value: area['name_eng'],
                child: Text(area['name_eng'] ?? ''),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedArea = value),
            validator: (value) => !_allOverBangladesh && value == null && _checkSubmit ? 'Required' : null,
          ),
        ],
      ],
    );
  }
  
  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      decoration: InputDecoration(
        labelText: 'Detailed Address *',
        hintText: 'Provide specific location details...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.home_outlined, size: 20),
      ),
      maxLines: 3,
      validator: (value) => value == null || value.trim().isEmpty && _checkSubmit ? 'Required' : null,
    );
  }
  
  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: 'Phone Number *',
        hintText: '01XXXXXXXXX',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.phone, size: 20),
      ),
      keyboardType: TextInputType.phone,
      maxLength: 11,
      validator: (value) {
        if (_checkSubmit && (value == null || value.trim().isEmpty)) return 'Required';
        if (_checkSubmit && value!.length != 11) return 'Must be 11 digits';
        return null;
      },
    );
  }
  
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email (Optional)',
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
          text: const TextSpan(
            style: TextStyle(fontSize: 12, color: Color(0xFF111827)),
            children: [
              TextSpan(text: 'I agree to the '),
              TextSpan(
                text: 'Terms and Conditions',
                style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600),
              ),
              TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600),
              ),
              TextSpan(
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.send, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Post Your Ad',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}

