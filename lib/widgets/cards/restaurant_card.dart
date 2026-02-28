import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/restaurant_model.dart';
import '../common/hover_wrapper.dart';

/// Restaurant card for home screen listings
class RestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final double? width;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return HoverWrapper(
      onTap: onTap,
      child: Container(
        width: width ?? 336,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Overlays
            Stack(
              children: [
                // Main Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimensions.cardRadius),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: restaurant.imageUrl,
                    height: 144.h, // +20% from 120
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) =>
                            Container(color: AppColors.shimmerBase),
                    errorWidget:
                        (context, url, error) => Container(
                          color: AppColors.shimmerBase,
                          child: const Icon(
                            Iconsax.gallery,
                            color: AppColors.textTertiary,
                          ),
                        ),
                  ),
                ),
                // Closed Overlay
                if (!restaurant.isOpen)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppDimensions.cardRadius),
                      ),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.6),
                        alignment: Alignment.center,
                        child: Text(
                          'CLOSED',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Time Badge
                if (restaurant.isOpen)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${restaurant.deliveryTime}-${restaurant.deliveryTime + 15} min',
                        style: const TextStyle(
                          fontSize: 12, // +20%
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                // Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Iconsax.heart5 : Iconsax.heart,
                        size: 20, // +20%
                        color: isFavorite ? AppColors.error : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(8), // Even tighter padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(
                            fontSize: 16, // +20%
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.starFilled,
                            size: 19, // +20%
                          ),
                          const SizedBox(width: 2),
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14, // +20%
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "(${restaurant.reviewCount}+)",
                            style: const TextStyle(
                              fontSize: 12, // +20%
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Subtitle
                  Text(
                    "${restaurant.priceRange} • ${restaurant.cuisine}",
                    style: const TextStyle(
                      fontSize: 13, // +20%
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Delivery Fee Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Iconsax.truck,
                          size: 17, // +20%
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.deliveryFee == 0
                              ? 'Free Delivery'
                              : '\$${restaurant.deliveryFee.toStringAsFixed(2)} Delivery',
                          style: const TextStyle(
                            fontSize: 13, // +20%
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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

/// Compact restaurant card for grid/list views
class RestaurantListCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const RestaurantListCard({
    super.key,
    required this.restaurant,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
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
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Restaurant image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: restaurant.imageUrl,
                    width: 96.w,
                    height: 96.h,
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
                  if (!restaurant.isOpen)
                    Container(
                      width: 96.w,
                      height: 96.h,
                      color: Colors.black.withValues(alpha: 0.6),
                      alignment: Alignment.center,
                      child: Text(
                        'CLOSED',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            // Restaurant info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
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
                    restaurant.cuisine,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.star1,
                        size: 14,
                        color: AppColors.starFilled,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.rating} (${restaurant.reviewCount})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Iconsax.clock,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.deliveryTime} min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Favorite button
            IconButton(
              onPressed: onFavorite,
              icon: Icon(
                isFavorite ? Iconsax.heart5 : Iconsax.heart,
                color: isFavorite ? AppColors.error : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
