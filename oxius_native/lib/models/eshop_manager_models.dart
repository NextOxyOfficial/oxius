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
  final int views;

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
    this.views = 0,
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
    
    // Helper function to safely parse price
    double? parsePrice(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return null;
        }
      }
      if (value is num) return value.toDouble();
      return null;
    }
    
    // Try sale_price first
    double? salePrice = parsePrice(json['sale_price']);
    if (salePrice != null && salePrice > 0) {
      price = salePrice;
    } else {
      // Try regular_price
      double? regularPrice = parsePrice(json['regular_price']);
      if (regularPrice != null) {
        price = regularPrice;
      } else {
        // Try generic price field
        double? genericPrice = parsePrice(json['price']);
        if (genericPrice != null) {
          price = genericPrice;
        }
      }
    }
    
    return ShopProduct(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? json['short_description'],
      price: price,
      stock: stock,
      status: status,
      image: json['image_details'] != null && (json['image_details'] as List).isNotEmpty
          ? json['image_details'][0]['image']
          : null,
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
      views: json['views'] ?? 0,
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
  final String id;
  final String image;
  final bool isPrimary;

  ProductImage({
    required this.id,
    required this.image,
    this.isPrimary = false,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id']?.toString() ?? '',
      image: json['image'] ?? '',
      isPrimary: json['is_primary'] ?? false,
    );
  }
}

class ShopOrder {
  final String id; // Changed from int to String to handle UUID
  final String? orderNumber;
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
    this.orderNumber,
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
    print('📦 Parsing order JSON: $json');
    
    // Handle id as String (UUID)
    String orderId = json['id']?.toString() ?? '';
    
    // Extract customer info from different possible fields
    String? customerName = json['customer_name'] ?? json['name'];
    String? customerEmail = json['customer_email'] ?? json['email'];
    String? customerPhone = json['customer_phone'] ?? json['phone'];
    String? shippingAddress = json['shipping_address'] ?? json['address'];

    return ShopOrder(
      id: orderId,
      orderNumber: json['order_number'],
      orderStatus: json['order_status'] ?? 'pending',
      total: _parseDouble(json['total']),
      paymentMethod: json['payment_method'],
      shippingAddress: shippingAddress,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
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
  
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
}

class OrderItem {
  final String id; // Changed from int to String for UUID
  final String productId; // Changed from int to String for UUID
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
    // Extract product name from product_details if available
    String productName = '';
    if (json['product_details'] != null && json['product_details']['name'] != null) {
      productName = json['product_details']['name'];
    } else if (json['product_name'] != null) {
      productName = json['product_name'];
    }

    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: (json['product_id'] ?? json['product'])?.toString() ?? '',
      productName: productName,
      quantity: json['quantity'] ?? 0,
      price: ShopOrder._parseDouble(json['price']),
      subtotal: json['subtotal'] != null ? ShopOrder._parseDouble(json['subtotal']) : ShopOrder._parseDouble(json['price']) * (json['quantity'] ?? 0),
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
