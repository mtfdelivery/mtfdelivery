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
        backgroundColor: const Color(0xFF00D18E),
        body: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder:
              (context, _) => [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  snap: true,
                  toolbarHeight: 50.h,
                  backgroundColor: const Color(0xFF00D18E),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primary,
                            size: 18.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            location.isEmpty ? 'Set location' : location,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: const Color(0xFF1A1A2E),
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
                    // ── Category Icons Grid ──
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: servicesAsync.when(
                        data: (services) {
                          final topRow = services.take(2).toList();
                          final bottomRow = services.skip(2).toList();
                          return Column(
                            children: [
                              // Top row — closer together
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildCategoryItem(
                                        topRow[0],
                                        cardBg,
                                        textColor,
                                      )
                                      .animate(delay: 0.ms)
                                      .fadeIn(duration: 500.ms)
                                      .slideY(begin: 0.1, end: 0),
                                  SizedBox(width: 20.w),
                                  _buildCategoryItem(
                                        topRow[1],
                                        cardBg,
                                        textColor,
                                      )
                                      .animate(delay: 100.ms)
                                      .fadeIn(duration: 500.ms)
                                      .slideY(begin: 0.1, end: 0),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              // Bottom row — spaced evenly
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children:
                                    bottomRow
                                        .asMap()
                                        .entries
                                        .map(
                                          (entry) => _buildCategoryItem(
                                                entry.value,
                                                cardBg,
                                                textColor,
                                              )
                                              .animate(
                                                delay:
                                                    (100 * (entry.key + 2)).ms,
                                              )
                                              .fadeIn(duration: 500.ms)
                                              .slideY(begin: 0.1, end: 0),
                                        )
                                        .toList(),
                              ),
                            ],
                          );
                        },
                        loading:
                            () => SizedBox(
                              height: 200.h,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // ── White Content Section ──
                    Stack(
                      children: [
                        // Semi-transparent rounded corner transition
                        Opacity(
                          opacity: 0.4,
                          child: Container(
                            width: double.infinity,
                            height: 100.h,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(25.r),
                              ),
                            ),
                          ),
                        ),
                        // Main white content area
                        Padding(
                          padding: EdgeInsets.only(top: 10.h),
                          child: Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              minHeight:
                                  MediaQuery.of(context).size.height * 0.5,
                            ),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(40.r),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(top: 24.h),
                              child: _buildCeciEstPourVous(
                                context,
                                popularAsync,
                                textColor,
                                cardBg,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Builds a single category item with Stack layout (bg blob + icon + label)
  Widget _buildCategoryItem(
    HomeService service,
    Color cardBg,
    Color textColor,
  ) {
    return GestureDetector(
      onTap:
          service.isAvailable && service.route != null
              ? () => context.push(service.route!)
              : null,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background blob container with service icon
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: const AssetImage('assets/services/service_bg.png'),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(22.w),
                child: Image.asset(
                  service.localAssetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported_rounded,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 28.sp,
                    );
                  },
                ),
              ),
            ),
          ),
          // Label pill overlapping at bottom
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: const Color(0xFF059669), width: 1),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
            child: Text(
              service.label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 12.sp,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Restaurants Populaires',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
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
              height: 225.h,
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
        context.isDesktop ? 200.w : (context.isTablet ? 150.w : 120.w);
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
