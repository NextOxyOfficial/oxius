import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_state_service.dart';
import '../services/order_service.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userState = UserStateService();
  final _orderService = OrderService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Form state
  String _deliveryOption = 'inside';
  String _paymentMethod = 'account';
  bool _isLoading = false;
  bool _showInsufficientFundsModal = false;
  bool _showSuccessModal = false;
  String? _orderNumber;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    // Pre-fill user data if authenticated
    if (_userState.isAuthenticated) {
      _nameController.text =
          '${_userState.currentUser?.firstName ?? ''} ${_userState.currentUser?.lastName ?? ''}'
              .trim();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return widget.cartItems.fold(0.0, (sum, item) {
      final price = item.product.salePrice ?? item.product.regularPrice;
      return sum + (price * item.quantity);
    });
  }

  int get _totalItems {
    return widget.cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  double get _deliveryFee {
    if (widget.cartItems.isEmpty) return 0.0;
    final firstProduct = widget.cartItems.first.product;

    if (firstProduct.isFreeDelivery == true) return 0.0;

    return _deliveryOption == 'inside'
        ? (firstProduct.deliveryFeeInsideDhaka ?? 100.0)
        : (firstProduct.deliveryFeeOutsideDhaka ?? 150.0);
  }

  double get _total => _subtotal + _deliveryFee;

  String get _estimatedDelivery {
    final today = DateTime.now();
    final deliveryDays = _deliveryOption == 'inside' ? 1 : 5;
    final deliveryDate = today.add(Duration(days: deliveryDays));

    return '${_getWeekday(deliveryDate.weekday)}, ${_getMonth(deliveryDate.month)} ${deliveryDate.day}, ${deliveryDate.year}';
  }

  String _getWeekday(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[weekday - 1];
  }

  String _getMonth(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  void _increaseQuantity(int index) {
    final item = widget.cartItems[index];
    if (item.quantity < item.product.quantity) {
      setState(() {
        item.quantity++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${item.product.quantity} units available in stock'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _decreaseQuantity(int index) {
    setState(() {
      if (widget.cartItems[index].quantity > 1) {
        widget.cartItems[index].quantity--;
      }
    });
  }

  Future<void> _processCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if account funds are sufficient
    if (_paymentMethod == 'account' &&
        _userState.balance < _total) {
      setState(() {
        _showInsufficientFundsModal = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final orderData = CreateOrderRequest(
        order: OrderData(
          userId: _userState.isAuthenticated ? _userState.currentUser?.id : null,
          name: _nameController.text,
          email: _userState.userEmail,
          address: _addressController.text,
          phone: _phoneController.text,
          total: _total,
          orderStatus: 'pending',
          deliveryFee: _deliveryFee,
          deliveryLocation:
              _deliveryOption == 'inside' ? 'inside_dhaka' : 'outside_dhaka',
          paymentMethod:
              _paymentMethod == 'account' ? 'balance' : 'cash_on_delivery',
        ),
        items: widget.cartItems.map((item) {
          return OrderItemData(
            productId: item.product.id,
            quantity: item.quantity,
            price: item.product.salePrice ?? item.product.regularPrice,
          );
        }).toList(),
      );

      final response = await _orderService.createOrder(orderData);

      if (response != null) {
        setState(() {
          _orderNumber = response.orderNumber ??
              (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
                  .toString();
          _showSuccessModal = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _switchToCOD() {
    setState(() {
      _paymentMethod = 'cod';
      _showInsufficientFundsModal = false;
    });
  }

  void _resetForm() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You have no products in the cart. Start adding some.'),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProductsList(),
                          const SizedBox(height: 12),
                          _buildCustomerInformation(),
                          const SizedBox(height: 12),
                          if (widget.cartItems.isNotEmpty &&
                              widget.cartItems.first.product.isFreeDelivery != true)
                            _buildDeliveryOptions(),
                          if (widget.cartItems.isNotEmpty &&
                              widget.cartItems.first.product.isFreeDelivery != true)
                            const SizedBox(height: 12),
                          _buildPaymentMethods(),
                          const SizedBox(height: 12),
                          _buildOrderSummary(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showInsufficientFundsModal) _buildInsufficientFundsModal(),
          if (_showSuccessModal) _buildSuccessModal(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: const Color(0xFF3B82F6),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3B82F6),
                Color(0xFF2563EB),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Checkout',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review and complete your order',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCheckoutSteps(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutSteps() {
    return Row(
      children: [
        _buildStep(Icons.shopping_cart_rounded, 'Cart', false),
        _buildStepDivider(),
        _buildStep(Icons.payment_rounded, 'Payment', true),
        _buildStepDivider(),
        _buildStep(Icons.check_circle_rounded, 'Done', false),
      ],
    );
  }

  Widget _buildStep(IconData icon, String label, bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 12,
            color: isActive ? const Color(0xFF3B82F6) : Colors.white,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 16,
      height: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildProductsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.shopping_bag_rounded,
                  color: Color(0xFF3B82F6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Order Items',
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.cartItems.length} ${widget.cartItems.length == 1 ? 'item' : 'items'}',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(
            widget.cartItems.length,
            (index) => _buildProductItem(index),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(int index) {
    final item = widget.cartItems[index];
    final product = item.product;
    final price = product.salePrice ?? product.regularPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              product.imageDetails?.isNotEmpty == true
                  ? product.imageDetails!.first.image
                  : 'https://via.placeholder.com/60',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  color: const Color(0xFFE5E7EB),
                  child: const Icon(Icons.image_rounded, color: Color(0xFF9CA3AF), size: 24),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: const Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '৳',
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF3B82F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${price.toStringAsFixed(0)}',
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF3B82F6),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (product.salePrice != null && product.salePrice! < product.regularPrice) ...[
                      const SizedBox(width: 6),
                      Text(
                        '৳${product.regularPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: const Color(0xFF9CA3AF),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _decreaseQuantity(index),
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: const Icon(Icons.remove, size: 14, color: Color(0xFF6B7280)),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Color(0xFFE5E7EB)),
                            right: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _increaseQuantity(index),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: const Icon(Icons.add, size: 14, color: Color(0xFF3B82F6)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInformation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Delivery Information',
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            style: GoogleFonts.roboto(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Full Name',
              labelStyle: GoogleFonts.roboto(fontSize: 13, color: const Color(0xFF6B7280)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              ),
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF6B7280)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _phoneController,
            style: GoogleFonts.roboto(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              labelStyle: GoogleFonts.roboto(fontSize: 13, color: const Color(0xFF6B7280)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              ),
              prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF6B7280)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              }
              if (!RegExp(r'^\d{10,11}$').hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _addressController,
            style: GoogleFonts.roboto(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Delivery Address',
              labelStyle: GoogleFonts.roboto(fontSize: 13, color: const Color(0xFF6B7280)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              ),
              prefixIcon: const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF6B7280)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Address is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOptions() {
    final product = widget.cartItems.first.product;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Color(0xFFF59E0B),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Delivery Method',
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDeliveryOption(
            'inside',
            'Inside Dhaka',
            '24 hours delivery',
            '৳${product.deliveryFeeInsideDhaka ?? 100}',
            Icons.location_city_rounded,
          ),
          const SizedBox(height: 8),
          _buildDeliveryOption(
            'outside',
            'Outside Dhaka',
            '3-5 days delivery',
            '৳${product.deliveryFeeOutsideDhaka ?? 150}',
            Icons.explore_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption(
    String value,
    String title,
    String subtitle,
    String price,
    IconData icon,
  ) {
    final isSelected = _deliveryOption == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _deliveryOption = value;
          });
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
            color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.05) : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF),
                    width: isSelected ? 5 : 2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                icon,
                size: 18,
                color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF1F2937) : const Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Method',
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_userState.isAuthenticated)
            _buildPaymentOption(
              'account',
              'Account Balance',
              'Available: ৳${_userState.balance.toStringAsFixed(2)}',
              Icons.account_balance_wallet_rounded,
            ),
          if (_userState.isAuthenticated)
            const SizedBox(height: 8),
          _buildPaymentOption(
            'cod',
            'Cash on Delivery',
            'Pay when you receive',
            Icons.money_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _paymentMethod == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _paymentMethod = value;
          });
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
            color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.05) : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF),
                    width: isSelected ? 5 : 2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                icon,
                size: 18,
                color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF1F2937) : const Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF2563EB),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Order Summary',
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Subtotal ($_totalItems items)', '৳${_subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          _buildSummaryRow('Delivery Fee', '৳${_deliveryFee.toStringAsFixed(0)}'),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0),
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '৳',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _total.toStringAsFixed(0),
                    style: GoogleFonts.roboto(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 13,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _processCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Complete Order',
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInsufficientFundsModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Close button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _showInsufficientFundsModal = false;
                    });
                  },
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey.shade600,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Warning icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade600,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    const Text(
                      'Insufficient Funds',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Description
                    Text(
                      'Your account balance (৳${_userState.balance.toStringAsFixed(2)}) is not sufficient to complete this purchase (৳${_total.toStringAsFixed(2)}).',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _switchToCOD,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.indigo.shade700,
                              side: BorderSide(color: Colors.indigo.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Switch to COD',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/deposit-withdraw');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade600,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Add Funds',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Cancel button
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showInsufficientFundsModal = false;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Close button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey.shade600,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    const Text(
                      'Order Successful!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Description
                    Text(
                      'Thank you for your purchase! Your order #$_orderNumber has been successfully placed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Order details card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Order total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order Total:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                '৳${_total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Estimated delivery - with wrapping
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated Delivery:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _estimatedDelivery,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Continue shopping button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _resetForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue Shopping',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
