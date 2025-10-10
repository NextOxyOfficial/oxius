import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/eshop_service.dart';
import '../widgets/product_card.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> with SingleTickerProviderStateMixin {
  int _selectedImageIndex = 0;
  int _quantity = 1;
  bool _isLoading = true;
  bool _isLoadingSimilarProducts = false;
  bool _isLoadingStoreProducts = false;
  
  Map<String, dynamic>? _productDetails;
  List<Map<String, dynamic>> _similarProducts = [];
  List<Map<String, dynamic>> _storeProducts = [];
  
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProductDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProductDetails() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, you might fetch detailed product info from API
      // For now, we'll use the passed product data
      _productDetails = widget.product;
      
      // Load similar products and store products in parallel
      await Future.wait([
        _loadSimilarProducts(),
        _loadStoreProducts(),
      ]);
    } catch (e) {
      print('Error loading product details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSimilarProducts() async {
    setState(() => _isLoadingSimilarProducts = true);
    
    try {
      // Fetch products from the same category
      final products = await EshopService.fetchEshopProducts(page: 1, pageSize: 10);
      
      setState(() {
        // Filter out current product
        _similarProducts = products.where((p) => p['id'] != widget.product['id']).take(6).toList();
      });
    } catch (e) {
      print('Error loading similar products: $e');
    } finally {
      setState(() => _isLoadingSimilarProducts = false);
    }
  }

  Future<void> _loadStoreProducts() async {
    setState(() => _isLoadingStoreProducts = true);
    
    try {
      // Fetch products from the same store/owner
      final products = await EshopService.fetchEshopProducts(page: 1, pageSize: 10);
      
      setState(() {
        // Filter out current product
        _storeProducts = products.where((p) => p['id'] != widget.product['id']).take(6).toList();
      });
    } catch (e) {
      print('Error loading store products: $e');
    } finally {
      setState(() => _isLoadingStoreProducts = false);
    }
  }

  String _getImageUrl(int index) {
    try {
      final imageDetails = _productDetails?['image_details'];
      if (imageDetails is List && imageDetails.length > index) {
        return imageDetails[index]['image']?.toString() ?? '';
      }
      return _productDetails?['image']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  int get _imageCount {
    try {
      final imageDetails = _productDetails?['image_details'];
      if (imageDetails is List) {
        return imageDetails.length;
      }
      return 1;
    } catch (e) {
      return 1;
    }
  }

  num? _toNum(dynamic v) {
    if (v == null) return null;
    try {
      if (v is num) return v;
      return num.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  String _formatPrice(dynamic v) {
    final n = _toNum(v);
    if (n == null) return '';
    return n.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  int _calcDiscount(dynamic sale, dynamic regular) {
    final s = _toNum(sale);
    final r = _toNum(regular);
    if (s == null || r == null) return 0;
    if (r <= 0 || s >= r) return 0;
    return (((r - s) / r) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF10B981),
          ),
        ),
      );
    }

    final product = _productDetails ?? widget.product;
    final title = product['name'] ?? product['title'] ?? 'Product';
    final sale = product['sale_price'];
    final regular = product['regular_price'] ?? product['price'];
    final discount = _calcDiscount(sale, regular);
    final isFreeDelivery = product['is_free_delivery'] == true;
    final description = product['description'] ?? '';
    final shortDescription = product['short_description'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.black87),
                onPressed: () {
                  // Share functionality
                },
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.black87),
                onPressed: () {
                  // Add to wishlist
                },
              ),
            ],
          ),

          // Product Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Gallery
                _buildImageGallery(product),

                // Product Info
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Price Section
                      Row(
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '৳',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: _formatPrice(sale ?? regular),
                                  style: GoogleFonts.roboto(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (sale != null && _toNum(sale) != null && regular != null && _toNum(regular) != null && _toNum(sale)! < _toNum(regular)!) ...[
                            const SizedBox(width: 12),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '৳',
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _formatPrice(regular),
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      color: Colors.grey.shade400,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$discount% OFF',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Short Description
                      if (shortDescription.isNotEmpty) ...[
                        Text(
                          shortDescription,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Quantity Selector
                      _buildQuantitySelector(),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Store Information
                _buildStoreInfo(product),

                const SizedBox(height: 8),

                // Description Tabs
                _buildDescriptionTabs(product),

                const SizedBox(height: 8),

                // Similar Products
                if (_similarProducts.isNotEmpty) _buildSimilarProducts(),

                const SizedBox(height: 8),

                // More from Store
                if (_storeProducts.isNotEmpty) _buildStoreProducts(product),

                const SizedBox(height: 80), // Space for bottom bar
              ],
            ),
          ),
        ],
      ),

      // Bottom Action Bar
      bottomNavigationBar: _buildBottomBar(product),
    );
  }

  Widget _buildImageGallery(Map<String, dynamic> product) {
    final isFreeDelivery = product['is_free_delivery'] == true;
    
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Main Image
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: _imageCount,
                  onPageChanged: (index) {
                    setState(() => _selectedImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final imageUrl = _getImageUrl(index);
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                      ),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                );
                              },
                            )
                          : Icon(
                              Icons.image,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                    );
                  },
                ),
                
                // Free Delivery Badge at Bottom Right
                if (isFreeDelivery)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_shipping, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'FREE DELIVERY',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Image Indicators
          if (_imageCount > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _imageCount,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _selectedImageIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _selectedImageIndex == index
                          ? const Color(0xFF10B981)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove),
                    color: _quantity > 1 ? Colors.grey.shade700 : Colors.grey.shade400,
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      _quantity.toString(),
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add),
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStoreInfo(Map<String, dynamic> product) {
    final ownerDetails = product['owner_details'];
    final storeName = ownerDetails is Map
        ? (ownerDetails['store_name']?.toString() ?? ownerDetails['name']?.toString() ?? 'Store')
        : 'Store';
    
    // Extract owner details
    final isPro = ownerDetails is Map ? (ownerDetails['is_pro'] == true || ownerDetails['subscription_type'] == 'pro') : false;
    final isVerified = ownerDetails is Map ? (ownerDetails['kyc'] == true || ownerDetails['is_verified'] == true) : false;
    
    // Extract address information
    final upazila = ownerDetails is Map ? (ownerDetails['upazila']?.toString() ?? '') : '';
    final city = ownerDetails is Map ? (ownerDetails['city']?.toString() ?? '') : '';
    final state = ownerDetails is Map ? (ownerDetails['state']?.toString() ?? '') : '';
    final country = ownerDetails is Map ? (ownerDetails['country']?.toString() ?? '') : '';
    final address = [upazila, city, state, country].where((s) => s.isNotEmpty).join(', ');
    
    // Extract and format member since date
    final dateJoined = ownerDetails is Map ? ownerDetails['date_joined']?.toString() : null;
    String memberSince = '';
    if (dateJoined != null && dateJoined.isNotEmpty) {
      try {
        final date = DateTime.parse(dateJoined);
        final month = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ][date.month - 1];
        memberSince = '$month ${date.year}';
      } catch (e) {
        memberSince = '';
      }
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Store Card with Icon, Name, Badges, and Visit Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Logo/Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.storefront,
                    size: 28,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Store Info and Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store Name
                    Text(
                      storeName,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Badges Row - Pro/Free and Verified/Unverified
                    Row(
                      children: [
                        // Pro/Free Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPro ? const Color(0xFFFFA000) : Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isPro)
                                const Icon(Icons.star, size: 12, color: Colors.white),
                              if (isPro) const SizedBox(width: 4),
                              Text(
                                isPro ? 'Pro' : 'Free',
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Verified/Unverified Badge
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                title: Row(
                                  children: [
                                    Icon(
                                      isVerified ? Icons.verified : Icons.info_outline,
                                      color: isVerified ? const Color(0xFF3B82F6) : const Color(0xFFFB923C),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isVerified ? 'Verified Store' : 'Unverified Store',
                                      style: GoogleFonts.roboto(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  isVerified
                                      ? 'This store has been verified by our team. You can trust this seller for safe and reliable transactions.'
                                      : 'This store has not completed the verification process yet. Please exercise caution when making purchases.',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF10B981),
                                    ),
                                    child: Text(
                                      'Got it',
                                      style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isVerified ? const Color(0xFF3B82F6) : const Color(0xFFFB923C),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isVerified ? Icons.verified : Icons.info_outline,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isVerified ? 'Verified' : 'Unverified',
                                  style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Visit Store Button
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to store
                },
                icon: Icon(
                  Icons.storefront_outlined,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
                label: Text(
                  'Visit Store',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          
          // Contact Information Section
          if (address.isNotEmpty || memberSince.isNotEmpty) ...[
            const SizedBox(height: 16),
            // Address
            if (address.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Member Since
            if (memberSince.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Member since $memberSince',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionTabs(Map<String, dynamic> product) {
    final description = product['description']?.toString() ?? '';
    final deliveryInfo = product['delivery_information']?.toString() ?? '';
    final feeInsideDhaka = product['delivery_fee_inside_dhaka']?.toString() ?? '';
    final feeOutsideDhaka = product['delivery_fee_outside_dhaka']?.toString() ?? '';
    final isFreeDelivery = product['is_free_delivery'] == true;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF10B981),
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: const Color(0xFF10B981),
            tabs: const [
              Tab(text: 'Description'),
              Tab(text: 'Delivery Info'),
              Tab(text: 'Reviews'),
            ],
          ),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Description Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    description.isNotEmpty ? description : 'No description available',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                ),
                // Delivery Information Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isFreeDelivery)
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
                              Icon(Icons.local_shipping, color: Colors.green.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'FREE DELIVERY',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!isFreeDelivery) ...[
                        _buildDeliveryInfoItem(
                          'Delivery Fee (Inside Dhaka)',
                          feeInsideDhaka.isNotEmpty ? '৳$feeInsideDhaka' : 'Not specified',
                          Icons.location_city,
                        ),
                        const SizedBox(height: 12),
                        _buildDeliveryInfoItem(
                          'Delivery Fee (Outside Dhaka)',
                          feeOutsideDhaka.isNotEmpty ? '৳$feeOutsideDhaka' : 'Not specified',
                          Icons.location_on,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (deliveryInfo.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text(
                          'Delivery Information',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          deliveryInfo,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.6,
                          ),
                        ),
                      ],
                      if (!isFreeDelivery && feeInsideDhaka.isEmpty && feeOutsideDhaka.isEmpty && deliveryInfo.isEmpty)
                        Center(
                          child: Text(
                            'No delivery information available',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Reviews Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No reviews yet',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
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

  Widget _buildDeliveryInfoItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProducts() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Similar Products',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _similarProducts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 160,
                  child: ProductCard(
                    product: _similarProducts[index],
                    isLoading: false,
                    onBuyNow: () {
                      // Handle buy now
                    },
                    onTap: () {
                      // Navigate to product details
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(
                            product: _similarProducts[index],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreProducts(Map<String, dynamic> product) {
    final ownerDetails = product['owner_details'];
    final storeName = ownerDetails is Map
        ? (ownerDetails['store_name']?.toString() ?? 'Store')
        : 'Store';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'More from $storeName',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _storeProducts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 160,
                  child: ProductCard(
                    product: _storeProducts[index],
                    isLoading: false,
                    onBuyNow: () {
                      // Handle buy now
                    },
                    onTap: () {
                      // Navigate to product details
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(
                            product: _storeProducts[index],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Add to cart
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product['name']} added to cart'),
                        backgroundColor: const Color(0xFF10B981),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Add to Cart',
                        style: GoogleFonts.roboto(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Buy now
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Proceeding to checkout for ${product['name']}'),
                        backgroundColor: const Color(0xFF10B981),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_on, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Buy Now',
                        style: GoogleFonts.roboto(
                          fontSize: 15,
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
      ),
    );
  }
}
