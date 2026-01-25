import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../buttons/app_buttons.dart';

/// Empty state widget with illustration and message
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: AppDimensions.spacingXxl),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            // Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppDimensions.spacingXxl),
              SizedBox(
                width: double.infinity,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 200,
                      maxWidth: 300,
                    ),
                    child: PrimaryButton(
                      text: buttonText!,
                      onPressed: onButtonPressed,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty cart state
class EmptyCartState extends StatelessWidget {
  final VoidCallback? onBrowse;

  const EmptyCartState({super.key, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Iconsax.shopping_cart,
      title: 'Your cart is empty',
      message: 'Add some delicious items to get started',
      buttonText: 'Browse Restaurants',
      onButtonPressed: onBrowse,
    );
  }
}

/// Empty orders state
class EmptyOrdersState extends StatelessWidget {
  final VoidCallback? onBrowse;

  const EmptyOrdersState({super.key, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Iconsax.receipt_2,
      title: 'No orders yet',
      message: 'Start ordering to see your history here',
      buttonText: 'Browse Restaurants',
      onButtonPressed: onBrowse,
    );
  }
}

/// Empty favorites state
class EmptyFavoritesState extends StatelessWidget {
  final VoidCallback? onBrowse;

  const EmptyFavoritesState({super.key, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Iconsax.heart,
      title: 'No favorites yet',
      message: 'Save your favorite restaurants and dishes here',
      buttonText: 'Browse Restaurants',
      onButtonPressed: onBrowse,
    );
  }
}

/// Empty search results state
class EmptySearchState extends StatelessWidget {
  final String? query;
  final VoidCallback? onClear;

  const EmptySearchState({super.key, this.query, this.onClear});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Iconsax.search_normal_1,
      title: 'No results found',
      message:
          query != null
              ? 'No results for "$query". Try a different search.'
              : 'Try searching for restaurants or dishes',
      buttonText: query != null ? 'Clear Search' : null,
      onButtonPressed: onClear,
    );
  }
}

/// Error state widget
class ErrorState extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, this.title, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.warning_2,
                size: 56,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXxl),
            Text(
              title ?? 'Something went wrong',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              message ?? 'Please try again',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spacingXxl),
              SizedBox(
                width: 160,
                child: SecondaryButton(
                  text: 'Try Again',
                  icon: Iconsax.refresh,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
