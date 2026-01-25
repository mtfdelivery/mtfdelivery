import 'food_item_model.dart';
import 'user_model.dart';

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
