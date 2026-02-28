import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/supabase_service.dart';
import '../data/models/food_item_model.dart';
import '../data/repositories/cart_repository.dart';

/// Exception thrown when trying to add an item from a different restaurant to the cart
class RestaurantConflictException implements Exception {
  final String existingRestaurantId;
  final String newRestaurantId;

  RestaurantConflictException({
    required this.existingRestaurantId,
    required this.newRestaurantId,
  });

  @override
  String toString() =>
      'RestaurantConflictException: Existing $existingRestaurantId, New $newRestaurantId';
}

/// Cart state notifier for managing cart items with Supabase persistence
/// Falls back to SharedPreferences when user is not authenticated.
class CartNotifier extends StateNotifier<List<CartItemModel>> {
  static const String _cartKey = 'mtf_cart_items';

  final CartRepository _repo = CartRepository();

  /// The Supabase cart ID for the current session (null for guests)
  String? _cartId;

  CartNotifier() : super([]) {
    _loadCart();
  }

  // ─── Loading ───────────────────────────────────────────────────────

  /// Load cart — tries Supabase first, falls back to local storage.
  Future<void> _loadCart() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      await _loadCartFromSupabase();
    } else {
      await _loadCartFromStorage();
    }
  }

  /// Load cart from Supabase.
  Future<void> _loadCartFromSupabase() async {
    try {
      final cartData = await _repo.fetchActiveCart();
      if (cartData == null) {
        state = [];
        _cartId = null;
        debugPrint('[CartNotifier] No active Supabase cart found');
        return;
      }

      _cartId = cartData['id'] as String;
      final rawItems = cartData['cart_items'] as List<dynamic>? ?? [];

      state =
          rawItems.map((item) {
            final menuItem = item['menu_items'] as Map<String, dynamic>?;

            return CartItemModel(
              foodItem:
                  menuItem != null
                      ? FoodItemModel.fromJson(menuItem)
                      : FoodItemModel(
                        id: item['menu_item_id'] as String,
                        restaurantId:
                            cartData['restaurant_id'] as String? ?? '',
                        name: 'Unknown Item',
                        description: '',
                        imageUrl: '',
                        price: (item['unit_price'] as num?)?.toDouble() ?? 0.0,
                        category: '',
                        rating: 0,
                        reviewCount: 0,
                        preparationTime: 0,
                      ),
              quantity: item['quantity'] as int? ?? 1,
              specialInstructions: item['notes'] as String?,
            );
          }).toList();

      debugPrint(
        '[CartNotifier] Loaded ${state.length} items from Supabase cart $_cartId',
      );
    } catch (e) {
      debugPrint(
        '[CartNotifier] Error loading from Supabase, falling back: $e',
      );
      await _loadCartFromStorage();
    }
  }

  /// Load cart from local storage (guest fallback).
  Future<void> _loadCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);

      if (cartJson != null) {
        final List<dynamic> itemsList = jsonDecode(cartJson);
        state =
            itemsList
                .map(
                  (item) => CartItemModel.fromLocalStorage(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
        debugPrint('[CartNotifier] Loaded ${state.length} items from storage');
      }
    } catch (e) {
      debugPrint('[CartNotifier] Error loading cart from storage: $e');
    }
  }

  // ─── Saving ────────────────────────────────────────────────────────

  /// Save cart to local storage.
  Future<void> _saveCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(state.map((item) => item.toJson()).toList());
      await prefs.setString(_cartKey, cartJson);
    } catch (e) {
      debugPrint('[CartNotifier] Error saving cart to storage: $e');
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  /// Ensure a Supabase cart row exists; create one if needed.
  Future<String?> _ensureCartId({String? restaurantId}) async {
    if (_cartId != null) return _cartId;

    final user = SupabaseService.currentUser;
    if (user == null) return null;

    _cartId = await _repo.createCart(restaurantId: restaurantId);
    debugPrint('[CartNotifier] Created new Supabase cart: $_cartId');
    return _cartId;
  }

  /// Get the restaurant ID of the items currently in the cart
  String? get currentRestaurantId {
    if (state.isEmpty) return null;
    return state.first.foodItem.restaurantId;
  }

  // ─── Mutations ─────────────────────────────────────────────────────

  /// Add item to cart
  void addItem(FoodItemModel item, {int quantity = 1, String? instructions}) {
    // Check for restaurant conflict
    final currentRid = currentRestaurantId;
    if (currentRid != null && currentRid != item.restaurantId) {
      throw RestaurantConflictException(
        existingRestaurantId: currentRid,
        newRestaurantId: item.restaurantId,
      );
    }

    final existingIndex = state.indexWhere((i) => i.foodItem.id == item.id);

    if (existingIndex >= 0) {
      final existing = state[existingIndex];
      final newQuantity = existing.quantity + quantity;
      state = [
        ...state.sublist(0, existingIndex),
        existing.copyWith(quantity: newQuantity),
        ...state.sublist(existingIndex + 1),
      ];
      _syncUpsertItem(item.id, newQuantity, item.price, instructions);
    } else {
      state = [
        ...state,
        CartItemModel(
          foodItem: item,
          quantity: quantity,
          specialInstructions: instructions,
        ),
      ];
      _syncUpsertItem(item.id, quantity, item.price, instructions);
    }
    _saveCartToStorage();
  }

  /// Remove item from cart
  void removeItem(String itemId) {
    state = state.where((i) => i.foodItem.id != itemId).toList();
    _syncRemoveItem(itemId);
    _saveCartToStorage();
  }

  /// Update item quantity
  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    final index = state.indexWhere((i) => i.foodItem.id == itemId);
    if (index >= 0) {
      final item = state[index];
      state = [
        ...state.sublist(0, index),
        item.copyWith(quantity: quantity),
        ...state.sublist(index + 1),
      ];
      _syncUpsertItem(
        itemId,
        quantity,
        item.foodItem.price,
        item.specialInstructions,
      );
      _saveCartToStorage();
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
      final item = state[index];
      state = [
        ...state.sublist(0, index),
        item.copyWith(specialInstructions: instructions),
        ...state.sublist(index + 1),
      ];
      _syncUpsertItem(itemId, item.quantity, item.foodItem.price, instructions);
      _saveCartToStorage();
    }
  }

  /// Clear all items from cart
  void clearCart() {
    final oldCartId = _cartId;
    state = [];
    _cartId = null;
    _saveCartToStorage();

    if (oldCartId != null && SupabaseService.currentUser != null) {
      _repo.clearCart(oldCartId).catchError((e) {
        debugPrint('[CartNotifier] Error clearing Supabase cart: $e');
      });
    }
  }

  // ─── Supabase sync helpers (fire-and-forget) ───────────────────────

  void _syncUpsertItem(
    String menuItemId,
    int quantity,
    double unitPrice,
    String? notes,
  ) {
    if (SupabaseService.currentUser == null) return;

    _ensureCartId(restaurantId: currentRestaurantId).then((cartId) {
      if (cartId == null) return;
      _repo
          .upsertCartItem(
            cartId: cartId,
            menuItemId: menuItemId,
            quantity: quantity,
            unitPrice: unitPrice,
            notes: notes,
          )
          .catchError((e) {
            debugPrint('[CartNotifier] Supabase upsert error: $e');
          });
    });
  }

  void _syncRemoveItem(String menuItemId) {
    if (SupabaseService.currentUser == null || _cartId == null) return;

    _repo.removeCartItem(cartId: _cartId!, menuItemId: menuItemId).catchError((
      e,
    ) {
      debugPrint('[CartNotifier] Supabase remove error: $e');
    });
  }

  // ─── Computed getters ──────────────────────────────────────────────

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
