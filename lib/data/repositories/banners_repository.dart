import '../../core/services/supabase_service.dart';
import '../models/category_model.dart';

class BannersRepository {
  final _client = SupabaseService.client;

  Future<List<PromoBannerModel>> fetchBanners() async {
    final response = await _client
        .from('banners')
        .select()
        .eq('is_active', true)
        .order('id');

    return (response as List)
        .map((json) => PromoBannerModel.fromJson(json))
        .toList();
  }
}
