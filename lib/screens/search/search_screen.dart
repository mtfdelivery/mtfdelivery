import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/responsive.dart';
import '../../core/constants/app_colors.dart';
import '../../data/mock/mock_data.dart';
import '../../widgets/widgets.dart';
import '../../providers/favorites_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';

  // State for filters and history
  final Set<String> _selectedFilters = {};
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
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
    });
  }

  void _addToRecent(String term) {
    if (term.isEmpty) return;
    setState(() {
      _recentSearches.remove(term); // Remove if exists to move to top
      _recentSearches.insert(0, term);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    });
  }

  void _removeFromRecent(String term) {
    setState(() {
      _recentSearches.remove(term);
    });
  }

  void _clearAllRecent() {
    setState(() {
      _recentSearches.clear();
    });
  }

  void _onSearch(String value) {
    setState(() {
      _query = value;
    });
    if (value.isNotEmpty) {
      _addToRecent(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Advanced filtering logic
    final allRestaurants = MockRestaurants.restaurants;
    final searchResults =
        allRestaurants.where((r) {
          // 1. Text Search
          final q = _query.toLowerCase();
          final matchesText =
              _query.isEmpty ||
              r.name.toLowerCase().contains(q) ||
              r.cuisine.toLowerCase().contains(q) ||
              r.cuisineTypes.any((t) => t.toLowerCase().contains(q));

          if (!matchesText) return false;

          // 2. Filter Chips
          if (_selectedFilters.isEmpty) return true;

          bool matchesFilters = true;
          if (_selectedFilters.contains('Top Rated') && r.rating < 4.5) {
            matchesFilters = false;
          }
          if (_selectedFilters.contains('Fast Food') &&
              !r.cuisine.contains('Fast Food') &&
              !r.cuisine.contains('Burger') &&
              !r.cuisine.contains('Pizza')) {
            matchesFilters = false;
          }
          if (_selectedFilters.contains('Healthy') &&
              !r.cuisine.contains('Healthy') &&
              !r.cuisine.contains('Salad')) {
            matchesFilters = false;
          }
          // Assuming 'Discount' means free delivery or some other metric, using delivery fee for now
          if (_selectedFilters.contains('Discount') && r.deliveryFee > 0) {
            matchesFilters = false;
          }

          return matchesFilters;
        }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar
            _buildSearchBar(),

            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 100.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Filter Chips
                    _buildFilterChips(),

                    // If searching or filtering, show results
                    if (_query.isNotEmpty || _selectedFilters.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      if (searchResults.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 40.h),
                          child: const EmptyState(
                            icon: Icons.search_off,
                            title: 'No results found',
                            message: 'Try adjusting your search or filters',
                          ),
                        )
                      else ...[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Text(
                            'Found ${searchResults.length} results',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        if (context.isMobile)
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            itemCount: searchResults.length,
                            separatorBuilder:
                                (context, index) => SizedBox(height: 12.h),
                            itemBuilder: (context, index) {
                              final restaurant = searchResults[index];
                              final isFavorite = ref.watch(
                                isRestaurantFavoriteProvider(restaurant.id),
                              );
                              return RestaurantCard(
                                restaurant: restaurant,
                                isFavorite: isFavorite,
                                width: double.infinity,
                                onTap:
                                    () => context.push(
                                      '/restaurant/${restaurant.id}',
                                    ),
                                onFavorite:
                                    () => ref
                                        .read(favoritesProvider.notifier)
                                        .toggleRestaurant(restaurant),
                              );
                            },
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            itemCount: searchResults.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: context.isDesktop ? 3 : 2,
                                  mainAxisSpacing: 16.h,
                                  crossAxisSpacing: 16.w,
                                  childAspectRatio: 0.8,
                                ),
                            itemBuilder: (context, index) {
                              final restaurant = searchResults[index];
                              final isFavorite = ref.watch(
                                isRestaurantFavoriteProvider(restaurant.id),
                              );
                              return RestaurantCard(
                                restaurant: restaurant,
                                isFavorite: isFavorite,
                                width: double.infinity,
                                onTap:
                                    () => context.push(
                                      '/restaurant/${restaurant.id}',
                                    ),
                                onFavorite:
                                    () => ref
                                        .read(favoritesProvider.notifier)
                                        .toggleRestaurant(restaurant),
                              );
                            },
                          ),
                      ],
                    ] else ...[
                      // Default View (Recent, Trending, Recommended)
                      SizedBox(height: 16.h),

                      // 3. Recent Searches
                      if (_recentSearches.isNotEmpty) ...[
                        _buildRecentSection(),
                        SizedBox(height: 24.h),
                      ],

                      // 4. Trending Nearby
                      _buildTrendingNearby(_trendingItems),

                      SizedBox(height: 24.h),

                      // 5. Recommended List
                      _buildRecommendedSection(),
                    ],
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: SearchField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus:
            false, // Changed to false to prevent keyboard popup annoyance on nav
        hint: 'Search for restaurant, food...',
        showFilter: false,
        onChanged: (val) {
          // Simple debounce could go here, but for mock data direct set is fine
          setState(() {
            _query = val;
          });
        },
        onSubmitted: _onSearch,
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Top Rated', 'Discount', 'Fast Food', 'Healthy'];
    // Check if we have active filters to show clear button or highlight
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children:
            filters.map((filter) {
              final isSelected = _selectedFilters.contains(filter);
              return Padding(
                padding: EdgeInsetsDirectional.only(end: 8.w),
                child: GestureDetector(
                  onTap: () => _toggleFilter(filter),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primary
                              : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.primary
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : const Color(0xFFE9ECEF)),
                        width: 1.w,
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color:
                            isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
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
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: _clearAllRecent,
                child: Text(
                  'Clear all',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ..._recentSearches.map(
            (search) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  Icon(
                    Iconsax.clock,
                    color: Theme.of(context).disabledColor,
                    size: 18.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _searchController.text = search;
                        _onSearch(search);
                      },
                      child: Text(
                        search,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _removeFromRecent(search),
                    child: Icon(
                      Iconsax.close_circle,
                      size: 18.sp,
                      color: Theme.of(context).disabledColor,
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

  Widget _buildTrendingNearby(List<String> trendingItems) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trending nearby',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children:
                trendingItems.map((item) {
                  return GestureDetector(
                    onTap: () {
                      // Strip emoji for search
                      final term =
                          item.replaceAll(RegExp(r'[^\w\s]'), '').trim();
                      _searchController.text = term;
                      _onSearch(term);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          if (context.isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recommended.length,
              separatorBuilder: (context, index) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final restaurant = recommended[index];
                final isFavorite = ref.watch(
                  isRestaurantFavoriteProvider(restaurant.id),
                );
                return RestaurantCard(
                  restaurant: restaurant,
                  isFavorite: isFavorite,
                  width: double.infinity, // Full width
                  onTap: () => context.push('/restaurant/${restaurant.id}'),
                  onFavorite:
                      () => ref
                          .read(favoritesProvider.notifier)
                          .toggleRestaurant(restaurant),
                );
              },
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recommended.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: context.isDesktop ? 3 : 2,
                mainAxisSpacing: 16.h,
                crossAxisSpacing: 16.w,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                return RestaurantCard(
                  restaurant: recommended[index],
                  width: double.infinity,
                );
              },
            ),
        ],
      ),
    );
  }
}
