import '../models/category_model.dart';

/// Mock promo banner data
class MockPromoBanners {
  MockPromoBanners._();

  static const List<PromoBannerModel> banners = [
    PromoBannerModel(
      id: 'b1',
      title: '30% OFF',
      subtitle: 'On your first order',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
      promoCode: 'FIRST30',
      discountPercentage: 30,
    ),
    PromoBannerModel(
      id: 'b2',
      title: 'Free Delivery',
      subtitle: 'Orders above \$25',
      imageUrl:
          'https://images.unsplash.com/photo-1493770348161-369560ae357d?w=800',
      promoCode: 'FREEDEL',
    ),
    PromoBannerModel(
      id: 'b3',
      title: 'Weekend Special',
      subtitle: 'Buy 1 Get 1 Free on Burgers',
      imageUrl:
          'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=800',
      restaurantId: 'r3',
      promoCode: 'BOGO',
    ),
    PromoBannerModel(
      id: 'b4',
      title: '20% OFF',
      subtitle: 'All Sushi Rolls',
      imageUrl:
          'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=800',
      restaurantId: 'r2',
      promoCode: 'SUSHI20',
      discountPercentage: 20,
    ),
    PromoBannerModel(
      id: 'b5',
      title: 'Happy Hour',
      subtitle: '15% OFF from 3-6 PM',
      imageUrl:
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
      promoCode: 'HAPPY15',
      discountPercentage: 15,
    ),
  ];
}
