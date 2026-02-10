/// Restaurant model for the food delivery app
class RestaurantModel {
  final String id;
  final String name;
  final String imageUrl;
  final String logoUrl;
  final String description;
  final double rating;
  final int reviewCount;
  final String cuisine; // Italian, Chinese, etc.
  final List<String> cuisineTypes;
  final int deliveryTime; // in minutes
  final double deliveryFee;
  final double minOrder;
  final double distance; // in km
  final String priceRange; // $, $$, $$$
  final bool isFeatured;
  final bool isOpen;
  final String address;
  final String openingHours;
  final String phone;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.logoUrl,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.cuisine,
    this.cuisineTypes = const [],
    required this.deliveryTime,
    required this.deliveryFee,
    required this.minOrder,
    required this.distance,
    required this.priceRange,
    this.isFeatured = false,
    this.isOpen = true,
    required this.address,
    required this.openingHours,
    required this.phone,
  });

  RestaurantModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? logoUrl,
    String? description,
    double? rating,
    int? reviewCount,
    String? cuisine,
    List<String>? cuisineTypes,
    int? deliveryTime,
    double? deliveryFee,
    double? minOrder,
    double? distance,
    String? priceRange,
    bool? isFeatured,
    bool? isOpen,
    String? address,
    String? openingHours,
    String? phone,
  }) {
    return RestaurantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      cuisine: cuisine ?? this.cuisine,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minOrder: minOrder ?? this.minOrder,
      distance: distance ?? this.distance,
      priceRange: priceRange ?? this.priceRange,
      isFeatured: isFeatured ?? this.isFeatured,
      isOpen: isOpen ?? this.isOpen,
      address: address ?? this.address,
      openingHours: openingHours ?? this.openingHours,
      phone: phone ?? this.phone,
    );
  }
}
