class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice {
    final price = product.salePrice ?? product.regularPrice;
    return price * quantity;
  }
}

class Product {
  final dynamic id; // Can be int or String (UUID)
  final String name;
  final String? description;
  final double regularPrice;
  final double? salePrice;
  final int quantity;
  final bool? isFreeDelivery;
  final double? deliveryFeeInsideDhaka;
  final double? deliveryFeeOutsideDhaka;
  final List<ProductImage>? imageDetails;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.regularPrice,
    this.salePrice,
    required this.quantity,
    this.isFreeDelivery,
    this.deliveryFeeInsideDhaka,
    this.deliveryFeeOutsideDhaka,
    this.imageDetails,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'], // Can be int or String
      name: json['name']?.toString() ?? 'Product',
      description: json['description']?.toString(),
      regularPrice: _parseDouble(json['regular_price']),
      salePrice: json['sale_price'] != null
          ? _parseDouble(json['sale_price'])
          : null,
      quantity: _parseInt(json['quantity']),
      isFreeDelivery: json['is_free_delivery'] as bool?,
      deliveryFeeInsideDhaka: json['delivery_fee_inside_dhaka'] != null
          ? _parseDouble(json['delivery_fee_inside_dhaka'])
          : null,
      deliveryFeeOutsideDhaka: json['delivery_fee_outside_dhaka'] != null
          ? _parseDouble(json['delivery_fee_outside_dhaka'])
          : null,
      imageDetails: json['image_details'] != null
          ? (json['image_details'] as List)
              .map((img) => ProductImage.fromJson(img))
              .toList()
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class ProductImage {
  final dynamic id; // Can be int or String
  final String image;

  ProductImage({
    required this.id,
    required this.image,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'], // Accept any type - int or String
      image: json['image']?.toString() ?? '',
    );
  }
}
