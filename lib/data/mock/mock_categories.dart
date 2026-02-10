import '../models/category_model.dart';

/// Mock category data
class MockCategories {
  MockCategories._();

  static const List<CategoryModel> categories = [
    CategoryModel(
      id: 'c1',
      name: 'Pizza',
      iconUrl: 'https://img.icons8.com/3d-fluency/100/pizza.png',
      color: '#E74C3C',
      itemCount: 45,
    ),
    CategoryModel(
      id: 'c2',
      name: 'Burgers',
      iconUrl: 'https://img.icons8.com/3d-fluency/100/hamburger.png',
      color: '#F39C12',
      itemCount: 32,
    ),
    CategoryModel(
      id: 'c3',
      name: 'Sushi',
      iconUrl: 'https://img.icons8.com/3d-fluency/100/sushi.png',
      color: '#9B59B6',
      itemCount: 28,
    ),
    CategoryModel(
      id: 'c4',
      name: 'Pasta',
      iconUrl: 'https://img.icons8.com/3d-fluency/100/spaghetti.png',
      color: '#E67E22',
      itemCount: 23,
    ),
    CategoryModel(
      id: 'c5',
      name: 'Salads',
      iconUrl: 'https://img.icons8.com/3d-fluency/100/salad.png',
      color: '#2ECC71',
      itemCount: 18,
    ),
    CategoryModel(
      id: 'c6',
      name: 'Desserts',
      iconUrl: 'https://img.icons8.com/3d-fluency/100/cupcake.png',
      color: '#E91E63',
      itemCount: 35,
    ),
    CategoryModel(
      id: 'c7',
      name: 'Drinks',
      iconUrl: 'https://img.icons8.com/3d-fluency/100/glass-of-soda.png',
      color: '#3498DB',
      itemCount: 42,
    ),
    CategoryModel(
      id: 'c8',
      name: 'Asian',
      iconUrl: 'https://img.icons8.com/3d-fluency/100/noodles.png',
      color: '#FF5722',
      itemCount: 56,
    ),
    CategoryModel(
      id: 'c9',
      name: 'Mexican',
      iconUrl: 'https://img.icons8.com/3d-fluency/100/taco.png',
      color: '#FFC107',
      itemCount: 27,
    ),
    CategoryModel(
      id: 'c10',
      name: 'Indian',
      iconUrl: 'https://img.icons8.com/3d-fluency/100/curry.png',
      color: '#FF9800',
      itemCount: 31,
    ),
  ];
}
