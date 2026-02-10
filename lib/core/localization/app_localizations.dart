import 'package:flutter/material.dart';

/// Basic localization class for the app
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = {
    'en': {
      'home': 'Home',
      'search': 'Search',
      'cart': 'Cart',
      'profile': 'Profile',
      'categories': 'Categories',
      'popular_restaurants': 'Popular Restaurants',
      'see_all': 'See All',
      'language': 'Language',
      'logout': 'Logout',
      'general': 'General',
      'promotional_activity': 'Promotional Activity',
      'help_support': 'Help & Support',
      'my_address': 'My address',
      'my_orders': 'My Orders',
      'my_favorites': 'My Favorites',
      'coupon': 'Coupon',
      'notifications': 'Notifications',
      'help_assistance': 'Help & assistance',
      'about_us': 'About us',
      'terms_conditions': 'Terms & Conditions',
      'privacy_policy': 'Privacy Policy',
      'select_language': 'Select Language',
    },
    'fr': {
      'home': 'Accueil',
      'search': 'Recherche',
      'cart': 'Panier',
      'profile': 'Profil',
      'categories': 'Catégories',
      'popular_restaurants': 'Restaurants Populaires',
      'see_all': 'Voir tout',
      'language': 'Langue',
      'logout': 'Déconnexion',
      'general': 'Général',
      'promotional_activity': 'Activité promotionnelle',
      'help_support': 'Aide et support',
      'my_address': 'Mes adresses',
      'my_orders': 'Mes commandes',
      'my_favorites': 'Mes favoris',
      'coupon': 'Coupon',
      'notifications': 'Notifications',
      'help_assistance': 'Aide et assistance',
      'about_us': 'À propos de nous',
      'terms_conditions': 'Termes et conditions',
      'privacy_policy': 'Politique de confidentialité',
      'select_language': 'Choisir la langue',
    },
    'ar': {
      'home': 'الرئيسية',
      'search': 'بحث',
      'cart': 'السلة',
      'profile': 'الملف الشخصي',
      'categories': 'الفئات',
      'popular_restaurants': 'المطاعم الشهيرة',
      'see_all': 'عرض الكل',
      'language': 'اللغة',
      'logout': 'تسجيل الخروج',
      'general': 'عام',
      'promotional_activity': 'النشاط الترويجي',
      'help_support': 'المساعدة والدعم',
      'my_address': 'عناويني',
      'my_orders': 'طلباتي',
      'my_favorites': 'المفضلة',
      'coupon': 'كوبون',
      'notifications': 'تنبيهات',
      'help_assistance': 'المساعدة والدعم',
      'about_us': 'من نحن',
      'terms_conditions': 'الشروط والأحكام',
      'privacy_policy': 'سياسة الخصوصية',
      'select_language': 'اختر اللغة',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Helper getters
  String get home => translate('home');
  String get search => translate('search');
  String get cart => translate('cart');
  String get profile => translate('profile');
  String get language => translate('language');
  String get logout => translate('logout');
  String get selectLanguage => translate('select_language');
  String get general => translate('general');
  String get promotionalActivity => translate('promotional_activity');
  String get helpSupportSection => translate('help_support');
  String get myAddress => translate('my_address');
  String get myOrders => translate('my_orders');
  String get myFavorites => translate('my_favorites');
  String get coupon => translate('coupon');
  String get notifications => translate('notifications');
  String get helpAssistance => translate('help_assistance');
  String get aboutUs => translate('about_us');
  String get termsConditions => translate('terms_conditions');
  String get privacyPolicy => translate('privacy_policy');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'fr', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
