import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../navigation/app_router.dart';
import '../../widgets/widgets.dart';

import 'package:flutter_animate/flutter_animate.dart';

/// Order tracking screen with live status
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final int _currentStep =
      1; // 0: Confirmed, 1: Preparing, 2: Out for Delivery, 3: Delivered

  final List<_TrackingStep> _steps = [
    _TrackingStep(
      title: 'Order Confirmed',
      description: 'Your order has been received',
      icon: Iconsax.tick_circle,
      time: '10:30 AM',
    ),
    _TrackingStep(
      title: 'Preparing',
      description: 'Restaurant is preparing your order',
      icon: Iconsax.timer_1,
      time: '10:35 AM',
    ),
    _TrackingStep(
      title: 'Out for Delivery',
      description: 'Driver is on the way',
      icon: Iconsax.truck,
      time: '10:55 AM',
    ),
    _TrackingStep(
      title: 'Delivered',
      description: 'Enjoy your meal!',
      icon: Iconsax.bag_tick,
      time: '11:15 AM',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order Tracking'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order information coming soon')),
              );
            },
            icon: const Icon(Iconsax.info_circle),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  const Text(
                    'Order ID: #ORD-123456',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Estimated Delivery',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '25-30 min',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Arriving by 11:15 AM',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.2, duration: 400.ms).fadeIn(),

            const SizedBox(height: AppDimensions.spacingXxl),

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
                    children: List.generate(_steps.length, (index) {
                      final step = _steps[index];
                      final isCompleted = index <= _currentStep;
                      final isActive = index == _currentStep;
                      final isLast = index == _steps.length - 1;

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
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.2),
                                              width: 4,
                                            )
                                            : null,
                                  ),
                                  child: Icon(
                                    isCompleted
                                        ? Iconsax.tick_circle
                                        : step.icon,
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                        if (isCompleted)
                                          Text(
                                            step.time,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                      ],
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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

            // Driver info card
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
                  child: Row(
                    children: [
                      // Driver avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),

                      // Driver info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'John Smith',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Iconsax.star1,
                                  size: 14,
                                  color: AppColors.starFilled,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '4.9 (500+)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Action buttons
                      Row(
                        children: [
                          _buildActionButton(Iconsax.call, () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Calling driver...'),
                              ),
                            );
                          }),
                          const SizedBox(width: AppDimensions.spacingSm),
                          _buildActionButton(Iconsax.message, () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opening chat...')),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                )
                .animate()
                .slideY(begin: 0.1, delay: 400.ms, duration: 400.ms)
                .fadeIn(),

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
      ),
    );
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

class _TrackingStep {
  final String title;
  final String description;
  final IconData icon;
  final String time;

  _TrackingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.time,
  });
}
