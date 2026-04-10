import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/eshop_manager_models.dart';
import '../../../services/eshop_manager_service.dart';

const _indigo = Color(0xFF6366F1);
const _violet = Color(0xFF8B5CF6);
const _emerald = Color(0xFF10B981);
const _slate50 = Color(0xFFF8FAFC);
const _slate100 = Color(0xFFF1F5F9);
const _slate200 = Color(0xFFE2E8F0);
const _slate400 = Color(0xFF94A3B8);
const _slate500 = Color(0xFF64748B);
const _slate700 = Color(0xFF334155);
const _slate800 = Color(0xFF1E293B);

class AddProductTab extends StatefulWidget {
  final List<ShopProduct> products;
  final int productLimit;
  final int totalProducts;
  final VoidCallback onProductAdded;

  const AddProductTab({
    super.key,
    required this.products,
    required this.productLimit,
    required this.totalProducts,
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
        currentProductCount: widget.totalProducts,
        onProductAdded: widget.onProductAdded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentProductCount = widget.totalProducts > 0
        ? widget.totalProducts
        : widget.products.length;
    final remainingSlots = (widget.productLimit - currentProductCount)
        .clamp(0, widget.productLimit);

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
  List<String> _selectedCategories = [];
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> localSelected = List.from(_selectedCategories);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                decoration: BoxDecoration(
                  color: _slate50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _slate200),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFF6F5FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _slate200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_indigo, _violet],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.category_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Categories',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: _slate800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Choose one or more categories for this product.',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: _slate500,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              icon: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _slate100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: _slate700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_categories.length} available',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _indigo,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (localSelected.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${localSelected.length} selected',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _emerald,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 420),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _slate200),
                        ),
                        child: _categories.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: _slate100,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.category_outlined,
                                          color: _slate500,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'No categories available',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _slate800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Try again after categories are loaded.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: _slate500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _categories.length,
                                itemBuilder: (context, index) {
                                  final cat = _categories[index];
                                  final catId = cat['id'].toString();
                                  final isSelected =
                                      localSelected.contains(catId);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: _buildCategoryDialogTile(
                                      name: cat['name'] ?? 'Unknown',
                                      isSelected: isSelected,
                                      onTap: () {
                                        setDialogState(() {
                                          if (isSelected) {
                                            localSelected.remove(catId);
                                          } else {
                                            localSelected.add(catId);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _slate700,
                                side: BorderSide(color: _slate200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategories =
                                      List.from(localSelected);
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _indigo,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Done',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
        productData['delivery_fee_inside_dhaka'] =
            double.parse(_insideDhakaController.text);
      }
      if (_outsideDhakaController.text.isNotEmpty) {
        productData['delivery_fee_outside_dhaka'] =
            double.parse(_outsideDhakaController.text);
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
        // Extract error details
        String errorMessage = result['message'] ?? 'Failed to add product';
        final errors = result['errors'];

        // Check if it's a product limit error
        if (errors is Map && errors['error'] == 'Product limit reached') {
          // Show dialog for product limit reached
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFD97706),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Product Limit Reached',
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
                    Text(
                      errors['message'] ??
                          'You have reached your product limit.',
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Current: ${errors['current_count']} / ${errors['limit']} products',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF065F46),
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
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Close add product sheet
                      // The parent screen should show buy slots option
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Buy More Slots'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          // Show validation errors
          if (errors is Map) {
            final errorList =
                errors.entries.map((e) => '${e.key}: ${e.value}').join('\n');
            errorMessage = errorList.isNotEmpty ? errorList : errorMessage;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: const Color(0xFFEF4444),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingSlots = (widget.productLimit - widget.currentProductCount)
        .clamp(0, widget.productLimit);

    return DraggableScrollableSheet(
      initialChildSize: 0.93,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _slate50,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: _slate200,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFF6F5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _slate200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_indigo, _violet],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _indigo.withValues(alpha: 0.22),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add New Product',
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: _slate800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Create a product listing for your shop manager catalog.',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: _slate500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _slate100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 17,
                              color: _slate700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildHeaderStat(
                            icon: Icons.sell_outlined,
                            label: 'Slots left',
                            value: '$remainingSlots',
                            tint: _indigo,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildHeaderStat(
                            icon: Icons.grid_view_rounded,
                            label: 'Used',
                            value:
                                '${widget.currentProductCount}/${widget.productLimit}',
                            tint: _emerald,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                  children: [
                    _buildFormSection(
                      title: 'Basic information',
                      subtitle: 'Name, category, keywords and descriptions.',
                      icon: Icons.info_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            label: 'Product Name',
                            controller: _nameController,
                            required: true,
                            hint: 'Enter product name',
                            validator: (v) =>
                                v?.trim().isEmpty == true ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildCategorySelector(),
                          const SizedBox(height: 12),
                          _buildKeywordsEditor(),
                          const SizedBox(height: 12),
                          _buildTextField(
                            label: 'Description',
                            controller: _descriptionController,
                            minLines: 3,
                            maxLines: 6,
                            hint: 'Describe your product',
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            label: 'Short Description',
                            controller: _shortDescController,
                            maxLines: 2,
                            hint: 'Brief overview (150 characters max)',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFormSection(
                      title: 'Media gallery',
                      subtitle:
                          'Add up to 5 product images for better conversion.',
                      icon: Icons.photo_library_rounded,
                      child: _buildMediaGallery(),
                    ),
                    const SizedBox(height: 12),
                    _buildFormSection(
                      title: 'Pricing & inventory',
                      subtitle: 'Set clear prices and keep stock accurate.',
                      icon: Icons.payments_rounded,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'Regular Price',
                                  controller: _regularPriceController,
                                  required: true,
                                  keyboardType: TextInputType.number,
                                  hint: '1000',
                                  validator: (v) => v?.trim().isEmpty == true
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 10),
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
                          const SizedBox(height: 12),
                          _buildTextField(
                            label: 'Stock Quantity',
                            controller: _stockController,
                            required: true,
                            keyboardType: TextInputType.number,
                            hint: '50',
                            validator: (v) =>
                                v?.trim().isEmpty == true ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFormSection(
                      title: 'Delivery information',
                      subtitle: 'Configure product weight and shipping method.',
                      icon: Icons.local_shipping_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            label: 'Weight (kg)',
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            hint: '1.5',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Delivery Method *',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _slate700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDeliveryOption(
                            title: 'Free Delivery All Over Bangladesh',
                            value: 'free',
                            subtitle:
                                'Show customers that nationwide delivery is included.',
                          ),
                          const SizedBox(height: 8),
                          _buildDeliveryOption(
                            title: 'Standard Shipping (Location Based)',
                            value: 'standard',
                            subtitle:
                                'Set separate charges for Dhaka and outside Dhaka.',
                          ),
                          if (_deliveryMethod == 'standard') ...[
                            const SizedBox(height: 10),
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
                                const SizedBox(width: 10),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 84),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _slate200)),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Add Product',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
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

  Widget _buildHeaderStat({
    required IconData icon,
    required String label,
    required String value,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: tint),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _slate500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _slate800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final accent = icon == Icons.local_shipping_rounded ? _emerald : _indigo;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, _violet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 17, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _slate800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _slate500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category *',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _slate700,
          ),
        ),
        const SizedBox(height: 6),
        _isLoadingCategories
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_indigo),
                  ),
                ),
              )
            : GestureDetector(
                onTap: _showCategorySelector,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _slate200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _slate100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.category_outlined,
                          size: 15,
                          color: _slate500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedCategories.isEmpty
                              ? 'Select categories'
                              : '${_selectedCategories.length} categories selected',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _selectedCategories.isEmpty
                                ? _slate400
                                : _slate800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: _slate500),
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
                (c) => c['id'].toString() == catId,
                orElse: () => {'id': catId, 'name': 'Unknown'},
              );
              return Chip(
                label: Text(
                  cat['name'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _indigo,
                  ),
                ),
                deleteIcon:
                    const Icon(Icons.close_rounded, size: 14, color: _indigo),
                onDeleted: () =>
                    setState(() => _selectedCategories.remove(catId)),
                backgroundColor: const Color(0xFFEEF2FF),
                side: BorderSide.none,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity:
                    const VisualDensity(horizontal: -2, vertical: -2),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryDialogTile({
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? _indigo : _slate200),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? _indigo : Colors.white,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: isSelected ? _indigo : _slate400),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _slate800,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: _indigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Selected',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _indigo,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeywordsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keywords (Optional)',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _slate700,
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
                  hintStyle: GoogleFonts.inter(color: _slate400, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _slate200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _slate200),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: _indigo, width: 1.5),
                  ),
                ),
                style: GoogleFonts.inter(fontSize: 12, color: _slate800),
                onSubmitted: (_) => _addKeyword(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _addKeyword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _slate800,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Add',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
                label: Text(
                  entry.value,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _emerald,
                  ),
                ),
                deleteIcon:
                    const Icon(Icons.close_rounded, size: 14, color: _emerald),
                onDeleted: () => _removeKeyword(entry.key),
                backgroundColor: const Color(0xFFECFDF5),
                side: BorderSide.none,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity:
                    const VisualDensity(horizontal: -2, vertical: -2),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaGallery() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._images.asMap().entries.map((entry) {
          return Stack(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _slate200),
                  image: DecorationImage(
                    image: MemoryImage(base64Decode(entry.value.split(',')[1])),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => _removeImage(entry.key),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.62),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 12, color: Colors.white),
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
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFF8FAFC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _slate200, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_photo_alternate_outlined,
                        color: _indigo, size: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add image',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _slate700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeliveryOption({
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _deliveryMethod == value;

    return GestureDetector(
      onTap: () => setState(() => _deliveryMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? _indigo : _slate200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: value,
              groupValue: _deliveryMethod,
              onChanged: (v) => setState(() => _deliveryMethod = v ?? ''),
              activeColor: _indigo,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _slate800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _slate500,
                      height: 1.35,
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int? minLines,
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
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _slate700,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Color(0xFFEF4444),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 12, color: _slate800),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: _slate400, fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: maxLines > 1 ? 10 : 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _slate200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _slate200),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: _indigo, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            errorStyle: GoogleFonts.inter(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
