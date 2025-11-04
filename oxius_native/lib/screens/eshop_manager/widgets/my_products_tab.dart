import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/eshop_manager_models.dart';
import '../../../services/eshop_manager_service.dart';

class MyProductsTab extends StatefulWidget {
  final List<ShopProduct> products;
  final int productLimit;
  final VoidCallback onRefresh;
  final VoidCallback onProductUpdated;
  final VoidCallback onProductDeleted;

  const MyProductsTab({
    super.key,
    required this.products,
    required this.productLimit,
    required this.onRefresh,
    required this.onProductUpdated,
    required this.onProductDeleted,
  });

  @override
  State<MyProductsTab> createState() => _MyProductsTabState();
}

class _MyProductsTabState extends State<MyProductsTab> {
  String _selectedFilter = 'all';
  ShopProduct? _editingProduct;
  bool _isProcessing = false;

  List<ShopProduct> get _filteredProducts {
    if (_selectedFilter == 'all') return widget.products;
    return widget.products.where((p) => p.status == _selectedFilter).toList();
  }

  int get _activeCount => widget.products.where((p) => p.status == 'active').length;
  int get _inactiveCount => widget.products.where((p) => p.status == 'inactive').length;
  int get _outOfStockCount => widget.products.where((p) => p.status == 'out-of-stock').length;

  void _showEditDialog(ShopProduct product) {
    setState(() => _editingProduct = product);
    
    final nameController = TextEditingController(text: product.name);
    final descController = TextEditingController(text: product.description ?? '');
    final priceController = TextEditingController(text: product.price.toString());
    final stockController = TextEditingController(text: product.stock.toString());
    String selectedStatus = product.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.edit_rounded, color: Color(0xFF10B981), size: 22),
              SizedBox(width: 8),
              Text(
                'Edit Product',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('Product Name', nameController, required: true),
                const SizedBox(height: 12),
                _buildTextField('Description', descController, maxLines: 3),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('Price (৳)', priceController, 
                        keyboardType: TextInputType.number, required: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField('Stock', stockController, 
                        keyboardType: TextInputType.number, required: true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                    DropdownMenuItem(value: 'out-of-stock', child: Text('Out of Stock')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedStatus = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isProcessing ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        _showSnackBar('Product name is required', isError: true);
                        return;
                      }

                      setState(() => _isProcessing = true);

                      final result = await EshopManagerService.updateProduct(
                        productId: product.id,
                        name: nameController.text.trim(),
                        description: descController.text.trim(),
                        price: double.tryParse(priceController.text),
                        stock: int.tryParse(stockController.text),
                        status: selectedStatus,
                      );

                      setState(() => _isProcessing = false);

                      if (result['success'] == true) {
                        Navigator.pop(context);
                        _showSnackBar('Product updated successfully');
                        widget.onProductUpdated();
                      } else {
                        _showSnackBar(result['message'] ?? 'Failed to update', isError: true);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(ShopProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text(
              'Delete Product',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isProcessing = true);

              final success = await EshopManagerService.deleteProduct(product.id);

              setState(() => _isProcessing = false);

              if (success) {
                _showSnackBar('Product deleted successfully');
                widget.onProductDeleted();
              } else {
                _showSnackBar('Failed to delete product', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All', widget.products.length),
                const SizedBox(width: 6),
                _buildFilterChip('active', 'Active', _activeCount),
                const SizedBox(width: 6),
                _buildFilterChip('inactive', 'Inactive', _inactiveCount),
                const SizedBox(width: 6),
                _buildFilterChip('out-of-stock', 'Out of Stock', _outOfStockCount),
              ],
            ),
          ),
        ),

        // Products Grid
        Expanded(
          child: _filteredProducts.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(_filteredProducts[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.3) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all' ? 'No products yet' : 'No $_selectedFilter products',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products to start selling',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ShopProduct product) {
    final imageUrl = product.featuredImage ?? 
                     (product.imageDetails?.isNotEmpty == true 
                         ? product.imageDetails!.first.image 
                         : product.image);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Color(0xFF10B981)),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.image_not_supported_rounded, size: 32),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_outlined, size: 32),
                    ),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  _buildStatusBadge(product.status),
                  const SizedBox(height: 6),

                  // Name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),

                  // Price & Stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '৳${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        'Stock: ${product.stock}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showEditDialog(product),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _showDeleteDialog(product),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'active':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        break;
      case 'inactive':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        break;
      case 'out-of-stock':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status == 'out-of-stock' ? 'Out of Stock' : status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEF4444),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
        ),
      ],
    );
  }
}
