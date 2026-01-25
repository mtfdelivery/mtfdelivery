/// App asset paths for images, icons, and animations
class AppAssets {
  AppAssets._();

  // Base paths
  static const String _imagesPath = 'assets/images';
  static const String _iconsPath = 'assets/icons';
  static const String _animationsPath = 'assets/animations';

  // Logo
  static const String logo = '$_imagesPath/logo.png';
  static const String logoWhite = '$_imagesPath/logo_white.png';

  // Onboarding
  static const String onboarding1 = '$_imagesPath/onboarding_1.png';
  static const String onboarding2 = '$_imagesPath/onboarding_2.png';
  static const String onboarding3 = '$_imagesPath/onboarding_3.png';

  // Illustrations
  static const String emptyCart = '$_imagesPath/empty_cart.png';
  static const String emptyOrders = '$_imagesPath/empty_orders.png';
  static const String emptyFavorites = '$_imagesPath/empty_favorites.png';
  static const String error = '$_imagesPath/error.png';
  static const String success = '$_imagesPath/success.png';
  static const String noResults = '$_imagesPath/no_results.png';
  static const String delivery = '$_imagesPath/delivery.png';

  // Placeholder Images (Network URLs for demo)
  static const String placeholderFood =
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400';
  static const String placeholderRestaurant =
      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400';
  static const String placeholderAvatar =
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200';
  static const String placeholderBanner =
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800';

  // Food Category Placeholders
  static const String categoryPizza =
      'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=200';
  static const String categoryBurger =
      'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200';
  static const String categorySushi =
      'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=200';
  static const String categoryPasta =
      'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=200';
  static const String categorySalad =
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200';
  static const String categoryDessert =
      'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=200';
  static const String categoryDrinks =
      'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=200';
  static const String categoryAsian =
      'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=200';

  // Animations (Lottie)
  static const String loadingAnimation = '$_animationsPath/loading.json';
  static const String successAnimation = '$_animationsPath/success.json';
  static const String deliveryAnimation = '$_animationsPath/delivery.json';
  static const String emptyAnimation = '$_animationsPath/empty.json';

  // Social Icons
  static const String googleIcon = '$_iconsPath/google.svg';
  static const String facebookIcon = '$_iconsPath/facebook.svg';
  static const String appleIcon = '$_iconsPath/apple.svg';

  // Payment Icons
  static const String visaIcon = '$_iconsPath/visa.svg';
  static const String mastercardIcon = '$_iconsPath/mastercard.svg';
  static const String paypalIcon = '$_iconsPath/paypal.svg';
  static const String cashIcon = '$_iconsPath/cash.svg';
}
