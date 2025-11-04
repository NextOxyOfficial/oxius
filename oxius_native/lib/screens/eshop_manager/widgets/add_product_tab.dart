import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../../models/eshop_manager_models.dart';
import '../../../services/eshop_manager_service.dart';

class AddProductTab extends StatefulWidget {
  final List<ShopProduct> products;
  final int productLimit;
  final VoidCallback onProductAdded;

  const AddProductTab({
    super.key,
    required this.products,
    required this.productLimit,
    required this.onProductAdded,
  });

  @override
  State<AddProductTab> createState() => _AddProductTabState();
}

class _AddProductTabState extends State<AddProductTab> {
  void _showAddProductBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddProductBottomSheet(
        productLimit: widget.productLimit,
        currentProductCount: widget.products.length,
        onProductAdded: widget.onProductAdded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingSlots = widget.productLimit - widget.products.length;

    if (remainingSlots <= 0) {
      return _buildLimitReached();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_circle_rounded,
              size: 64,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Add New Product',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You can add $remainingSlots more product${remainingSlots > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddProductBottomSheet,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Add Product',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitReached() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                size: 48,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Product Limit Reached',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You have reached the maximum limit of ${widget.productLimit} products. Buy additional product slots to list more products.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom Sheet Widget
class AddProductBottomSheet extends StatefulWidget {
  final int productLimit;
  final int currentProductCount;
  final VoidCallback onProductAdded;

  const AddProductBottomSheet({
    super.key,
    required this.productLimit,
    required this.currentProductCount,
    required this.onProductAdded,
  });

  @override
  State<AddProductBottomSheet> createState() => _AddProductBottomSheetState();
}

class _AddProductBottomSheetState extends State<AddProductBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _regularPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _weightController = TextEditingController();
  final _keywordController = TextEditingController();
  final _insideDhakaController = TextEditingController();
  final _outsideDhakaController = TextEditingController();
  
  String _deliveryMethod = '';
  bool _isSubmitting = false;
  bool _isLoadingCategories = true;
  
  List<Map<String, dynamic>> _categories = [];
  List<int> _selectedCategories = [];
  List<String> _keywords = [];
  List<String> _images = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await EshopManagerService.getCategories();
      print('📦 Loaded ${categories.length} categories');
      
      // Debug: Print each category
      for (var cat in categories) {
        print('📦 Category: ${cat['name']} (ID: ${cat['id']}, Type: ${cat['id'].runtimeType})');
      }
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print('❌ Error loading categories: $e');
      if (mounted) {
        setState(() {
          _categories = [];
          _isLoadingCategories = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load categories'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _shortDescController.dispose();
    _regularPriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _weightController.dispose();
    _keywordController.dispose();
    _insideDhakaController.dispose();
    _outsideDhakaController.dispose();
    super.dispose();
  }

  void _addKeyword() {
    final keyword = _keywordController.text.trim();
    if (keyword.isNotEmpty && _keywords.length < 20) {
      setState(() {
        _keywords.add(keyword);
        _keywordController.clear();
      });
    }
  }

  void _removeKeyword(int index) {
    setState(() => _keywords.removeAt(index));
  }

  Future<void> _pickImages() async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 images allowed'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isEmpty) return;

    for (var file in pickedFiles) {
      if (_images.length >= 5) break;
      
      final bytes = await file.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      setState(() => _images.add(base64Image));
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _showCategorySelector() {
    print('📦 Opening category selector with ${_categories.length} categories');
    print('📦 Currently selected: $_selectedCategories');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Create a local copy of selected categories for the dialog
        List<int> localSelected = List.from(_selectedCategories);
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Text(
                    'Select Categories',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (localSelected.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${localSelected.length} selected',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: _categories.isEmpty
                    ? const Center(
                        child: Text(
                          'No categories available',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          // Convert id to int if it's a string
                          final catId = cat['id'] is String 
                              ? int.tryParse(cat['id']) ?? cat['id']
                              : cat['id'];
                          final isSelected = localSelected.contains(catId);
                          
                          return CheckboxListTile(
                            title: Text(
                              cat['name'] ?? 'Unknown',
                              style: const TextStyle(fontSize: 14),
                            ),
                            value: isSelected,
                            onChanged: (bool? checked) {
                              print('📦 Checkbox changed: ${cat['name']} = $checked');
                              setDialogState(() {
                                if (checked == true) {
                                  if (!localSelected.contains(catId)) {
                                    localSelected.add(catId);
                                    print('📦 Added category: $catId');
                                  }
                                } else {
                                  localSelected.remove(catId);
                                  print('📦 Removed category: $catId');
                                }
                              });
                              print('📦 Local selected now: $localSelected');
                            },
                            activeColor: const Color(0xFF10B981),
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategories = List.from(localSelected);
                    });
                    print('📦 Final selected categories: $_selectedCategories');
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_deliveryMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery method'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    print('📦 Starting product submission...');
    print('📦 Selected categories: $_selectedCategories');
    print('📦 Keywords: $_keywords');
    print('📦 Images count: ${_images.length}');
    print('📦 Delivery method: $_deliveryMethod');

    // Build product data matching Vue structure
    final Map<String, dynamic> productData = {
      'name': _nameController.text.trim(),
      'regular_price': double.parse(_regularPriceController.text),
      'quantity': int.parse(_stockController.text),
      'category': _selectedCategories,
      'is_free_delivery': _deliveryMethod == 'free',
    };

    // Add optional fields
    if (_descriptionController.text.trim().isNotEmpty) {
      productData['description'] = _descriptionController.text.trim();
    }
    if (_shortDescController.text.trim().isNotEmpty) {
      productData['short_description'] = _shortDescController.text.trim();
    }
    if (_keywords.isNotEmpty) {
      productData['keywords'] = _keywords.join(',');
    }
    if (_images.isNotEmpty) {
      productData['images'] = _images;
    }
    if (_salePriceController.text.isNotEmpty) {
      productData['sale_price'] = double.parse(_salePriceController.text);
    }
    if (_weightController.text.isNotEmpty) {
      productData['weight'] = double.parse(_weightController.text);
    }
    if (_deliveryMethod == 'standard') {
      if (_insideDhakaController.text.isNotEmpty) {
        productData['delivery_fee_inside_dhaka'] = double.parse(_insideDhakaController.text);
      }
      if (_outsideDhakaController.text.isNotEmpty) {
        productData['delivery_fee_outside_dhaka'] = double.parse(_outsideDhakaController.text);
      }
    } else {
      productData['delivery_fee_inside_dhaka'] = 0;
      productData['delivery_fee_outside_dhaka'] = 0;
    }

    final result = await EshopManagerService.createProductRaw(productData);

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        widget.onProductAdded();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to add product'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_rounded, color: Color(0xFF10B981), size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'Add New Product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 24),
                    onPressed: () => Navigator.pop(context),
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Basic Information
                    _buildSectionHeader('Basic Information', Icons.info_rounded),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Product Name',
                      controller: _nameController,
                      required: true,
                      hint: 'Enter product name',
                      validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Category Multi-Select
                    const Text(
                      'Category *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _isLoadingCategories
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : GestureDetector(
                            onTap: () => _showCategorySelector(),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedCategories.isEmpty
                                          ? 'Select categories'
                                          : '${_selectedCategories.length} selected',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _selectedCategories.isEmpty
                                            ? Colors.grey.shade400
                                            : const Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                ],
                              ),
                            ),
                          ),
                    if (_selectedCategories.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _selectedCategories.map((catId) {
                          final cat = _categories.firstWhere(
                            (c) {
                              final cId = c['id'] is String ? int.tryParse(c['id']) ?? c['id'] : c['id'];
                              return cId == catId;
                            },
                            orElse: () => {'id': catId, 'name': 'Unknown'},
                          );
                          return Chip(
                            label: Text(cat['name'] ?? '', style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() => _selectedCategories.remove(catId));
                            },
                            backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    
                    // Keywords
                    const Text(
                      'Keywords (Optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _keywordController,
                            decoration: InputDecoration(
                              hintText: 'Add keyword',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                            ),
                            onSubmitted: (_) => _addKeyword(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addKeyword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Add', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                    if (_keywords.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _keywords.asMap().entries.map((entry) {
                          return Chip(
                            label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _removeKeyword(entry.key),
                            backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    
                    // Description
                    _buildTextField(
                      label: 'Description',
                      controller: _descriptionController,
                      maxLines: 4,
                      hint: 'Describe your product',
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      label: 'Short Description',
                      controller: _shortDescController,
                      maxLines: 2,
                      hint: 'Brief overview (150 characters max)',
                    ),
                    const SizedBox(height: 24),
                    
                    // Media Gallery
                    _buildSectionHeader('Media Gallery', Icons.photo_rounded),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._images.asMap().entries.map((entry) {
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                  image: DecorationImage(
                                    image: MemoryImage(
                                      base64Decode(entry.value.split(',')[1]),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(entry.key),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        if (_images.length < 5)
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 2),
                                color: Colors.grey.shade50,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, color: Colors.grey.shade400, size: 24),
                                  const SizedBox(height: 4),
                                  Text('Add', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Pricing
                    _buildSectionHeader('Pricing & Inventory', Icons.attach_money_rounded),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Regular Price',
                            controller: _regularPriceController,
                            required: true,
                            keyboardType: TextInputType.number,
                            hint: '1000',
                            validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'Sale Price',
                            controller: _salePriceController,
                            keyboardType: TextInputType.number,
                            hint: '800',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Stock Quantity',
                      controller: _stockController,
                      required: true,
                      keyboardType: TextInputType.number,
                      hint: '50',
                      validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    // Delivery
                    _buildSectionHeader('Delivery Information', Icons.local_shipping_rounded),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Weight (kg)',
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      hint: '1.5',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Delivery Method *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: const Text('Free Delivery All Over Bangladesh', style: TextStyle(fontSize: 13)),
                      value: 'free',
                      groupValue: _deliveryMethod,
                      onChanged: (v) => setState(() => _deliveryMethod = v!),
                      activeColor: const Color(0xFF10B981),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      title: const Text('Standard Shipping (Location Based)', style: TextStyle(fontSize: 13)),
                      value: 'standard',
                      groupValue: _deliveryMethod,
                      onChanged: (v) => setState(() => _deliveryMethod = v!),
                      activeColor: const Color(0xFF10B981),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_deliveryMethod == 'standard') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Inside Dhaka Rate',
                              controller: _insideDhakaController,
                              keyboardType: TextInputType.number,
                              hint: '100',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              label: 'Outside Dhaka Rate',
                              controller: _outsideDhakaController,
                              keyboardType: TextInputType.number,
                              hint: '150',
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            // Submit Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Add Product',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF10B981)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
    String? Function(String?)? validator,
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
                  fontSize: 13,
                  color: Color(0xFFEF4444),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
