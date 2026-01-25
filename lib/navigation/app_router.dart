import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/main_navigation.dart';
import '../screens/restaurant/restaurant_detail_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/order_tracking/order_tracking_screen.dart';

/// App router configuration
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
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

      // Main Navigation (Home, Search, Cart, Orders, Profile)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainNavigation(),
      ),

      // Restaurant Detail
      GoRoute(
        path: '/restaurant/:id',
        name: 'restaurantDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RestaurantDetailScreen(restaurantId: id);
        },
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

      // Checkout
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutScreen(),
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
  static const String checkout = '/checkout';

  static String restaurantDetail(String id) => '/restaurant/$id';
  static String orderTracking(String id) => '/order-tracking/$id';
}
