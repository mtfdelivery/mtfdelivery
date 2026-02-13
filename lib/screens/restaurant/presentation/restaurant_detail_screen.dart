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
import 'widgets/food_detail_bottom_sheet.dart';
import '../../../providers/cart_provider.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final RestaurantModel restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  final List<MenuCategoryEntity> _categories = const [
    MenuCategoryEntity(id: 'All Items', name: 'All Items', itemCount: 0),
    MenuCategoryEntity(
      id: 'Signature Pizza',
      name: 'Signature Pizza',
      itemCount: 0,
    ),
    MenuCategoryEntity(id: 'Sides', name: 'Sides', itemCount: 0),
    MenuCategoryEntity(id: 'Desserts', name: 'Desserts', itemCount: 0),
  ];

  String _selectedCategoryId = 'All Items';
  bool _isFavorite = false;

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  List<FoodItemModel> get _filteredItems {
    // Mock data for demonstration, matching the context images
    var items = [
      const FoodItemModel(
        id: 'f1',
        restaurantId: 'r1',
        name: 'Truffle Mushroom Pizza',
        description:
            'Wild mushrooms, truffle oil, fresh mozzarella, and aromatic herbs',
        imageUrl:
            'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
        price: 18.50,
        category: 'Signature Pizza',
        isPopular: true,
        rating: 4.8,
        reviewCount: 156,
        preparationTime: 20,
      ),
      const FoodItemModel(
        id: 'f2',
        restaurantId: 'r1',
        name: 'Chocolate Lava Cake',
        description:
            'Warm chocolate cake with a molten center, served with vanilla bean cr..',
        imageUrl:
            'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400',
        price: 7.99,
        category: 'Desserts',
        isPopular: true,
        rating: 4.7,
        reviewCount: 45,
        preparationTime: 10,
      ),
      const FoodItemModel(
        id: 'f3',
        restaurantId: 'r1',
        name: 'Artisan Garlic Bread',
        description:
            'House-made dough with roasted garlic butter and fresh parsley',
        imageUrl:
            'https://images.unsplash.com/photo-1573140247632-f8fd74997d5c?w=400',
        price: 6.50,
        category: 'Sides',
        isPopular: true,
        rating: 4.5,
        reviewCount: 82,
        preparationTime: 12,
      ),
      const FoodItemModel(
        id: 'f4',
        restaurantId: 'r1',
        name: 'Iced Berry Hibiscus',
        description:
            'Refreshing cold brewed hibiscus tea with fresh forest berries',
        imageUrl:
            'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=400',
        price: 4.20,
        category: 'All Items', // Simplified for demo
        isPopular: true,
        rating: 4.9,
        reviewCount: 23,
        preparationTime: 5,
      ),
    ];

    if (_selectedCategoryId == 'All Items') return items;
    return items.where((i) => i.category == _selectedCategoryId).toList();
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
      builder: (context) => FoodDetailBottomSheet(item: item),
    );
  }

  void _addToCart(FoodItemModel item) {
    ref.read(cartProvider.notifier).addItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            ref.read(cartProvider.notifier).removeItem(item.id);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Image + Action Bar + Floating Info Card (Stack)
            Stack(
              children: [
                // Hero image
                Container(
                  width: double.infinity,
                  height: 280.h,
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

                // Top action bar (back, map, favorite)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16.w,
                      MediaQuery.of(context).padding.top + 8.h,
                      16.w,
                      0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCircleIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onPressed: () => Navigator.pop(context),
                        ),
                        Row(
                          children: [
                            _buildCircleIconButton(
                              icon: Icons.map_outlined,
                              onPressed: _openMap,
                            ),
                            SizedBox(width: 8.w),
                            _buildCircleIconButton(
                              icon:
                                  _isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                              iconColor: AppColors.error,
                              onPressed:
                                  () => setState(
                                    () => _isFavorite = !_isFavorite,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Floating info card (overlaps the image)
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 200.h, 24.w, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 8,
                          color: Color(0x1A000000),
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFE5E5F0),
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16.r),
                              child: Container(
                                width: 64.w,
                                height: 64.h,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFE5E5F0),
                                  ),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: widget.restaurant.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.restaurant.name,
                                    style: GoogleFonts.urbanist(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 22.sp,
                                      color: const Color(0xFF0A0A0F),
                                      height: 1.25,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    widget.restaurant.cuisineTypes.join(' • '),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.sp,
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
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 4.h,
                              ),
                              child: Text(
                                'OPEN',
                                style: GoogleFonts.urbanist(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.sp,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        const Divider(height: 1, color: Color(0xFFE5E5F0)),
                        SizedBox(height: 20.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _InfoColumn(
                              icon: Icons.star_rounded,
                              iconColor: const Color(0xFF0A0A0F),
                              value: '4.8',
                              label: '2k+ reviews',
                            ),
                            _VerticalDivider(),
                            _InfoColumn(
                              icon: Icons.schedule_rounded,
                              iconColor: AppColors.primary,
                              value: '25-35',
                              label: 'min delivery',
                            ),
                            _VerticalDivider(),
                            _InfoColumn(
                              icon: Icons.delivery_dining_rounded,
                              iconColor: AppColors.success,
                              value: 'Free',
                              label: 'On \$20+',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 2. Category Filter
            SizedBox(height: 24.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children:
                    _categories.map((category) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: _CategoryChip(
                          label: category.name,
                          isSelected: _selectedCategoryId == category.id,
                          onTap: () => _onCategorySelected(category.id),
                        ),
                      );
                    }).toList(),
              ),
            ),

            // 3. Food List Header
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 16.h),
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

            // 4. Food Items List
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children:
                    _filteredItems.map((item) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: _FoodItemCard(
                          item: item,
                          onTap: () => _showFoodDetail(item),
                          onAdd: () => _addToCart(item),
                        ),
                      );
                    }).toList(),
              ),
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? iconColor,
  }) {
    return Center(
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
            Icon(icon, color: iconColor, size: 18.sp),
            SizedBox(width: 4.w),
            Text(
              value,
              style: GoogleFonts.urbanist(
                fontWeight: FontWeight.w700,
                fontSize: 17.sp,
                color: const Color(0xFF0A0A0F),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.sp,
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
    return Container(width: 1, height: 32.h, color: const Color(0xFFE5E5F0));
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

class _FoodItemCard extends StatelessWidget {
  final FoodItemModel item;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _FoodItemCard({
    required this.item,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: const [
              BoxShadow(
                blurRadius: 2,
                color: Color(0x1A000000),
                offset: Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(color: const Color(0xFFE5E5F0), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.urbanist(
                          fontWeight: FontWeight.bold,
                          fontSize: 17.sp,
                          color: const Color(0xFF0A0A0F),
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.normal,
                          fontSize: 12.sp,
                          color: const Color(0xFF646470),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: GoogleFonts.urbanist(
                          fontWeight: FontWeight.bold,
                          fontSize: 17.sp,
                          color: AppColors.success,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: SizedBox(
                    width: 100.w,
                    height: 100.h,
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          width: 100.w,
                          height: 100.h,
                          fit: BoxFit.cover,
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.w),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: GestureDetector(
                              onTap: onAdd,
                              child: Container(
                                width: 32.w,
                                height: 32.h,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 4,
                                      color: Color(0x1A000000),
                                      offset: Offset(0, 2),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
