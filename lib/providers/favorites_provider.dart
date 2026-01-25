import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/restaurant_model.dart';
import '../data/models/food_item_model.dart';

/// Favorites state notifier for managing favorite restaurants and food items
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier() : super(const FavoritesState());

  /// Toggle restaurant favorite
  void toggleRestaurant(RestaurantModel restaurant) {
    final currentFavorites = [...state.restaurants];
    final index = currentFavorites.indexWhere((r) => r.id == restaurant.id);

    if (index >= 0) {
      currentFavorites.removeAt(index);
    } else {
      currentFavorites.add(restaurant);
    }

    state = state.copyWith(restaurants: currentFavorites);
  }

  /// Toggle food item favorite
  void toggleFoodItem(FoodItemModel item) {
    final currentFavorites = [...state.foodItems];
    final index = currentFavorites.indexWhere((f) => f.id == item.id);

    if (index >= 0) {
      currentFavorites.removeAt(index);
    } else {
      currentFavorites.add(item);
    }

    state = state.copyWith(foodItems: currentFavorites);
  }

  /// Check if restaurant is favorite
  bool isRestaurantFavorite(String restaurantId) {
    return state.restaurants.any((r) => r.id == restaurantId);
  }

  /// Check if food item is favorite
  bool isFoodItemFavorite(String itemId) {
    return state.foodItems.any((f) => f.id == itemId);
  }

  /// Clear all favorites
  void clearAll() {
    state = const FavoritesState();
  }
}

/// Favorites state model
class FavoritesState {
  final List<RestaurantModel> restaurants;
  final List<FoodItemModel> foodItems;

  const FavoritesState({
    this.restaurants = const [],
    this.foodItems = const [],
  });

  FavoritesState copyWith({
    List<RestaurantModel>? restaurants,
    List<FoodItemModel>? foodItems,
  }) {
    return FavoritesState(
      restaurants: restaurants ?? this.restaurants,
      foodItems: foodItems ?? this.foodItems,
    );
  }

  int get totalCount => restaurants.length + foodItems.length;
}

/// Favorites provider
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
      return FavoritesNotifier();
    });

/// Favorite restaurants provider
final favoriteRestaurantsProvider = Provider<List<RestaurantModel>>((ref) {
  return ref.watch(favoritesProvider).restaurants;
});

/// Favorite food items provider
final favoriteFoodItemsProvider = Provider<List<FoodItemModel>>((ref) {
  return ref.watch(favoritesProvider).foodItems;
});

/// Check if specific restaurant is favorite
final isRestaurantFavoriteProvider = Provider.family<bool, String>((
  ref,
  restaurantId,
) {
  return ref
      .watch(favoritesProvider)
      .restaurants
      .any((r) => r.id == restaurantId);
});

/// Check if specific food item is favorite
final isFoodItemFavoriteProvider = Provider.family<bool, String>((ref, itemId) {
  return ref.watch(favoritesProvider).foodItems.any((f) => f.id == itemId);
});
