import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/restaurant_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/models/restaurant_model.dart';
import '../data/models/food_item_model.dart';
import '../data/models/category_model.dart';
import '../screens/restaurant/domain/customization_entity.dart';

// Repositories
final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepository();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

// App Data Providers

/// Categories (cached)
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.fetchCategories();
});

/// All restaurants (cached)
final restaurantsProvider = FutureProvider<List<RestaurantModel>>((ref) async {
  final repository = ref.watch(restaurantRepositoryProvider);
  return repository.fetchRestaurants();
});

/// Featured restaurants only (cached)
final featuredRestaurantsProvider = FutureProvider<List<RestaurantModel>>((
  ref,
) async {
  final repository = ref.watch(restaurantRepositoryProvider);
  return repository.fetchFeaturedRestaurants();
});

/// Menu items for a restaurant - REALTIME STREAM
/// This provider uses a Stream to listen for changes in availability, price, etc.
final restaurantMenuStreamProvider =
    StreamProvider.family<List<FoodItemModel>, String>((ref, restaurantId) {
      final repository = ref.watch(restaurantRepositoryProvider);
      return repository.watchMenuItems(restaurantId);
    });

// Single Restaurant Provider (helper)
final restaurantProvider = FutureProvider.family<RestaurantModel?, String>((
  ref,
  id,
) async {
  final restaurants = await ref.watch(restaurantsProvider.future);
  return restaurants.cast<RestaurantModel?>().firstWhere(
    (r) => r?.id == id,
    orElse: () => null,
  );
});

/// Customization groups for a specific menu item
final menuItemAddonsProvider =
    FutureProvider.family<List<CustomizationGroup>, String>((
      ref,
      itemId,
    ) async {
      final repository = ref.watch(restaurantRepositoryProvider);
      return repository.fetchAddonGroups(itemId);
    });
