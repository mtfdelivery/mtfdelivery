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

/// Selected category ID for filtering ('all' for no filter)
final selectedCategoryProvider = StateProvider<String>((ref) => 'all');

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

/// Filtered restaurants based on selected category
final filteredRestaurantsProvider = FutureProvider<List<RestaurantModel>>((
  ref,
) async {
  final restaurants = await ref.watch(restaurantsProvider.future);
  final selectedCategoryId = ref.watch(selectedCategoryProvider);

  if (selectedCategoryId == 'all') {
    return restaurants;
  }

  return restaurants.where((r) {
    return r.categoryIds.contains(selectedCategoryId);
  }).toList();
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
  // Try from cached list first
  final restaurants = await ref.watch(restaurantsProvider.future);
  final found = restaurants.cast<RestaurantModel?>().firstWhere(
    (r) => r?.id == id,
    orElse: () => null,
  );
  if (found != null) return found;

  // Fall back to direct fetch
  final repository = ref.watch(restaurantRepositoryProvider);
  return repository.fetchRestaurantById(id);
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
