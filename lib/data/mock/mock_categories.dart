import '../models/category_model.dart';

/// Mock category data
class MockCategories {
  MockCategories._();

  static const List<CategoryModel> categories = [
    CategoryModel(
      id: 'c1',
      name: 'Pizza',
      iconUrl:
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=200',
      color: '#E74C3C',
      itemCount: 45,
    ),
    CategoryModel(
      id: 'c2',
      name: 'Burgers',
      iconUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200',
      color: '#F39C12',
      itemCount: 32,
    ),
    CategoryModel(
      id: 'c3',
      name: 'Sushi',
      iconUrl:
          'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=200',
      color: '#9B59B6',
      itemCount: 28,
    ),
    CategoryModel(
      id: 'c4',
      name: 'Pasta',
      iconUrl:
          'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=200',
      color: '#E67E22',
      itemCount: 23,
    ),
    CategoryModel(
      id: 'c5',
      name: 'Salads',
      iconUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200',
      color: '#2ECC71',
      itemCount: 18,
    ),
    CategoryModel(
      id: 'c6',
      name: 'Desserts',
      iconUrl:
          'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=200',
      color: '#E91E63',
      itemCount: 35,
    ),
    CategoryModel(
      id: 'c7',
      name: 'Drinks',
      iconUrl:
          'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=200',
      color: '#3498DB',
      itemCount: 42,
    ),
    CategoryModel(
      id: 'c8',
      name: 'Asian',
      iconUrl:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=200',
      color: '#FF5722',
      itemCount: 56,
    ),
    CategoryModel(
      id: 'c9',
      name: 'Mexican',
      iconUrl:
          'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=200',
      color: '#FFC107',
      itemCount: 27,
    ),
    CategoryModel(
      id: 'c10',
      name: 'Indian',
      iconUrl:
          'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=200',
      color: '#FF9800',
      itemCount: 31,
    ),
  ];
}
