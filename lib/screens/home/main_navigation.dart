import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../providers/cart_provider.dart';
import '../../navigation/app_router.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/responsive.dart';

/// Main navigation with bottom navigation bar
class MainNavigation extends ConsumerWidget {
  final Widget child;
  const MainNavigation({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;

    int currentIndex = 0;
    if (location.startsWith('/search')) {
      currentIndex = 1;
    } else if (location.startsWith('/cart')) {
      currentIndex = 2;
    } else if (location.startsWith('/profile')) {
      currentIndex = 3;
    }

    final cartItemCount = ref.watch(cartItemCountProvider);

    // Main content
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: Row(
        children: [
          if (!context.isMobile)
            NavigationRail(
              backgroundColor: AppColors.surface,
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/home/restaurants');
                  case 1:
                    context.go(Routes.search);
                  case 2:
                    context.go(Routes.cart);
                  case 3:
                    context.go(Routes.profile);
                }
              },
              labelType: NavigationRailLabelType.all,
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
              indicatorColor: AppColors.primary.withValues(alpha: 0.1),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Iconsax.home_2),
                  selectedIcon: Icon(Iconsax.home_25),
                  label: Text('Home'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Iconsax.search_normal_1),
                  selectedIcon: Icon(Iconsax.search_normal_1),
                  label: Text('Search'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    label: Text(cartItemCount.toString()),
                    isLabelVisible: cartItemCount > 0,
                    child: const Icon(Iconsax.shopping_cart),
                  ),
                  label: const Text('Cart'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Iconsax.user),
                  label: Text('Profile'),
                ),
              ],
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar:
          context.isMobile
              ? Container(
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
                          icon: Iconsax.home_2,
                          activeIcon: Iconsax.home_25,
                          label: 'Home',
                          index: 0,
                          currentIndex: currentIndex,
                          location: location,
                        ),
                        _buildNavItem(
                          context: context,
                          ref: ref,
                          icon: Iconsax.search_normal_1,
                          activeIcon: Iconsax.search_normal_1,
                          label: 'Search',
                          index: 1,
                          currentIndex: currentIndex,
                          location: location,
                        ),
                        _buildNavItem(
                          context: context,
                          ref: ref,
                          icon: Iconsax.shopping_cart,
                          activeIcon: Iconsax.shopping_cart,
                          label: 'Cart',
                          index: 2,
                          currentIndex: currentIndex,
                          location: location,
                          badge: cartItemCount,
                        ),
                        _buildNavItem(
                          context: context,
                          ref: ref,
                          icon: Iconsax.user,
                          activeIcon: Iconsax.user,
                          label: 'Profile',
                          index: 3,
                          currentIndex: currentIndex,
                          location: location,
                        ),
                      ],
                    ),
                  ),
                ),
              )
              : null,
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
    required String location,
    int badge = 0,
  }) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            if (location == '/home/restaurants') {
              context.go(Routes.home);
            } else {
              context.go('/home/restaurants');
            }
          case 1:
            context.go(Routes.search);
          case 2:
            context.go(Routes.cart);
          case 3:
            context.go(Routes.profile);
        }
      },
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
            const SizedBox(height: 2),
            if (isSelected)
              Container(
                width: 14,
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              const SizedBox(height: 2),
            const SizedBox(height: 2),
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
