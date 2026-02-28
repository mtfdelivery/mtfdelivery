import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';
import '../data/models/restaurant_model.dart';
import '../data/models/food_item_model.dart';
import '../data/repositories/favorites_repository.dart';
import 'restaurant_providers.dart';

/// Favorites state notifier with Supabase persistence via public.wishlists.
/// Falls back to in-memory only when user is not authenticated.
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final FavoritesRepository _repo = FavoritesRepository();

  FavoritesNotifier() : super(const FavoritesState()) {
    _loadFavorites();
  }

  // ─── Loading ───────────────────────────────────────────────────────

  /// Load favorites — from Supabase if logged in, otherwise empty.
  Future<void> _loadFavorites() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      final restaurantIds = await _repo.fetchFavoriteRestaurantIds();
      final menuItemIds = await _repo.fetchFavoriteMenuItemIds();

      state = state.copyWith(
        favoriteRestaurantIds: restaurantIds,
        favoriteMenuItemIds: menuItemIds,
      );

      debugPrint(
        '[FavoritesNotifier] Loaded ${restaurantIds.length} restaurants + '
        '${menuItemIds.length} menu items from Supabase',
      );
    } catch (e) {
      debugPrint('[FavoritesNotifier] Error loading favorites: $e');
    }
  }

  // ─── Mutations ─────────────────────────────────────────────────────

  /// Toggle restaurant favorite
  void toggleRestaurant(RestaurantModel restaurant) {
    final currentIds = {...state.favoriteRestaurantIds};
    final isFav = currentIds.contains(restaurant.id);

    if (isFav) {
      currentIds.remove(restaurant.id);
    } else {
      currentIds.add(restaurant.id);
    }

    state = state.copyWith(favoriteRestaurantIds: currentIds);

    // Sync to Supabase (fire-and-forget)
    _syncToggle('restaurant', restaurant.id, !isFav);
  }

  /// Toggle food item favorite
  void toggleFoodItem(FoodItemModel item) {
    final currentIds = {...state.favoriteMenuItemIds};
    final isFav = currentIds.contains(item.id);

    if (isFav) {
      currentIds.remove(item.id);
    } else {
      currentIds.add(item.id);
    }

    state = state.copyWith(favoriteMenuItemIds: currentIds);

    // Sync to Supabase (fire-and-forget)
    _syncToggle('menu_item', item.id, !isFav);
  }

  /// Check if restaurant is favorite
  bool isRestaurantFavorite(String restaurantId) {
    return state.favoriteRestaurantIds.contains(restaurantId);
  }

  /// Check if food item is favorite
  bool isFoodItemFavorite(String itemId) {
    return state.favoriteMenuItemIds.contains(itemId);
  }

  /// Clear all favorites
  void clearAll() {
    state = const FavoritesState();
  }

  // ─── Supabase sync helper (fire-and-forget) ────────────────────────

  void _syncToggle(String targetType, String targetId, bool add) {
    if (SupabaseService.currentUser == null) return;

    final future =
        add
            ? _repo.addFavorite(targetType: targetType, targetId: targetId)
            : _repo.removeFavorite(targetType: targetType, targetId: targetId);

    future.catchError((e) {
      debugPrint('[FavoritesNotifier] Supabase sync error: $e');
    });
  }
}

/// Favorites state model — tracks only IDs (for quick lookups)
class FavoritesState {
  final Set<String> favoriteRestaurantIds;
  final Set<String> favoriteMenuItemIds;

  const FavoritesState({
    this.favoriteRestaurantIds = const {},
    this.favoriteMenuItemIds = const {},
  });

  FavoritesState copyWith({
    Set<String>? favoriteRestaurantIds,
    Set<String>? favoriteMenuItemIds,
  }) {
    return FavoritesState(
      favoriteRestaurantIds:
          favoriteRestaurantIds ?? this.favoriteRestaurantIds,
      favoriteMenuItemIds: favoriteMenuItemIds ?? this.favoriteMenuItemIds,
    );
  }

  int get totalCount =>
      favoriteRestaurantIds.length + favoriteMenuItemIds.length;
}

/// Favorites provider
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
      return FavoritesNotifier();
    });

/// Favorite restaurants provider (derived from realtime restaurants)
final favoriteRestaurantsProvider = Provider<List<RestaurantModel>>((ref) {
  final favoriteIds = ref.watch(favoritesProvider).favoriteRestaurantIds;
  final allRestaurants = ref.watch(restaurantsProvider).value ?? [];
  return allRestaurants.where((r) => favoriteIds.contains(r.id)).toList();
});

/// Favorite food items provider
final favoriteFoodItemsProvider = Provider<List<FoodItemModel>>((ref) {
  return [];
});

/// Check if specific restaurant is favorite (by ID)
final isRestaurantFavoriteProvider = Provider.family<bool, String>((
  ref,
  restaurantId,
) {
  return ref
      .watch(favoritesProvider)
      .favoriteRestaurantIds
      .contains(restaurantId);
});

/// Check if specific food item is favorite (by ID)
final isFoodItemFavoriteProvider = Provider.family<bool, String>((ref, itemId) {
  return ref.watch(favoritesProvider).favoriteMenuItemIds.contains(itemId);
});
