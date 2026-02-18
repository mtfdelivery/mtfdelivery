import '../../core/services/supabase_service.dart';
import '../../data/models/category_model.dart';

class CategoryRepository {
  /// Fetch all active categories, ordered by sort_order
  Future<List<CategoryModel>> fetchCategories() async {
    final response = await SupabaseService.client
        .schema('food')
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    // Filter out nulls if any, and map to model
    return (response as List).map((e) => CategoryModel.fromJson(e)).toList();
  }
}
