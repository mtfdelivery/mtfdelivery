import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../navigation/app_router.dart';
import '../../widgets/widgets.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_provider.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

/// Order tracking screen with live status
class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  // Map OrderStatus enum to a step index
  int _stepIndexFromStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 0;
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.outForDelivery:
        return 2;
      case OrderStatus.delivered:
        return 3;
      case OrderStatus.cancelled:
        return -1; // special
    }
  }

  static const _stepDefinitions = [
    _TrackingStepDef(
      title: 'Order Confirmed',
      description: 'Your order has been received',
      icon: Iconsax.tick_circle,
    ),
    _TrackingStepDef(
      title: 'Preparing',
      description: 'Restaurant is preparing your order',
      icon: Iconsax.timer_1,
    ),
    _TrackingStepDef(
      title: 'Out for Delivery',
      description: 'Driver is on the way',
      icon: Iconsax.truck,
    ),
    _TrackingStepDef(
      title: 'Delivered',
      description: 'Enjoy your meal!',
      icon: Iconsax.bag_tick,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final trackingAsync = ref.watch(orderTrackingProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Tracking'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
      ),
      body: trackingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.warning_2, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load order tracking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SecondaryButton(
                      text: 'Retry',
                      onPressed:
                          () => ref.invalidate(
                            orderTrackingProvider(widget.orderId),
                          ),
                    ),
                  ],
                ),
              ),
            ),
        data: (order) {
          if (order == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.receipt_item,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Order not found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SecondaryButton(
                    text: 'Back to Home',
                    onPressed: () => context.go(Routes.home),
                  ),
                ],
              ),
            );
          }

          // Cancelled state
          if (order.status == OrderStatus.cancelled) {
            return _buildCancelledView(order);
          }

          final currentStep = _stepIndexFromStatus(order.status);
          return _buildTrackingBody(order, currentStep);
        },
      ),
    );
  }

  Widget _buildTrackingBody(OrderModel order, int currentStep) {
    final estimatedTime = _formatEstimatedTime(order);
    final shortOrderId =
        order.id.length > 8
            ? order.id.substring(0, 8).toUpperCase()
            : order.id.toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      child: Column(
        children: [
          // Estimated time card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.paddingXl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Order #$shortOrderId',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Estimated Delivery',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  estimatedTime,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (order.estimatedDelivery != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Arriving by ${DateFormat.jm().format(order.estimatedDelivery!)}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ).animate().slideY(begin: 0.2, duration: 400.ms).fadeIn(),

          const SizedBox(height: AppDimensions.spacingXxl),

          // Tracking note (if any)
          if (order.trackingNote != null && order.trackingNote!.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppDimensions.spacingLg),
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.info_circle, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.trackingNote!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Tracking steps
          Container(
                padding: const EdgeInsets.all(AppDimensions.paddingLg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(_stepDefinitions.length, (index) {
                    final step = _stepDefinitions[index];
                    final isCompleted = index <= currentStep;
                    final isActive = index == currentStep;
                    final isLast = index == _stepDefinitions.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Step indicator
                          Column(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color:
                                      isCompleted
                                          ? AppColors.primary
                                          : AppColors.surfaceVariant,
                                  shape: BoxShape.circle,
                                  border:
                                      isActive
                                          ? Border.all(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.2,
                                            ),
                                            width: 4,
                                          )
                                          : null,
                                ),
                                child: Icon(
                                  isCompleted ? Iconsax.tick_circle : step.icon,
                                  size: 16,
                                  color:
                                      isCompleted
                                          ? Colors.white
                                          : AppColors.textTertiary,
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color:
                                        isCompleted
                                            ? AppColors.primary
                                            : AppColors.border,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: AppDimensions.spacingMd),

                          // Step content
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppDimensions.paddingLg,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          isActive
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                      color:
                                          isCompleted
                                              ? AppColors.textPrimary
                                              : AppColors.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    step.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          isCompleted
                                              ? AppColors.textSecondary
                                              : AppColors.textTertiary,
                                    ),
                                  ),
                                  if (isActive)
                                    RepaintBoundary(
                                      child: Container(
                                            margin: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'In Progress',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          )
                                          .animate(
                                            onPlay:
                                                (controller) => controller
                                                    .repeat(reverse: true),
                                          )
                                          .shimmer(
                                            duration: 2.seconds,
                                            color: Colors.white,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(
                      delay: (index * 100).ms,
                      duration: 400.ms,
                    );
                  }),
                ),
              )
              .animate()
              .slideY(begin: 0.1, delay: 200.ms, duration: 400.ms)
              .fadeIn(),

          const SizedBox(height: AppDimensions.spacingXxl),

          // Driver info card — show only when driver data is available
          if (order.driverName != null && order.driverName!.isNotEmpty)
            _buildDriverCard(order),

          const SizedBox(height: AppDimensions.spacingXxl),

          // Back to home button
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              text: 'Back to Home',
              onPressed: () => context.go(Routes.home),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Driver avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
              image:
                  order.driverAvatar != null && order.driverAvatar!.isNotEmpty
                      ? DecorationImage(
                        image: NetworkImage(order.driverAvatar!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                order.driverAvatar == null || order.driverAvatar!.isEmpty
                    ? Icon(
                      Iconsax.user,
                      size: 24,
                      color: AppColors.textTertiary,
                    )
                    : null,
          ),
          const SizedBox(width: AppDimensions.spacingMd),

          // Driver info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.driverName ?? 'Driver',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (order.driverRating != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.star1,
                        size: 14,
                        color: AppColors.starFilled,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.driverRating!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          Row(
            children: [
              if (order.driverPhone != null && order.driverPhone!.isNotEmpty)
                _buildActionButton(Iconsax.call, () async {
                  final uri = Uri.parse('tel:${order.driverPhone}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                }),
              const SizedBox(width: AppDimensions.spacingSm),
              _buildActionButton(Iconsax.message, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat coming soon')),
                );
              }),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.1, delay: 400.ms, duration: 400.ms).fadeIn();
  }

  Widget _buildCancelledView(OrderModel order) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.close_circle, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Order Cancelled',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              order.trackingNote ?? 'This order has been cancelled.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                text: 'Back to Home',
                onPressed: () => context.go(Routes.home),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEstimatedTime(OrderModel order) {
    if (order.status == OrderStatus.delivered) return 'Delivered';

    if (order.estimatedDelivery != null) {
      final now = DateTime.now();
      final diff = order.estimatedDelivery!.difference(now);
      if (diff.isNegative) return 'Any moment';
      final mins = diff.inMinutes;
      if (mins < 60) return '$mins min';
      return '${diff.inHours}h ${mins % 60}m';
    }
    return '-- min';
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}

class _TrackingStepDef {
  final String title;
  final String description;
  final IconData icon;

  const _TrackingStepDef({
    required this.title,
    required this.description,
    required this.icon,
  });
}
