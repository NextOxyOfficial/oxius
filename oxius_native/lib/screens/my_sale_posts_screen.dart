import 'package:flutter/material.dart';
import '../services/sale_post_service.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../models/sale_post.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

/// My Sale Posts — manage the user's পুরোনো কেনাবেচা ads.
/// Shop-manager style: filter chips + flat stripe list with hairline dividers.
class MySalePostsScreen extends StatefulWidget {
  final String? initialTab;

  const MySalePostsScreen({
    super.key,
    this.initialTab,
  });

  @override
  State<MySalePostsScreen> createState() => _MySalePostsScreenState();
}

class _MySalePostsScreenState extends State<MySalePostsScreen> {
  late SalePostService _postService;
  final ScrollController _scrollController = ScrollController();

  final TranslationService _i18n = TranslationService();
  String _t(String key, String fallback) =>
      _i18n.translate(key, fallback: fallback);

  static const _green = Color(0xFF10B981);
  static const _greenDark = Color(0xFF059669);

  List<SalePost> _myPosts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _statusFilter; // null=all, 'active', 'sold', 'pending'
  final Map<String, int> _stats = {
    'total': 0,
    'active': 0,
    'sold': 0,
    'pending': 0,
  };

  @override
  void initState() {
    super.initState();
    _postService = SalePostService(baseUrl: ApiService.baseUrl);
    _scrollController.addListener(_onScroll);
    _fetchMyPosts();
    _fetchAllStats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) _loadMorePosts();
    }
  }

  void _selectFilter(String? filter) {
    if (filter == _statusFilter) return;
    setState(() => _statusFilter = filter);
    _fetchMyPosts(refresh: true);
  }

  Future<void> _fetchMyPosts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _myPosts.clear();
        _hasMore = true;
      });
    }
    setState(() => _isLoading = true);

    try {
      final response = await _postService.fetchMyPosts(
        page: _currentPage,
        pageSize: 20,
        status: _statusFilter,
      );
      if (mounted) {
        setState(() {
          _myPosts = response.results;
          _hasMore = response.next != null;
          _isLoading = false;
        });
        if (refresh) _fetchAllStats();
      }
    } catch (e) {
      debugPrint('Error fetching my posts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final response = await _postService.fetchMyPosts(
        page: nextPage,
        pageSize: 20,
        status: _statusFilter,
      );
      if (mounted) {
        setState(() {
          _myPosts.addAll(response.results);
          _currentPage = nextPage;
          _hasMore = response.next != null;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more posts: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _fetchAllStats() async {
    try {
      final all =
          await _postService.fetchMyPosts(page: 1, pageSize: 1, status: null);
      final active = await _postService.fetchMyPosts(
          page: 1, pageSize: 1, status: 'active');
      final sold =
          await _postService.fetchMyPosts(page: 1, pageSize: 1, status: 'sold');
      final pending = await _postService.fetchMyPosts(
          page: 1, pageSize: 1, status: 'pending');

      if (mounted) {
        setState(() {
          _stats['total'] = all.count;
          _stats['active'] = active.count;
          _stats['sold'] = sold.count;
          _stats['pending'] = pending.count;
        });
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  // ── Status helpers ──

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return _greenDark;
      case 'pending':
        return const Color(0xFFD97706);
      case 'sold':
        return const Color(0xFF2563EB);
      case 'expired':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFFD1FAE5);
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'sold':
        return const Color(0xFFDBEAFE);
      case 'expired':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'active':
        return _t('sale_status_active', 'অ্যাক্টিভ');
      case 'pending':
        return _t('sale_status_pending', 'রিভিউতে আছে');
      case 'sold':
        return _t('sale_status_sold', 'বিক্রি হয়ে গেছে');
      case 'expired':
        return _t('sale_status_expired', 'মেয়াদ শেষ');
      default:
        return status;
    }
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,##,###');
    return '৳${formatter.format(price)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMM').format(date);
  }

  // ── Actions ──

  Future<void> _changeStatus(SalePost post, String newStatus) async {
    final updated = await _postService.changeStatus(post.slug, newStatus);
    if (!mounted) return;
    if (updated != null) {
      AdsyToast.success(
          context,
          newStatus == 'sold'
              ? _t('sale_marked_sold', 'বিক্রি হয়ে গেছে হিসেবে মার্ক করা হলো')
              : _t('sale_marked_active', 'বিজ্ঞাপন আবার অ্যাক্টিভ হলো'));
      _fetchMyPosts(refresh: true);
    } else {
      AdsyToast.error(
          context, _t('sale_status_change_failed', 'স্ট্যাটাস বদলানো গেল না'));
    }
  }

  void _showStatusSheet(SalePost post) {
    if (post.status == 'pending') {
      AdsyToast.info(
          context,
          _t('sale_pending_note',
              'বিজ্ঞাপনটা এখনো রিভিউতে আছে — অ্যাপ্রুভ হলেই লাইভ হবে'));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              _t('sale_change_status', 'স্ট্যাটাস বদলান'),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            _statusOption(
              ctx,
              post,
              'active',
              Icons.check_circle_rounded,
              _t('sale_status_active', 'অ্যাক্টিভ'),
              _t('sale_status_active_sub', 'সবাই বিজ্ঞাপনটা দেখতে পাবে'),
            ),
            const SizedBox(height: 8),
            _statusOption(
              ctx,
              post,
              'sold',
              Icons.shopping_bag_rounded,
              _t('sale_status_sold', 'বিক্রি হয়ে গেছে'),
              _t('sale_status_sold_sub', 'মার্কেটপ্লেস থেকে সরে যাবে'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusOption(BuildContext sheetCtx, SalePost post, String value,
      IconData icon, String label, String subtitle) {
    final selected = post.status == value;
    final color = _statusColor(value);
    return InkWell(
      onTap: () {
        Navigator.pop(sheetCtx);
        if (!selected) _changeStatus(post, value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? _statusBg(value) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : const Color(0xFFE2E8F0),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: selected ? color : const Color(0xFF1F2937))),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5, color: Color(0xFF64748B))),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  static const List<(String, String)> _conditionOptions = [
    ('brand-new', 'একদম নতুন'),
    ('like-new', 'নতুনের মতো'),
    ('good', 'ভালো'),
    ('fair', 'মোটামুটি'),
    ('for-parts', 'পার্টসের জন্য'),
  ];

  String _conditionLabel(String value) {
    for (final o in _conditionOptions) {
      if (o.$1 == value) {
        return _t('sale_condition_${o.$1.replaceAll('-', '_')}', o.$2);
      }
    }
    return value;
  }

  Future<void> _showEditSheet(SalePost post) async {
    final titleController = TextEditingController(text: post.title);
    final descController =
        TextEditingController(text: post.description ?? '');
    final priceController =
        TextEditingController(text: post.price.toStringAsFixed(0));
    final phoneController = TextEditingController(text: post.phone ?? '');
    final addressController =
        TextEditingController(text: post.detailedAddress ?? '');
    String condition = post.condition;
    bool negotiable = post.negotiable;
    final saving = ValueNotifier<bool>(false);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.edit_outlined,
                          color: _greenDark, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _t('sale_edit_post', 'বিজ্ঞাপন এডিট'),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _editField(_t('sale_title_label', 'টাইটেল'),
                      titleController),
                  const SizedBox(height: 12),
                  _editField(_t('sale_desc_label', 'ডিটেইলস'), descController,
                      maxLines: 3),
                  const SizedBox(height: 12),
                  // Condition selector
                  Text(_t('sale_condition_label', 'কন্ডিশন'),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _conditionOptions.map((o) {
                      final selected = condition == o.$1;
                      return InkWell(
                        onTap: () => setSheet(() => condition = o.$1),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? _green
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: selected
                                    ? _green
                                    : const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            _conditionLabel(o.$1),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  _editField(_t('sale_price_label', 'দাম (৳)'),
                      priceController,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  _editField(_t('sale_phone_label', 'ফোন নাম্বার'),
                      phoneController,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _editField(_t('sale_address_label', 'ঠিকানা'),
                      addressController,
                      maxLines: 2),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _t('sale_negotiable', 'দামাদামি করা যাবে'),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151)),
                        ),
                      ),
                      Switch(
                        value: negotiable,
                        onChanged: (v) => setSheet(() => negotiable = v),
                        activeThumbColor: Colors.white,
                        activeTrackColor: _green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: saving,
                      builder: (context, isSaving, _) => ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final title = titleController.text.trim();
                                if (title.isEmpty) {
                                  AdsyToast.error(
                                      context,
                                      _t('sale_title_required',
                                          'টাইটেল দিতে হবে'));
                                  return;
                                }
                                saving.value = true;
                                // Only send non-empty values — the backend
                                // rejects explicitly-blanked required fields.
                                final desc = descController.text.trim();
                                final phone = phoneController.text.trim();
                                final address =
                                    addressController.text.trim();
                                final payload = <String, dynamic>{
                                  'title': title,
                                  'condition': condition,
                                  'price': double.tryParse(
                                          priceController.text.trim()) ??
                                      post.price,
                                  'negotiable': negotiable,
                                  if (desc.isNotEmpty) 'description': desc,
                                  if (phone.isNotEmpty) 'phone': phone,
                                  if (address.isNotEmpty)
                                    'detailed_address': address,
                                };
                                final updated = await _postService
                                    .updatePost(post.slug, payload);
                                saving.value = false;
                                if (!ctx.mounted) return;
                                if (updated != null) {
                                  Navigator.pop(ctx);
                                  if (mounted) {
                                    AdsyToast.success(
                                        context,
                                        _t('sale_post_updated',
                                            'বিজ্ঞাপন আপডেট হয়ে গেছে'));
                                    _fetchMyPosts(refresh: true);
                                  }
                                } else {
                                  AdsyToast.error(
                                      context,
                                      _t('sale_update_failed',
                                          'আপডেট করা গেল না'));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11)),
                          elevation: 0,
                        ),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: saving,
                          builder: (context, s, _) => s
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: AdsyLoadingIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(
                                  _t('sale_save', 'সেভ করুন'),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    titleController.dispose();
    descController.dispose();
    priceController.dispose();
    phoneController.dispose();
    addressController.dispose();
  }

  Widget _editField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _green),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deletePost(SalePost post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded,
                color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 8),
            Text(
              _t('sale_delete_post', 'বিজ্ঞাপন ডিলিট'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          _t('sale_delete_confirm',
              'বিজ্ঞাপনটা ডিলিট করতে চান? এটা আর ফেরত আনা যাবে না।'),
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('sale_cancel', 'ক্যান্সেল')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(_t('sale_delete', 'ডিলিট')),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final success = await _postService.deletePost(post.slug);
    if (!mounted) return;
    if (success) {
      AdsyToast.success(
          context, _t('sale_post_deleted', 'বিজ্ঞাপন ডিলিট হয়ে গেছে'));
      _fetchMyPosts(refresh: true);
    } else {
      AdsyToast.error(
          context, _t('sale_delete_failed', 'ডিলিট করা গেল না'));
    }
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _t('sale_my_posts', 'আমার বিজ্ঞাপন'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/sale'),
            icon: const Icon(Icons.storefront_outlined, size: 20),
            tooltip: _t('sale_marketplace', 'মার্কেটপ্লেস'),
            style: IconButton.styleFrom(
              backgroundColor: _green.withValues(alpha: 0.1),
              foregroundColor: _green,
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF1F5F9)),
        ),
      ),
      body: Column(
        children: [
          // Filter chips — shop-manager style
          Container(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(null, _t('sale_filter_all', 'সব'),
                      _stats['total'] ?? 0),
                  const SizedBox(width: 6),
                  _filterChip('active', _t('sale_status_active', 'অ্যাক্টিভ'),
                      _stats['active'] ?? 0),
                  const SizedBox(width: 6),
                  _filterChip(
                      'sold',
                      _t('sale_status_sold', 'বিক্রি হয়ে গেছে'),
                      _stats['sold'] ?? 0),
                  const SizedBox(width: 6),
                  _filterChip(
                      'pending',
                      _t('sale_status_pending', 'রিভিউতে আছে'),
                      _stats['pending'] ?? 0),
                ],
              ),
            ),
          ),

          // Stripe list
          Expanded(child: _buildPostsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result =
              await Navigator.pushNamed(context, '/create-sale-post');
          if (result == true) _fetchMyPosts(refresh: true);
        },
        backgroundColor: _green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _t('sale_create_post', 'বিজ্ঞাপন দিন'),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _filterChip(String? value, String label, int count) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => _selectFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _green : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _green : Colors.grey.shade300,
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
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
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

  Widget _buildPostsList() {
    if (_isLoading && _myPosts.isEmpty) {
      return const Center(child: AdsyLoadingIndicator(color: _green));
    }

    return AdsyRefreshIndicator(
      onRefresh: () => _fetchMyPosts(refresh: true),
      color: _green,
      child: _myPosts.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _emptyState(),
                ),
              ],
            )
          : ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(2, 4, 2, 90),
              itemCount: _myPosts.length + (_isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const Divider(
                  height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                if (index == _myPosts.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: AdsyLoadingIndicator(
                            strokeWidth: 2, color: _green),
                      ),
                    ),
                  );
                }
                return _buildPostRow(_myPosts[index]);
              },
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sell_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _t('sale_no_posts', 'এখনো কোনো বিজ্ঞাপন নেই'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _t('sale_no_posts_hint',
                'পুরোনো জিনিস বেচতে প্রথম বিজ্ঞাপনটা দিয়ে ফেলুন'),
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPostRow(SalePost post) {
    final imageUrl = post.images != null && post.images!.isNotEmpty
        ? post.images![0].image
        : null;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/sale/detail',
            arguments: {'slug': post.slug, 'id': post.id},
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 78,
                  height: 78,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: AdsyLoadingIndicator(
                                  strokeWidth: 2, color: _green),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade100,
                            child: Icon(Icons.image_not_supported_outlined,
                                color: Colors.grey.shade400, size: 26),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: Icon(Icons.image_outlined,
                              color: Colors.grey.shade400, size: 26),
                        ),
                ),
              ),
              const SizedBox(width: 10),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge + title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            post.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusBg(post.status),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _statusText(post.status),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(post.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Price + views + date
                    Row(
                      children: [
                        Text(
                          _formatPrice(post.price),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _greenDark,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.remove_red_eye_outlined,
                            size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(
                          '${post.viewsCount}',
                          style: TextStyle(
                              fontSize: 10.5, color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time,
                            size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(
                          _formatDate(post.createdAt),
                          style: TextStyle(
                              fontSize: 10.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),

                    // Actions: এডিট | ডিলিট ... স্ট্যাটাস
                    Row(
                      children: [
                        _actionButton(
                          icon: Icons.edit_outlined,
                          label: _t('sale_edit', 'এডিট'),
                          color: _greenDark,
                          onTap: () => _showEditSheet(post),
                        ),
                        const SizedBox(width: 4),
                        _actionButton(
                          icon: Icons.delete_outline,
                          label: _t('sale_delete', 'ডিলিট'),
                          color: const Color(0xFFDC2626),
                          onTap: () => _deletePost(post),
                        ),
                        const Spacer(),
                        _actionButton(
                          icon: Icons.swap_horiz_rounded,
                          label: _t('sale_status', 'স্ট্যাটাস'),
                          color: const Color(0xFF2563EB),
                          onTap: () => _showStatusSheet(post),
                        ),
                      ],
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

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
