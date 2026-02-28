import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/food_item_model.dart';
import '../../../data/models/restaurant_model.dart';
import '../domain/menu_category_entity.dart';
import 'widgets/item_customization_sheet.dart';
import 'widgets/food_item_tile.dart';
import 'package:intl/intl.dart';
import '../../../data/models/review_model.dart';
import '../../../providers/review_provider.dart';
import '../../../providers/restaurant_providers.dart';
import '../../../providers/favorites_provider.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final RestaurantModel restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  String _selectedCategoryId = 'All Items';

  late ScrollController _scrollController;
  bool _showStickyAppBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final shouldShow = _scrollController.offset > 200;
      if (shouldShow != _showStickyAppBar) {
        setState(() {
          _showStickyAppBar = shouldShow;
        });
      }
    }
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  // Helper to filter items based on selection
  List<FoodItemModel> _getFilteredItems(List<FoodItemModel> allItems) {
    if (_selectedCategoryId == 'All Items') return allItems;
    return allItems.where((i) => i.category == _selectedCategoryId).toList();
  }

  Future<void> _openMap() async {
    final query = Uri.encodeComponent(widget.restaurant.address);
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$query';
    final appleMapsUrl = 'https://maps.apple.com/?q=$query';

    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(
        Uri.parse(googleMapsUrl),
        mode: LaunchMode.externalApplication,
      );
    } else if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
      await launchUrl(
        Uri.parse(appleMapsUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open map.')));
      }
    }
  }

  void _showFoodDetail(FoodItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemCustomizationSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuItemsAsync = ref.watch(
      restaurantMenuStreamProvider(widget.restaurant.id),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: Stack(
        children: [
          // Custom Scroll View for the main content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 1. Integrated Header: Image behind Info Card
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background Image Layer
                    Container(
                      height: 320.h,
                      width: double.infinity,
                      foregroundDecoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                      child: Hero(
                        tag: 'restaurant_${widget.restaurant.id}',
                        child: CachedNetworkImage(
                          imageUrl: widget.restaurant.imageUrl,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) =>
                                  Container(color: AppColors.surfaceVariant),
                          errorWidget:
                              (context, url, error) => Container(
                                color: AppColors.surfaceVariant,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                        ),
                      ),
                    ),
                    // Restaurant Info Card with Glassmorphism
                    Padding(
                      padding: EdgeInsets.only(top: 230.h),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 19.w,
                            vertical: 18.h,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(13.r),
                                    child: Container(
                                      width: 51.w,
                                      height: 51.h,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFFE5E5F0),
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          13.r,
                                        ),
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: widget.restaurant.imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 13.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.restaurant.name,
                                          style: GoogleFonts.urbanist(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18.sp,
                                            color: const Color(0xFF0A0A0F),
                                            height: 1.25,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          widget.restaurant.cuisine.isNotEmpty
                                              ? widget.restaurant.cuisine
                                              : widget.restaurant.cuisineTypes
                                                  .join(' • '),
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.sp,
                                            color: const Color(0xFF646470),
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE9FBF4),
                                      borderRadius: BorderRadius.circular(13.r),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 3.h,
                                    ),
                                    child: Text(
                                      widget.restaurant.isOpen
                                          ? 'OPEN'
                                          : 'CLOSED',
                                      style: GoogleFonts.urbanist(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9.sp,
                                        color:
                                            widget.restaurant.isOpen
                                                ? AppColors.success
                                                : AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 19.h),
                              const Divider(
                                height: 1,
                                color: Color(0xFFE5E5F0),
                              ),
                              SizedBox(height: 16.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _InfoColumn(
                                    icon: Icons.star_rounded,
                                    iconColor: const Color(0xFF0A0A0F),
                                    value: widget.restaurant.rating
                                        .toStringAsFixed(1),
                                    label:
                                        '${widget.restaurant.reviewCount > 0 ? widget.restaurant.reviewCount : 0}+ reviews',
                                  ),
                                  _VerticalDivider(),
                                  _InfoColumn(
                                    icon: Icons.schedule_rounded,
                                    iconColor: AppColors.primary,
                                    value: '${widget.restaurant.deliveryTime}',
                                    label: 'min delivery',
                                  ),
                                  _VerticalDivider(),
                                  _InfoColumn(
                                    icon: Icons.delivery_dining_rounded,
                                    iconColor: AppColors.success,
                                    value:
                                        widget.restaurant.deliveryFee == 0
                                            ? 'Free'
                                            : '\$${widget.restaurant.deliveryFee.toStringAsFixed(2)}',
                                    label: 'Delivery Fee',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              menuItemsAsync.when(
                data: (items) {
                  // Dynamically derive categories
                  final categoryNames =
                      {'All Items', ...items.map((e) => e.category)}.toList();

                  final categories =
                      categoryNames.map((name) {
                        final count =
                            name == 'All Items'
                                ? items.length
                                : items.where((i) => i.category == name).length;
                        return MenuCategoryEntity(
                          id: name,
                          name: name,
                          itemCount: count,
                        );
                      }).toList();

                  final filteredItems = _getFilteredItems(items);

                  return SliverMainAxisGroup(
                    slivers: [
                      // 3. Pinned Category Filter Chips
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyHeaderDelegate(
                          topPadding:
                              MediaQuery.of(context).padding.top +
                              kToolbarHeight +
                              20.h,
                          child: Container(
                            color: Colors.white,
                            padding: EdgeInsets.only(bottom: 8.h, top: 4.h),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Row(
                                children:
                                    categories.map((category) {
                                      return Padding(
                                        padding: EdgeInsets.only(right: 8.w),
                                        child: _CategoryChip(
                                          label: category.name,
                                          isSelected:
                                              _selectedCategoryId ==
                                              category.id,
                                          onTap:
                                              () => _onCategorySelected(
                                                category.id,
                                              ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 4. Food List Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Popular Items',
                                style: GoogleFonts.urbanist(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17.sp,
                                  color: const Color(0xFF0A0A0F),
                                ),
                              ),
                              Text(
                                'See All',
                                style: GoogleFonts.urbanist(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.sp,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 5. Food Items List
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item =
                                  filteredItems[index]; // Use filteredItems
                              return Padding(
                                padding: EdgeInsets.only(bottom: 16.h),
                                child: FoodItemTile(
                                  item: item,
                                  onTap: () => _showFoodDetail(item),
                                  onAddToCart: () => _showFoodDetail(item),
                                ),
                              );
                            },
                            childCount:
                                filteredItems
                                    .length, // Use filteredItems length
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(child: SizedBox(height: 32.h)),

                      ...ref
                          .watch(
                            restaurantReviewsProvider(widget.restaurant.id),
                          )
                          .when(
                            data: (reviews) {
                              if (reviews.isEmpty) {
                                return [
                                  const SliverToBoxAdapter(
                                    child: SizedBox.shrink(),
                                  ),
                                ];
                              }
                              return [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: 20.w,
                                      right: 20.w,
                                      top: 24.h,
                                    ),
                                    child: Text(
                                      'Reviews',
                                      style: GoogleFonts.urbanist(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0A0A0F),
                                      ),
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: EdgeInsets.only(top: 16.h),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final review = reviews[index];
                                      return _ReviewItem(review: review);
                                    }, childCount: reviews.length),
                                  ),
                                ),
                              ];
                            },
                            loading:
                                () => [
                                  const SliverToBoxAdapter(
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                ],
                            error:
                                (err, _) => [
                                  SliverToBoxAdapter(
                                    child: Text('Error: $err'),
                                  ),
                                ],
                          ),

                      SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                    ],
                  );
                },
                loading:
                    () => SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32.h),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                error:
                    (err, stack) => SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32.h),
                        child: Center(child: Text('Error loading menu: $err')),
                      ),
                    ),
              ),
            ],
          ),

          // 2. Floating Navigation Bar (Positioned over content)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height:
                  MediaQuery.of(context).padding.top + kToolbarHeight + 20.h,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20.h,
              ),
              decoration: BoxDecoration(
                color: _showStickyAppBar ? Colors.white : Colors.transparent,
                boxShadow:
                    _showStickyAppBar
                        ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : [],
              ),
              child: Row(
                children: [
                  SizedBox(width: 4.w),
                  _buildCircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.pop(context),
                    isSticky: _showStickyAppBar,
                  ),
                  const Spacer(),
                  _buildCircleIconButton(
                    icon: Icons.map_outlined,
                    onPressed: _openMap,
                    isSticky: _showStickyAppBar,
                  ),
                  SizedBox(width: 8.w),
                  Consumer(
                    builder: (context, ref, _) {
                      final isFav = ref.watch(
                        isRestaurantFavoriteProvider(widget.restaurant.id),
                      );
                      return _buildCircleIconButton(
                        icon:
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                        iconColor: AppColors.error,
                        onPressed: () {
                          ref
                              .read(favoritesProvider.notifier)
                              .toggleRestaurant(widget.restaurant);
                        },
                        isSticky: _showStickyAppBar,
                      );
                    },
                  ),
                  SizedBox(width: 16.w),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? iconColor,
    bool isSticky = false,
  }) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: isSticky ? Colors.transparent : Colors.white,
          shape: BoxShape.circle,
          boxShadow:
              isSticky
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Icon(
              icon,
              size: 20.sp,
              color: iconColor ?? const Color(0xFF0A0A0F),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Internal Widgets ---

class _InfoColumn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _InfoColumn({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 14.sp),
            SizedBox(width: 3.w),
            Text(
              value,
              style: GoogleFonts.urbanist(
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
                color: const Color(0xFF0A0A0F),
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9.sp,
            color: const Color(0xFF646470),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 26.h, color: const Color(0xFFE5E5F0));
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double topPadding;

  _StickyHeaderDelegate({required this.child, this.topPadding = 0.0});

  @override
  double get minExtent => 64.h + topPadding;

  @override
  double get maxExtent => 64.h + topPadding;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          Positioned(bottom: 0, left: 0, right: 0, height: 64.h, child: child),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return child != oldDelegate.child || topPadding != oldDelegate.topPadding;
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E5F0),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.w600,
            fontSize: 15.sp,
            color: isSelected ? Colors.white : const Color(0xFF646470),
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final ReviewModel review;

  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF1F1F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundImage:
                    review.userAvatar != null
                        ? CachedNetworkImageProvider(review.userAvatar!)
                        : null,
                child:
                    review.userAvatar == null ? const Icon(Icons.person) : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: GoogleFonts.urbanist(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(review.date),
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.primary,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      review.rating.toString(),
                      style: GoogleFonts.urbanist(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF4B4B57),
                height: 1.5,
              ),
            ),
          ],
          if (review.reply != null && review.reply!.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Restaurant Reply',
                    style: GoogleFonts.urbanist(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    review.reply!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF646470),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
