import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';
import '../data/models/food_item_model.dart';
import '../data/models/order_model.dart';
import '../data/models/user_model.dart';
import '../data/models/address_model.dart';
import 'cart_provider.dart';

/// Order state for tracking submission status
enum OrderSubmissionStatus { idle, submitting, success, error }

class OrderSubmissionState {
  final OrderSubmissionStatus status;
  final String? orderId;
  final String? errorMessage;

  const OrderSubmissionState({
    this.status = OrderSubmissionStatus.idle,
    this.orderId,
    this.errorMessage,
  });

  OrderSubmissionState copyWith({
    OrderSubmissionStatus? status,
    String? orderId,
    String? errorMessage,
  }) {
    return OrderSubmissionState(
      status: status ?? this.status,
      orderId: orderId ?? this.orderId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Order notifier for managing order submission and fetching
class OrderNotifier extends StateNotifier<OrderSubmissionState> {
  final Ref _ref;

  OrderNotifier(this._ref) : super(const OrderSubmissionState());

  /// Submit a new order to Supabase
  Future<String?> submitOrder({
    required String restaurantId,
    required String restaurantName,
    required String restaurantImage,
    required AddressModel deliveryAddress,
    required String paymentMethod,
    String? notes,
    double? tip,
  }) async {
    // Double-submission guard
    if (state.status == OrderSubmissionStatus.submitting) {
      debugPrint(
        'Order submission already in progress — ignoring duplicate call',
      );
      return null;
    }

    state = state.copyWith(status: OrderSubmissionStatus.submitting);

    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        state = state.copyWith(
          status: OrderSubmissionStatus.error,
          errorMessage: 'User not authenticated',
        );
        return null;
      }

      final cartItems = _ref.read(cartProvider);
      if (cartItems.isEmpty) {
        state = state.copyWith(
          status: OrderSubmissionStatus.error,
          errorMessage: 'Cart is empty',
        );
        return null;
      }

      final subtotal = _ref.read(cartSubtotalProvider);
      final deliveryFee = _ref.read(deliveryFeeProvider);
      final tax = _ref.read(taxProvider);
      final total = _ref.read(cartTotalProvider);

      // Create the order in food.orders table
      final orderResponse =
          await SupabaseService.client
              .schema('food')
              .from('orders')
              .insert({
                'user_id': user.id,
                'restaurant_id': restaurantId,
                'delivery_address_id': deliveryAddress.id,
                'delivery_address_text': deliveryAddress.fullAddress,
                'delivery_lat': deliveryAddress.latitude,
                'delivery_lng': deliveryAddress.longitude,
                'subtotal': subtotal,
                'delivery_fee': deliveryFee,
                'tax_amount': tax,
                'total': total,
                'payment_method': paymentMethod,
                'payment_status': 'pending',
                'notes': notes,
                'tip': tip ?? 0,
                'status': 'pending',
              })
              .select('id, order_number')
              .single();

      final orderId = orderResponse['id'] as String;

      // Insert order items
      final orderItems =
          cartItems.map((item) {
            return {
              'order_id': orderId,
              'menu_item_id': item.foodItem.id,
              'menu_item_name': item.foodItem.name,
              'quantity': item.quantity,
              'unit_price': item.foodItem.price,
              'total_price': item.totalPrice,
              'notes': item.specialInstructions,
            };
          }).toList();

      await SupabaseService.client
          .schema('food')
          .from('order_items')
          .insert(orderItems);

      // Clear the cart after successful order
      _ref.read(cartProvider.notifier).clearCart();

      state = state.copyWith(
        status: OrderSubmissionStatus.success,
        orderId: orderId,
      );

      debugPrint('[OrderNotifier] Order created successfully: $orderId');
      return orderId;
    } catch (e) {
      debugPrint('[OrderNotifier] Error submitting order: $e');
      state = state.copyWith(
        status: OrderSubmissionStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Reset submission state
  void resetState() {
    state = const OrderSubmissionState();
  }
}

/// Order provider
final orderProvider =
    StateNotifierProvider<OrderNotifier, OrderSubmissionState>((ref) {
      return OrderNotifier(ref);
    });

/// Provider for fetching user's order history
final userOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  try {
    final response = await SupabaseService.client
        .schema('food')
        .from('orders')
        .select('''
          id,
          order_number,
          restaurant_id,
          status,
          subtotal,
          delivery_fee,
          tax_amount,
          discount,
          total,
          payment_method,
          created_at,
          estimated_delivery_at,
          delivered_at,
          notes,
          delivery_address_text,
          restaurants(name, cover_url),
          order_items(
            id,
            menu_item_name,
            quantity,
            unit_price,
            total_price,
            notes
          )
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    return response.map<OrderModel>((orderData) {
      final restaurant = orderData['restaurants'] as Map<String, dynamic>?;
      final items = orderData['order_items'] as List<dynamic>?;

      return OrderModel(
        id: orderData['id'] as String,
        restaurantId: orderData['restaurant_id'] as String,
        restaurantName: restaurant?['name'] as String? ?? 'Unknown Restaurant',
        restaurantImage: restaurant?['cover_url'] as String? ?? '',
        items:
            items?.map<CartItemModel>((item) {
              return CartItemModel(
                foodItem: FoodItemModel(
                  id: item['id'] as String,
                  restaurantId: orderData['restaurant_id'] as String,
                  name: item['menu_item_name'] as String,
                  description: '',
                  imageUrl: '',
                  price: (item['unit_price'] as num?)?.toDouble() ?? 0.0,
                  category: '',
                  rating: 0,
                  reviewCount: 0,
                  preparationTime: 0,
                ),
                quantity: item['quantity'] as int? ?? 1,
                specialInstructions: item['notes'] as String?,
              );
            }).toList() ??
            [],
        status: _parseOrderStatus(orderData['status'] as String?),
        subtotal: (orderData['subtotal'] as num?)?.toDouble() ?? 0.0,
        deliveryFee: (orderData['delivery_fee'] as num?)?.toDouble() ?? 0.0,
        tax: (orderData['tax_amount'] as num?)?.toDouble() ?? 0.0,
        discount: (orderData['discount'] as num?)?.toDouble() ?? 0.0,
        total: (orderData['total'] as num?)?.toDouble() ?? 0.0,
        deliveryAddress: AddressModel(
          id: '',
          label: 'Delivery',
          street: orderData['delivery_address_text'] as String? ?? '',
          city: '',
          zipCode: '',
          latitude: 0,
          longitude: 0,
        ),
        paymentMethod: orderData['payment_method'] as String? ?? '',
        orderDate:
            DateTime.tryParse(orderData['created_at'] as String? ?? '') ??
            DateTime.now(),
        estimatedDelivery:
            orderData['estimated_delivery_at'] != null
                ? DateTime.tryParse(
                  orderData['estimated_delivery_at'] as String,
                )
                : null,
        deliveredAt:
            orderData['delivered_at'] != null
                ? DateTime.tryParse(orderData['delivered_at'] as String)
                : null,
      );
    }).toList();
  } catch (e) {
    debugPrint('[userOrdersProvider] Error fetching orders: $e');
    return [];
  }
});

/// Stream provider for real-time order tracking
final orderTrackingProvider = StreamProvider.family<OrderModel?, String>((
  ref,
  orderId,
) async* {
  try {
    final stream = SupabaseService.client
        .schema('food')
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .limit(1);

    await for (final data in stream) {
      if (data.isEmpty) {
        yield null;
        continue;
      }

      final orderData = data.first;

      // Fetch restaurant info
      final restaurantResponse =
          await SupabaseService.client
              .schema('food')
              .from('restaurants')
              .select('name, cover_url')
              .eq('id', orderData['restaurant_id'])
              .maybeSingle();

      // Fetch order items
      final itemsResponse = await SupabaseService.client
          .schema('food')
          .from('order_items')
          .select()
          .eq('order_id', orderId);

      yield OrderModel(
        id: orderData['id'] as String,
        restaurantId: orderData['restaurant_id'] as String,
        restaurantName: restaurantResponse?['name'] as String? ?? '',
        restaurantImage: restaurantResponse?['cover_url'] as String? ?? '',
        items:
            (itemsResponse as List).map<CartItemModel>((item) {
              return CartItemModel(
                foodItem: FoodItemModel(
                  id: item['menu_item_id'] as String? ?? '',
                  restaurantId: orderData['restaurant_id'] as String,
                  name: item['menu_item_name'] as String,
                  description: '',
                  imageUrl: '',
                  price: (item['unit_price'] as num?)?.toDouble() ?? 0.0,
                  category: '',
                  rating: 0,
                  reviewCount: 0,
                  preparationTime: 0,
                ),
                quantity: item['quantity'] as int? ?? 1,
                specialInstructions: item['notes'] as String?,
              );
            }).toList(),
        status: _parseOrderStatus(orderData['status'] as String?),
        subtotal: (orderData['subtotal'] as num?)?.toDouble() ?? 0.0,
        deliveryFee: (orderData['delivery_fee'] as num?)?.toDouble() ?? 0.0,
        tax: (orderData['tax_amount'] as num?)?.toDouble() ?? 0.0,
        discount: (orderData['discount'] as num?)?.toDouble() ?? 0.0,
        total: (orderData['total'] as num?)?.toDouble() ?? 0.0,
        deliveryAddress: AddressModel(
          id: '',
          label: 'Delivery',
          street: orderData['delivery_address_text'] as String? ?? '',
          city: '',
          zipCode: '',
          latitude: 0,
          longitude: 0,
        ),
        paymentMethod: orderData['payment_method'] as String? ?? '',
        orderDate:
            DateTime.tryParse(orderData['created_at'] as String? ?? '') ??
            DateTime.now(),
        estimatedDelivery:
            orderData['estimated_delivery_at'] != null
                ? DateTime.tryParse(
                  orderData['estimated_delivery_at'] as String,
                )
                : null,
        deliveredAt:
            orderData['delivered_at'] != null
                ? DateTime.tryParse(orderData['delivered_at'] as String)
                : null,
        trackingNote: orderData['notes'] as String?,
      );
    }
  } catch (e) {
    debugPrint('[orderTrackingProvider] Error: $e');
    yield null;
  }
});

/// Helper to parse order status from string
OrderStatus _parseOrderStatus(String? status) {
  switch (status) {
    case 'pending':
    case 'pending_dispatch':
      return OrderStatus.pending;
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'preparing':
    case 'ready':
      return OrderStatus.preparing;
    case 'picked_up':
      return OrderStatus.outForDelivery;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
    case 'refunded':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}
