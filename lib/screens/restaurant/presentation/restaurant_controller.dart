import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/restaurant_entity.dart';

final popularRestaurantsProvider = FutureProvider<List<RestaurantEntity>>((
  ref,
) async {
  // Mock data for now
  await Future.delayed(const Duration(seconds: 1));
  return [
    const RestaurantEntity(
      id: '1',
      name: 'Pizza Hut',
      imageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=500&q=60',
      rating: 4.8,
      deliveryTime: '30-45 min',
      deliveryFee: 2.5,
    ),
    const RestaurantEntity(
      id: '2',
      name: 'Burger King',
      imageUrl:
          'https://images.unsplash.com/photo-1571091718767-18b5b1457add?auto=format&fit=crop&w=500&q=60',
      rating: 4.2,
      deliveryTime: '15-25 min',
      deliveryFee: 1.5,
    ),
    const RestaurantEntity(
      id: '3',
      name: 'KFC',
      imageUrl:
          'https://images.unsplash.com/photo-1513639776629-9269d0521307?auto=format&fit=crop&w=500&q=60',
      rating: 4.5,
      deliveryTime: '20-30 min',
      deliveryFee: 0.0,
    ),
    const RestaurantEntity(
      id: '4',
      name: 'Sushi Art',
      imageUrl:
          'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=500&q=60',
      rating: 4.9,
      deliveryTime: '45-60 min',
      deliveryFee: 3.0,
    ),
  ];
});
