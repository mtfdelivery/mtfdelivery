import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../restaurant/presentation/restaurant_controller.dart';
import '../restaurant/domain/restaurant_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/providers.dart';
import '../../navigation/app_router.dart';
import 'domain/home_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/responsive.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/ai_chat_bottom_sheet.dart';

// Provider to fetch home services
final homeServicesProvider = FutureProvider<List<HomeService>>((ref) async {
  try {
    return _getDefaultServices();
  } catch (e) {
    debugPrint('Failed to load services: $e');
    return _getDefaultServices();
  }
});

List<HomeService> _getDefaultServices() {
  return [
    const HomeService(
      id: 'restaurants',
      label: 'Restaurants',
      localAssetPath: 'assets/services/restaurant.png',
      route: '/home/restaurants',
      isLarge: true,
    ),
    const HomeService(
      id: 'taxi',
      label: 'Taxi',
      localAssetPath: 'assets/services/taxi.png',
      route: '/taxi',
      isLarge: true,
      hasPromo: true,
    ),
    const HomeService(
      id: 'shops',
      label: 'Shops',
      localAssetPath: 'assets/services/boutique.png',
      isAvailable: false,
    ),
    const HomeService(
      id: 'parapharmacy',
      label: 'Parapharmacy',
      localAssetPath: 'assets/services/pharmacy.png',
      isAvailable: false,
    ),
    const HomeService(
      id: 'delivery',
      label: 'Delivery',
      localAssetPath: 'assets/services/courier.png',
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
  @override
  Widget build(BuildContext context) {
    final location = ref.watch(selectedLocationProvider);
    final popularAsync = ref.watch(popularRestaurantsProvider);
    final servicesAsync = ref.watch(homeServicesProvider);
    final isAiAssistantEnabled = ref.watch(aiAssistantEnabledProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton:
            isAiAssistantEnabled
                ? Container(
                  margin: EdgeInsets.only(bottom: 90.h),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useRootNavigator: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AiChatBottomSheet(),
                      );
                    },
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                )
                : null,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: NestedScrollView(
            floatHeaderSlivers: true,
            headerSliverBuilder:
                (context, _) => [
                  SliverAppBar(
                    pinned: true,
                    floating: true,
                    snap: true,
                    toolbarHeight: 70.h,
                    backgroundColor: Colors.white,
                    automaticallyImplyLeading: false,
                    elevation: 0,
                    centerTitle: true,
                    title: GestureDetector(
                      onTap: () async {
                        final result = await context.push<String>(
                          Routes.setLocation,
                        );
                        if (result != null && mounted) {
                          ref.read(selectedLocationProvider.notifier).state =
                              result;
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              location.isEmpty ? 'Set location' : location,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
            body: Builder(
              builder: (context) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // ── Services Card Grid ──
                      SizedBox(height: 50.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: servicesAsync.when(
                          data: (services) {
                            final topRow =
                                services.where((s) => s.isLarge).toList();
                            final bottomRow =
                                services.where((s) => !s.isLarge).toList();
                            return Column(
                              children: [
                                // Top row — 2 large cards
                                Row(
                                  children:
                                      topRow
                                          .asMap()
                                          .entries
                                          .map(
                                            (entry) => Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  right:
                                                      entry.key == 0 ? 6.w : 0,
                                                  left:
                                                      entry.key == 1 ? 6.w : 0,
                                                ),
                                                child: _buildLargeServiceCard(
                                                      entry.value,
                                                      textColor,
                                                    )
                                                    .animate(
                                                      delay:
                                                          (100 * entry.key).ms,
                                                    )
                                                    .fadeIn(duration: 400.ms)
                                                    .slideY(
                                                      begin: 0.08,
                                                      end: 0,
                                                    ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                                SizedBox(height: 12.h),
                                // Bottom row — small cards + 'More'
                                Row(
                                  children: [
                                    ...bottomRow.asMap().entries.map(
                                      (entry) => Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 4.w,
                                          ),
                                          child: _buildSmallServiceCard(
                                                entry.value,
                                                textColor,
                                              )
                                              .animate(
                                                delay:
                                                    (100 * (entry.key + 2)).ms,
                                              )
                                              .fadeIn(duration: 400.ms)
                                              .slideY(begin: 0.08, end: 0),
                                        ),
                                      ),
                                    ),
                                    // "More" button
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4.w,
                                        ),
                                        child: _buildMoreCard(textColor)
                                            .animate(delay: 500.ms)
                                            .fadeIn(duration: 400.ms)
                                            .slideY(begin: 0.08, end: 0),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                          loading:
                              () => SizedBox(
                                height: 200.h,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),

                      SizedBox(height: 50.h),

                      // ── Popular Restaurants ──
                      _buildCeciEstPourVous(
                        context,
                        popularAsync,
                        textColor,
                        cardBg,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a large service card (top row) — rounded rectangle with icon top-right,
  /// label bottom-left, optional Promo badge
  Widget _buildLargeServiceCard(HomeService service, Color textColor) {
    return GestureDetector(
      onTap:
          service.isAvailable && service.route != null
              ? () => context.push(service.route!)
              : null,
      child: Container(
        height: 110.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Stack(
          children: [
            // Service icon — top right
            Positioned(
              top: 12.h,
              right: 12.w,
              child: Image.asset(
                service.localAssetPath,
                width: 50.w,
                height: 50.w,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_not_supported_rounded,
                    color: Colors.grey.withValues(alpha: 0.5),
                    size: 28.sp,
                  );
                },
              ),
            ),
            // Label — bottom left
            Positioned(
              bottom: 14.h,
              left: 14.w,
              child: Text(
                service.label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                  color: textColor,
                ),
              ),
            ),
            // Promo badge — top right corner
            if (service.hasPromo)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16.r),
                      bottomLeft: Radius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Promo',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a small service card (bottom row) — compact rounded rectangle
  Widget _buildSmallServiceCard(HomeService service, Color textColor) {
    return GestureDetector(
      onTap:
          service.isAvailable && service.route != null
              ? () => context.push(service.route!)
              : null,
      child: Container(
        height: 85.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              service.localAssetPath,
              width: 36.w,
              height: 36.w,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.image_not_supported_rounded,
                  color: Colors.grey.withValues(alpha: 0.5),
                  size: 22.sp,
                );
              },
            ),
            SizedBox(height: 6.h),
            Text(
              service.label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 11.sp,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the "More" card for the bottom row
  Widget _buildMoreCard(Color textColor) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to full services list
      },
      child: Container(
        height: 85.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.more_horiz_rounded, size: 30.sp, color: textColor),
            SizedBox(height: 6.h),
            Text(
              'More',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 11.sp,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Popular restaurants section
  Widget _buildCeciEstPourVous(
    BuildContext context,
    AsyncValue<List<RestaurantEntity>> popularAsync,
    Color textColor,
    Color cardBg,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Restaurants Populaires',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        popularAsync.when(
          data: (restaurants) {
            if (restaurants.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 270.h, // +20% for larger cards
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: restaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = restaurants[index];
                  return Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: _buildPopularRestaurantCard(
                      restaurant,
                      textColor,
                      cardBg,
                    ),
                  );
                },
              ),
            );
          },
          loading:
              () => SizedBox(
                height: 180.h,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
          error: (err, stack) => const SizedBox.shrink(),
        ),
        SizedBox(height: 100.h),
      ],
    );
  }

  /// Popular restaurant card
  Widget _buildPopularRestaurantCard(
    RestaurantEntity restaurant,
    Color textColor,
    Color cardBg,
  ) {
    final cardWidth =
        context.isDesktop ? 240.w : (context.isTablet ? 180.w : 150.w);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        debugPrint('Navigating to restaurant: ${restaurant.id}');
        context.push('/restaurant/${restaurant.id}');
      },
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: CachedNetworkImage(
                  imageUrl: restaurant.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(color: Colors.grey[100]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
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
                          color: textColor,
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
                              color: textColor,
                            ),
                          ),
                          Text(
                            ' (100+)',
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
        ),
      ),
    );
  }
}
