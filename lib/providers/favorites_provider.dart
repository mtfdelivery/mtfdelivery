import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';
import '../data/models/restaurant_model.dart';
import '../data/models/food_item_model.dart';
import '../data/repositories/favorites_repository.dart';

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

    // Update local state first (optimistic)
    final currentRestaurants = [...state.restaurants];
    if (isFav) {
      currentRestaurants.removeWhere((r) => r.id == restaurant.id);
    } else {
      currentRestaurants.add(restaurant);
    }

    state = state.copyWith(
      favoriteRestaurantIds: currentIds,
      restaurants: currentRestaurants,
    );

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

    // Update local state first (optimistic)
    final currentItems = [...state.foodItems];
    if (isFav) {
      currentItems.removeWhere((f) => f.id == item.id);
    } else {
      currentItems.add(item);
    }

    state = state.copyWith(
      favoriteMenuItemIds: currentIds,
      foodItems: currentItems,
    );

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

/// Favorites state model — tracks both IDs (for quick lookups)
/// and full model objects (for display on favorites page).
class FavoritesState {
  final Set<String> favoriteRestaurantIds;
  final Set<String> favoriteMenuItemIds;
  final List<RestaurantModel> restaurants;
  final List<FoodItemModel> foodItems;

  const FavoritesState({
    this.favoriteRestaurantIds = const {},
    this.favoriteMenuItemIds = const {},
    this.restaurants = const [],
    this.foodItems = const [],
  });

  FavoritesState copyWith({
    Set<String>? favoriteRestaurantIds,
    Set<String>? favoriteMenuItemIds,
    List<RestaurantModel>? restaurants,
    List<FoodItemModel>? foodItems,
  }) {
    return FavoritesState(
      favoriteRestaurantIds:
          favoriteRestaurantIds ?? this.favoriteRestaurantIds,
      favoriteMenuItemIds: favoriteMenuItemIds ?? this.favoriteMenuItemIds,
      restaurants: restaurants ?? this.restaurants,
      foodItems: foodItems ?? this.foodItems,
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

/// Favorite restaurants provider (full models, for favorites page)
final favoriteRestaurantsProvider = Provider<List<RestaurantModel>>((ref) {
  return ref.watch(favoritesProvider).restaurants;
});

/// Favorite food items provider (full models, for favorites page)
final favoriteFoodItemsProvider = Provider<List<FoodItemModel>>((ref) {
  return ref.watch(favoritesProvider).foodItems;
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
