/// Category model for food categories
class CategoryModel {
  final String id;
  final String name;
  final String iconUrl;
  final String color;
  final int itemCount;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.color,
    this.itemCount = 0,
  });
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['icon_url'] ?? '',
      color: json['color'] ?? '#FF6B35',
      itemCount: 0, // Not in table, could count later
    );
  }
}

/// Promo banner model for carousel
class PromoBannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? restaurantId;
  final String? promoCode;
  final double? discountPercentage;

  const PromoBannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.restaurantId,
    this.promoCode,
    this.discountPercentage,
  });
}
