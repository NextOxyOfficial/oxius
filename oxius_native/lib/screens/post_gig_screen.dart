import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../services/gigs_service.dart';
import '../services/user_state_service.dart';

class PostGigScreen extends StatefulWidget {
  const PostGigScreen({super.key});

  @override
  State<PostGigScreen> createState() => _PostGigScreenState();
}

class _PostGigScreenState extends State<PostGigScreen> {
  final GigsService _gigsService = GigsService();
  final UserStateService _userService = UserStateService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  // Form fields
  String? _selectedCategory;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _actionLinkController = TextEditingController();
  
  List<String> _selectedDevices = [];
  List<String> _selectedNetworks = [];
  List<String> _uploadedImages = [];
  
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isUploading = false;
  String? _uploadError;
  bool _checkSubmit = false;

  // Dynamic data from backend
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _networks = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);
    
    try {
      final results = await Future.wait([
        _gigsService.fetchMicroGigCategories(),
        _gigsService.fetchTargetDevices(),
        _gigsService.fetchTargetNetworks(),
      ]);
      
      if (mounted) {
        setState(() {
          _categories = results[0];
          _devices = results[1];
          _networks = results[2];
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _instructionsController.dispose();
    _actionLinkController.dispose();
    super.dispose();
  }

  double get totalCost {
    final price = double.tryParse(_priceController.text) ?? 0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final balance = price * quantity;
    return balance + (balance * 0.1); // 10% service fee
  }

  bool get hasInsufficientBalance {
    final userBalance = _userService.balance;
    return userBalance < totalCost;
  }

  Future<void> _handleImageUpload() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _isUploading = true;
          _uploadError = null;
        });

        // Check file size (12MB max)
        final bytes = await image.readAsBytes();
        if (bytes.length > 12 * 1024 * 1024) {
          setState(() {
            _uploadError = 'File size should be less than 12MB';
            _isUploading = false;
          });
          return;
        }

        // Convert to base64
        final base64String = base64Encode(bytes);
        
        setState(() {
          _uploadedImages.add('data:image/jpeg;base64,$base64String');
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _uploadError = 'Failed to upload image';
        _isUploading = false;
      });
    }
  }

  void _deleteImage(int index) {
    setState(() {
      _uploadedImages.removeAt(index);
    });
  }

  bool _validateForm() {
    return _selectedCategory != null &&
           _titleController.text.trim().isNotEmpty &&
           _priceController.text.trim().isNotEmpty &&
           _quantityController.text.trim().isNotEmpty &&
           _instructionsController.text.trim().isNotEmpty &&
           double.tryParse(_priceController.text) != null &&
           int.tryParse(_quantityController.text) != null;
  }

  bool _isValidUrl(String url) {
    try {
      String processedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        processedUrl = 'https://$url';
      }
      Uri.parse(processedUrl);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _checkSubmit = true);

    // Check NID verification first
    final currentUser = _userService.currentUser;
    if (currentUser == null || !currentUser.isVerified) {
      _showNIDVerificationDialog();
      return;
    }

    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate action link if provided
    if (_actionLinkController.text.trim().isNotEmpty &&
        !_isValidUrl(_actionLinkController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Process action link
      String? actionLink = _actionLinkController.text.trim();
      if (actionLink.isNotEmpty) {
        if (!actionLink.startsWith('http://') && !actionLink.startsWith('https://')) {
          actionLink = 'https://$actionLink';
        }
      } else {
        actionLink = null;
      }

      // Prepare form data
      final formData = {
        'category': _selectedCategory,
        'title': _titleController.text.trim(),
        'price': double.parse(_priceController.text),
        'required_quantity': int.parse(_quantityController.text),
        'instructions': _instructionsController.text.trim(),
        'medias': _uploadedImages,
        'target_country': 'Bangladesh',
        'target_device': _selectedDevices.join(','),
        'target_network': _selectedNetworks.join(','),
        'action_link': actionLink,
        'active_gig': true,
        'total_cost': totalCost,
        'balance': double.parse(_priceController.text) * int.parse(_quantityController.text),
      };

      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gig posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting gig: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNIDVerificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'NID Verification Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To post a gig, you need to verify your National ID (NID) first. This helps us maintain a trusted community.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.shade100,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Verification usually takes 24-48 hours',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Verify NID',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add_circle_outline,
              size: 16,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Post a Gig',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      centerTitle: true,
    ),
    body: _isLoadingData
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          )
        : SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                _buildHeader(isMobile),

                // Form Section
                _buildForm(isMobile),
              ],
            ),
          ),
  );
}

Widget _buildHeader(bool isMobile) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          const Color(0xFF10B981).withOpacity(0.1),
          const Color(0xFF3B82F6).withOpacity(0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.add_circle_outline,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Gig',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Reach potential customers',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildForm(bool isMobile) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          // Basic Details Section
          _buildSectionCard(
              title: 'Basic Details',
              icon: Icons.description,
              child: Column(
                children: [
                  _buildDropdownField(
                    label: 'Category',
                    value: _selectedCategory,
                    items: _categories.map((cat) => DropdownMenuItem<String>(
                      value: cat['id'].toString(),
                      child: Text(cat['title']),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value),
                    isRequired: true,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Title',
                    controller: _titleController,
                    hintText: 'Enter gig title',
                    icon: Icons.title,
                    isRequired: true,
                  ),
                ],
              ),
            ),

            // Pricing Section
            _buildSectionCard(
              title: 'Pricing & Quantity',
              icon: Icons.attach_money,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Budget Per Action',
                          controller: _priceController,
                          hintText: '0.00',
                          icon: Icons.currency_exchange,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          label: 'Required Quantity',
                          controller: _quantityController,
                          hintText: '1',
                          icon: Icons.numbers,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Cost Calculator
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.w500)),
                            Text('৳${((double.tryParse(_priceController.text) ?? 0) * (int.tryParse(_quantityController.text) ?? 0)).toStringAsFixed(2)}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Service Fee (10%):', style: TextStyle(fontWeight: FontWeight.w500)),
                            Text('৳${(((double.tryParse(_priceController.text) ?? 0) * (int.tryParse(_quantityController.text) ?? 0)) * 0.1).toStringAsFixed(2)}'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Cost:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('৳${totalCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Instructions Section
            _buildSectionCard(
              title: 'Instructions',
              icon: Icons.assignment,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Provide detailed instructions for completing this gig',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Instructions',
                    controller: _instructionsController,
                    hintText: 'Describe what users need to do...',
                    maxLines: 6,
                    isRequired: true,
                  ),
                ],
              ),
            ),

            // Media Upload Section
            _buildSectionCard(
              title: 'Media Gallery',
              icon: Icons.photo,
              child: _buildMediaUpload(),
            ),

            // Targeting Options Section
            _buildSectionCard(
              title: 'Targeting Options',
              icon: Icons.location_on,
              child: Column(
                children: [
                  // Device Selection
                  _buildMultiSelectChips(
                    label: 'Target Devices',
                    options: _devices,
                    selectedValues: _selectedDevices,
                    onChanged: (selected) => setState(() => _selectedDevices = selected),
                  ),
                  const SizedBox(height: 20),
                  // Network Selection
                  _buildMultiSelectChips(
                    label: 'Target Networks',
                    options: _networks,
                    selectedValues: _selectedNetworks,
                    onChanged: (selected) => setState(() => _selectedNetworks = selected),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Action Link (Optional)',
                    controller: _actionLinkController,
                    hintText: 'https://example.com',
                    icon: Icons.link,
                  ),
                ],
              ),
            ),

            // Submit Section
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Low balance warning (only show if balance is insufficient)
                  if (hasInsufficientBalance && totalCost > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Insufficient Balance',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your balance: ৳${_userService.balance.toStringAsFixed(2)} | Required: ৳${totalCost.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(context, '/deposit-withdraw'),
                                  child: const Text(
                                    'Click here to make a deposit',
                                    style: TextStyle(
                                      color: Color(0xFF059669),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isLoading || hasInsufficientBalance) ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send),
                                SizedBox(width: 8),
                                Text(
                                  'Post Gig',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
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
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF059669), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
            children: isRequired ? [
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ] : null,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
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
              borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: isRequired && _checkSubmit
              ? (value) => value?.trim().isEmpty == true ? 'This field is required' : null
              : null,
          onChanged: (value) {
            if (controller == _priceController || controller == _quantityController) {
              setState(() {}); // Rebuild to update cost calculator
            }
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
            children: isRequired ? [
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ] : null,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
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
              borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: isRequired && _checkSubmit
              ? (value) => value == null ? 'Please select an option' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildMultiSelectChips({
    required String label,
    required List<Map<String, dynamic>> options,
    required List<String> selectedValues,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final optionId = option['id'].toString();
            final optionTitle = option['title'];
            final isSelected = selectedValues.contains(optionId);
            return FilterChip(
              label: Text(optionTitle),
              selected: isSelected,
              onSelected: (selected) {
                final newSelected = List<String>.from(selectedValues);
                if (selected) {
                  newSelected.add(optionId);
                } else {
                  newSelected.remove(optionId);
                }
                onChanged(newSelected);
              },
              backgroundColor: const Color(0xFFF9FAFB),
              selectedColor: const Color(0xFF059669),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMediaUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add photos or videos to explain your task (optional)',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Uploaded images
            ..._uploadedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final imageData = entry.value;
              
              // Decode base64 to display
              final bytes = base64Decode(imageData.split(',')[1]);
              
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        bytes,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _deleteImage(index),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            // Upload button
            GestureDetector(
              onTap: _isUploading ? null : _handleImageUpload,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF059669),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  color: const Color(0xFF059669).withOpacity(0.05),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isUploading) ...[
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Uploading...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.add_photo_alternate,
                        size: 32,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add Media',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_uploadError != null) ...[
          const SizedBox(height: 8),
          Text(
            _uploadError!,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}