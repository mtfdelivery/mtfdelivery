class RestaurantEntity {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final String deliveryTime;
  final double deliveryFee;

  const RestaurantEntity({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.rating = 4.5,
    this.deliveryTime = '20-30 min',
    this.deliveryFee = 0.0,
  });
}
