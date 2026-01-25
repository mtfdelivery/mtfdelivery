import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/restaurant_model.dart';
import '../../navigation/app_router.dart';
import '../../widgets/widgets.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';
  final List<String> _recentSearches = [
    "McDonald's",
    "Starbucks Coffee",
    "Sushi Zen",
  ];
  final List<String> _trendingItems = [
    "🔥 Burger",
    "🍕 Pizza",
    "🍣 Sushi",
    "🥗 Salad",
  ];

  @override
  Widget build(BuildContext context) {
    // Basic search filtering logic using our MockData
    final allRestaurants = MockRestaurants.restaurants;
    final searchResults =
        _query.isEmpty
            ? <RestaurantModel>[]
            : allRestaurants.where((r) {
              final q = _query.toLowerCase();
              return r.name.toLowerCase().contains(q) ||
                  r.cuisine.toLowerCase().contains(q);
            }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Restore standard app bar behavior if needed, or keep full custom
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar
            _buildSearchBar(),

            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Filter Chips
                    _buildFilterChips(),

                    if (_query.isEmpty) ...[
                      SizedBox(height: 24.h),
                      // 3. Recent Searches
                      _buildRecentSection(),

                      SizedBox(height: 24.h),
                      // 4. Trending Nearby
                      _buildTrendingNearby(_trendingItems),

                      SizedBox(height: 24.h),
                      // 5. Recommended List
                      _buildRecommendedSection(),
                    ] else ...[
                      // Search Results
                      SizedBox(height: 16.h),
                      if (searchResults.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 40.h),
                          child: const EmptyState(
                            icon: Icons.search_off,
                            title: 'No results found',
                            message: 'Try searching for something else',
                          ),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Results for "$_query"',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: searchResults.length,
                                separatorBuilder:
                                    (context, index) => SizedBox(height: 12.h),
                                itemBuilder: (context, index) {
                                  return RestaurantListCard(
                                    restaurant: searchResults[index],
                                    onTap:
                                        () => context.push(
                                          Routes.restaurantDetail(
                                            searchResults[index].id,
                                          ),
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return ListenableBuilder(
      listenable: _searchFocusNode,
      builder: (context, _) {
        final isFocused = _searchFocusNode.hasFocus;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Container(
            height: 48.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color:
                  isFocused
                      ? (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF5F5F5))
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color:
                    isFocused
                        ? Colors.transparent
                        : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFE0E0E0)),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Icon(
                    Icons.arrow_back,
                    size: 20.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 12.w),
                // Icon(
                //   Icons.search_rounded,
                //   color: const Color(0xFF10B981),
                //   size: 20.sp,
                // ),
                // SizedBox(width: 12.w),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (val) => setState(() => _query = val),
                    decoration: InputDecoration(
                      hintText: 'Search for restaurant, food...',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 13.sp,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20.sp),
                    onPressed:
                        () => setState(() {
                          _query = '';
                          _searchController.clear();
                        }),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Top Rated', 'Discount', 'Fast Food', 'Healthy'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          // "Filters" Button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                Icon(Icons.tune, color: Colors.white, size: 14.sp),
                SizedBox(width: 6.w),
                Text(
                  'Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          // Filter List
          ...filters.map((filter) {
            return Padding(
              padding: EdgeInsetsDirectional.only(end: 10.w),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFE9ECEF),
                    width: 1.w,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'Clear all',
                style: TextStyle(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ..._recentSearches.map(
            (search) => Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _query = search;
                    _searchController.text = search;
                  });
                },
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        color: Theme.of(context).primaryColor,
                        size: 16.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        search,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.north_west_rounded,
                      size: 16.sp,
                      color: Theme.of(context).disabledColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingNearby(List<String> trendingItems) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trending nearby',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children:
                trendingItems.map((item) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20.r), // Rounded Pill
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).shadowColor.withValues(alpha: 0.02),
                          blurRadius: 8.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection() {
    // Basic recommendation logic: pick first 3 restaurants
    final recommended = MockRestaurants.restaurants.take(3).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended for you',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recommended.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              return RestaurantListCard(
                restaurant: recommended[index],
                onTap:
                    () => context.push(
                      Routes.restaurantDetail(recommended[index].id),
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}
