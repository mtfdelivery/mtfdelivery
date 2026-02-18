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

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['cover_url'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      description: json['description'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      cuisine:
          json['cuisine'] ??
          '', // Fallback, real implementation might fetch from relation
      cuisineTypes: [], // To be populated from relation if needed
      deliveryTime: (json['estimated_delivery_min'] as num?)?.toInt() ?? 30,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      minOrder: (json['min_order_amount'] as num?)?.toDouble() ?? 0.0,
      distance: 0.0, // Calculated dynamically based on lat/lng
      priceRange: '\$\$', // Placeholder or derived
      isFeatured: json['is_featured'] ?? false,
      isOpen: json['is_open'] ?? false,
      address: json['address'] ?? '',
      openingHours: '', // Placeholder
      phone: json['phone'] ?? '',
    );
  }
}
