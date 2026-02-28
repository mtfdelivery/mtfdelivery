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

  /// Convert to JSON for local storage persistence
  Map<String, dynamic> toJson() => {
    'id': id,
    'restaurant_id': restaurantId,
    'name': name,
    'description': description,
    'image_url': imageUrl,
    'price': price,
    'original_price': originalPrice,
    'category': category,
    'is_vegetarian': isVegetarian,
    'is_vegan': isVegan,
    'is_spicy': isSpicy,
    'is_popular': isPopular,
    'rating': rating,
    'review_count': reviewCount,
    'preparation_time': preparationTime,
    'calories': calories,
    'is_available': isAvailable,
  };

  /// Create from local storage JSON
  factory FoodItemModel.fromLocalStorage(Map<String, dynamic> json) {
    return FoodItemModel(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      name: json['name'] as String,
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      category: json['category'] ?? 'General',
      isVegetarian: json['is_vegetarian'] ?? false,
      isVegan: json['is_vegan'] ?? false,
      isSpicy: json['is_spicy'] ?? false,
      isPopular: json['is_popular'] ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
      preparationTime: json['preparation_time'] ?? 15,
      calories: json['calories'] ?? 0,
      isAvailable: json['is_available'] ?? true,
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

  /// Convert to JSON for local storage persistence
  Map<String, dynamic> toJson() => {
    'food_item': foodItem.toJson(),
    'quantity': quantity,
    'special_instructions': specialInstructions,
  };

  /// Create from local storage JSON
  factory CartItemModel.fromLocalStorage(Map<String, dynamic> json) {
    return CartItemModel(
      foodItem: FoodItemModel.fromLocalStorage(
        json['food_item'] as Map<String, dynamic>,
      ),
      quantity: json['quantity'] as int? ?? 1,
      specialInstructions: json['special_instructions'] as String?,
    );
  }
}
