import '../models/food_item_model.dart';

/// Mock food item data with realistic content
class MockFoodItems {
  MockFoodItems._();

  static const List<FoodItemModel> foodItems = [
    // Bella Italia (r1) - Italian
    FoodItemModel(
      id: 'f1',
      restaurantId: 'r1',
      name: 'Margherita Pizza',
      description:
          'Classic pizza with fresh mozzarella, tomato sauce, and basil leaves',
      imageUrl:
          'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400',
      price: 14.99,
      category: 'Pizza',
      isVegetarian: true,
      isPopular: true,
      rating: 4.8,
      reviewCount: 156,
      ingredients: ['Mozzarella', 'Tomato Sauce', 'Fresh Basil', 'Olive Oil'],
      preparationTime: 20,
      calories: 850,
    ),
    FoodItemModel(
      id: 'f2',
      restaurantId: 'r1',
      name: 'Spaghetti Carbonara',
      description:
          'Creamy pasta with pancetta, egg, parmesan, and black pepper',
      imageUrl:
          'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=400',
      price: 16.99,
      category: 'Pasta',
      isPopular: true,
      rating: 4.9,
      reviewCount: 203,
      ingredients: ['Spaghetti', 'Pancetta', 'Egg', 'Parmesan', 'Black Pepper'],
      preparationTime: 18,
      calories: 780,
    ),
    FoodItemModel(
      id: 'f3',
      restaurantId: 'r1',
      name: 'Tiramisu',
      description:
          'Classic Italian dessert with espresso-soaked ladyfingers and mascarpone cream',
      imageUrl:
          'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400',
      price: 8.99,
      category: 'Desserts',
      isVegetarian: true,
      rating: 4.7,
      reviewCount: 89,
      ingredients: ['Ladyfingers', 'Espresso', 'Mascarpone', 'Cocoa'],
      preparationTime: 5,
      calories: 450,
    ),

    // Sakura Sushi (r2) - Japanese
    FoodItemModel(
      id: 'f4',
      restaurantId: 'r2',
      name: 'Dragon Roll',
      description: 'Shrimp tempura roll topped with avocado and eel sauce',
      imageUrl:
          'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400',
      price: 18.99,
      category: 'Sushi Rolls',
      isPopular: true,
      rating: 4.9,
      reviewCount: 234,
      ingredients: ['Shrimp Tempura', 'Avocado', 'Eel Sauce', 'Sesame Seeds'],
      preparationTime: 15,
      calories: 520,
    ),
    FoodItemModel(
      id: 'f5',
      restaurantId: 'r2',
      name: 'Salmon Sashimi',
      description: 'Premium fresh salmon slices, 8 pieces',
      imageUrl:
          'https://images.unsplash.com/photo-1534256958597-7fe685cbd745?w=400',
      price: 16.99,
      category: 'Sashimi',
      isPopular: true,
      rating: 4.8,
      reviewCount: 178,
      ingredients: ['Fresh Salmon', 'Wasabi', 'Pickled Ginger'],
      preparationTime: 10,
      calories: 280,
    ),
    FoodItemModel(
      id: 'f6',
      restaurantId: 'r2',
      name: 'Miso Soup',
      description:
          'Traditional Japanese soup with tofu, seaweed, and green onions',
      imageUrl:
          'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400',
      price: 4.99,
      category: 'Soup',
      isVegetarian: true,
      isVegan: true,
      rating: 4.5,
      reviewCount: 112,
      ingredients: ['Miso Paste', 'Tofu', 'Seaweed', 'Green Onions'],
      preparationTime: 5,
      calories: 120,
    ),

    // Burger Palace (r3) - American
    FoodItemModel(
      id: 'f7',
      restaurantId: 'r3',
      name: 'Classic Cheeseburger',
      description:
          'Angus beef patty with cheddar cheese, lettuce, tomato, and special sauce',
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
      price: 12.99,
      originalPrice: 14.99,
      category: 'Burgers',
      isPopular: true,
      rating: 4.6,
      reviewCount: 445,
      ingredients: [
        'Angus Beef',
        'Cheddar',
        'Lettuce',
        'Tomato',
        'Special Sauce',
      ],
      preparationTime: 12,
      calories: 950,
    ),
    FoodItemModel(
      id: 'f8',
      restaurantId: 'r3',
      name: 'Loaded Fries',
      description:
          'Crispy fries topped with cheese, bacon, sour cream, and chives',
      imageUrl:
          'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400',
      price: 7.99,
      category: 'Sides',
      rating: 4.4,
      reviewCount: 267,
      ingredients: ['Potatoes', 'Cheese', 'Bacon', 'Sour Cream', 'Chives'],
      preparationTime: 10,
      calories: 680,
    ),
    FoodItemModel(
      id: 'f9',
      restaurantId: 'r3',
      name: 'Chocolate Milkshake',
      description: 'Thick and creamy chocolate milkshake with whipped cream',
      imageUrl:
          'https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=400',
      price: 5.99,
      category: 'Drinks',
      isVegetarian: true,
      rating: 4.7,
      reviewCount: 189,
      ingredients: ['Ice Cream', 'Milk', 'Chocolate Syrup', 'Whipped Cream'],
      preparationTime: 5,
      calories: 580,
    ),

    // Spice Garden (r4) - Indian
    FoodItemModel(
      id: 'f10',
      restaurantId: 'r4',
      name: 'Butter Chicken',
      description: 'Tender chicken in creamy tomato sauce with aromatic spices',
      imageUrl:
          'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=400',
      price: 15.99,
      category: 'Main Course',
      isPopular: true,
      rating: 4.8,
      reviewCount: 312,
      ingredients: ['Chicken', 'Tomato', 'Cream', 'Butter', 'Spices'],
      preparationTime: 25,
      calories: 720,
    ),
    FoodItemModel(
      id: 'f11',
      restaurantId: 'r4',
      name: 'Vegetable Biryani',
      description:
          'Fragrant basmati rice with mixed vegetables and aromatic spices',
      imageUrl:
          'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400',
      price: 13.99,
      category: 'Rice',
      isVegetarian: true,
      isVegan: true,
      isPopular: true,
      rating: 4.6,
      reviewCount: 198,
      ingredients: ['Basmati Rice', 'Mixed Vegetables', 'Saffron', 'Spices'],
      preparationTime: 30,
      calories: 650,
    ),
    FoodItemModel(
      id: 'f12',
      restaurantId: 'r4',
      name: 'Garlic Naan',
      description: 'Soft flatbread with garlic butter, baked in tandoor',
      imageUrl:
          'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',
      price: 3.99,
      category: 'Bread',
      isVegetarian: true,
      rating: 4.5,
      reviewCount: 156,
      ingredients: ['Flour', 'Garlic', 'Butter', 'Cilantro'],
      preparationTime: 8,
      calories: 280,
    ),

    // Dragon Wok (r5) - Chinese
    FoodItemModel(
      id: 'f13',
      restaurantId: 'r5',
      name: 'Kung Pao Chicken',
      description:
          'Spicy stir-fried chicken with peanuts, vegetables, and chili peppers',
      imageUrl:
          'https://images.unsplash.com/photo-1525755662778-989d0524087e?w=400',
      price: 14.99,
      category: 'Main Course',
      isSpicy: true,
      isPopular: true,
      rating: 4.5,
      reviewCount: 234,
      ingredients: ['Chicken', 'Peanuts', 'Bell Peppers', 'Chili', 'Soy Sauce'],
      preparationTime: 18,
      calories: 580,
    ),
    FoodItemModel(
      id: 'f14',
      restaurantId: 'r5',
      name: 'Dim Sum Platter',
      description:
          'Assorted steamed dumplings including har gow, siu mai, and cha siu bao',
      imageUrl:
          'https://images.unsplash.com/photo-1496116218417-1a781b1c416c?w=400',
      price: 16.99,
      category: 'Dim Sum',
      isPopular: true,
      rating: 4.7,
      reviewCount: 189,
      ingredients: ['Shrimp', 'Pork', 'Vegetables', 'Dough'],
      preparationTime: 20,
      calories: 520,
    ),
    FoodItemModel(
      id: 'f15',
      restaurantId: 'r5',
      name: 'Fried Rice',
      description:
          'Wok-fried rice with eggs, vegetables, and choice of protein',
      imageUrl:
          'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400',
      price: 11.99,
      category: 'Rice',
      rating: 4.4,
      reviewCount: 312,
      ingredients: ['Rice', 'Eggs', 'Peas', 'Carrots', 'Soy Sauce'],
      preparationTime: 15,
      calories: 620,
    ),

    // Taco Fiesta (r6) - Mexican
    FoodItemModel(
      id: 'f16',
      restaurantId: 'r6',
      name: 'Carne Asada Tacos',
      description:
          'Three tacos with grilled steak, cilantro, onions, and salsa verde',
      imageUrl:
          'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?w=400',
      price: 11.99,
      category: 'Tacos',
      isPopular: true,
      rating: 4.8,
      reviewCount: 423,
      ingredients: [
        'Steak',
        'Cilantro',
        'Onions',
        'Salsa Verde',
        'Corn Tortillas',
      ],
      preparationTime: 15,
      calories: 480,
    ),
    FoodItemModel(
      id: 'f17',
      restaurantId: 'r6',
      name: 'Chicken Burrito',
      description:
          'Large flour tortilla stuffed with chicken, rice, beans, cheese, and guacamole',
      imageUrl:
          'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=400',
      price: 12.99,
      category: 'Burritos',
      isPopular: true,
      rating: 4.6,
      reviewCount: 356,
      ingredients: [
        'Chicken',
        'Rice',
        'Beans',
        'Cheese',
        'Guacamole',
        'Sour Cream',
      ],
      preparationTime: 12,
      calories: 890,
    ),
    FoodItemModel(
      id: 'f18',
      restaurantId: 'r6',
      name: 'Nachos Supreme',
      description:
          'Crispy tortilla chips loaded with beef, cheese, jalapeños, and toppings',
      imageUrl:
          'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=400',
      price: 10.99,
      category: 'Appetizers',
      isSpicy: true,
      rating: 4.5,
      reviewCount: 267,
      ingredients: [
        'Tortilla Chips',
        'Ground Beef',
        'Cheese',
        'Jalapeños',
        'Sour Cream',
      ],
      preparationTime: 10,
      calories: 720,
    ),

    // More items for variety
    FoodItemModel(
      id: 'f19',
      restaurantId: 'r7',
      name: 'Falafel Wrap',
      description:
          'Crispy falafel with hummus, tahini, and fresh vegetables in pita',
      imageUrl:
          'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=400',
      price: 10.99,
      category: 'Wraps',
      isVegetarian: true,
      isVegan: true,
      isPopular: true,
      rating: 4.6,
      reviewCount: 198,
      ingredients: ['Chickpeas', 'Hummus', 'Tahini', 'Lettuce', 'Tomatoes'],
      preparationTime: 12,
      calories: 480,
    ),
    FoodItemModel(
      id: 'f20',
      restaurantId: 'r8',
      name: 'Pad Thai',
      description:
          'Stir-fried rice noodles with shrimp, peanuts, and tamarind sauce',
      imageUrl:
          'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=400',
      price: 14.99,
      category: 'Noodles',
      isPopular: true,
      rating: 4.7,
      reviewCount: 287,
      ingredients: ['Rice Noodles', 'Shrimp', 'Peanuts', 'Tamarind', 'Egg'],
      preparationTime: 18,
      calories: 650,
    ),
    FoodItemModel(
      id: 'f21',
      restaurantId: 'r8',
      name: 'Green Curry',
      description:
          'Aromatic Thai green curry with coconut milk, vegetables, and basil',
      imageUrl:
          'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=400',
      price: 15.99,
      category: 'Curry',
      isSpicy: true,
      isVegetarian: true,
      rating: 4.6,
      reviewCount: 167,
      ingredients: [
        'Coconut Milk',
        'Green Curry Paste',
        'Bamboo Shoots',
        'Thai Basil',
      ],
      preparationTime: 20,
      calories: 580,
    ),
    FoodItemModel(
      id: 'f22',
      restaurantId: 'r10',
      name: 'Korean BBQ Platter',
      description: 'Assorted grilled meats with banchan and dipping sauces',
      imageUrl:
          'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=400',
      price: 32.99,
      category: 'BBQ',
      isPopular: true,
      rating: 4.8,
      reviewCount: 234,
      ingredients: [
        'Beef',
        'Pork Belly',
        'Chicken',
        'Kimchi',
        'Pickled Vegetables',
      ],
      preparationTime: 25,
      calories: 980,
    ),
    FoodItemModel(
      id: 'f23',
      restaurantId: 'r10',
      name: 'Bibimbap',
      description:
          'Mixed rice bowl with vegetables, beef, gochujang, and fried egg',
      imageUrl:
          'https://images.unsplash.com/photo-1553163147-622ab57be1c7?w=400',
      price: 14.99,
      category: 'Rice Bowls',
      isSpicy: true,
      isPopular: true,
      rating: 4.7,
      reviewCount: 198,
      ingredients: ['Rice', 'Beef', 'Vegetables', 'Egg', 'Gochujang'],
      preparationTime: 18,
      calories: 720,
    ),
    FoodItemModel(
      id: 'f24',
      restaurantId: 'r12',
      name: 'Acai Bowl',
      description: 'Açaí blend topped with granola, fresh berries, and honey',
      imageUrl:
          'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=400',
      price: 11.99,
      category: 'Bowls',
      isVegetarian: true,
      isVegan: true,
      isPopular: true,
      rating: 4.6,
      reviewCount: 234,
      ingredients: ['Açaí', 'Banana', 'Granola', 'Berries', 'Honey'],
      preparationTime: 8,
      calories: 420,
    ),
    FoodItemModel(
      id: 'f25',
      restaurantId: 'r12',
      name: 'Caesar Salad',
      description:
          'Crisp romaine lettuce with parmesan, croutons, and Caesar dressing',
      imageUrl:
          'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=400',
      price: 9.99,
      category: 'Salads',
      isVegetarian: true,
      rating: 4.4,
      reviewCount: 156,
      ingredients: ['Romaine', 'Parmesan', 'Croutons', 'Caesar Dressing'],
      preparationTime: 10,
      calories: 380,
    ),
    FoodItemModel(
      id: 'f26',
      restaurantId: 'r14',
      name: 'Chocolate Lava Cake',
      description:
          'Warm chocolate cake with molten center, served with vanilla ice cream',
      imageUrl:
          'https://images.unsplash.com/photo-1624353365286-3f8d62daad51?w=400',
      price: 8.99,
      category: 'Desserts',
      isVegetarian: true,
      isPopular: true,
      rating: 4.9,
      reviewCount: 345,
      ingredients: [
        'Dark Chocolate',
        'Butter',
        'Eggs',
        'Flour',
        'Vanilla Ice Cream',
      ],
      preparationTime: 15,
      calories: 580,
    ),
    FoodItemModel(
      id: 'f27',
      restaurantId: 'r14',
      name: 'New York Cheesecake',
      description:
          'Creamy cheesecake with graham cracker crust and berry compote',
      imageUrl:
          'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?w=400',
      price: 7.99,
      category: 'Desserts',
      isVegetarian: true,
      rating: 4.7,
      reviewCount: 267,
      ingredients: [
        'Cream Cheese',
        'Graham Crackers',
        'Eggs',
        'Sugar',
        'Vanilla',
      ],
      preparationTime: 5,
      calories: 450,
    ),
    FoodItemModel(
      id: 'f28',
      restaurantId: 'r15',
      name: 'Pho Bo',
      description:
          'Traditional beef pho with rice noodles, herbs, and rich broth',
      imageUrl:
          'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=400',
      price: 13.99,
      category: 'Soup',
      isPopular: true,
      rating: 4.8,
      reviewCount: 312,
      ingredients: ['Beef', 'Rice Noodles', 'Bean Sprouts', 'Basil', 'Lime'],
      preparationTime: 15,
      calories: 520,
    ),
    FoodItemModel(
      id: 'f29',
      restaurantId: 'r15',
      name: 'Banh Mi',
      description:
          'Vietnamese baguette with grilled pork, pickled vegetables, and cilantro',
      imageUrl:
          'https://images.unsplash.com/photo-1600688640154-9619e002df30?w=400',
      price: 9.99,
      category: 'Sandwiches',
      isPopular: true,
      rating: 4.6,
      reviewCount: 198,
      ingredients: [
        'Pork',
        'Pickled Carrots',
        'Daikon',
        'Cilantro',
        'Jalapenos',
      ],
      preparationTime: 12,
      calories: 480,
    ),
    FoodItemModel(
      id: 'f30',
      restaurantId: 'r13',
      name: 'BBQ Ribs',
      description: 'Slow-smoked pork ribs glazed with house-made BBQ sauce',
      imageUrl:
          'https://images.unsplash.com/photo-1544025162-d76694265947?w=400',
      price: 22.99,
      category: 'BBQ',
      isPopular: true,
      rating: 4.7,
      reviewCount: 356,
      ingredients: ['Pork Ribs', 'BBQ Sauce', 'Dry Rub Spices'],
      preparationTime: 35,
      calories: 1100,
    ),
    FoodItemModel(
      id: 'f31',
      restaurantId: 'r9',
      name: 'Croissant',
      description: 'Buttery, flaky French pastry, freshly baked',
      imageUrl:
          'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400',
      price: 3.99,
      category: 'Pastries',
      isVegetarian: true,
      rating: 4.6,
      reviewCount: 145,
      ingredients: ['Butter', 'Flour', 'Yeast', 'Milk'],
      preparationTime: 5,
      calories: 280,
    ),
    FoodItemModel(
      id: 'f32',
      restaurantId: 'r9',
      name: 'French Onion Soup',
      description: 'Caramelized onion soup with melted Gruyère cheese crouton',
      imageUrl:
          'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400',
      price: 9.99,
      category: 'Soup',
      isVegetarian: true,
      rating: 4.7,
      reviewCount: 123,
      ingredients: ['Onions', 'Beef Broth', 'Gruyère', 'French Bread'],
      preparationTime: 15,
      calories: 380,
    ),
    FoodItemModel(
      id: 'f33',
      restaurantId: 'r11',
      name: 'Pepperoni Pizza',
      description: 'Classic pizza loaded with pepperoni and mozzarella cheese',
      imageUrl:
          'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=400',
      price: 15.99,
      category: 'Pizza',
      isPopular: true,
      rating: 4.5,
      reviewCount: 456,
      ingredients: ['Pepperoni', 'Mozzarella', 'Tomato Sauce', 'Oregano'],
      preparationTime: 18,
      calories: 920,
    ),
    FoodItemModel(
      id: 'f34',
      restaurantId: 'r11',
      name: 'Garlic Knots',
      description: 'Soft bread knots brushed with garlic butter and parsley',
      imageUrl:
          'https://images.unsplash.com/photo-1619531040576-f9416740661b?w=400',
      price: 5.99,
      category: 'Sides',
      isVegetarian: true,
      rating: 4.4,
      reviewCount: 234,
      ingredients: ['Dough', 'Garlic', 'Butter', 'Parsley'],
      preparationTime: 10,
      calories: 320,
    ),
    FoodItemModel(
      id: 'f35',
      restaurantId: 'r3',
      name: 'Double Bacon Burger',
      description:
          'Two beef patties with crispy bacon, cheese, and all the fixings',
      imageUrl:
          'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400',
      price: 16.99,
      originalPrice: 18.99,
      category: 'Burgers',
      isPopular: true,
      rating: 4.8,
      reviewCount: 378,
      ingredients: [
        'Angus Beef',
        'Bacon',
        'American Cheese',
        'Pickles',
        'Onion',
      ],
      preparationTime: 15,
      calories: 1250,
    ),
  ];

  /// Get food items by restaurant ID
  static List<FoodItemModel> getByRestaurant(String restaurantId) =>
      foodItems.where((f) => f.restaurantId == restaurantId).toList();

  /// Get popular items
  static List<FoodItemModel> get popular =>
      foodItems.where((f) => f.isPopular).toList();

  /// Get items by category
  static List<FoodItemModel> getByCategory(String category) =>
      foodItems
          .where((f) => f.category.toLowerCase() == category.toLowerCase())
          .toList();

  /// Get food item by ID
  static FoodItemModel? getById(String id) => foodItems
      .cast<FoodItemModel?>()
      .firstWhere((f) => f?.id == id, orElse: () => null);

  /// Get unique categories from a restaurant
  static List<String> getCategoriesForRestaurant(String restaurantId) {
    final items = getByRestaurant(restaurantId);
    return items.map((f) => f.category).toSet().toList();
  }
}
