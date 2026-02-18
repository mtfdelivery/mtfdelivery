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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.myCart,
          style: GoogleFonts.urbanist(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
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
                      // Account for bottom navigation and safe area
                      AppDimensions.paddingLg + 70.h,
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
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppDimensions.radiusLg),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        const Divider(height: AppDimensions.spacingXl),
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
            child:
                item.foodItem.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: item.foodItem.imageUrl,
                      width: 80.w,
                      height: 80.w,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(
                              Iconsax.image,
                              color: AppColors.textTertiary,
                            ),
                          ),
                    )
                    : Container(
                      width: 80.w,
                      height: 80.w,
                      color: AppColors.surfaceVariant,
                      child: const Icon(
                        Iconsax.image,
                        color: AppColors.textTertiary,
                      ),
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
                  style: GoogleFonts.urbanist(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.specialInstructions != null)
                  Text(
                    item.specialInstructions!,
                    style: GoogleFonts.urbanist(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.urbanist(
                        fontSize: 16.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
          style: GoogleFonts.urbanist(
            fontSize: isTotal ? 16.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          highlight && value == 0 ? 'Free' : '\$${value.toStringAsFixed(2)}',
          style: GoogleFonts.urbanist(
            fontSize: isTotal ? 18.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color:
                highlight && value == 0
                    ? AppColors.primary
                    : isTotal
                    ? AppColors.textPrimary
                    : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
