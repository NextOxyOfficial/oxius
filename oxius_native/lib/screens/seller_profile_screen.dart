import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sale_post.dart';
import '../services/api_service.dart';

/// Seller Profile Screen - Display seller information and their listings
class SellerProfileScreen extends StatefulWidget {
  final String? userId;

  const SellerProfileScreen({
    Key? key,
    this.userId,
  }) : super(key: key);

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  Map<String, dynamic>? _seller;
  List<SalePost> _sellerPosts = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _isLoadingPosts = true;
  bool _showPhone = false;
  bool _showShareDialog = false;
  bool _copied = false;
  String _selectedSort = 'recent';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchSellerInfo();
    _fetchCategories();
    _fetchSellerPosts();
  }
  
  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/sale/categories/'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _categories = List<Map<String, dynamic>>.from(data);
          });
        }
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchSellerInfo() async {
    if (widget.userId == null) return;

    setState(() => _isLoading = true);
    
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/user/${widget.userId}/'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _seller = data;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load seller info');
      }
    } catch (e) {
      print('Error fetching seller info: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchSellerPosts() async {
    if (widget.userId == null) return;

    setState(() => _isLoadingPosts = true);
    
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'seller': widget.userId!,
        'page_size': '50',
        'ordering': _getSortParam(),
      };
      
      // Add category filter if selected
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        queryParams['category'] = _selectedCategory!;
      }
      
      final uri = Uri.parse('${ApiService.baseUrl}/sale/posts/').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        if (mounted) {
          setState(() {
            _sellerPosts = results.map((e) => SalePost.fromJson(e)).toList();
            _isLoadingPosts = false;
          });
        }
      } else {
        throw Exception('Failed to load seller posts');
      }
    } catch (e) {
      print('Error fetching seller posts: $e');
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
    }
  }

  String _getSortParam() {
    switch (_selectedSort) {
      case 'price-low':
        return 'price';
      case 'price-high':
        return '-price';
      case 'popular':
        return '-views';
      default:
        return '-created_at';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently';
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,##,###');
    return '৳${formatter.format(price)}';
  }

  String _capitalizeTitle(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _maskPhoneNumber(String? phone) {
    if (phone == null || phone.length <= 4) return phone ?? '';
    return phone.substring(0, 3) + '****' + phone.substring(phone.length - 2);
  }

  @override
  Widget build(BuildContext context) {
    // Get seller name
    String sellerName = 'Seller Profile';
    if (_seller != null) {
      if (_seller!['name'] != null && _seller!['name'].toString().isNotEmpty) {
        sellerName = _seller!['name'];
      } else {
        final firstName = _seller!['first_name']?.toString() ?? '';
        final lastName = _seller!['last_name']?.toString() ?? '';
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          sellerName = '$firstName $lastName'.trim();
        }
      }
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          sellerName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 22),
            onPressed: () => setState(() => _showShareDialog = true),
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              : _seller == null
                  ? _buildErrorState()
                  : _buildContent(),
          
          // Share Dialog
          if (_showShareDialog) _buildShareDialog(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Seller not found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Build full name from first_name and last_name, or use name field if available
    String name = 'Seller';
    if (_seller!['name'] != null && _seller!['name'].toString().isNotEmpty) {
      name = _seller!['name'];
    } else {
      final firstName = _seller!['first_name']?.toString() ?? '';
      final lastName = _seller!['last_name']?.toString() ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        name = '$firstName $lastName'.trim();
      }
    }
    
    final image = _seller!['image'];
    final email = _seller!['email'];
    final phone = _seller!['phone'];
    final address = _seller!['address'];
    final dateJoined = _seller!['date_joined'] != null 
        ? DateTime.tryParse(_seller!['date_joined']) 
        : null;
    final salePostCount = _seller!['sale_post_count'] ?? 0;
    final kyc = _seller!['kyc'] == true;
    final isPro = _seller!['is_pro'] == true;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Cover gradient
                Container(
                  height: 140,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
                
                // Profile info
                Transform.translate(
                  offset: const Offset(0, -50),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: image != null
                                ? CachedNetworkImage(
                                    imageUrl: image,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey.shade200,
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: const Color(0xFF10B981).withOpacity(0.1),
                                      child: Center(
                                        child: Text(
                                          name[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 40,
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    child: Center(
                                      child: Text(
                                        name[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 40,
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Name with badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (kyc) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified,
                                size: 22,
                                color: Color(0xFF2563EB),
                              ),
                            ],
                          ],
                        ),
                        
                        if (isPro) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4F46E5).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.shield, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Pro Member',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 12),
                        
                        // Member since
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              'Member since ${_formatDate(dateJoined)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Stats row
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.sell, size: 18, color: Color(0xFF10B981)),
                              const SizedBox(width: 8),
                              Text(
                                '$salePostCount Active Listings',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Contact Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contact Information',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              if (phone != null) ...[
                                _buildContactRow(
                                  Icons.phone,
                                  'Phone',
                                  _showPhone ? phone : _maskPhoneNumber(phone),
                                  trailing: IconButton(
                                    icon: Icon(
                                      _showPhone ? Icons.visibility_off : Icons.visibility,
                                      size: 18,
                                      color: const Color(0xFF10B981),
                                    ),
                                    onPressed: () => setState(() => _showPhone = !_showPhone),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              
                              if (email != null) ...[
                                _buildContactRow(Icons.email, 'Email', email),
                                const SizedBox(height: 8),
                              ],
                              
                              if (address != null) ...[
                                _buildContactRow(Icons.location_on, 'Location', address),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Contact button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: phone != null ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Call: $phone')),
                              );
                            } : null,
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text(
                              'Contact Seller',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Listings Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                
                // Section header
                Row(
                  children: [
                    const Icon(Icons.grid_view, size: 20, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$name\'s Listings',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Filter Row - Category and Sort in one row
                Row(
                  children: [
                    // Category filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white,
                        ),
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          hint: Text(
                            'All Categories',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          underline: const SizedBox(),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Categories'),
                            ),
                            ...(_categories ?? []).map((category) {
                              return DropdownMenuItem<String>(
                                value: category['id'].toString(),
                                child: Text(
                                  category['name'] ?? 'Unknown',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedCategory = value);
                            _fetchSellerPosts();
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Sort dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white,
                        ),
                        child: DropdownButton<String>(
                          value: _selectedSort,
                          underline: const SizedBox(),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          items: const [
                            DropdownMenuItem(value: 'recent', child: Text('Most Recent')),
                            DropdownMenuItem(value: 'price-low', child: Text('Price: Low-High')),
                            DropdownMenuItem(value: 'price-high', child: Text('Price: High-Low')),
                            DropdownMenuItem(value: 'popular', child: Text('Most Popular')),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedSort = value!);
                            _fetchSellerPosts();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Listings Grid
                _isLoadingPosts
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: Color(0xFF10B981)),
                        ),
                      )
                    : _sellerPosts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(Icons.inbox, size: 60, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No listings yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'This seller hasn\'t posted anything yet',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _sellerPosts.length,
                            itemBuilder: (context, index) {
                              final post = _sellerPosts[index];
                              return _buildListingCard(post);
                            },
                          ),
                
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value, {Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF10B981)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildListingCard(SalePost post) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/sale/detail',
          arguments: {'slug': post.slug},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: AspectRatio(
                aspectRatio: 1.1,
                child: post.images != null && post.images!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: post.images![0].image,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF10B981),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade100,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: Center(
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
              ),
            ),
            
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    _capitalizeTitle(post.title),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Location
                  if (post.division != null && post.district != null && post.area != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${post.division}, ${post.district}, ${post.area}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          post.price > 0 ? _formatPrice(post.price) : 'Contact for Price',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareDialog() {
    final sellerId = widget.userId ?? '';
    final sellerName = _seller?['name'] ?? 'Seller';
    final shareUrl = 'https://adsyclub.com/seller/$sellerId';
    
    return GestureDetector(
      onTap: () => setState(() => _showShareDialog = false),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Share $sellerName\'s Profile',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _showShareDialog = false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Copy Link
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.link, color: Color(0xFF10B981)),
                    ),
                    title: const Text('Copy Link', style: TextStyle(fontSize: 14)),
                    trailing: _copied 
                        ? const Icon(Icons.check, color: Color(0xFF10B981))
                        : null,
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: shareUrl));
                      setState(() => _copied = true);
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) setState(() => _copied = false);
                      });
                    },
                  ),
                  
                  const Divider(height: 1),
                  
                  // Social Media Options
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                    ),
                    title: const Text('Share on Facebook', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Facebook share coming soon!')),
                      );
                    },
                  ),
                  
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chat, color: Color(0xFF25D366)),
                    ),
                    title: const Text('Share on WhatsApp', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('WhatsApp share coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
