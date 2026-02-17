import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/food_item_model.dart';
import '../../navigation/app_router.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/widgets.dart';

/// Cart screen
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final deliveryFee = ref.watch(deliveryFeeProvider);
    final tax = ref.watch(taxProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120.h),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.paddingLg,
                40.h,
                AppDimensions.paddingLg,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Spacer
                  Text(
                    AppStrings.myCart,
                    style: GoogleFonts.urbanist(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A0A0F),
                    ),
                  ),
                  if (cartItems.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).clearCart();
                      },
                      child: Text(
                        'Clear',
                        style: GoogleFonts.urbanist(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),
      body:
          cartItems.isEmpty
              ? EmptyCartState(
                onBrowse: () {
                  context.go(Routes.restaurantHome);
                },
              )
              : Column(
                children: [
                  // Cart items list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppDimensions.paddingLg),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppDimensions.spacingMd,
                          ),
                          child: _buildCartItem(context, ref, item),
                        );
                      },
                    ),
                  ),

                  // Bottom section with totals
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      AppDimensions.paddingLg,
                      AppDimensions.paddingLg,
                      AppDimensions.paddingLg,
                      AppDimensions.paddingLg + AppDimensions.bottomNavHeight,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Coupon code input
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingMd,
                            vertical: AppDimensions.paddingSm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Iconsax.ticket_discount,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppDimensions.spacingSm),
                              const Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Enter coupon code',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    fillColor: Colors.transparent,
                                  ),
                                ),
                              ),
                              SmallButton(
                                text: AppStrings.apply,
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingLg),

                        // Price breakdown
                        _buildPriceRow('Subtotal', subtotal),
                        const SizedBox(height: AppDimensions.spacingSm),
                        _buildPriceRow(
                          'Delivery Fee',
                          deliveryFee,
                          highlight: deliveryFee == 0,
                        ),
                        const SizedBox(height: AppDimensions.spacingSm),
                        _buildPriceRow('Tax', tax),
                        const Divider(height: AppDimensions.spacingXxl),
                        _buildPriceRow('Total', total, isTotal: true),
                        const SizedBox(height: AppDimensions.spacingLg),

                        // Checkout button
                        PrimaryButton(
                          text: AppStrings.proceedToCheckout,
                          onPressed: () => context.push(Routes.checkout),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    WidgetRef ref,
    CartItemModel item,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Food image
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            child: CachedNetworkImage(
              imageUrl: item.foodItem.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),

          // Food info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.foodItem.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.foodItem.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity controls
                    QuantitySelector(
                      quantity: item.quantity,
                      minValue: 0,
                      onDecrement: () {
                        ref
                            .read(cartProvider.notifier)
                            .decrementQuantity(item.foodItem.id);
                      },
                      onIncrement: () {
                        ref
                            .read(cartProvider.notifier)
                            .incrementQuantity(item.foodItem.id);
                      },
                    ),
                    // Item total
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double value, {
    bool isTotal = false,
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          highlight && value == 0 ? 'Free' : '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color:
                highlight && value == 0
                    ? AppColors.primary
                    : isTotal
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
