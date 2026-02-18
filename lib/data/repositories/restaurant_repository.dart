import '../../core/services/supabase_service.dart';
import '../../screens/restaurant/domain/customization_entity.dart';
import '../models/restaurant_model.dart';
import '../models/food_item_model.dart';

class RestaurantRepository {
  /// Fetch all active restaurants from Supabase
  Future<List<RestaurantModel>> fetchRestaurants() async {
    // We select typical columns.
    // Note: We might want to join with cuisines if we need names, but for now
    // we'll use the raw data and handle cuisine display in the UI or a separate lookup.
    final response = await SupabaseService.client
        .schema('food')
        .from('restaurants')
        .select()
        .eq('is_active', true)
        .order('is_featured', ascending: false) // Featured first
        .order('rating', ascending: false); // Then by rating

    return (response as List).map((e) => RestaurantModel.fromJson(e)).toList();
  }

  /// Fetch only featured restaurants
  Future<List<RestaurantModel>> fetchFeaturedRestaurants() async {
    final response = await SupabaseService.client
        .schema('food')
        .from('restaurants')
        .select()
        .eq('is_active', true)
        .eq('is_featured', true)
        .limit(10);

    return (response as List).map((e) => RestaurantModel.fromJson(e)).toList();
  }

  /// Fetch menu items for a specific restaurant
  Future<List<FoodItemModel>> fetchMenuItems(String restaurantId) async {
    final response = await SupabaseService.client
        .schema('food')
        .from('menu_items')
        .select('*, menu_sections(name)')
        .eq('restaurant_id', restaurantId)
        .eq('is_available', true)
        .order('sort_order', ascending: true);

    return (response as List).map((e) => FoodItemModel.fromJson(e)).toList();
  }

  /// Watch menu items in real-time (for price updates, sold out status)
  Stream<List<FoodItemModel>> watchMenuItems(String restaurantId) async* {
    // 1. Fetch sections lookup map first (since sections rarely change)
    // We treat this as a one-time fetch per stream subscription
    final sectionsResponse = await SupabaseService.client
        .schema('food')
        .from('menu_sections')
        .select('id, name')
        .eq('restaurant_id', restaurantId);

    final sectionsMap = {
      for (var s in sectionsResponse) s['id'] as String: s['name'] as String,
    };

    // 2. Listen to real-time changes
    final stream = SupabaseService.client
        .schema('food')
        .from('menu_items')
        .stream(primaryKey: ['id'])
        .eq('restaurant_id', restaurantId)
        .order('sort_order', ascending: true);

    await for (final data in stream) {
      yield data.map((json) {
        // Manually inject section name for fromJson
        final sectionId = json['section_id'] as String?;
        if (sectionId != null) {
          json['menu_sections'] = {'name': sectionsMap[sectionId]};
        }
        return FoodItemModel.fromJson(json);
      }).toList();
    }
  }

  /// Fetch customization groups and their addons for a menu item
  Future<List<CustomizationGroup>> fetchAddonGroups(String menuItemId) async {
    final response = await SupabaseService.client
        .schema('food')
        .from('addon_groups')
        .select('*, addons(*)')
        .eq('menu_item_id', menuItemId)
        .order('sort_order', ascending: true);

    return (response as List)
        .map((e) => CustomizationGroup.fromJson(e))
        .toList();
  }
}
