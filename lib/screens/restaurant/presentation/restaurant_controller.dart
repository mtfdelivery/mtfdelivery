import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/restaurant_entity.dart';
import '../../../providers/restaurant_providers.dart';

final popularRestaurantsProvider = FutureProvider<List<RestaurantEntity>>((
  ref,
) async {
  final repository = ref.watch(restaurantRepositoryProvider);
  final restaurants = await repository.fetchFeaturedRestaurants();

  return restaurants
      .map(
        (r) => RestaurantEntity(
          id: r.id,
          name: r.name,
          imageUrl: r.imageUrl,
          description: r.description,
          rating: r.rating,
          reviewCount: r.reviewCount,
          deliveryTime: '${r.deliveryTime} min',
          deliveryFee: r.deliveryFee,
          cuisineTypes: r.cuisine.isNotEmpty ? [r.cuisine] : [],
          categoryIds: r.categoryIds,
          isOpen: r.isOpen,
        ),
      )
      .toList();
});

/// Popular restaurants filtered by the currently selected category.
/// Returns all popular restaurants when 'all' is selected.
/// Returns only restaurants whose categoryIds contain the selected category otherwise.
final filteredPopularRestaurantsProvider =
    FutureProvider<List<RestaurantEntity>>((ref) async {
      final popular = await ref.watch(popularRestaurantsProvider.future);
      final selectedCategory = ref.watch(selectedCategoryProvider);

      if (selectedCategory == 'all') {
        return popular;
      }

      return popular
          .where((r) => r.categoryIds.contains(selectedCategory))
          .toList();
    });
