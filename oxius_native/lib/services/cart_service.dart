import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  
  factory CartService() {
    return _instance;
  }
  
  CartService._internal();

  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  
  int get itemCount => _cartItems.length;
  
  int get totalQuantity {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }
  
  double get subtotal {
    return _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // Update quantity if product already in cart
      final newQuantity = _cartItems[existingIndex].quantity + quantity;
      if (newQuantity <= product.quantity) {
        _cartItems[existingIndex].quantity = newQuantity;
      }
    } else {
      // Add new item to cart
      if (quantity <= product.quantity) {
        _cartItems.add(CartItem(product: product, quantity: quantity));
      }
    }
    
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(int productId, int newQuantity) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    
    if (index >= 0) {
      if (newQuantity <= 0) {
        _cartItems.removeAt(index);
      } else if (newQuantity <= _cartItems[index].product.quantity) {
        _cartItems[index].quantity = newQuantity;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  bool isInCart(int productId) {
    return _cartItems.any((item) => item.product.id == productId);
  }

  CartItem? getCartItem(int productId) {
    try {
      return _cartItems.firstWhere((item) => item.product.id == productId);
    } catch (e) {
      return null;
    }
  }
}
