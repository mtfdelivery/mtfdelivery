import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../providers/cart_provider.dart';
import '../../providers/navigation_provider.dart';
import '../home/home_screen.dart';
import '../search/search_screen.dart';
import '../cart/cart_screen.dart';
import '../order_history/order_history_screen.dart';
import '../profile/profile_screen.dart';

/// Main navigation with bottom navigation bar
class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);

    final screens = [
      const HomeScreen(),
      const SearchScreen(),
      const CartScreen(),
      const OrderHistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: AppDimensions.bottomNavHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  ref: ref,
                  icon: Iconsax.home,
                  activeIcon: Iconsax.home_15,
                  label: 'Home',
                  index: 0,
                  currentIndex: currentIndex,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  icon: Iconsax.search_normal,
                  activeIcon: Iconsax.search_normal_1,
                  label: 'Search',
                  index: 1,
                  currentIndex: currentIndex,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  icon: Iconsax.shopping_cart,
                  activeIcon: Iconsax.shopping_cart,
                  label: 'Cart',
                  index: 2,
                  currentIndex: currentIndex,
                  badge: cartItemCount,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  icon: Iconsax.receipt_2,
                  activeIcon: Iconsax.receipt_21,
                  label: 'Orders',
                  index: 3,
                  currentIndex: currentIndex,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  icon: Iconsax.user,
                  activeIcon: Iconsax.user,
                  label: 'Profile',
                  index: 4,
                  currentIndex: currentIndex,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
    int badge = 0,
  }) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => ref.read(navigationProvider.notifier).setIndex(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: AppDimensions.bottomNavIconSize,
                  color:
                      isSelected ? AppColors.primary : AppColors.textTertiary,
                ),
                if (badge > 0)
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badge > 99 ? '99+' : badge.toString(),
                        style: const TextStyle(
                          color: AppColors.textOnPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
