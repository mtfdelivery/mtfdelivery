import 'package:flutter/foundation.dart';
import '../../core/services/supabase_service.dart';

/// Repository for Supabase-backed favorites/wishlist operations (public.wishlists)
class FavoritesRepository {
  static const String _appContext = 'food';

  /// Fetch all wishlist entries for the current user.
  /// Returns a list of maps with [target_type] and [target_id].
  Future<List<Map<String, dynamic>>> fetchFavorites() async {
    final user = SupabaseService.currentUser;
    if (user == null) return [];

    try {
      final response = await SupabaseService.client
          .from('wishlists')
          .select('id, target_type, target_id, created_at')
          .eq('user_id', user.id)
          .eq('app_context', _appContext)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('[FavoritesRepository] Error fetching favorites: $e');
      return [];
    }
  }

  /// Fetch favorite restaurant IDs for the current user.
  Future<Set<String>> fetchFavoriteRestaurantIds() async {
    final all = await fetchFavorites();
    return all
        .where((w) => w['target_type'] == 'restaurant')
        .map((w) => w['target_id'] as String)
        .toSet();
  }

  /// Fetch favorite menu item IDs for the current user.
  Future<Set<String>> fetchFavoriteMenuItemIds() async {
    final all = await fetchFavorites();
    return all
        .where((w) => w['target_type'] == 'menu_item')
        .map((w) => w['target_id'] as String)
        .toSet();
  }

  /// Add a favorite (restaurant or menu_item).
  Future<void> addFavorite({
    required String targetType,
    required String targetId,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      await SupabaseService.client.from('wishlists').upsert({
        'user_id': user.id,
        'app_context': _appContext,
        'target_type': targetType,
        'target_id': targetId,
      }, onConflict: 'user_id, app_context, target_type, target_id');
    } catch (e) {
      debugPrint('[FavoritesRepository] Error adding favorite: $e');
      rethrow;
    }
  }

  /// Remove a favorite.
  Future<void> removeFavorite({
    required String targetType,
    required String targetId,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      await SupabaseService.client
          .from('wishlists')
          .delete()
          .eq('user_id', user.id)
          .eq('app_context', _appContext)
          .eq('target_type', targetType)
          .eq('target_id', targetId);
    } catch (e) {
      debugPrint('[FavoritesRepository] Error removing favorite: $e');
      rethrow;
    }
  }
}
