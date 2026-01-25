import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Rating display widget with star
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final bool showCount;
  final double size;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount,
    this.showCount = true,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Iconsax.star1, size: size, color: AppColors.starFilled),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (showCount && reviewCount != null) ...[
          Text(
            ' ($reviewCount)',
            style: TextStyle(
              fontSize: size - 2,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Star rating bar (for reviews)
class StarRating extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color filledColor;
  final Color emptyColor;
  final ValueChanged<double>? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 24,
    this.filledColor = AppColors.starFilled,
    this.emptyColor = AppColors.starEmpty,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        final isFilled = index < rating.floor();
        final isHalf = index == rating.floor() && (rating % 1) >= 0.5;

        return GestureDetector(
          onTap:
              onRatingChanged != null
                  ? () => onRatingChanged!((index + 1).toDouble())
                  : null,
          child: Icon(
            isFilled
                ? Iconsax.star1
                : isHalf
                ? Iconsax.star_1
                : Iconsax.star,
            size: size,
            color: isFilled || isHalf ? filledColor : emptyColor,
          ),
        );
      }),
    );
  }
}

/// Price tag widget
class PriceTag extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final bool large;

  const PriceTag({
    super.key,
    required this.price,
    this.originalPrice,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: large ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        if (originalPrice != null && originalPrice! > price) ...[
          const SizedBox(width: 8),
          Text(
            '\$${originalPrice!.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: large ? 14 : 12,
              color: AppColors.textTertiary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }
}

/// Discount badge
class DiscountBadge extends StatelessWidget {
  final double percentage;

  const DiscountBadge({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '-${percentage.toStringAsFixed(0)}%',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textOnPrimary,
        ),
      ),
    );
  }
}

/// Quantity selector widget
class QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final int minValue;
  final int maxValue;

  const QuantitySelector({
    super.key,
    required this.quantity,
    this.onIncrement,
    this.onDecrement,
    this.minValue = 1,
    this.maxValue = 99,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement button
          IconButton(
            onPressed: quantity > minValue ? onDecrement : null,
            icon: Icon(
              Iconsax.minus,
              size: AppDimensions.iconSm,
              color:
                  quantity > minValue
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
            ),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          // Quantity display
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Increment button
          IconButton(
            onPressed: quantity < maxValue ? onIncrement : null,
            icon: Icon(
              Iconsax.add,
              size: AppDimensions.iconSm,
              color:
                  quantity < maxValue
                      ? AppColors.primary
                      : AppColors.textTertiary,
            ),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

/// Delivery time badge
class DeliveryTimeBadge extends StatelessWidget {
  final int minutes;

  const DeliveryTimeBadge({super.key, required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.paddingXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Iconsax.clock,
            size: AppDimensions.iconSm,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$minutes min',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge (for orders)
class StatusBadge extends StatelessWidget {
  final String status;
  final Color? color;

  const StatusBadge({super.key, required this.status, this.color});

  Color get _backgroundColor {
    if (color != null) return color!;
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'preparing':
      case 'out for delivery':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.paddingXs,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _backgroundColor,
        ),
      ),
    );
  }
}
