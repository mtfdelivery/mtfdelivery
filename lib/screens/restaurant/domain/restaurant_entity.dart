class RestaurantEntity {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final double rating;
  final int reviewCount;
  final String deliveryTime;
  final double deliveryFee;
  final List<String> cuisineTypes;
  final bool isOpen;

  const RestaurantEntity({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.description = '',
    this.rating = 4.5,
    this.reviewCount = 0,
    this.deliveryTime = '20-30 min',
    this.deliveryFee = 0.0,
    this.cuisineTypes = const [],
    this.isOpen = true,
  });
}
