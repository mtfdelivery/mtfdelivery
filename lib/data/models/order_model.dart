import 'food_item_model.dart';
import 'address_model.dart';
import 'user_model.dart';
import '../../providers/order_provider.dart' show parseOrderStatus;

/// Order status enumeration
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

/// Order model for tracking orders
class OrderModel {
  final String id;
  final String? orderNumber;
  final String restaurantId;
  final String restaurantName;
  final String restaurantImage;
  final List<CartItemModel> items;
  final OrderStatus status;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double discount;
  final double total;
  final AddressModel deliveryAddress;
  final String paymentMethod;
  final DateTime orderDate;
  final DateTime? estimatedDelivery;
  final DateTime? deliveredAt;
  final String? driverName;
  final String? driverPhone;
  final String? driverAvatar;
  final double? driverRating;
  final String? trackingNote;

  const OrderModel({
    required this.id,
    this.orderNumber,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantImage,
    required this.items,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    this.discount = 0,
    required this.total,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.orderDate,
    this.estimatedDelivery,
    this.deliveredAt,
    this.driverName,
    this.driverPhone,
    this.driverAvatar,
    this.driverRating,
    this.trackingNote,
  });

  /// Parse an OrderStatus from a DB string — delegates to the canonical parser.
  static OrderStatus _parseStatus(String? status) => parseOrderStatus(status);

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse order items if present
    final itemsList = <CartItemModel>[];
    if (json['order_items'] != null && json['order_items'] is List) {
      for (final itemJson in json['order_items'] as List) {
        final map = itemJson as Map<String, dynamic>;
        itemsList.add(
          CartItemModel(
            foodItem: FoodItemModel(
              id: map['menu_item_id'] as String? ?? '',
              name: map['menu_item_name'] as String? ?? '',
              description: '',
              price: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
              imageUrl: map['menu_item_image'] as String? ?? '',
              restaurantId: json['restaurant_id'] as String? ?? '',
              category: map['category'] as String? ?? '',
              rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
              reviewCount: map['review_count'] as int? ?? 0,
              preparationTime: map['preparation_time'] as int? ?? 0,
              isAvailable: true,
            ),
            quantity: map['quantity'] as int? ?? 1,
            specialInstructions: map['notes'] as String?,
          ),
        );
      }
    }

    // Parse delivery address
    final addressJson = json['delivery_address'] as Map<String, dynamic>?;
    final deliveryAddress =
        addressJson != null
            ? AddressModel.fromJson(addressJson)
            : AddressModel(
              id: json['delivery_address_id'] as String? ?? '',
              label: 'Delivery',
              street: json['delivery_address_text'] as String? ?? '',
              city: '',
              latitude: (json['delivery_lat'] as num?)?.toDouble() ?? 0.0,
              longitude: (json['delivery_lng'] as num?)?.toDouble() ?? 0.0,
            );

    return OrderModel(
      id: json['id'] as String? ?? '',
      orderNumber: json['order_number'] as String?,
      restaurantId: json['restaurant_id'] as String? ?? '',
      restaurantName:
          json['restaurant_name'] as String? ??
          (json['restaurants'] != null
              ? (json['restaurants'] as Map<String, dynamic>)['name']
                      as String? ??
                  ''
              : ''),
      restaurantImage:
          json['restaurant_image'] as String? ??
          (json['restaurants'] != null
              ? (json['restaurants'] as Map<String, dynamic>)['cover_url']
                      as String? ??
                  ''
              : ''),
      items: itemsList,
      status: _parseStatus(json['status'] as String?),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: deliveryAddress,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      orderDate:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      estimatedDelivery:
          json['estimated_delivery_at'] != null
              ? DateTime.tryParse(json['estimated_delivery_at'] as String)
              : (json['estimated_delivery'] != null
                  ? DateTime.tryParse(json['estimated_delivery'] as String)
                  : null),
      deliveredAt:
          json['actual_delivery_at'] != null
              ? DateTime.tryParse(json['actual_delivery_at'] as String)
              : (json['delivered_at'] != null
                  ? DateTime.tryParse(json['delivered_at'] as String)
                  : null),
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      driverAvatar: json['driver_avatar'] as String?,
      driverRating: (json['driver_rating'] as num?)?.toDouble(),
      trackingNote: json['tracking_note'] as String?,
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  OrderModel copyWith({
    String? id,
    String? restaurantId,
    String? restaurantName,
    String? restaurantImage,
    List<CartItemModel>? items,
    OrderStatus? status,
    double? subtotal,
    double? deliveryFee,
    double? tax,
    double? discount,
    double? total,
    AddressModel? deliveryAddress,
    String? paymentMethod,
    DateTime? orderDate,
    DateTime? estimatedDelivery,
    DateTime? deliveredAt,
    String? driverName,
    String? driverPhone,
    String? driverAvatar,
    double? driverRating,
    String? trackingNote,
  }) {
    return OrderModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantImage: restaurantImage ?? this.restaurantImage,
      items: items ?? this.items,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderDate: orderDate ?? this.orderDate,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverAvatar: driverAvatar ?? this.driverAvatar,
      driverRating: driverRating ?? this.driverRating,
      trackingNote: trackingNote ?? this.trackingNote,
    );
  }
}
