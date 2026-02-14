import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/main_navigation.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/primary_home_screen.dart';
import '../screens/help/privacy_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/order_history/order_history_screen.dart';
import '../screens/order_tracking/order_tracking_screen.dart';
import '../screens/help/help_screen.dart';
import '../screens/help/about_screen.dart';
import '../screens/profile/notification_screen.dart';
import '../screens/profile/coupon_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/profile/address_list_screen.dart';
import '../screens/profile/add_address_screen.dart';
import '../screens/help/terms_screen.dart';
import '../screens/profile/user_details_screen.dart';
import '../screens/error/error_404_screen.dart';
import '../screens/restaurant/presentation/restaurant_detail_screen.dart';
import '../screens/location/set_location_screen.dart';
import '../screens/location/map_picker_screen.dart';
import '../data/models/restaurant_model.dart';

/// App router configuration
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => const Error404Screen(),
    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Shell Route for persistent bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigation(child: child);
        },
        routes: [
          // Home
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const PrimaryHomeScreen(),
          ),
          // Search
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const SearchScreen(),
          ),
          // Cart
          GoRoute(
            path: '/cart',
            name: 'cart',
            builder: (context, state) => const CartScreen(),
          ),
          // Profile
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          // Restaurant Home (listing)
          GoRoute(
            path: '/home/restaurants',
            name: 'restaurantHome',
            builder: (context, state) => const HomeScreen(),
          ),
        ],
      ),

      // Other routes that don't have the navbar
      // Courier (placeholder)
      GoRoute(
        path: '/home/courier',
        name: 'courierHome',
        builder:
            (context, state) => const Scaffold(
              body: Center(child: Text('Courier Coming Soon')),
            ),
      ),

      // Checkout
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),

      // Order History
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) => const OrderHistoryScreen(),
      ),

      // Order Tracking
      GoRoute(
        path: '/order-tracking/:id',
        name: 'orderTracking',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderTrackingScreen(orderId: id);
        },
      ),

      // Restaurant Detail
      GoRoute(
        path: '/restaurant/:id',
        name: 'restaurantDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          // For now, create a mock restaurant - in production this would fetch from provider
          final mockRestaurant = RestaurantModel(
            id: id,
            name: 'The Burger House',
            imageUrl:
                'https://images.unsplash.com/photo-1571091718767-18b5b1457add?auto=format&fit=crop&w=1200&q=80',
            logoUrl: '',
            description: 'Premium burgers and sides',
            rating: 4.8,
            reviewCount: 1245,
            cuisine: 'American',
            cuisineTypes: ['Burgers', 'Fast Food', 'American'],
            deliveryTime: 25,
            deliveryFee: 0.0,
            minOrder: 10.0,
            distance: 1.2,
            priceRange: '\$\$',
            isFeatured: true,
            isOpen: true,
            address: '123 Main St',
            openingHours: '10:00 AM - 10:00 PM',
            phone: '555-0123',
          );
          return RestaurantDetailScreen(restaurant: mockRestaurant);
        },
      ),
      // ... (rest of the help/profile routes)
      // Help & Assistance
      GoRoute(
        path: '/help',
        name: 'help',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/terms',
        name: 'terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/coupons',
        name: 'coupons',
        builder: (context, state) => const CouponScreen(),
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/addresses',
        name: 'addresses',
        builder: (context, state) => const AddressListScreen(),
      ),
      GoRoute(
        path: '/profile/addresses/add',
        name: 'addAddress',
        builder: (context, state) => const AddNewAddressScreen(),
      ),
      GoRoute(
        path: '/profile/details',
        name: 'profile_details',
        builder: (context, state) => const UserDetailsScreen(),
      ),

      // Location Picker
      GoRoute(
        path: '/set-location',
        name: 'setLocation',
        builder: (context, state) => const SetLocationScreen(),
      ),
      GoRoute(
        path: '/map-picker',
        name: 'mapPicker',
        builder: (context, state) => const MapPickerScreen(),
      ),
    ],
  );
}

/// Route names for easy navigation
class Routes {
  Routes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String search = '/search';
  static const String cart = '/cart';
  static const String profile = '/profile';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String help = '/help';
  static const String about = '/about';
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String notifications = '/notifications';
  static const String coupons = '/coupons';
  static const String favorites = '/favorites';
  static const String addresses = '/addresses';
  static const String restaurantHome = '/home/restaurants';
  static const String profileDetails = '/profile/details';
  static const String setLocation = '/set-location';
  static const String mapPicker = '/map-picker';
  static const String addAddress = '/profile/addresses/add';

  static String orderTracking(String id) => '/order-tracking/$id';
}
