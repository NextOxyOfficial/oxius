class CreateOrderRequest {
  final OrderData order;
  final List<OrderItemData> items;

  CreateOrderRequest({
    required this.order,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'order': order.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class OrderData {
  final String? userId;
  final String name;
  final String? email;
  final String address;
  final String phone;
  final double total;
  final String orderStatus;
  final double deliveryFee;
  final String deliveryLocation;
  final String paymentMethod;

  OrderData({
    this.userId,
    required this.name,
    this.email,
    required this.address,
    required this.phone,
    required this.total,
    required this.orderStatus,
    required this.deliveryFee,
    required this.deliveryLocation,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'user': userId,
      'name': name,
      if (email != null) 'email': email,
      'address': address,
      'phone': phone,
      'total': total,
      'order_status': orderStatus,
      'delivery_fee': deliveryFee,
      'delivery_location': deliveryLocation,
      'payment_method': paymentMethod,
    };
  }
}

class OrderItemData {
  final dynamic productId; // Can be int or String (UUID)
  final int quantity;
  final double price;

  OrderItemData({
    required this.productId,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'product': productId,
      'quantity': quantity,
      'price': price,
    };
  }
}

class OrderResponse {
  final String? orderNumber;
  final Map<String, dynamic> data;

  OrderResponse({
    this.orderNumber,
    required this.data,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      orderNumber: json['order_number'] as String?,
      data: json,
    );
  }
}
