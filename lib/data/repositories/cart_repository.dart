import 'package:flutter/foundation.dart';
import '../../core/services/supabase_service.dart';

/// Repository for Supabase-backed cart operations (food.carts + food.cart_items)
class CartRepository {
  /// Fetch the active cart for the current user.
  /// Returns null if no cart exists.
  Future<Map<String, dynamic>?> fetchActiveCart() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    try {
      final response =
          await SupabaseService.client
              .schema('food')
              .from('carts')
              .select(
                '*, cart_items(*, menu_items(id, restaurant_id, name, description, images, price, compare_price, is_vegetarian, is_vegan, is_spicy, is_popular, prep_time_min, calories, is_available, menu_sections(name)))',
              )
              .eq('user_id', user.id)
              .order('updated_at', ascending: false)
              .limit(1)
              .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('[CartRepository] Error fetching active cart: $e');
      return null;
    }
  }

  /// Create a new cart for the current user.
  Future<String?> createCart({String? restaurantId}) async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    try {
      final response =
          await SupabaseService.client
              .schema('food')
              .from('carts')
              .insert({
                'user_id': user.id,
                if (restaurantId != null) 'restaurant_id': restaurantId,
              })
              .select('id')
              .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('[CartRepository] Error creating cart: $e');
      return null;
    }
  }

  /// Add or update an item in the cart.
  /// If the item already exists (same cart_id + menu_item_id), update quantity.
  Future<void> upsertCartItem({
    required String cartId,
    required String menuItemId,
    required int quantity,
    required double unitPrice,
    String? notes,
  }) async {
    try {
      // Check if item already exists in the cart
      final existing =
          await SupabaseService.client
              .schema('food')
              .from('cart_items')
              .select('id, quantity')
              .eq('cart_id', cartId)
              .eq('menu_item_id', menuItemId)
              .maybeSingle();

      if (existing != null) {
        // Update existing item
        await SupabaseService.client
            .schema('food')
            .from('cart_items')
            .update({
              'quantity': quantity,
              'unit_price': unitPrice,
              if (notes != null) 'notes': notes,
            })
            .eq('id', existing['id']);
      } else {
        // Insert new item
        await SupabaseService.client.schema('food').from('cart_items').insert({
          'cart_id': cartId,
          'menu_item_id': menuItemId,
          'quantity': quantity,
          'unit_price': unitPrice,
          'notes': notes,
        });
      }

      // Touch the cart's updated_at
      await SupabaseService.client
          .schema('food')
          .from('carts')
          .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', cartId);
    } catch (e) {
      debugPrint('[CartRepository] Error upserting cart item: $e');
      rethrow;
    }
  }

  /// Remove a single item from the cart by menu_item_id.
  Future<void> removeCartItem({
    required String cartId,
    required String menuItemId,
  }) async {
    try {
      await SupabaseService.client
          .schema('food')
          .from('cart_items')
          .delete()
          .eq('cart_id', cartId)
          .eq('menu_item_id', menuItemId);
    } catch (e) {
      debugPrint('[CartRepository] Error removing cart item: $e');
      rethrow;
    }
  }

  /// Clear all items from a cart and delete the cart itself.
  Future<void> clearCart(String cartId) async {
    try {
      // Delete all cart items (cascade should handle this, but be explicit)
      await SupabaseService.client
          .schema('food')
          .from('cart_items')
          .delete()
          .eq('cart_id', cartId);

      // Delete the cart
      await SupabaseService.client
          .schema('food')
          .from('carts')
          .delete()
          .eq('id', cartId);
    } catch (e) {
      debugPrint('[CartRepository] Error clearing cart: $e');
      rethrow;
    }
  }

  /// Update the restaurant_id on the cart (when first item is added).
  Future<void> updateCartRestaurant({
    required String cartId,
    required String restaurantId,
  }) async {
    try {
      await SupabaseService.client
          .schema('food')
          .from('carts')
          .update({
            'restaurant_id': restaurantId,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', cartId);
    } catch (e) {
      debugPrint('[CartRepository] Error updating cart restaurant: $e');
      rethrow;
    }
  }
}
