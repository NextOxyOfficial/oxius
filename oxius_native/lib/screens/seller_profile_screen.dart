import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/sale_post.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/adsyconnect_service.dart';
import 'adsy_connect_chat_interface.dart';

/// Seller Profile Screen - Display seller information and their listings
class SellerProfileScreen extends StatefulWidget {
  final String? userId;
  final String? userName;

  const SellerProfileScreen({
    Key? key,
    this.userId,
    this.userName,
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

      final uri = Uri.parse('${ApiService.baseUrl}/sale/posts/')
          .replace(queryParameters: queryParams);

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
    // Get seller name — prefer live API data, fall back to passed-in name
    String sellerName = widget.userName ?? 'Seller Profile';
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
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 21),
            onPressed: () => setState(() => _showShareDialog = true),
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF10B981)))
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
    final phone = _seller!['phone'];
    final address = _seller!['address'];
    final dateJoined = _seller!['date_joined'] != null
        ? DateTime.tryParse(_seller!['date_joined'])
        : null;
    final salePostCount = _seller!['sale_post_count'] ?? 0;
    final kyc = _seller!['kyc'] == true;
    final isPro = _seller!['is_pro'] == true;

    final divider = Container(height: 1, color: Colors.grey.shade200);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Seller header ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 62,
                  width: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFE5E7EB), width: 2),
                  ),
                  child: ClipOval(
                    child: image != null
                        ? CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey.shade200),
                            errorWidget: (context, url, error) =>
                                _buildAvatarFallback(name),
                          )
                        : _buildAvatarFallback(name),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF10B981)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (kyc) ...[
                            const SizedBox(width: 5),
                            const Icon(Icons.verified,
                                size: 17, color: Color(0xFF2563EB)),
                          ],
                          if (isPro) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  Color(0xFF4F46E5),
                                  Color(0xFF2563EB)
                                ]),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text('PRO',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _openChatWithSeller(
                                widget.userId ?? '', name),
                            child: Image.asset(
                              'assets/icons/chat_icon.png',
                              width: 26,
                              height: 26,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                'Member since ${_formatDate(dateJoined)}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sell_outlined,
                                  size: 12, color: Color(0xFF10B981)),
                              const SizedBox(width: 4),
                              Text(
                                '$salePostCount Listings',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (phone != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.phone_rounded,
                                size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 5),
                            Text(
                              _showPhone
                                  ? phone
                                  : _maskPhoneNumber(phone),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827)),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showPhone = !_showPhone),
                              child: Icon(
                                  _showPhone
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 16,
                                  color: const Color(0xFF10B981)),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                try {
                                  await launchUrl(Uri.parse('tel:$phone'),
                                      mode: LaunchMode.externalApplication);
                                } catch (_) {}
                              },
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Icon(Icons.phone_rounded,
                                    size: 13, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (address != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                address,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          divider,
          const SizedBox(height: 8),

          // ── Listings header ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Row(
              children: [
                const Text(
                  'Listings',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827)),
                ),
                const Spacer(),
                // Category dropdown
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      hint: Text('Category',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700),
                      isDense: true,
                      items: [
                        const DropdownMenuItem<String>(
                            value: null, child: Text('All')),
                        ..._categories.map((c) => DropdownMenuItem<String>(
                            value: c['id'].toString(),
                            child: Text(c['name'] ?? '',
                                overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedCategory = v);
                        _fetchSellerPosts();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sort dropdown
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSort,
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      isDense: true,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700),
                      items: const [
                        DropdownMenuItem(
                            value: 'recent', child: Text('Recent')),
                        DropdownMenuItem(
                            value: 'price-low', child: Text('Low Price')),
                        DropdownMenuItem(
                            value: 'price-high', child: Text('High Price')),
                        DropdownMenuItem(
                            value: 'popular', child: Text('Popular')),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedSort = v!);
                        _fetchSellerPosts();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Grid ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _isLoadingPosts
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child:
                          CircularProgressIndicator(color: Color(0xFF10B981)),
                    ),
                  )
                : _sellerPosts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.inbox,
                                  size: 60, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('No listings yet',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _sellerPosts.length,
                        itemBuilder: (context, index) =>
                            _buildListingCard(_sellerPosts[index]),
                      ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _openChatWithSeller(String userId, String userName) async {
    if (!AuthService.isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
      final chatroom =
          await AdsyConnectService.getOrCreateChatRoom(userId);
      if (mounted) Navigator.pop(context);
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: AdsyConnectChatInterface(
                chatroomId: chatroom['id'].toString(),
                userId: userId,
                userName: userName,
                userAvatar: _seller?['image'],
                profession: null,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        if (mounted) _showLoginRequiredDialog();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open chat. Please try again.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Login Required',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You need to be logged in to chat with the seller.',
                style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5)),
            SizedBox(height: 12),
            Text('Please login or create an account to continue.',
                style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Login',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: const Color(0xFF10B981).withOpacity(0.1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              fontSize: 28,
              color: Color(0xFF10B981),
              fontWeight: FontWeight.w800),
        ),
      ),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
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
                  if (post.division != null &&
                      post.district != null &&
                      post.area != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(Icons.location_on,
                                size: 12, color: Colors.grey.shade500),
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
                          post.price > 0
                              ? _formatPrice(post.price)
                              : 'Contact for Price',
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
    final shareText = 'Check out $sellerName on AdsyClub\n$shareUrl';

    Future<void> launch(String url) async {
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the app')),
          );
        }
      }
    }

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
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Share Profile',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            setState(() => _showShareDialog = false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.ios_share_rounded,
                          color: Color(0xFF10B981)),
                    ),
                    title: const Text('Share via...',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    onTap: () {
                      setState(() => _showShareDialog = false);
                      Share.share(shareText, subject: sellerName);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.link, color: Color(0xFF6B7280)),
                    ),
                    title: const Text('Copy Link',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chat_rounded,
                          color: Color(0xFF25D366)),
                    ),
                    title: const Text('Share on WhatsApp',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    onTap: () {
                      setState(() => _showShareDialog = false);
                      launch(
                          'https://wa.me/?text=${Uri.encodeComponent(shareText)}');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('𝕏',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.black)),
                    ),
                    title: const Text('Share on X',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    onTap: () {
                      setState(() => _showShareDialog = false);
                      launch(
                          'https://x.com/intent/tweet?text=${Uri.encodeComponent(sellerName)}&url=${Uri.encodeComponent(shareUrl)}');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                    ),
                    title: const Text('Share on Facebook',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    onTap: () {
                      setState(() => _showShareDialog = false);
                      launch(
                          'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareUrl)}');
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
