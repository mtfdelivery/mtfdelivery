import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../restaurant/presentation/restaurant_controller.dart';
import '../restaurant/domain/restaurant_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/providers.dart';
import 'domain/home_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Provider to fetch home services
final homeServicesProvider = FutureProvider<List<HomeService>>((ref) async {
  try {
    final client = ref.read(supabaseClientProvider);
    final data = await client
        .from('home_services')
        .select()
        .order('order_index', ascending: true);

    if (data.isEmpty) {
      return _getDefaultServices();
    }

    return (data as List).map((e) => HomeService.fromJson(e)).toList();
  } catch (e) {
    debugPrint('Failed to fetch home services: $e');
    return _getDefaultServices();
  }
});

List<HomeService> _getDefaultServices() {
  return [
    const HomeService(
      id: 'coursier',
      label: 'Coursier',
      localAssetPath: 'assets/services/courier.png',
      iconUrl:
          'https://cdn-icons-png.flaticon.com/512/2830/2830305.png', // Premium 3D icon
      route: '/courier',
      isLarge: true,
    ),
    const HomeService(
      id: 'restaurants',
      label: 'Restaurants',
      localAssetPath: 'assets/services/restaurant.png',
      iconUrl:
          'https://cdn-icons-png.flaticon.com/512/7541/7541675.png', // Premium 3D icon
      route: '/home/restaurants',
      isLarge: true,
    ),
    const HomeService(
      id: 'courses',
      label: 'Courses',
      localAssetPath: 'assets/services/grocery.png',
      iconUrl: 'https://cdn-icons-png.flaticon.com/512/3081/3081840.png',
      isAvailable: false,
    ),
    const HomeService(
      id: 'boutiques',
      label: 'Boutiques',
      localAssetPath: 'assets/services/boutique.png',
      iconUrl: 'https://cdn-icons-png.flaticon.com/512/3081/3081559.png',
      isAvailable: false,
    ),
    const HomeService(
      id: 'pharmacies',
      label: 'Pharmacies',
      localAssetPath: 'assets/services/pharmacy.png',
      iconUrl: 'https://cdn-icons-png.flaticon.com/512/3081/3081510.png',
      isAvailable: false,
    ),
  ];
}

class PrimaryHomeScreen extends ConsumerStatefulWidget {
  const PrimaryHomeScreen({super.key});

  @override
  ConsumerState<PrimaryHomeScreen> createState() => _PrimaryHomeScreenState();
}

class _PrimaryHomeScreenState extends ConsumerState<PrimaryHomeScreen> {
  Color get primaryColor => AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(selectedLocationProvider);
    final popularAsync = ref.watch(popularRestaurantsProvider);
    final servicesAsync = ref.watch(homeServicesProvider);

    // Using a CustomScrollView for better sliver control
    return Scaffold(
      backgroundColor: const Color(
        0xFFF8F9FE,
      ), // very light grey/blue tint background
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(homeServicesProvider.future),
            ref.refresh(popularRestaurantsProvider.future),
          ]);
          await Future.delayed(const Duration(milliseconds: 800));
        },
        color: primaryColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Premium Header
            // 1. Premium Header (Green)
            _buildSliverAppBar(context, location),

            // 3. Services Grid (Wrapped in Green Container bottom rounded)
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16.w,
                    right: 16.w,
                    bottom: 24.h,
                  ),
                  child: servicesAsync.when(
                    data: (services) {
                      return MasonryGridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        itemCount: services.length,
                        mainAxisSpacing: 12.h,
                        crossAxisSpacing: 12.w,
                        itemBuilder: (context, index) {
                          final service = services[index];
                          return _buildPremiumServiceCard(
                                context,
                                service,
                                index,
                              )
                              .animate(delay: (100 * index).ms)
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.1, end: 0);
                        },
                      );
                    },
                    loading:
                        () => SizedBox(
                          height: 200.h,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // 5. Popular Restaurants
            SliverToBoxAdapter(
              child:
                  _buildCeciEstPourVous(
                    context,
                    popularAsync,
                  ).animate(delay: 500.ms).fadeIn(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String location) {
    return SliverAppBar(
      pinned: true,
      floating: true, // snaps: true
      snap: true,
      expandedHeight: 60.h,
      backgroundColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: GestureDetector(
          onTap: () => context.push('/location-intro'),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: Colors.white, // White icon on green
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    location.isEmpty ? 'Définir l\'adresse' : location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white, // White text
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumServiceCard(
    BuildContext context,
    HomeService service,
    int index,
  ) {
    // Dynamic height for staggered effect if desired, or fixed content driven
    // For specific staggered look:
    // If we want the first two (Coursier, Restaurants) to be prominent
    // We can make them larger.

    return GestureDetector(
      onTap:
          service.isAvailable
              ? () {
                if (service.route != null) {
                  context.push(service.route!);
                }
              }
              : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            if (service.isAvailable)
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.05),
                blurRadius: 0,
                offset: const Offset(0, 0),
                spreadRadius: 0,
              ),
          ],
        ),
        child: Stack(
          children: [
            // Background decoration (optional subtle circle)
            Positioned(
              right: -15,
              top: -15,
              child: CircleAvatar(
                radius: 30,
                backgroundColor:
                    service.isAvailable
                        ? primaryColor.withValues(alpha: 0.03)
                        : Colors.grey.withValues(alpha: 0.05),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon/Image
                  Container(
                    height: 40.h,
                    width: 40.h,
                    decoration: BoxDecoration(
                      color:
                          service.isAvailable
                              ? const Color(0xFFF8F9FE)
                              : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    padding: EdgeInsets.all(8.r),
                    child: Opacity(
                      opacity: service.isAvailable ? 1.0 : 0.5,
                      child: CachedNetworkImage(
                        imageUrl: service.iconUrl ?? '',
                        fit: BoxFit.contain,
                        placeholder:
                            (context, url) => const SizedBox(), // clean loading
                        errorWidget:
                            (context, url, error) =>
                                Icon(Icons.apps_rounded, color: primaryColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          service.label,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color:
                                service.isAvailable
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF94A3B8),
                            letterSpacing: -0.5,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      if (!service.isAvailable)
                        Icon(
                          Icons.lock_rounded,
                          size: 14.sp,
                          color: const Color(0xFFCBD5E1),
                        ),
                      if (service.isAvailable)
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16.sp,
                          color: primaryColor,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCeciEstPourVous(
    BuildContext context,
    AsyncValue<List<RestaurantEntity>> popularAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Restaurants Populaires',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.5,
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.grey[400],
                size: 18.sp,
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        popularAsync.when(
          data: (restaurants) {
            if (restaurants.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 225.h, // Increased from 210.h to resolve overflow
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: restaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = restaurants[index];
                  return Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: _buildPopularRestaurantCard(restaurant),
                  );
                },
              ),
            );
          },
          loading:
              () => SizedBox(
                height: 180.h,
                child: Center(
                  child: CircularProgressIndicator(color: primaryColor),
                ),
              ),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  // New vertical card for popular restaurants
  Widget _buildPopularRestaurantCard(RestaurantEntity restaurant) {
    return Container(
      width: 120.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
              child: CachedNetworkImage(
                imageUrl: restaurant.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(color: Colors.grey[100]),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 12.sp,
                        color: const Color(0xFFFFB000),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        restaurant.rating.toString(),
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        ' (100+)', // Mock
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '15-25 min • Gratuit',
                    style: TextStyle(
                      fontSize: 8.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
