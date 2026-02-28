import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/responsive.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/restaurant_model.dart';
import '../../providers/restaurant_providers.dart';
import '../../widgets/widgets.dart';
import '../../providers/favorites_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<String> _recentSearches = [];
  static const String _recentSearchesKey = 'recent_searches';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
    });
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

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
    _saveRecentSearches();
  }

  void _removeFromRecent(String term) {
    setState(() {
      _recentSearches.remove(term);
    });
    _saveRecentSearches();
  }

  void _clearAllRecent() {
    setState(() {
      _recentSearches.clear();
    });
    _saveRecentSearches();
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
    final restaurantsAsync = ref.watch(restaurantsProvider);

    return restaurantsAsync.when(
      loading:
          () => Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) => Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(child: Text('Error loading restaurants: $e')),
          ),
      data: (allRestaurants) => _buildBody(context, allRestaurants),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<RestaurantModel> allRestaurants,
  ) {
    // Advanced filtering logic
    final searchResults =
        allRestaurants.where((r) {
          // 1. Text Search
          final q = _query.toLowerCase();
          final matchesText =
              _query.isEmpty ||
              r.name.toLowerCase().contains(q) ||
              r.cuisine.toLowerCase().contains(q);

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
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 2. Filter Chips
                  SliverToBoxAdapter(child: _buildFilterChips()),

                  // If searching or filtering, show results
                  if (_query.isNotEmpty || _selectedFilters.isNotEmpty) ...[
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    if (searchResults.isEmpty)
                      SliverPadding(
                        padding: EdgeInsets.only(top: 40.h),
                        sliver: const SliverToBoxAdapter(
                          child: EmptyState(
                            icon: Icons.search_off,
                            title: 'No results found',
                            message: 'Try adjusting your search or filters',
                          ),
                        ),
                      )
                    else ...[
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'Found ${searchResults.length} results',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),
                      if (context.isMobile)
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final restaurant = searchResults[index];
                              final isFavorite = ref.watch(
                                isRestaurantFavoriteProvider(restaurant.id),
                              );
                              return Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: RestaurantCard(
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
                                ),
                              );
                            }, childCount: searchResults.length),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: context.isDesktop ? 3 : 2,
                                  mainAxisSpacing: 20.h,
                                  crossAxisSpacing: 20.w,
                                  childAspectRatio: 0.8,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
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
                            }, childCount: searchResults.length),
                          ),
                        ),
                    ],
                  ] else ...[
                    // Default View (Recent, Trending, Recommended)
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // 3. Recent Searches
                    if (_recentSearches.isNotEmpty) ...[
                      SliverToBoxAdapter(child: _buildRecentSection()),
                      const SliverToBoxAdapter(child: SizedBox(height: 30)),
                    ],

                    // 4. Trending Nearby
                    ref
                        .watch(categoriesProvider)
                        .when(
                          data: (categories) {
                            final trendingNames =
                                categories.take(6).map((c) => c.name).toList();
                            return _buildTrendingNearby(trendingNames);
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                    const SliverToBoxAdapter(child: SizedBox(height: 30)),

                    // 5. Recommended List
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Recommended for you',
                          style: TextStyle(
                            fontSize: 19.sp, // +20%
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),
                    _buildRecommendedSliver(),
                  ],
                  // Bottom Padding
                  SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
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
        height: 50.h, // +20%
        iconSize: 22.sp, // +20%
        textSize: 16.sp, // +20%
        hintTextSize: 16.sp, // +20%
        borderRadius: 120.r, // +20%
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
                      horizontal: 14.w, // +20%
                      vertical: 8.h, // +20%
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primary
                              : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(17.r), // +20%
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
                        fontSize: 14.sp, // +20%
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
                  fontSize: 19.sp, // +20%
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
                    fontSize: 14.sp, // +20%
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
                    size: 22.sp, // +20%
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
                          fontSize: 17.sp, // +20%
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
                      size: 22.sp, // +20%
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
              fontSize: 19.sp, // +20%
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 14.h), // +20%
          Wrap(
            spacing: 10.w, // +20%
            runSpacing: 10.h, // +20%
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
                        horizontal: 14.w, // +20%
                        vertical: 10.h, // +20%
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24.r), // +20%
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
                              fontSize: 14.sp, // +20%
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

  Widget _buildRecommendedSliver() {
    final allRestaurants = ref.watch(restaurantsProvider).valueOrNull ?? [];
    final recommended = allRestaurants.take(3).toList();

    if (context.isMobile) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final restaurant = recommended[index];
            final isFavorite = ref.watch(
              isRestaurantFavoriteProvider(restaurant.id),
            );
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: RestaurantCard(
                restaurant: restaurant,
                isFavorite: isFavorite,
                width: double.infinity,
                onTap: () => context.push('/restaurant/${restaurant.id}'),
                onFavorite:
                    () => ref
                        .read(favoritesProvider.notifier)
                        .toggleRestaurant(restaurant),
              ),
            );
          }, childCount: recommended.length),
        ),
      );
    } else {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: context.isDesktop ? 3 : 2,
            mainAxisSpacing: 20.h, // +20%
            crossAxisSpacing: 20.w, // +20%
            childAspectRatio: 0.8,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final restaurant = recommended[index];
            final isFavorite = ref.watch(
              isRestaurantFavoriteProvider(restaurant.id),
            );
            return RestaurantCard(
              restaurant: restaurant,
              isFavorite: isFavorite,
              width: double.infinity,
              onTap: () => context.push('/restaurant/${restaurant.id}'),
              onFavorite:
                  () => ref
                      .read(favoritesProvider.notifier)
                      .toggleRestaurant(restaurant),
            );
          }, childCount: recommended.length),
        ),
      );
    }
  }
}
