import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';
import '../../../models/store_review.dart';
import '../../../services/review_service.dart';
import '../../../services/translation_service.dart';
import '../../product_details_screen.dart';

/// Reviews left on the store owner's products, with the ability to reply.
class StoreReviewsTab extends StatefulWidget {
  final void Function(int count)? onCountChanged;

  const StoreReviewsTab({super.key, this.onCountChanged});

  @override
  State<StoreReviewsTab> createState() => _StoreReviewsTabState();
}

class _StoreReviewsTabState extends State<StoreReviewsTab> {
  final TranslationService _i18n = TranslationService();
  String _t(String key, String fallback) =>
      _i18n.translate(key, fallback: fallback);

  final ScrollController _scrollController = ScrollController();
  final List<StoreReview> _reviews = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  int _total = 0;

  static const _amber = Color(0xFFF59E0B);
  static const _green = Color(0xFF059669);
  static const _slate = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ReviewService.getStoreReviews(page: 1);
    if (!mounted) return;
    setState(() {
      _reviews
        ..clear()
        ..addAll(res['reviews'] as List<StoreReview>);
      _hasMore = res['hasMore'] as bool;
      _total = res['total'] as int;
      _page = 1;
      _loading = false;
    });
    widget.onCountChanged?.call(_total);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final res = await ReviewService.getStoreReviews(page: _page + 1);
    if (!mounted) return;
    setState(() {
      _reviews.addAll(res['reviews'] as List<StoreReview>);
      _hasMore = res['hasMore'] as bool;
      _page += 1;
      _loadingMore = false;
    });
  }

  Future<void> _openReplySheet(StoreReview review) async {
    final controller = TextEditingController(text: review.sellerResponse ?? '');
    final saving = ValueNotifier<bool>(false);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
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
                  const Icon(Icons.reply_rounded, color: _green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    review.hasReply
                        ? _t('eshop_edit_reply', 'রিপ্লাই এডিট')
                        : _t('eshop_reply_to_review', 'রিভিউতে রিপ্লাই দিন'),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 4,
                maxLength: 1000,
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: _t('eshop_reply_hint',
                      'কাস্টমারকে সুন্দরভাবে উত্তর দিন...'),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _green),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder<bool>(
                  valueListenable: saving,
                  builder: (context, isSaving, _) => ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final text = controller.text.trim();
                            if (text.isEmpty) {
                              AdsyToast.error(
                                  context,
                                  _t('eshop_reply_required',
                                      'রিপ্লাই লিখুন'));
                              return;
                            }
                            saving.value = true;
                            final result = await ReviewService.replyToReview(
                                reviewId: review.id, text: text);
                            saving.value = false;
                            if (!ctx.mounted) return;
                            if (result['success'] == true) {
                              final updated = result['data'] as StoreReview;
                              review.sellerResponse = updated.sellerResponse;
                              review.sellerResponseAt =
                                  updated.sellerResponseAt;
                              if (mounted) setState(() {});
                              Navigator.pop(ctx);
                              AdsyToast.success(
                                  context,
                                  _t('eshop_reply_saved',
                                      'রিপ্লাই সেভ হয়েছে'));
                            } else {
                              final msg = (result['message'] as String?)?.trim();
                              AdsyToast.error(
                                  context,
                                  (msg != null && msg.isNotEmpty)
                                      ? msg
                                      : _t('eshop_reply_failed',
                                          'রিপ্লাই সেভ করা গেল না'));
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
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: AdsyLoadingIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            _t('eshop_send_reply', 'রিপ্লাই পাঠান'),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteReply(StoreReview review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(_t('eshop_delete_reply', 'রিপ্লাই ডিলিট'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
            _t('eshop_delete_reply_confirm',
                'আপনার রিপ্লাই মুছে ফেলতে চান?'),
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_t('eshop_cancel', 'ক্যান্সেল'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0),
            child: Text(_t('eshop_delete', 'ডিলিট')),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final result = await ReviewService.deleteReply(reviewId: review.id);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        review.sellerResponse = null;
        review.sellerResponseAt = null;
      });
      AdsyToast.success(
          context, _t('eshop_reply_deleted', 'রিপ্লাই ডিলিট হয়েছে'));
    } else {
      AdsyToast.error(
          context, _t('eshop_reply_delete_failed', 'ডিলিট করা গেল না'));
    }
  }

  void _openProduct(StoreReview r) {
    if (r.productId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          product: {'id': r.productId, 'name': r.productName},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: AdsyLoadingIndicator(color: _green));
    }
    return AdsyRefreshIndicator(
      onRefresh: _load,
      color: _green,
      child: _reviews.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _emptyState(),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(2, 6, 2, 12),
                    itemCount: _reviews.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, i) => _reviewRow(_reviews[i]),
                  ),
                ),
                if (_loadingMore)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          AdsyLoadingIndicator(strokeWidth: 2, color: _green),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          Text(_t('eshop_no_reviews_yet', 'এখনো কোনো রিভিউ নেই'),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(
            _t('eshop_reviews_appear_hint',
                'কাস্টমার রিভিউ দিলে এখানে দেখা যাবে'),
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _stars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 15,
          color: i < rating ? _amber : const Color(0xFFCBD5E1),
        );
      }),
    );
  }

  Widget _reviewRow(StoreReview r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer + rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(r),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(r.reviewerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A))),
                        ),
                        if (r.isVerifiedPurchase) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified_rounded,
                              size: 14, color: _green),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _stars(r.rating),
                        const SizedBox(width: 6),
                        Text(r.formattedDate,
                            style: const TextStyle(
                                fontSize: 10.5, color: _slate)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Product name (tap to open the product page)
          if (r.productName.isNotEmpty)
            InkWell(
              onTap: () => _openProduct(r),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 11, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(r.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB))),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.chevron_right_rounded,
                        size: 13, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ),
          if (r.title != null && r.title!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.title!,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 5),
          Text(r.comment,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.4, color: Color(0xFF334155))),

          // Seller reply block
          const SizedBox(height: 10),
          if (r.hasReply)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD1FAE5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded,
                          size: 13, color: _green),
                      const SizedBox(width: 5),
                      Text(_t('eshop_your_reply', 'আপনার রিপ্লাই'),
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _green)),
                      const Spacer(),
                      InkWell(
                        onTap: () => _openReplySheet(r),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.edit_outlined,
                              size: 16, color: _green),
                        ),
                      ),
                      InkWell(
                        onTap: () => _deleteReply(r),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.delete_outline,
                              size: 16, color: Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(r.sellerResponse ?? '',
                      style: const TextStyle(
                          fontSize: 12, height: 1.4, color: Color(0xFF166534))),
                ],
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _openReplySheet(r),
                icon: const Icon(Icons.reply_rounded, size: 16),
                label: Text(_t('eshop_reply', 'রিপ্লাই দিন')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _green,
                  side: const BorderSide(color: _green),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 34),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9)),
                  textStyle: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _avatar(StoreReview r) {
    final img = r.reviewerImage;
    if (img != null && img.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: img,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _initialAvatar(r.reviewerName),
        ),
      );
    }
    return _initialAvatar(r.reviewerName);
  }

  Widget _initialAvatar(String name) {
    final letter =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(letter,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: _green)),
    );
  }
}
