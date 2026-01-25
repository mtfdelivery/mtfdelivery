import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/category_model.dart';
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
    final banners = MockPromoBanners.banners;
    final featuredRestaurants = MockRestaurants.featured;
    final selectedCategoryId = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ... (keep existing app bar and search bar) ...

            // App bar with location and cart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingLg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deliver to',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Iconsax.location,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Home - 123 Main Street',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                                color: AppColors.textPrimary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Iconsax.notification, size: 24),
                    ),
                  ],
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLg,
                ),
                child: GestureDetector(
                  onTap: () => context.push(Routes.search),
                  child: const SearchField(
                    hint: AppStrings.searchHint,
                    showFilter: true,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacingXxl),
            ),

            // Promo banner carousel
            SliverToBoxAdapter(
              child: CarouselSlider.builder(
                itemCount: banners.length,
                itemBuilder: (context, index, realIndex) {
                  final banner = banners[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.bannerRadius,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.bannerRadius,
                      ),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: banner.imageUrl,
                            width: double.infinity,
                            height: AppDimensions.bannerHeight,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.black.withValues(alpha: 0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(
                              AppDimensions.paddingXl,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  banner.title,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.surface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  banner.subtitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.surface.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                ),
                                if (banner.promoCode != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Code: ${banner.promoCode}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                options: CarouselOptions(
                  height: AppDimensions.bannerHeight,
                  viewportFraction: 0.9,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 4),
                  enlargeCenterPage: true,
                  enlargeFactor: 0.2,
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacingXxl),
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
                          onPressed: () {},
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
                      itemCount: categories.length + 1, // +1 for "All"
                      itemBuilder: (context, index) {
                        // "All" Category
                        if (index == 0) {
                          final isSelected = selectedCategoryId == 'all';
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: AppDimensions.spacingMd,
                            ),
                            child: CategoryChip(
                              category: const CategoryModel(
                                id: 'all',
                                name: 'All',
                                iconUrl:
                                    'https://cdn-icons-png.flaticon.com/512/3480/3480708.png', // Plate icon
                                color: '#10B981',
                                itemCount: 0, // Placeholder
                              ),
                              isSelected: isSelected,
                              onTap: () {
                                ref
                                    .read(selectedCategoryProvider.notifier)
                                    .state = 'all';
                              },
                            ),
                          );
                        }

                        // Other Categories
                        final category = categories[index - 1];
                        final isSelected = selectedCategoryId == category.id;
                        return Padding(
                          padding: EdgeInsets.only(
                            right:
                                index < categories.length
                                    ? AppDimensions.spacingMd
                                    : 0,
                          ),
                          child: CategoryChip(
                            category: category,
                            isSelected: isSelected,
                            onTap: () {
                              ref
                                  .read(selectedCategoryProvider.notifier)
                                  .state = category.id;
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          AppStrings.popularRestaurants,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        AppTextButton(
                          text: AppStrings.seeAll,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  SizedBox(
                    height: AppDimensions.restaurantCardHeight,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingLg,
                      ),
                      itemCount: featuredRestaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = featuredRestaurants[index];
                        final isFavorite = ref.watch(
                          isRestaurantFavoriteProvider(restaurant.id),
                        );
                        return Padding(
                          padding: EdgeInsets.only(
                            right:
                                index < featuredRestaurants.length - 1
                                    ? AppDimensions.spacingLg
                                    : 0,
                          ),
                          child: RestaurantCard(
                            restaurant: restaurant,
                            isFavorite: isFavorite,
                            onTap:
                                () => context.push(
                                  Routes.restaurantDetail(restaurant.id),
                                ),
                            onFavorite: () {
                              ref
                                  .read(favoritesProvider.notifier)
                                  .toggleRestaurant(restaurant);
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

            // Popular Dishes section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All Restaurants',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppTextButton(text: AppStrings.seeAll, onPressed: () {}),
                  ],
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
                        onTap:
                            () => context.push(
                              Routes.restaurantDetail(restaurant.id),
                            ),
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
}
