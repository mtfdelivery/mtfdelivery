import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/restaurant_model.dart';
import '../../data/models/food_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/widgets.dart';

/// Restaurant detail screen with menu
class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final String restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends ConsumerState<RestaurantDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late RestaurantModel restaurant;
  late ScrollController _scrollController;
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController()..addListener(_onScroll);
    restaurant =
        MockRestaurants.getById(widget.restaurantId) ??
        MockRestaurants.restaurants.first;
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showTitle) {
      setState(() => _showTitle = true);
    } else if (_scrollController.offset <= 200 && _showTitle) {
      setState(() => _showTitle = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foodItems = MockFoodItems.getByRestaurant(widget.restaurantId);
    final categories = MockFoodItems.getCategoriesForRestaurant(
      widget.restaurantId,
    );
    // Reviews will be used in Reviews tab (future implementation)
    // final reviews = MockReviews.getByRestaurant(widget.restaurantId);
    final isFavorite = ref.watch(isRestaurantFavoriteProvider(restaurant.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App bar with hero image
          SliverAppBar(
            expandedHeight: context.screenHeight * 0.35,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.shadow, blurRadius: 4),
                  ],
                ),
                child: const Icon(Iconsax.arrow_left, size: 20),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.shadow, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(Iconsax.search_normal, size: 20),
                ),
              ),
              IconButton(
                onPressed: () {
                  ref
                      .read(favoritesProvider.notifier)
                      .toggleRestaurant(restaurant);
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.shadow, blurRadius: 4),
                    ],
                  ),
                  child: Icon(
                    isFavorite ? Iconsax.heart5 : Iconsax.heart,
                    size: 20,
                    color: isFavorite ? AppColors.error : null,
                  ),
                ),
              ),
            ],
            title: AnimatedOpacity(
              opacity: _showTitle ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                restaurant.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: restaurant.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Restaurant info card
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLg,
                ),
                padding: const EdgeInsets.all(AppDimensions.paddingLg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (restaurant.isOpen)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Open',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      restaurant.cuisine,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        RatingDisplay(
                          rating: restaurant.rating,
                          reviewCount: restaurant.reviewCount,
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Iconsax.clock,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${restaurant.deliveryTime} min',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Iconsax.truck,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.deliveryFee == 0
                              ? 'Free'
                              : '\$${restaurant.deliveryFee.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                restaurant.deliveryFee == 0
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                            fontWeight:
                                restaurant.deliveryFee == 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Menu'),
                  Tab(text: 'Reviews'),
                  Tab(text: 'Info'),
                ],
              ),
            ),
          ),

          // Tab content - Menu items
          SliverPadding(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index >= categories.length) return null;
                final category = categories[index];
                final categoryItems =
                    foodItems.where((f) => f.category == category).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index > 0)
                      const SizedBox(height: AppDimensions.spacingXxl),
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    ...categoryItems.map((item) {
                      final quantity =
                          ref
                              .watch(cartProvider)
                              .firstWhere(
                                (c) => c.foodItem.id == item.id,
                                orElse:
                                    () => CartItemModel(
                                      foodItem: item,
                                      quantity: 0,
                                    ),
                              )
                              .quantity;
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppDimensions.spacingMd,
                        ),
                        child: FoodListItem(
                          item: item,
                          quantity: quantity,
                          onAddToCart: () {
                            ref.read(cartProvider.notifier).addItem(item);
                          },
                          onIncrement: () {
                            ref
                                .read(cartProvider.notifier)
                                .incrementQuantity(item.id);
                          },
                          onDecrement: () {
                            ref
                                .read(cartProvider.notifier)
                                .decrementQuantity(item.id);
                          },
                        ),
                      );
                    }),
                  ],
                );
              }, childCount: categories.length),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.surface, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
