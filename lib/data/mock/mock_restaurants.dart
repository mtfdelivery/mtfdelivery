import '../models/restaurant_model.dart';

/// Mock restaurant data with realistic content
class MockRestaurants {
  MockRestaurants._();

  static const List<RestaurantModel> restaurants = [
    RestaurantModel(
      id: 'r1',
      name: 'Bella Italia',
      imageUrl:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600',
      logoUrl:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=100',
      description:
          'Authentic Italian cuisine with handmade pasta and wood-fired pizzas. Experience the taste of Italy in every bite.',
      rating: 4.8,
      reviewCount: 324,
      cuisine: 'Italian',
      cuisineTypes: ['Italian', 'Pizza', 'Pasta'],
      deliveryTime: 25,
      deliveryFee: 2.99,
      minOrder: 15.0,
      distance: 1.2,
      priceRange: '\$\$',
      isFeatured: true,
      isOpen: true,
      address: '123 Main Street, Downtown',
      openingHours: '11:00 AM - 10:00 PM',
      phone: '+1 234 567 8900',
    ),
    RestaurantModel(
      id: 'r2',
      name: 'Sakura Sushi',
      imageUrl:
          'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=600',
      logoUrl:
          'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=100',
      description:
          'Premium Japanese sushi and sashimi prepared by master chefs. Fresh fish delivered daily.',
      rating: 4.9,
      reviewCount: 512,
      cuisine: 'Japanese',
      cuisineTypes: ['Japanese', 'Sushi', 'Asian'],
      deliveryTime: 30,
      deliveryFee: 3.49,
      minOrder: 20.0,
      distance: 2.5,
      priceRange: '\$\$\$',
      isFeatured: true,
      isOpen: true,
      address: '456 Ocean Boulevard',
      openingHours: '12:00 PM - 11:00 PM',
      phone: '+1 234 567 8901',
    ),
    RestaurantModel(
      id: 'r3',
      name: 'Burger Palace',
      imageUrl:
          'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=600',
      logoUrl:
          'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=100',
      description:
          'Gourmet burgers with premium Angus beef patties, crispy fries, and creamy milkshakes.',
      rating: 4.5,
      reviewCount: 876,
      cuisine: 'American',
      cuisineTypes: ['American', 'Burgers', 'Fast Food'],
      deliveryTime: 20,
      deliveryFee: 1.99,
      minOrder: 10.0,
      distance: 0.8,
      priceRange: '\$',
      isFeatured: false,
      isOpen: true,
      address: '789 Food Court Plaza',
      openingHours: '10:00 AM - 12:00 AM',
      phone: '+1 234 567 8902',
    ),
    RestaurantModel(
      id: 'r4',
      name: 'Spice Garden',
      imageUrl:
          'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=600',
      logoUrl:
          'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=100',
      description:
          'Authentic Indian curries, tandoori specialties, and aromatic biryanis. A journey through India\'s rich culinary heritage.',
      rating: 4.6,
      reviewCount: 234,
      cuisine: 'Indian',
      cuisineTypes: ['Indian', 'Curry', 'Asian'],
      deliveryTime: 35,
      deliveryFee: 2.49,
      minOrder: 18.0,
      distance: 3.1,
      priceRange: '\$\$',
      isFeatured: true,
      isOpen: true,
      address: '321 Spice Lane',
      openingHours: '11:30 AM - 10:30 PM',
      phone: '+1 234 567 8903',
    ),
    RestaurantModel(
      id: 'r5',
      name: 'Dragon Wok',
      imageUrl:
          'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=600',
      logoUrl:
          'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=100',
      description:
          'Traditional Chinese cuisine with a modern twist. From dim sum to Peking duck, we\'ve got it all.',
      rating: 4.4,
      reviewCount: 445,
      cuisine: 'Chinese',
      cuisineTypes: ['Chinese', 'Asian', 'Noodles'],
      deliveryTime: 28,
      deliveryFee: 2.29,
      minOrder: 15.0,
      distance: 1.8,
      priceRange: '\$\$',
      isFeatured: false,
      isOpen: true,
      address: '567 Chinatown Street',
      openingHours: '11:00 AM - 11:00 PM',
      phone: '+1 234 567 8904',
    ),
    RestaurantModel(
      id: 'r6',
      name: 'Taco Fiesta',
      imageUrl:
          'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=600',
      logoUrl:
          'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=100',
      description:
          'Vibrant Mexican flavors with fresh ingredients. Tacos, burritos, and margaritas to die for!',
      rating: 4.7,
      reviewCount: 567,
      cuisine: 'Mexican',
      cuisineTypes: ['Mexican', 'Tacos', 'Latin'],
      deliveryTime: 22,
      deliveryFee: 1.99,
      minOrder: 12.0,
      distance: 1.5,
      priceRange: '\$',
      isFeatured: true,
      isOpen: true,
      address: '890 Fiesta Avenue',
      openingHours: '10:00 AM - 11:00 PM',
      phone: '+1 234 567 8905',
    ),
    RestaurantModel(
      id: 'r7',
      name: 'Mediterranean Delight',
      imageUrl:
          'https://images.unsplash.com/photo-1544025162-d76694265947?w=600',
      logoUrl:
          'https://images.unsplash.com/photo-1544025162-d76694265947?w=100',
      description:
          'Fresh Mediterranean cuisine featuring grilled meats, hummus, falafel, and vibrant salads.',
      rating: 4.5,
      reviewCount: 289,
      cuisine: 'Mediterranean',
      cuisineTypes: ['Mediterranean', 'Greek', 'Healthy'],
      deliveryTime: 30,
      deliveryFee: 2.99,
      minOrder: 16.0,
      distance: 2.2,
      priceRange: '\$\$',
      isFeatured: false,
      isOpen: true,
      address: '234 Olive Street',
      openingHours: '11:00 AM - 10:00 PM',
      phone: '+1 234 567 8906',
    ),
    RestaurantModel(
      id: 'r8',
      name: 'Thai Orchid',
      imageUrl:
          'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=600',
      logoUrl:
          'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=100',
      description:
          'Exquisite Thai dishes with the perfect balance of sweet, sour, salty, and spicy flavors.',
      rating: 4.6,
      reviewCount: 378,
      cuisine: 'Thai',
      cuisineTypes: ['Thai', 'Asian', 'Curry'],
      deliveryTime: 32,
      deliveryFee: 2.49,
      minOrder: 15.0,
      distance: 2.8,
      priceRange: '\$\$',
      isFeatured: false,
      isOpen: true,
      address: '678 Bangkok Road',
      openingHours: '11:30 AM - 10:30 PM',
      phone: '+1 234 567 8907',
    ),
    RestaurantModel(
      id: 'r9',
      name: 'Le Petit Bistro',
      imageUrl:
          'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?w=600',
      logoUrl:
          'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?w=100',
      description:
          'Classic French cuisine in an intimate setting. From croissants to coq au vin, savor the taste of Paris.',
      rating: 4.8,
      reviewCount: 198,
      cuisine: 'French',
      cuisineTypes: ['French', 'European', 'Fine Dining'],
      deliveryTime: 40,
      deliveryFee: 4.99,
      minOrder: 25.0,
      distance: 3.5,
      priceRange: '\$\$\$',
      isFeatured: true,
      isOpen: true,
      address: '12 Paris Lane',
      openingHours: '12:00 PM - 10:00 PM',
      phone: '+1 234 567 8908',
    ),
    RestaurantModel(
      id: 'r10',
      name: 'Seoul Kitchen',
      imageUrl:
          'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?w=600',
      logoUrl:
          'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?w=100',
      description:
          'Authentic Korean BBQ and traditional dishes. Sizzling meats, savory stews, and perfect banchan.',
      rating: 4.7,
      reviewCount: 421,
      cuisine: 'Korean',
      cuisineTypes: ['Korean', 'Asian', 'BBQ'],
      deliveryTime: 35,
      deliveryFee: 2.99,
      minOrder: 20.0,
      distance: 2.1,
      priceRange: '\$\$',
      isFeatured: false,
      isOpen: true,
      address: '456 Seoul Street',
      openingHours: '11:00 AM - 11:00 PM',
      phone: '+1 234 567 8909',
    ),
    RestaurantModel(
      id: 'r11',
      name: 'Pizza Paradise',
      imageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600',
      logoUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=100',
      description:
          'New York style pizzas with thin, crispy crusts and generous toppings. Made fresh from scratch daily.',
      rating: 4.4,
      reviewCount: 756,
      cuisine: 'Italian',
      cuisineTypes: ['Pizza', 'Italian', 'Fast Food'],
      deliveryTime: 25,
      deliveryFee: 0.0,
      minOrder: 12.0,
      distance: 0.9,
      priceRange: '\$',
      isFeatured: false,
      isOpen: true,
      address: '789 Slice Avenue',
      openingHours: '10:00 AM - 1:00 AM',
      phone: '+1 234 567 8910',
    ),
    RestaurantModel(
      id: 'r12',
      name: 'Green Bowl',
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600',
      logoUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=100',
      description:
          'Healthy bowls, fresh salads, and nutritious smoothies. Fuel your body with the best ingredients.',
      rating: 4.6,
      reviewCount: 312,
      cuisine: 'Healthy',
      cuisineTypes: ['Healthy', 'Salads', 'Vegan'],
      deliveryTime: 20,
      deliveryFee: 2.49,
      minOrder: 14.0,
      distance: 1.3,
      priceRange: '\$\$',
      isFeatured: true,
      isOpen: true,
      address: '321 Wellness Way',
      openingHours: '8:00 AM - 9:00 PM',
      phone: '+1 234 567 8911',
    ),
    RestaurantModel(
      id: 'r13',
      name: 'BBQ Smokehouse',
      imageUrl:
          'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=600',
      logoUrl:
          'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=100',
      description:
          'Slow-smoked meats, tangy BBQ sauces, and classic Southern sides. BBQ done right.',
      rating: 4.5,
      reviewCount: 534,
      cuisine: 'BBQ',
      cuisineTypes: ['BBQ', 'American', 'Steakhouse'],
      deliveryTime: 35,
      deliveryFee: 2.99,
      minOrder: 18.0,
      distance: 2.4,
      priceRange: '\$\$',
      isFeatured: false,
      isOpen: true,
      address: '567 Smoke Lane',
      openingHours: '11:00 AM - 10:00 PM',
      phone: '+1 234 567 8912',
    ),
    RestaurantModel(
      id: 'r14',
      name: 'Sweet Treats',
      imageUrl:
          'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=600',
      logoUrl:
          'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=100',
      description:
          'Decadent desserts, artisan cakes, and creamy ice cream. Life is sweet at Sweet Treats!',
      rating: 4.9,
      reviewCount: 678,
      cuisine: 'Desserts',
      cuisineTypes: ['Desserts', 'Bakery', 'Ice Cream'],
      deliveryTime: 25,
      deliveryFee: 1.99,
      minOrder: 10.0,
      distance: 1.0,
      priceRange: '\$\$',
      isFeatured: true,
      isOpen: true,
      address: '890 Sugar Street',
      openingHours: '9:00 AM - 11:00 PM',
      phone: '+1 234 567 8913',
    ),
    RestaurantModel(
      id: 'r15',
      name: 'Pho House',
      imageUrl:
          'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600',
      logoUrl:
          'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=100',
      description:
          'Steaming bowls of Vietnamese pho, fresh spring rolls, and banh mi sandwiches.',
      rating: 4.7,
      reviewCount: 389,
      cuisine: 'Vietnamese',
      cuisineTypes: ['Vietnamese', 'Asian', 'Noodles'],
      deliveryTime: 28,
      deliveryFee: 2.29,
      minOrder: 12.0,
      distance: 1.7,
      priceRange: '\$',
      isFeatured: false,
      isOpen: true,
      address: '234 Saigon Road',
      openingHours: '10:00 AM - 10:00 PM',
      phone: '+1 234 567 8914',
    ),
  ];

  /// Get featured restaurants
  static List<RestaurantModel> get featured =>
      restaurants.where((r) => r.isFeatured).toList();

  /// Get restaurants by cuisine
  static List<RestaurantModel> getByCuisine(String cuisine) =>
      restaurants
          .where(
            (r) =>
                r.cuisine.toLowerCase() == cuisine.toLowerCase() ||
                r.cuisineTypes.any(
                  (c) => c.toLowerCase() == cuisine.toLowerCase(),
                ),
          )
          .toList();

  /// Get restaurant by ID
  static RestaurantModel? getById(String id) => restaurants
      .cast<RestaurantModel?>()
      .firstWhere((r) => r?.id == id, orElse: () => null);
}
