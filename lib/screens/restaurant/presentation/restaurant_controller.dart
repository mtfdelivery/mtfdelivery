import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/restaurant_entity.dart';

final popularRestaurantsProvider = FutureProvider<List<RestaurantEntity>>((
  ref,
) async {
  // Mock data — 10 example restaurants
  await Future.delayed(const Duration(seconds: 1));
  return [
    const RestaurantEntity(
      id: '1',
      name: 'Pizza Hut',
      imageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=500&q=60',
      description:
          'Classic New York-style pizzas with crispy crusts and generous toppings, baked fresh to order.',
      rating: 4.8,
      reviewCount: 1240,
      deliveryTime: '30-45 min',
      deliveryFee: 2.5,
      cuisineTypes: ['Pizza', 'Italian', 'Fast Food'],
      isOpen: true,
    ),
    const RestaurantEntity(
      id: '2',
      name: 'Burger King',
      imageUrl:
          'https://images.unsplash.com/photo-1571091718767-18b5b1457add?auto=format&fit=crop&w=500&q=60',
      description:
          'Flame-grilled burgers with premium Angus beef, crispy fries, and refreshing milkshakes.',
      rating: 4.2,
      reviewCount: 876,
      deliveryTime: '15-25 min',
      deliveryFee: 1.5,
      cuisineTypes: ['Burgers', 'American', 'Fast Food'],
      isOpen: true,
    ),
    const RestaurantEntity(
      id: '3',
      name: 'KFC',
      imageUrl:
          'https://images.unsplash.com/photo-1513639776629-9269d0521307?auto=format&fit=crop&w=500&q=60',
      description:
          'Finger-lickin\' good fried chicken with the Colonel\'s secret blend of 11 herbs and spices.',
      rating: 4.5,
      reviewCount: 2034,
      deliveryTime: '20-30 min',
      deliveryFee: 0.0,
      cuisineTypes: ['Chicken', 'American', 'Fast Food'],
      isOpen: true,
    ),
    const RestaurantEntity(
      id: '4',
      name: 'Sushi Art',
      imageUrl:
          'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=500&q=60',
      description:
          'Premium Japanese sushi and sashimi crafted by master chefs using the freshest daily catch.',
      rating: 4.9,
      reviewCount: 512,
      deliveryTime: '45-60 min',
      deliveryFee: 3.0,
      cuisineTypes: ['Sushi', 'Japanese', 'Asian'],
      isOpen: true,
    ),
    const RestaurantEntity(
      id: '5',
      name: 'Spice Garden',
      imageUrl:
          'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=500&q=60',
      description:
          'Authentic Indian curries, tandoori specialties, and aromatic biryanis — a journey through India\'s rich culinary heritage.',
      rating: 4.6,
      reviewCount: 389,
      deliveryTime: '35-50 min',
      deliveryFee: 2.49,
      cuisineTypes: ['Indian', 'Curry', 'Asian'],
      isOpen: true,
    ),
    const RestaurantEntity(
      id: '6',
      name: 'Taco Fiesta',
      imageUrl:
          'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=500&q=60',
      description:
          'Vibrant Mexican flavors with fresh ingredients — tacos, burritos, and quesadillas made to order.',
      rating: 4.7,
      reviewCount: 567,
      deliveryTime: '20-30 min',
      deliveryFee: 1.99,
      cuisineTypes: ['Mexican', 'Tacos', 'Latin'],
      isOpen: true,
    ),
    const RestaurantEntity(
      id: '7',
      name: 'Dragon Wok',
      imageUrl:
          'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=500&q=60',
      description:
          'Traditional Chinese cuisine with a modern twist — from dim sum to Peking duck, all cooked in a blazing wok.',
      rating: 4.4,
      reviewCount: 445,
      deliveryTime: '25-40 min',
      deliveryFee: 2.29,
      cuisineTypes: ['Chinese', 'Asian', 'Noodles'],
      isOpen: true,
    ),
    const RestaurantEntity(
      id: '8',
      name: 'Le Petit Bistro',
      imageUrl:
          'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?auto=format&fit=crop&w=500&q=60',
      description:
          'Classic French cuisine in an intimate setting — from buttery croissants to coq au vin, savor the taste of Paris.',
      rating: 4.8,
      reviewCount: 198,
      deliveryTime: '40-55 min',
      deliveryFee: 4.99,
      cuisineTypes: ['French', 'European', 'Fine Dining'],
      isOpen: true,
    ),
    const RestaurantEntity(
      id: '9',
      name: 'Green Bowl',
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=500&q=60',
      description:
          'Healthy bowls, fresh salads, and nutritious smoothies — fuel your body with the best plant-based ingredients.',
      rating: 4.6,
      reviewCount: 312,
      deliveryTime: '15-25 min',
      deliveryFee: 2.49,
      cuisineTypes: ['Healthy', 'Salads', 'Vegan'],
      isOpen: true,
    ),
    const RestaurantEntity(
      id: '10',
      name: 'BBQ Smokehouse',
      imageUrl:
          'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?auto=format&fit=crop&w=500&q=60',
      description:
          'Slow-smoked meats, tangy BBQ sauces, and classic Southern sides — BBQ done the right way.',
      rating: 4.5,
      reviewCount: 534,
      deliveryTime: '30-45 min',
      deliveryFee: 2.99,
      cuisineTypes: ['BBQ', 'American', 'Steakhouse'],
      isOpen: true,
    ),
  ];
});
