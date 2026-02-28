import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
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

  // Set up real-time listener
  final channel =
      SupabaseService.client
          .channel('restaurants_all_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'food',
            table: 'restaurants',
            callback: (payload) {
              ref.invalidateSelf();
            },
          )
          .subscribe();

  ref.onDispose(() {
    SupabaseService.client.removeChannel(channel);
  });

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

  // Set up real-time listener
  final channel =
      SupabaseService.client
          .channel('restaurants_featured_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'food',
            table: 'restaurants',
            callback: (payload) {
              ref.invalidateSelf();
            },
          )
          .subscribe();

  ref.onDispose(() {
    SupabaseService.client.removeChannel(channel);
  });

  return repository.fetchFeaturedRestaurants();
});

/// Featured restaurants filtered by the currently selected category.
/// Returns all featured restaurants when 'all' is selected.
final filteredFeaturedRestaurantsProvider =
    FutureProvider<List<RestaurantModel>>((ref) async {
      final featured = await ref.watch(featuredRestaurantsProvider.future);
      final selectedCategory = ref.watch(selectedCategoryProvider);

      if (selectedCategory == 'all') {
        return featured;
      }

      return featured
          .where((r) => r.categoryIds.contains(selectedCategory))
          .toList();
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
  final repository = ref.watch(restaurantRepositoryProvider);

  final channel =
      SupabaseService.client
          .channel('restaurant_$id')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'food',
            table: 'restaurants',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: id,
            ),
            callback: (payload) {
              ref.invalidateSelf();
            },
          )
          .subscribe();

  ref.onDispose(() {
    SupabaseService.client.removeChannel(channel);
  });

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
