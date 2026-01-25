import '../models/review_model.dart';

/// Mock review data
class MockReviews {
  MockReviews._();

  static final List<ReviewModel> reviews = [
    ReviewModel(
      id: 'rev1',
      userId: 'u1',
      userName: 'John Smith',
      userAvatar:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100',
      restaurantId: 'r1',
      rating: 5.0,
      comment:
          'Amazing Italian food! The pasta was perfectly cooked and the pizza had the most authentic taste. Will definitely order again!',
      date: DateTime.now().subtract(const Duration(days: 2)),
      helpfulCount: 24,
    ),
    ReviewModel(
      id: 'rev2',
      userId: 'u2',
      userName: 'Sarah Johnson',
      userAvatar:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
      restaurantId: 'r1',
      rating: 4.5,
      comment:
          'Delicious food and quick delivery. The tiramisu was heavenly! Only minor issue was the garlic bread was a bit cold.',
      date: DateTime.now().subtract(const Duration(days: 5)),
      helpfulCount: 18,
      reply:
          'Thank you for your feedback! We\'ll ensure the garlic bread stays warm next time.',
    ),
    ReviewModel(
      id: 'rev3',
      userId: 'u3',
      userName: 'Mike Chen',
      userAvatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      restaurantId: 'r2',
      rating: 5.0,
      comment:
          'Best sushi in town! Fresh fish, perfect rice, and the presentation was beautiful. The dragon roll is a must-try!',
      date: DateTime.now().subtract(const Duration(days: 1)),
      images: [
        'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400',
      ],
      helpfulCount: 45,
    ),
    ReviewModel(
      id: 'rev4',
      userId: 'u4',
      userName: 'Emily Davis',
      userAvatar:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100',
      restaurantId: 'r2',
      rating: 4.0,
      comment:
          'Great sushi quality but the portion sizes could be bigger for the price. Service was excellent though!',
      date: DateTime.now().subtract(const Duration(days: 7)),
      helpfulCount: 12,
    ),
    ReviewModel(
      id: 'rev5',
      userId: 'u5',
      userName: 'David Wilson',
      userAvatar:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
      restaurantId: 'r3',
      rating: 4.5,
      comment:
          'Juicy burgers with the perfect char! The loaded fries are insane. Fast delivery too.',
      date: DateTime.now().subtract(const Duration(days: 3)),
      helpfulCount: 34,
    ),
    ReviewModel(
      id: 'rev6',
      userId: 'u6',
      userName: 'Lisa Anderson',
      userAvatar:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
      restaurantId: 'r4',
      rating: 5.0,
      comment:
          'Authentic Indian flavors that remind me of home! The butter chicken is creamy perfection and the naan is soft and fluffy.',
      date: DateTime.now().subtract(const Duration(days: 4)),
      helpfulCount: 28,
    ),
    ReviewModel(
      id: 'rev7',
      userId: 'u7',
      userName: 'Tom Brown',
      userAvatar:
          'https://images.unsplash.com/photo-1463453091185-61582044d556?w=100',
      restaurantId: 'r5',
      rating: 4.0,
      comment:
          'Good Chinese food with generous portions. The kung pao chicken had the perfect spice level!',
      date: DateTime.now().subtract(const Duration(days: 6)),
      helpfulCount: 15,
    ),
    ReviewModel(
      id: 'rev8',
      userId: 'u8',
      userName: 'Jennifer Taylor',
      userAvatar:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
      restaurantId: 'r6',
      rating: 5.0,
      comment:
          'Best tacos I\'ve ever had! Fresh ingredients, flavorful meat, and the salsa verde is incredible.',
      date: DateTime.now().subtract(const Duration(days: 2)),
      images: [
        'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?w=400',
      ],
      helpfulCount: 52,
    ),
    ReviewModel(
      id: 'rev9',
      userId: 'u9',
      userName: 'Robert Martinez',
      userAvatar:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100',
      restaurantId: 'r6',
      rating: 4.5,
      comment:
          'Authentic Mexican flavors! The burrito was massive and packed with flavor. Great value for money.',
      date: DateTime.now().subtract(const Duration(days: 8)),
      helpfulCount: 20,
    ),
    ReviewModel(
      id: 'rev10',
      userId: 'u10',
      userName: 'Amanda White',
      userAvatar:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100',
      restaurantId: 'r8',
      rating: 4.5,
      comment:
          'Love the pad thai here! Perfect balance of sweet and sour. The green curry was also amazing.',
      date: DateTime.now().subtract(const Duration(days: 1)),
      helpfulCount: 19,
    ),
    ReviewModel(
      id: 'rev11',
      userId: 'u11',
      userName: 'Chris Lee',
      userAvatar:
          'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=100',
      restaurantId: 'r10',
      rating: 5.0,
      comment:
          'The Korean BBQ platter was amazing! Meat was perfectly marinated and the banchan selection was impressive.',
      date: DateTime.now().subtract(const Duration(days: 5)),
      helpfulCount: 38,
    ),
    ReviewModel(
      id: 'rev12',
      userId: 'u12',
      userName: 'Michelle Garcia',
      userAvatar:
          'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=100',
      restaurantId: 'r12',
      rating: 4.5,
      comment:
          'Healthy and delicious! The acai bowl was refreshing and the salads are so fresh. Perfect for a light meal.',
      date: DateTime.now().subtract(const Duration(days: 3)),
      helpfulCount: 22,
    ),
    ReviewModel(
      id: 'rev13',
      userId: 'u13',
      userName: 'Kevin Park',
      userAvatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      restaurantId: 'r14',
      rating: 5.0,
      comment:
          'The chocolate lava cake is to die for! Best desserts in the city. Everything is made fresh.',
      date: DateTime.now().subtract(const Duration(days: 2)),
      helpfulCount: 67,
    ),
    ReviewModel(
      id: 'rev14',
      userId: 'u14',
      userName: 'Rachel Kim',
      userAvatar:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100',
      restaurantId: 'r15',
      rating: 4.5,
      comment:
          'The pho here is authentic and comforting. Rich broth and generous portions. Banh mi is also excellent!',
      date: DateTime.now().subtract(const Duration(days: 4)),
      helpfulCount: 31,
    ),
    ReviewModel(
      id: 'rev15',
      userId: 'u15',
      userName: 'James Thompson',
      userAvatar:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100',
      restaurantId: 'r9',
      rating: 5.0,
      comment:
          'Exquisite French cuisine! The croissants are flaky perfection and the French onion soup is divine.',
      date: DateTime.now().subtract(const Duration(days: 6)),
      helpfulCount: 25,
    ),
    ReviewModel(
      id: 'rev16',
      userId: 'u16',
      userName: 'Sophie Turner',
      userAvatar:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
      restaurantId: 'r11',
      rating: 4.0,
      comment:
          'Great pizza with crispy crust! The pepperoni pizza is loaded with toppings. Fast delivery.',
      date: DateTime.now().subtract(const Duration(days: 1)),
      helpfulCount: 16,
    ),
    ReviewModel(
      id: 'rev17',
      userId: 'u17',
      userName: 'Daniel Ross',
      userAvatar:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
      restaurantId: 'r13',
      rating: 5.0,
      comment:
          'BBQ heaven! The ribs fall off the bone and the sauce is perfectly smoky. Mac and cheese sides are great too.',
      date: DateTime.now().subtract(const Duration(days: 3)),
      helpfulCount: 43,
    ),
    ReviewModel(
      id: 'rev18',
      userId: 'u18',
      userName: 'Olivia Harris',
      userAvatar:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
      restaurantId: 'r7',
      rating: 4.5,
      comment:
          'Fresh and flavorful Mediterranean food! The falafel wrap was perfectly crispy and the hummus so creamy.',
      date: DateTime.now().subtract(const Duration(days: 5)),
      helpfulCount: 21,
    ),
    ReviewModel(
      id: 'rev19',
      userId: 'u19',
      userName: 'William Clark',
      userAvatar:
          'https://images.unsplash.com/photo-1463453091185-61582044d556?w=100',
      restaurantId: 'r3',
      rating: 4.5,
      comment:
          'The double bacon burger is incredible! Perfectly cooked patties and crispy bacon. Milkshakes are thick and creamy.',
      date: DateTime.now().subtract(const Duration(days: 2)),
      helpfulCount: 29,
    ),
    ReviewModel(
      id: 'rev20',
      userId: 'u20',
      userName: 'Emma Watson',
      userAvatar:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100',
      restaurantId: 'r4',
      rating: 4.0,
      comment:
          'Loved the vegetable biryani! Fragrant rice with perfect spice levels. Garlic naan was amazing.',
      date: DateTime.now().subtract(const Duration(days: 7)),
      helpfulCount: 14,
    ),
  ];

  /// Get reviews by restaurant ID
  static List<ReviewModel> getByRestaurant(String restaurantId) =>
      reviews.where((r) => r.restaurantId == restaurantId).toList();

  /// Get average rating for a restaurant
  static double getAverageRating(String restaurantId) {
    final restaurantReviews = getByRestaurant(restaurantId);
    if (restaurantReviews.isEmpty) return 0.0;
    return restaurantReviews.map((r) => r.rating).reduce((a, b) => a + b) /
        restaurantReviews.length;
  }
}
