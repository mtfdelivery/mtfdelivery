import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/food_item_model.dart';
import '../buttons/app_buttons.dart';
import '../common/hover_wrapper.dart';

/// Food item card for menu and grid displays
class FoodItemCard extends StatelessWidget {
  final FoodItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final int cartQuantity;

  const FoodItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onAddToCart,
    this.onFavorite,
    this.isFavorite = false,
    this.cartQuantity = 0,
  });

  @override
  Widget build(BuildContext context) {
    return HoverWrapper(
      onTap: onTap,
      child: Container(
        width: AppDimensions.foodCardWidth,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food image with badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimensions.radiusMd),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    height: AppDimensions.foodCardImageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) =>
                            Container(color: AppColors.shimmerBase),
                    errorWidget:
                        (context, url, error) => Container(
                          color: AppColors.shimmerBase,
                          child: const Icon(Iconsax.gallery),
                        ),
                  ),
                ),
                // Discount badge
                if (item.discountPercentage != null)
                  Positioned(
                    top: AppDimensions.spacingSm,
                    left: AppDimensions.spacingSm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-${item.discountPercentage!.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ),
                // Favorite button
                Positioned(
                  top: AppDimensions.spacingSm,
                  right: AppDimensions.spacingSm,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.shadow, blurRadius: 4),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Iconsax.heart5 : Iconsax.heart,
                        size: 16,
                        color:
                            isFavorite
                                ? AppColors.error
                                : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                // Badges row (veg, spicy, popular)
                Positioned(
                  bottom: AppDimensions.spacingSm,
                  left: AppDimensions.spacingSm,
                  child: Row(
                    children: [
                      if (item.isVegetarian)
                        _buildBadge(Iconsax.activity, AppColors.success),
                      if (item.isSpicy)
                        _buildBadge(Iconsax.flash, AppColors.error),
                      if (item.isPopular)
                        _buildBadge(Iconsax.medal_star, AppColors.secondary),
                    ],
                  ),
                ),
              ],
            ),
            // Food info
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.star1,
                        size: 12,
                        color: AppColors.starFilled,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Iconsax.clock,
                        size: 12,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${item.preparationTime}min',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          if (item.originalPrice != null)
                            Text(
                              '\$${item.originalPrice!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      // Add button
                      if (cartQuantity > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$cartQuantity',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Iconsax.add,
                              size: 18,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 10, color: AppColors.textOnPrimary),
    );
  }
}

/// Horizontal food item card for lists
class FoodListItem extends StatelessWidget {
  final FoodItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final int quantity;

  const FoodListItem({
    super.key,
    required this.item,
    this.onTap,
    this.onAddToCart,
    this.onIncrement,
    this.onDecrement,
    this.quantity = 0,
  });

  @override
  Widget build(BuildContext context) {
    return HoverWrapper(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Row(
          children: [
            // Food image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(color: AppColors.shimmerBase),
                errorWidget:
                    (context, url, error) => Container(
                      color: AppColors.shimmerBase,
                      child: const Icon(Iconsax.gallery),
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
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (quantity > 0)
                        _buildQuantitySelector()
                      else
                        SmallButton(
                          text: 'Add',
                          icon: Iconsax.add,
                          onPressed: onAddToCart,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Iconsax.minus, size: 16),
            color: AppColors.primary,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 24),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Iconsax.add, size: 16),
            color: AppColors.primary,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
