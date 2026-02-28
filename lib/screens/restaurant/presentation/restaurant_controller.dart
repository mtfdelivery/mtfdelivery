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
          cuisineTypes:
              r.cuisine.isNotEmpty
                  ? [r.cuisine]
                  : [], // Use the cuisine field from RestaurantModel
          isOpen: r.isOpen,
        ),
      )
      .toList();
});
