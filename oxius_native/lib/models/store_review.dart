/// A review left on one of the store's products, as seen by the store owner.
class StoreReview {
  final String id;
  final int rating;
  final String? title;
  final String comment;
  final String reviewerName;
  final String? reviewerImage;
  final String productId;
  final String productName;
  final String formattedDate;
  final int helpfulCount;
  final bool isVerifiedPurchase;
  String? sellerResponse;
  String? sellerResponseAt;

  StoreReview({
    required this.id,
    required this.rating,
    this.title,
    required this.comment,
    required this.reviewerName,
    this.reviewerImage,
    required this.productId,
    required this.productName,
    required this.formattedDate,
    this.helpfulCount = 0,
    this.isVerifiedPurchase = false,
    this.sellerResponse,
    this.sellerResponseAt,
  });

  bool get hasReply =>
      sellerResponse != null && sellerResponse!.trim().isNotEmpty;

  factory StoreReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final product = json['product'] as Map<String, dynamic>?;
    return StoreReview(
      id: json['id'].toString(),
      rating: _toInt(json['rating']),
      title: json['title']?.toString(),
      comment: (json['comment'] ?? '').toString(),
      reviewerName: (json['reviewer_name'] ??
              user?['display_name'] ??
              user?['name'] ??
              user?['username'] ??
              'Customer')
          .toString(),
      reviewerImage: user?['image']?.toString(),
      productId: (product?['id'] ?? '').toString(),
      productName: (product?['name'] ?? '').toString(),
      formattedDate: (json['formatted_date'] ?? '').toString(),
      helpfulCount: _toInt(json['helpful_count']),
      isVerifiedPurchase: json['is_verified_purchase'] == true,
      sellerResponse: json['seller_response']?.toString(),
      sellerResponseAt: json['seller_response_at']?.toString(),
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
