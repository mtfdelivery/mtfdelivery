# 🚀 MTF Delivery - Flutter Integration Guide

## 📱 Complete Flutter Setup for Food Delivery App

This guide will help you integrate your Flutter apps (Customer, Restaurant, Driver) with the Supabase backend.

---

## 📋 Table of Contents

1. [Project Setup](#project-setup)
2. [Supabase Configuration](#supabase-configuration)
3. [Project Structure](#project-structure)
4. [Authentication](#authentication)
5. [Database Operations](#database-operations)
6. [Real-time Updates](#real-time-updates)
7. [File Uploads](#file-uploads)
8. [Push Notifications](#push-notifications)
9. [Maps Integration](#maps-integration)
10. [Payment Integration](#payment-integration)
11. [State Management](#state-management)

---

## 🛠️ Project Setup

### 1. Install Required Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Supabase
  supabase_flutter: ^2.5.0
  
  # State Management
  flutter_riverpod: ^2.5.1  # or provider, bloc, getx
  
  # UI Components
  flutter_screenutil: ^5.9.0
  google_fonts: ^6.2.1
  cached_network_image: ^3.3.1
  
  # Maps & Location
  google_maps_flutter: ^2.6.1
  geolocator: ^11.0.0
  geocoding: ^3.0.0
  flutter_polyline_points: ^2.0.1
  
  # Payments
  flutter_stripe: ^10.1.1
  
  # Notifications
  firebase_core: ^2.27.0
  firebase_messaging: ^14.7.15
  flutter_local_notifications: ^17.0.0
  
  # Image Handling
  image_picker: ^1.0.7
  image_cropper: ^5.0.1
  
  # Utilities
  intl: ^0.19.0
  url_launcher: ^6.2.5
  share_plus: ^7.2.2
  permission_handler: ^11.3.0
  connectivity_plus: ^5.0.2
  
  # HTTP
  dio: ^5.4.1
  
  # Local Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  hive_generator: ^2.0.1
  build_runner: ^2.4.8
```

### 2. Install Packages

```bash
flutter pub get
```

---

## ⚙️ Supabase Configuration

### 1. Initialize Supabase

Create `lib/core/config/supabase_config.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}
```

### 2. Initialize in main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  // Initialize Firebase (for notifications)
  await Firebase.initializeApp();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTF Delivery',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
```

---

## 📂 Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/
│   │   ├── supabase_config.dart
│   │   ├── firebase_config.dart
│   │   └── app_config.dart
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── api_constants.dart
│   ├── routes/
│   │   └── app_router.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   └── utils/
│       ├── helpers.dart
│       └── validators.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── services/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   ├── home/
│   ├── restaurants/
│   ├── cart/
│   ├── orders/
│   ├── profile/
│   └── tracking/
└── shared/
    ├── models/
    ├── widgets/
    └── providers/
```

---

## 🔐 Authentication

### 1. Auth Service

Create `lib/features/auth/data/services/auth_service.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Get current user
  User? get currentUser => _supabase.auth.currentUser;
  
  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  // Sign up with email
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'phone': phone,
      },
    );
    
    if (response.user != null) {
      // Update user profile in users table
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'name': name,
        'phone': phone,
        'role': 'customer',
      });
    }
    
    return response;
  }
  
  // Sign in with email
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  // Sign in with phone (OTP)
  Future<void> signInWithPhone(String phone) async {
    await _supabase.auth.signInWithOtp(
      phone: phone,
    );
  }
  
  // Verify OTP
  Future<AuthResponse> verifyOTP({
    required String phone,
    required String token,
  }) async {
    return await _supabase.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }
  
  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
  
  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    await _supabase.from('users').update({
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    }).eq('id', userId);
  }
}
```

### 2. Auth Provider (Riverpod)

Create `lib/features/auth/presentation/providers/auth_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => null,
  );
});
```

### 3. Login Screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  
  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Navigation handled by auth state listener
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

---

## 💾 Database Operations

### 1. Restaurant Service

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../models/restaurant_model.dart';

class RestaurantService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Get all restaurants
  Future<List<RestaurantModel>> getRestaurants({
    String? cuisine,
    bool? isOpen,
    double? maxDistance,
  }) async {
    var query = _supabase
        .from('restaurants')
        .select('*')
        .eq('is_active', true);
    
    if (cuisine != null) {
      query = query.eq('cuisine', cuisine);
    }
    
    if (isOpen != null) {
      query = query.eq('is_open', isOpen);
    }
    
    final response = await query.order('rating', ascending: false);
    
    return (response as List)
        .map((json) => RestaurantModel.fromJson(json))
        .toList();
  }
  
  // Get restaurant by ID
  Future<RestaurantModel> getRestaurantById(String id) async {
    final response = await _supabase
        .from('restaurants')
        .select('*')
        .eq('id', id)
        .single();
    
    return RestaurantModel.fromJson(response);
  }
  
  // Search restaurants
  Future<List<RestaurantModel>> searchRestaurants(String query) async {
    final response = await _supabase
        .from('restaurants')
        .select('*')
        .or('name.ilike.%$query%,cuisine.ilike.%$query%')
        .eq('is_active', true);
    
    return (response as List)
        .map((json) => RestaurantModel.fromJson(json))
        .toList();
  }
  
  // Get food items for restaurant
  Future<List<FoodItemModel>> getRestaurantMenu(String restaurantId) async {
    final response = await _supabase
        .from('food_items')
        .select('*')
        .eq('restaurant_id', restaurantId)
        .eq('is_active', true)
        .eq('is_available', true)
        .order('category');
    
    return (response as List)
        .map((json) => FoodItemModel.fromJson(json))
        .toList();
  }
}
```

### 2. Order Service

```dart
class OrderService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Create order
  Future<String> createOrder({
    required String restaurantId,
    required List<CartItem> items,
    required String deliveryAddressId,
    required String paymentMethod,
    String? promoCode,
    String? specialInstructions,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    // Calculate totals
    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final deliveryFee = 2.99;
    final tax = subtotal * 0.1;
    final total = subtotal + deliveryFee + tax;
    
    // Create order
    final orderResponse = await _supabase.from('orders').insert({
      'user_id': userId,
      'restaurant_id': restaurantId,
      'delivery_address_id': deliveryAddressId,
      'payment_method': paymentMethod,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'tax': tax,
      'total': total,
      'status': 'pending',
      'payment_status': 'pending',
      if (promoCode != null) 'promo_code': promoCode,
      if (specialInstructions != null) 'special_instructions': specialInstructions,
    }).select().single();
    
    final orderId = orderResponse['id'];
    
    // Create order items
    for (final item in items) {
      await _supabase.from('order_items').insert({
        'order_id': orderId,
        'food_item_id': item.foodItemId,
        'food_item_name': item.name,
        'food_item_image': item.imageUrl,
        'price': item.price,
        'quantity': item.quantity,
        if (item.specialInstructions != null)
          'special_instructions': item.specialInstructions,
      });
    }
    
    return orderId;
  }
  
  // Get user orders
  Future<List<OrderModel>> getUserOrders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    final response = await _supabase
        .from('orders')
        .select('''
          *,
          restaurant:restaurants(*),
          driver:drivers(*)
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => OrderModel.fromJson(json))
        .toList();
  }
  
  // Get order by ID
  Future<OrderModel> getOrderById(String orderId) async {
    final response = await _supabase
        .from('orders')
        .select('''
          *,
          restaurant:restaurants(*),
          driver:drivers(*),
          items:order_items(*)
        ''')
        .eq('id', orderId)
        .single();
    
    return OrderModel.fromJson(response);
  }
  
  // Cancel order
  Future<void> cancelOrder(String orderId, String reason) async {
    await _supabase.from('orders').update({
      'status': 'cancelled',
      'cancelled_by': 'customer',
      'cancellation_reason': reason,
    }).eq('id', orderId);
  }
}
```

### 3. Cart Service (Local Storage)

```dart
import 'package:hive/hive.dart';

class CartService {
  static const String _boxName = 'cart';
  
  Box<CartItem> get _box => Hive.box<CartItem>(_boxName);
  
  // Add item to cart
  Future<void> addItem(CartItem item) async {
    await _box.put(item.foodItemId, item);
  }
  
  // Remove item from cart
  Future<void> removeItem(String foodItemId) async {
    await _box.delete(foodItemId);
  }
  
  // Update quantity
  Future<void> updateQuantity(String foodItemId, int quantity) async {
    final item = _box.get(foodItemId);
    if (item != null) {
      final updated = item.copyWith(quantity: quantity);
      await _box.put(foodItemId, updated);
    }
  }
  
  // Get all cart items
  List<CartItem> getCartItems() {
    return _box.values.toList();
  }
  
  // Clear cart
  Future<void> clearCart() async {
    await _box.clear();
  }
  
  // Get cart total
  double getCartTotal() {
    return _box.values.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }
  
  // Get cart item count
  int getCartItemCount() {
    return _box.values.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
  }
}
```

---

## ⚡ Real-time Updates

### 1. Order Tracking (Real-time)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderTrackingService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Listen to order status changes
  Stream<OrderModel> trackOrder(String orderId) {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((data) => OrderModel.fromJson(data.first));
  }
  
  // Listen to driver location updates
  Stream<DriverLocation> trackDriverLocation(String driverId) {
    return _supabase
        .from('driver_locations')
        .stream(primaryKey: ['id'])
        .eq('driver_id', driverId)
        .order('timestamp', ascending: false)
        .limit(1)
        .map((data) {
          if (data.isEmpty) throw Exception('No location data');
          return DriverLocation.fromJson(data.first);
        });
  }
}
```

### 2. Order Tracking Screen

```dart
class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  
  const OrderTrackingScreen({Key? key, required this.orderId}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderStream = ref.watch(orderTrackingProvider(orderId));
    
    return Scaffold(
      appBar: AppBar(title: const Text('Track Order')),
      body: orderStream.when(
        data: (order) => Column(
          children: [
            _buildOrderStatusTimeline(order),
            if (order.driverId != null)
              Expanded(
                child: _buildDriverMap(order.driverId!),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
  
  Widget _buildDriverMap(String driverId) {
    return StreamBuilder<DriverLocation>(
      stream: OrderTrackingService().trackDriverLocation(driverId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final location = snapshot.data!;
        
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(location.latitude, location.longitude),
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('driver'),
              position: LatLng(location.latitude, location.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
            ),
          },
        );
      },
    );
  }
}
```

---

## 📸 File Uploads

### Upload Service

```dart
class UploadService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Upload avatar
  Future<String> uploadAvatar(File file) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/$fileName';
    
    await _supabase.storage.from('avatars').upload(path, file);
    
    final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
    
    return publicUrl;
  }
  
  // Upload food item image (restaurant owner)
  Future<String> uploadFoodItemImage(File file, String foodItemId) async {
    final fileName = '${foodItemId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$foodItemId/$fileName';
    
    await _supabase.storage.from('food-items').upload(path, file);
    
    final publicUrl = _supabase.storage.from('food-items').getPublicUrl(path);
    
    return publicUrl;
  }
  
  // Upload review image
  Future<String> uploadReviewImage(File file) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/$fileName';
    
    await _supabase.storage.from('reviews').upload(path, file);
    
    final publicUrl = _supabase.storage.from('reviews').getPublicUrl(path);
    
    return publicUrl;
  }
}
```

---

## 🔔 Push Notifications

### Firebase Cloud Messaging Setup

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  Future<void> initialize() async {
    // Request permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Initialize local notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );
    
    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveDeviceToken(token);
    }
    
    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveDeviceToken);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }
  
  Future<void> _saveDeviceToken(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    await _supabase.from('device_tokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'is_active': true,
    });
  }
  
  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(
      message.notification?.title ?? '',
      message.notification?.body ?? '',
    );
  }
  
  Future<void> _showLocalNotification(String title, String body) async {
    const android = AndroidNotificationDetails(
      'order_updates',
      'Order Updates',
      channelDescription: 'Notifications for order status updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iOS = DarwinNotificationDetails();
    
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(android: android, iOS: iOS),
    );
  }
  
  void _handleNotificationTap(RemoteMessage message) {
    // Navigate to order detail screen
    final orderId = message.data['order_id'];
    if (orderId != null) {
      // Navigate to OrderDetailScreen(orderId: orderId)
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}
```

---

## 🗺️ Maps Integration

### Google Maps Service

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapsService {
  static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  // Get current location
  Future<Position> getCurrentLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    
    return await Geolocator.getCurrentPosition();
  }
  
  // Calculate distance between two points
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    ) / 1000; // Convert to km
  }
  
  // Get route polyline
  Future<List<LatLng>> getRoutePolyline(
    LatLng origin,
    LatLng destination,
  ) async {
    final polylinePoints = PolylinePoints();
    
    final result = await polylinePoints.getRouteBetweenCoordinates(
      _apiKey,
      PointLatLng(origin.latitude, origin.longitude),
      PointLatLng(destination.latitude, destination.longitude),
      travelMode: TravelMode.driving,
    );
    
    if (result.points.isNotEmpty) {
      return result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    }
    
    return [];
  }
}
```

---

## 💳 Payment Integration (Stripe)

### Stripe Service

```dart
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:dio/dio.dart';

class PaymentService {
  final Dio _dio = Dio();
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Initialize Stripe
  static Future<void> initialize() async {
    Stripe.publishableKey = 'YOUR_STRIPE_PUBLISHABLE_KEY';
  }
  
  // Create payment intent
  Future<String> createPaymentIntent(double amount, String orderId) async {
    try {
      final response = await _supabase.functions.invoke(
        'process-payment',
        body: {
          'amount': amount,
          'orderId': orderId,
        },
      );
      
      return response.data['client_secret'];
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }
  
  // Process payment
  Future<bool> processPayment({
    required double amount,
    required String orderId,
  }) async {
    try {
      // Create payment intent
      final clientSecret = await createPaymentIntent(amount, orderId);
      
      // Present payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'MTF Delivery',
        ),
      );
      
      await Stripe.instance.presentPaymentSheet();
      
      // Payment successful
      await _updateOrderPaymentStatus(orderId, 'paid');
      
      return true;
    } catch (e) {
      print('Payment error: $e');
      return false;
    }
  }
  
  Future<void> _updateOrderPaymentStatus(
    String orderId,
    String status,
  ) async {
    await _supabase.from('orders').update({
      'payment_status': status,
    }).eq('id', orderId);
  }
}
```

---

## 🎯 Complete Usage Example

### Restaurant List Screen

```dart
class RestaurantListScreen extends ConsumerStatefulWidget {
  const RestaurantListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RestaurantListScreen> createState() => 
      _RestaurantListScreenState();
}

class _RestaurantListScreenState extends ConsumerState<RestaurantListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    final restaurants = ref.watch(restaurantsProvider(_searchQuery));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search restaurants...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ),
      ),
      body: restaurants.when(
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final restaurant = list[index];
            return RestaurantCard(restaurant: restaurant);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

---

## 📝 Models Example

### Restaurant Model

```dart
class RestaurantModel {
  final String id;
  final String name;
  final String? imageUrl;
  final String? logoUrl;
  final String description;
  final double rating;
  final int reviewCount;
  final String cuisine;
  final int deliveryTime;
  final double deliveryFee;
  final double minOrder;
  final double? distance;
  final String priceRange;
  final bool isOpen;
  final bool isFeatured;
  
  RestaurantModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.logoUrl,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.cuisine,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.minOrder,
    this.distance,
    required this.priceRange,
    required this.isOpen,
    required this.isFeatured,
  });
  
  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
      logoUrl: json['logo_url'],
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      cuisine: json['cuisine'],
      deliveryTime: json['delivery_time'],
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
      minOrder: (json['min_order'] ?? 0).toDouble(),
      distance: json['distance']?.toDouble(),
      priceRange: json['price_range'] ?? '\$',
      isOpen: json['is_open'] ?? true,
      isFeatured: json['is_featured'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'logo_url': logoUrl,
      'description': description,
      'rating': rating,
      'review_count': reviewCount,
      'cuisine': cuisine,
      'delivery_time': deliveryTime,
      'delivery_fee': deliveryFee,
      'min_order': minOrder,
      'distance': distance,
      'price_range': priceRange,
      'is_open': isOpen,
      'is_featured': isFeatured,
    };
  }
}
```

---

## 🚀 Next Steps

1. **Set up your Supabase project** and run the complete SQL schema
2. **Configure environment variables** (API keys, etc.)
3. **Implement the authentication flow**
4. **Build the main features** (restaurants, cart, orders)
5. **Add real-time tracking**
6. **Integrate payments**
7. **Test thoroughly**
8. **Deploy to App Store & Play Store**

---

**Your Flutter app is now ready to integrate with your Supabase backend! 🎉**
