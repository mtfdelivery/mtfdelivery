import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/widgets.dart';

import 'package:go_router/go_router.dart';
import '../../core/utils/responsive.dart';
import '../../navigation/app_router.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_provider.dart';

/// Order history screen
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.orderHistory),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => context.pop(),
        ),
      ),
      body: ordersAsync.when(
        data:
            (orders) =>
                orders.isEmpty
                    ? const EmptyOrdersState()
                    : context.isMobile
                    ? ListView.builder(
                      padding: const EdgeInsets.all(AppDimensions.paddingLg),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppDimensions.spacingMd,
                          ),
                          child: _buildOrderCard(context, order),
                        );
                      },
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(AppDimensions.paddingLg),
                      itemCount: orders.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: context.isDesktop ? 3 : 2,
                        mainAxisSpacing: 16.h,
                        crossAxisSpacing: 16.w,
                        childAspectRatio: 2.2,
                      ),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return _buildOrderCard(context, order);
                      },
                    ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
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
                              order.orderNumber ??
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
                          '${order.totalItems} items • ${DateFormat('MMM d, yyyy').format(order.orderDate)}',
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
                            StatusBadge(
                              status: _mapToStatusString(order.status),
                            ),
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
                      onPressed:
                          order.status == OrderStatus.delivered
                              ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Reorder functionality coming soon!',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                              : null,
                      icon: const Icon(Iconsax.refresh, size: 18),
                      label: const Text(AppStrings.reorder),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            order.status == OrderStatus.delivered
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

  String _mapToStatusString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
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
}
