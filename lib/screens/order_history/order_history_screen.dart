import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/widgets.dart';

import 'package:go_router/go_router.dart';
import '../../navigation/app_router.dart';

/// Order history screen
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  // Mock order data
  List<_MockOrder> get _orders => [
    _MockOrder(
      id: 'ORD-82749',
      restaurantName: 'Bella Italia',
      restaurantImage:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
      date: 'Jan 23, 2026',
      total: 42.50,
      status: 'Delivered',
      itemCount: 3,
    ),
    _MockOrder(
      id: 'ORD-82635',
      restaurantName: 'Sakura Sushi',
      restaurantImage:
          'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=400',
      date: 'Jan 20, 2026',
      total: 58.00,
      status: 'Delivered',
      itemCount: 5,
    ),
    _MockOrder(
      id: 'ORD-82501',
      restaurantName: 'Burger Palace',
      restaurantImage:
          'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400',
      date: 'Jan 18, 2026',
      total: 28.99,
      status: 'Delivered',
      itemCount: 2,
    ),
    _MockOrder(
      id: 'ORD-82398',
      restaurantName: 'Taco Fiesta',
      restaurantImage:
          'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400',
      date: 'Jan 15, 2026',
      total: 35.50,
      status: 'Cancelled',
      itemCount: 4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.orderHistory),
        centerTitle: true,
      ),
      body:
          _orders.isEmpty
              ? const EmptyOrdersState()
              : ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.paddingLg),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.spacingMd,
                    ),
                    child: _buildOrderCard(context, order),
                  );
                },
              ),
    );
  }

  Widget _buildOrderCard(BuildContext context, _MockOrder order) {
    return GestureDetector(
      onTap: () => context.push(Routes.orderTracking(order.id)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(
                          order.restaurantImage,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.restaurantName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '#${order.id.split('-').last}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.itemCount} items • ${order.date}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '\$${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const Spacer(),
                            StatusBadge(status: order.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            const Divider(height: 1, indent: 16, endIndent: 16),

            // Actions
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingSm),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed:
                          () => context.push(Routes.orderTracking(order.id)),
                      icon: const Icon(Iconsax.receipt_2, size: 18),
                      label: const Text('Track Order'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 20, color: AppColors.border),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: order.status == 'Delivered' ? () {} : null,
                      icon: const Icon(Iconsax.refresh, size: 18),
                      label: const Text(AppStrings.reorder),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            order.status == 'Delivered'
                                ? AppColors.primary
                                : AppColors.textTertiary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockOrder {
  final String id;
  final String restaurantName;
  final String restaurantImage;
  final String date;
  final double total;
  final String status;
  final int itemCount;

  _MockOrder({
    required this.id,
    required this.restaurantName,
    required this.restaurantImage,
    required this.date,
    required this.total,
    required this.status,
    required this.itemCount,
  });
}
