import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/restaurant_model.dart';
import '../../providers/favorites_provider.dart';
import '../../core/responsive_utils.dart';
import '../../widgets/common/custom_network_image.dart';
import '../../widgets/widgets.dart';
import '../../navigation/app_router.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteRestaurantsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color,
            size: 20.sp,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My Favorites',
          style: TextStyle(
            color:
                Theme.of(context).appBarTheme.titleTextStyle?.color ??
                Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: scaledFont(16),
          ),
        ),
      ),
      body:
          favorites.isEmpty
              ? EmptyFavoritesState(
                onBrowse: () => context.go(Routes.restaurantHome),
              )
              : ListView.builder(
                padding: EdgeInsets.all(16.r),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final restaurant = favorites[index];
                  return _buildFavoriteCard(context, ref, restaurant);
                },
              ),
    );
  }

  Widget _buildFavoriteCard(
    BuildContext context,
    WidgetRef ref,
    RestaurantModel restaurant,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey[200]!,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: InkWell(
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              CustomNetworkImage(
                imageUrl: restaurant.imageUrl,
                width: 70.w,
                height: 70.w,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(10.r),
                errorWidget: Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 22.sp,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: TextStyle(
                        fontSize: scaledFont(14),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      restaurant.cuisine,
                      style: TextStyle(
                        fontSize: scaledFont(12),
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16.sp),
                        SizedBox(width: 4.w),
                        Text(
                          restaurant.rating.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: scaledFont(12),
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Icon(
                          Icons.access_time,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                          size: 16.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${restaurant.deliveryTime} min',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: scaledFont(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.error,
                  size: 22.sp,
                ),
                onPressed: () {
                  ref
                      .read(favoritesProvider.notifier)
                      .toggleRestaurant(restaurant);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
