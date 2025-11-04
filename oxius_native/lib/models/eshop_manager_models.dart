class StoreDetails {
  final String storeName;
  final String storeUsername;
  final String? storeAddress;
  final String? storeDescription;
  final String? storeLogo;
  final String? storeBanner;
  final bool isActive;
  final DateTime? createdAt;

  StoreDetails({
    required this.storeName,
    required this.storeUsername,
    this.storeAddress,
    this.storeDescription,
    this.storeLogo,
    this.storeBanner,
    this.isActive = true,
    this.createdAt,
  });

  factory StoreDetails.fromJson(Map<String, dynamic> json) {
    return StoreDetails(
      storeName: json['store_name'] ?? '',
      storeUsername: json['store_username'] ?? '',
      storeAddress: json['store_address'],
      storeDescription: json['store_description'],
      storeLogo: json['store_logo'],
      storeBanner: json['store_banner'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_name': storeName,
      'store_username': storeUsername,
      'store_address': storeAddress,
      'store_description': storeDescription,
      'store_logo': storeLogo,
      'store_banner': storeBanner,
      'is_active': isActive,
    };
  }
}

class ShopProduct {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String status; // active, inactive, out-of-stock
  final String? image;
  final List<ProductImage>? imageDetails;
  final String? featuredImage;
  final String? categoryId;
  final String? categoryName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String sellerId;
  final String? sellerName;

  ShopProduct({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.status,
    this.image,
    this.imageDetails,
    this.featuredImage,
    this.categoryId,
    this.categoryName,
    required this.createdAt,
    this.updatedAt,
    required this.sellerId,
    this.sellerName,
  });

  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    // Convert backend fields to match our model
    String status = 'active';
    if (json['is_active'] != null) {
      status = json['is_active'] == true ? 'active' : 'inactive';
    } else if (json['status'] != null) {
      status = json['status'];
    }
    
    // Handle quantity field (backend uses 'quantity', we use 'stock')
    int stock = json['stock'] ?? json['quantity'] ?? 0;
    
    // Handle price fields (backend uses 'regular_price' and 'sale_price')
    double price = 0.0;
    if (json['sale_price'] != null && json['sale_price'] > 0) {
      price = (json['sale_price'] is String) 
          ? double.parse(json['sale_price']) 
          : (json['sale_price'] as num).toDouble();
    } else if (json['regular_price'] != null) {
      price = (json['regular_price'] is String) 
          ? double.parse(json['regular_price']) 
          : (json['regular_price'] as num).toDouble();
    } else if (json['price'] != null) {
      price = (json['price'] is String) 
          ? double.parse(json['price']) 
          : (json['price'] as num).toDouble();
    }
    
    return ShopProduct(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? json['short_description'],
      price: price,
      stock: stock,
      status: status,
      image: json['image'] is List && (json['image'] as List).isNotEmpty
          ? json['image'][0]['image']
          : json['image'],
      imageDetails: json['image_details'] != null
          ? (json['image_details'] as List)
              .map((img) => ProductImage.fromJson(img))
              .toList()
          : json['image'] is List
              ? (json['image'] as List)
                  .map((img) => ProductImage.fromJson(img))
                  .toList()
              : null,
      featuredImage: json['featured_image'],
      categoryId: json['category'] is List && (json['category'] as List).isNotEmpty
          ? (json['category'][0] is Map ? json['category'][0]['id']?.toString() : json['category'][0]?.toString())
          : json['category']?.toString(),
      categoryName: json['category_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      sellerId: (json['seller'] ?? json['owner'] ?? json['owner_id'])?.toString() ?? '',
      sellerName: json['seller_name'] ?? json['owner_details']?['username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'status': status,
      'image': image,
      'category': categoryId,
    };
  }
}

class ProductImage {
  final int id;
  final String image;
  final bool isPrimary;

  ProductImage({
    required this.id,
    required this.image,
    this.isPrimary = false,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] ?? 0,
      image: json['image'] ?? '',
      isPrimary: json['is_primary'] ?? false,
    );
  }
}

class ShopOrder {
  final int id;
  final String orderStatus; // pending, processing, delivered, cancelled
  final double total;
  final String? paymentMethod;
  final String? shippingAddress;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderItem>? items;

  ShopOrder({
    required this.id,
    required this.orderStatus,
    required this.total,
    this.paymentMethod,
    this.shippingAddress,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.createdAt,
    this.updatedAt,
    this.items,
  });

  factory ShopOrder.fromJson(Map<String, dynamic> json) {
    // Handle id as either int or array
    int orderId;
    if (json['id'] is List) {
      orderId = (json['id'] as List).isNotEmpty ? json['id'][0] : 0;
    } else {
      orderId = json['id'] ?? 0;
    }

    return ShopOrder(
      id: orderId,
      orderStatus: json['order_status'] ?? 'pending',
      total: (json['total'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'],
      shippingAddress: json['shipping_address'],
      customerName: json['customer_name'],
      customerEmail: json['customer_email'],
      customerPhone: json['customer_phone'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList()
          : null,
    );
  }
}

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? json['product'] ?? 0,
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }
}

class ProductSlotPackage {
  final int id;
  final String name;
  final int slots;
  final double price;
  final String? description;
  final bool isPopular;

  ProductSlotPackage({
    required this.id,
    required this.name,
    required this.slots,
    required this.price,
    this.description,
    this.isPopular = false,
  });

  factory ProductSlotPackage.fromJson(Map<String, dynamic> json) {
    return ProductSlotPackage(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slots: json['slots'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'],
      isPopular: json['is_popular'] ?? false,
    );
  }
}

class OrderStats {
  final int totalOrders;
  final int pendingOrders;
  final int processingOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double totalRevenue;

  OrderStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.processingOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
  });

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      totalOrders: json['total_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      processingOrders: json['processing_orders'] ?? 0,
      deliveredOrders: json['delivered_orders'] ?? 0,
      cancelledOrders: json['cancelled_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
    );
  }
}
