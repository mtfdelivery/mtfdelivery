import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/food_item_model.dart';

/// Cart state notifier for managing cart items
class CartNotifier extends StateNotifier<List<CartItemModel>> {
  CartNotifier() : super([]);

  /// Add item to cart
  void addItem(FoodItemModel item, {int quantity = 1, String? instructions}) {
    final existingIndex = state.indexWhere((i) => i.foodItem.id == item.id);

    if (existingIndex >= 0) {
      // Update quantity if item already exists
      final existing = state[existingIndex];
      state = [
        ...state.sublist(0, existingIndex),
        existing.copyWith(quantity: existing.quantity + quantity),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      // Add new item
      state = [
        ...state,
        CartItemModel(
          foodItem: item,
          quantity: quantity,
          specialInstructions: instructions,
        ),
      ];
    }
  }

  /// Remove item from cart
  void removeItem(String itemId) {
    state = state.where((i) => i.foodItem.id != itemId).toList();
  }

  /// Update item quantity
  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    final index = state.indexWhere((i) => i.foodItem.id == itemId);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        state[index].copyWith(quantity: quantity),
        ...state.sublist(index + 1),
      ];
    }
  }

  /// Increment item quantity
  void incrementQuantity(String itemId) {
    final index = state.indexWhere((i) => i.foodItem.id == itemId);
    if (index >= 0) {
      updateQuantity(itemId, state[index].quantity + 1);
    }
  }

  /// Decrement item quantity
  void decrementQuantity(String itemId) {
    final index = state.indexWhere((i) => i.foodItem.id == itemId);
    if (index >= 0) {
      updateQuantity(itemId, state[index].quantity - 1);
    }
  }

  /// Update special instructions
  void updateInstructions(String itemId, String? instructions) {
    final index = state.indexWhere((i) => i.foodItem.id == itemId);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        state[index].copyWith(specialInstructions: instructions),
        ...state.sublist(index + 1),
      ];
    }
  }

  /// Clear all items from cart
  void clearCart() {
    state = [];
  }

  /// Get total number of items
  int get totalItems => state.fold(0, (sum, item) => sum + item.quantity);

  /// Get subtotal
  double get subtotal => state.fold(0, (sum, item) => sum + item.totalPrice);

  /// Check if item is in cart
  bool isInCart(String itemId) => state.any((i) => i.foodItem.id == itemId);

  /// Get quantity of specific item
  int getItemQuantity(String itemId) {
    final item = state.cast<CartItemModel?>().firstWhere(
      (i) => i?.foodItem.id == itemId,
      orElse: () => null,
    );
    return item?.quantity ?? 0;
  }
}

/// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItemModel>>((
  ref,
) {
  return CartNotifier();
});

/// Cart total items count provider
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

/// Cart subtotal provider
final cartSubtotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.totalPrice);
});

/// Delivery fee (mock - could be dynamic based on distance)
final deliveryFeeProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  // Free delivery over $25
  return subtotal >= 25 ? 0 : 2.99;
});

/// Tax provider (mock - 8% tax rate)
final taxProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  return subtotal * 0.08;
});

/// Cart total provider
final cartTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final deliveryFee = ref.watch(deliveryFeeProvider);
  final tax = ref.watch(taxProvider);
  return subtotal + deliveryFee + tax;
});
