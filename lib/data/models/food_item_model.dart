/// Food item model for menu items
class FoodItemModel {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final double? originalPrice; // For discounts
  final String category; // Appetizers, Main Course, etc.
  final bool isVegetarian;
  final bool isVegan;
  final bool isSpicy;
  final bool isPopular;
  final double rating;
  final int reviewCount;
  final List<String> ingredients;
  final int preparationTime; // in minutes
  final int calories;
  final bool isAvailable;

  const FoodItemModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.originalPrice,
    required this.category,
    this.isVegetarian = false,
    this.isVegan = false,
    this.isSpicy = false,
    this.isPopular = false,
    required this.rating,
    required this.reviewCount,
    this.ingredients = const [],
    required this.preparationTime,
    this.calories = 0,
    this.isAvailable = true,
  });

  double? get discountPercentage {
    if (originalPrice != null && originalPrice! > price) {
      return ((originalPrice! - price) / originalPrice! * 100);
    }
    return null;
  }

  FoodItemModel copyWith({
    String? id,
    String? restaurantId,
    String? name,
    String? description,
    String? imageUrl,
    double? price,
    double? originalPrice,
    String? category,
    bool? isVegetarian,
    bool? isVegan,
    bool? isSpicy,
    bool? isPopular,
    double? rating,
    int? reviewCount,
    List<String>? ingredients,
    int? preparationTime,
    int? calories,
    bool? isAvailable,
  }) {
    return FoodItemModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      category: category ?? this.category,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isSpicy: isSpicy ?? this.isSpicy,
      isPopular: isPopular ?? this.isPopular,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      ingredients: ingredients ?? this.ingredients,
      preparationTime: preparationTime ?? this.preparationTime,
      calories: calories ?? this.calories,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    return FoodItemModel(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      name: json['name'] as String,
      description: json['description'] ?? '',
      imageUrl: (json['images'] as List?)?.firstOrNull as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['compare_price'] as num?)?.toDouble(),
      category:
          (json['menu_sections'] as Map?)?['name'] as String? ?? 'General',
      isVegetarian: json['is_vegetarian'] ?? false,
      isVegan: json['is_vegan'] ?? false,
      isSpicy: json['is_spicy'] ?? false,
      isPopular: json['is_popular'] ?? false,
      rating: 0.0, // Not in menu_items table
      reviewCount: 0,
      preparationTime: (json['prep_time_min'] as num?)?.toInt() ?? 15,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      isAvailable: json['is_available'] ?? true,
      ingredients: [], // Placeholder
    );
  }
}

/// Cart item model (food item with quantity)
class CartItemModel {
  final FoodItemModel foodItem;
  final int quantity;
  final String? specialInstructions;

  const CartItemModel({
    required this.foodItem,
    required this.quantity,
    this.specialInstructions,
  });

  double get totalPrice => foodItem.price * quantity;

  CartItemModel copyWith({
    FoodItemModel? foodItem,
    int? quantity,
    String? specialInstructions,
  }) {
    return CartItemModel(
      foodItem: foodItem ?? this.foodItem,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}
