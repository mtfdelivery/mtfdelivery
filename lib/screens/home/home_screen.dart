import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/utils/responsive.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../data/mock/mock_data.dart';
import '../../navigation/app_router.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/misc_providers.dart';
import '../../widgets/widgets.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'all');

/// Main home screen
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = MockCategories.categories;
    final featuredRestaurants = MockRestaurants.featured;
    final selectedCategoryId = ref.watch(selectedCategoryProvider);
    final selectedLocation = ref.watch(selectedLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _isLoading = true;
            });
            await _simulateLoading();
            ref.invalidate(selectedCategoryProvider);
          },
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Keep existing app bar and search bar
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
                              fontSize: 11.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final result = await context.push<String>(
                                Routes.setLocation,
                              );
                              if (result != null && mounted) {
                                ref
                                    .read(selectedLocationProvider.notifier)
                                    .state = result;
                              }
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.location,
                                  size: 18.sp,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    selectedLocation.isEmpty
                                        ? 'Set Location'
                                        : selectedLocation,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 20.sp,
                                  color: AppColors.textPrimary,
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

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: SearchField(
                    hint: 'Search for restaurant, food...',
                    onTap: () => context.push(Routes.search),
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
                          if (!_isLoading)
                            AppTextButton(
                              text: AppStrings.seeAll,
                              onPressed: () => _showAllCategories(context, ref),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    SizedBox(
                      height: 110,
                      child:
                          _isLoading
                              ? ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.paddingLg,
                                ),
                                itemCount: 6,
                                separatorBuilder:
                                    (context, index) => SizedBox(
                                      width: AppDimensions.spacingMd,
                                    ),
                                itemBuilder:
                                    (context, index) => Container(
                                      width: 75,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusMd,
                                        ),
                                      ),
                                    ),
                              )
                              : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.paddingLg,
                                ),
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  final isSelected =
                                      selectedCategoryId == category.id;
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
                      height: 125.h,
                      child:
                          _isLoading
                              ? ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.paddingLg,
                                ),
                                itemCount: 4,
                                separatorBuilder:
                                    (context, index) => SizedBox(
                                      width: AppDimensions.spacingMd,
                                    ),
                                itemBuilder:
                                    (context, index) => Container(
                                      width: 105,
                                      height: 105,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusLg,
                                        ),
                                      ),
                                    ),
                              )
                              : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.paddingLg,
                                ),
                                itemCount: featuredRestaurants.length,
                                itemBuilder: (context, index) {
                                  final restaurant = featuredRestaurants[index];
                                  return Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        context.push(
                                          '/restaurant/${restaurant.id}',
                                        );
                                      },
                                      child: Container(
                                        width: 105.h,
                                        height: 105.h,
                                        margin: EdgeInsets.only(
                                          right:
                                              index <
                                                      featuredRestaurants
                                                              .length -
                                                          1
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
                                              color: AppColors.shadow
                                                  .withValues(alpha: 0.1),
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
                                                  color:
                                                      AppColors.surfaceVariant,
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(
                                                      Icons.restaurant_rounded,
                                                    ),
                                          ),
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

              // All Restaurants List Header
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
              if (_isLoading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppDimensions.spacingMd,
                        ),
                        child: Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                        ),
                      ),
                      childCount: 3,
                    ),
                  ),
                )
              else
                context.isMobile
                    ? SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingLg,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final restaurant =
                              featuredRestaurants[index %
                                  featuredRestaurants.length];
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
                              onTap: () {
                                context.push('/restaurant/${restaurant.id}');
                              },
                              onFavorite: () {
                                ref
                                    .read(favoritesProvider.notifier)
                                    .toggleRestaurant(restaurant);
                              },
                            ),
                          );
                        }, childCount: featuredRestaurants.length),
                      ),
                    )
                    : SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingLg,
                      ),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: context.isDesktop ? 3 : 2,
                          mainAxisSpacing: 16.h,
                          crossAxisSpacing: 16.w,
                          childAspectRatio: 0.7,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final restaurant =
                              featuredRestaurants[index %
                                  featuredRestaurants.length];
                          final isFavorite = ref.watch(
                            isRestaurantFavoriteProvider(restaurant.id),
                          );
                          return RestaurantCard(
                            restaurant: restaurant,
                            isFavorite: isFavorite,
                            onTap: () {
                              context.push('/restaurant/${restaurant.id}');
                            },
                            onFavorite: () {
                              ref
                                  .read(favoritesProvider.notifier)
                                  .toggleRestaurant(restaurant);
                            },
                          );
                        }, childCount: featuredRestaurants.length),
                      ),
                    ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.spacingHuge),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllCategories(BuildContext context, WidgetRef ref) {
    // ... keep existing _showAllCategories logic ...
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
                          childAspectRatio: 0.7,
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
