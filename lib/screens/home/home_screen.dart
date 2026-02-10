import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../data/mock/mock_data.dart';
import '../../navigation/app_router.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/widgets.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'all');

/// Main home screen
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = MockCategories.categories;
    final featuredRestaurants = MockRestaurants.featured;
    final selectedCategoryId = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ... (keep existing app bar and search bar) ...

            // App bar with location and cart
            // App bar with location and cart
            // App bar with location and cart
            SliverAppBar(
              pinned: true,
              floating: false,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.background,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 80.h,
              leading: IconButton(
                icon: Icon(
                  Iconsax.arrow_left_2,
                  size: 24.sp,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.go(Routes.home),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deliver to',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Iconsax.location,
                              size: 16.sp,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Home - 123 Main Street',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 18.sp,
                              color: AppColors.textPrimary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: GestureDetector(
                  onTap: () => context.push(Routes.search),
                  child: const NeumorphicSearchField(hint: 'Search in Food'),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox.shrink()),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacingMd),
            ),

            // Categories section
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingLg,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          AppStrings.categories,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        AppTextButton(
                          text: AppStrings.seeAll,
                          onPressed: () => _showAllCategories(context, ref),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  SizedBox(
                    height: 110, // Increased height for the new circular chip
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingLg,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = selectedCategoryId == category.id;
                        return Padding(
                          padding: EdgeInsets.only(
                            right:
                                index < categories.length - 1
                                    ? AppDimensions.spacingMd
                                    : 0,
                          ),
                          child: CategoryChip(
                            category: category,
                            isSelected: isSelected,
                            onTap: () {
                              final notifier = ref.read(
                                selectedCategoryProvider.notifier,
                              );
                              if (isSelected) {
                                // Toggle off: back to 'all' (no filter)
                                notifier.state = 'all';
                              } else {
                                notifier.state = category.id;
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacingXxl),
            ),

            // Popular Restaurants section
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingLg,
                    ),
                    child: const Text(
                      AppStrings.popularRestaurants,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  SizedBox(
                    height:
                        85.h, // Increased to accommodate square cards + shadows
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingLg,
                      ),
                      itemCount: featuredRestaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = featuredRestaurants[index];
                        return Center(
                          child: Container(
                            width: 70.h,
                            height: 70.h,
                            margin: EdgeInsets.only(
                              right:
                                  index < featuredRestaurants.length - 1
                                      ? AppDimensions.spacingMd
                                      : 0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusLg,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadow.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusLg,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: restaurant.imageUrl,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color: AppColors.surfaceVariant,
                                    ),
                                errorWidget:
                                    (context, url, error) =>
                                        const Icon(Icons.restaurant_rounded),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacingXxl),
            ),

            // Popular Dishes section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLg,
                ),
                child: const Text(
                  'All Restaurants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacingMd),
            ),

            // All Restaurants List
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLg,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final restaurant =
                        featuredRestaurants[index %
                            featuredRestaurants
                                .length]; // Reusing featured for demo or use all
                    final isFavorite = ref.watch(
                      isRestaurantFavoriteProvider(restaurant.id),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.spacingMd,
                      ),
                      child: RestaurantCard(
                        restaurant: restaurant,
                        isFavorite: isFavorite,
                        onFavorite: () {
                          ref
                              .read(favoritesProvider.notifier)
                              .toggleRestaurant(restaurant);
                        },
                      ),
                    );
                  },
                  childCount: featuredRestaurants.length,
                ), // Verify if we want full list or subset
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacingHuge),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllCategories(BuildContext context, WidgetRef ref) {
    final categories = MockCategories.categories;
    final selectedCategoryId = ref.read(selectedCategoryProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Grid
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppDimensions.paddingLg),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: AppDimensions.spacingSm,
                          mainAxisSpacing: AppDimensions.spacingSm,
                        ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = selectedCategoryId == category.id;
                      return Center(
                        child: CategoryChip(
                          category: category,
                          isSelected: isSelected,
                          onTap: () {
                            final notifier = ref.read(
                              selectedCategoryProvider.notifier,
                            );
                            if (isSelected) {
                              notifier.state = 'all';
                            } else {
                              notifier.state = category.id;
                            }
                            context.pop();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
