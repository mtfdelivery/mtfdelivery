import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';

class ReviewsRepository {
  final _client = Supabase.instance.client;

  Future<List<ReviewModel>> fetchReviewsByRestaurant(
    String restaurantId,
  ) async {
    final response = await _client
        .from('reviews')
        .select('*, profiles!reviews_user_id_fkey(full_name, avatar_url)')
        .eq('target_type', 'restaurant')
        .eq('target_id', restaurantId)
        .eq('is_visible', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ReviewModel.fromJson(json))
        .toList();
  }

  Future<List<ReviewModel>> fetchReviewsByFoodItem(String foodItemId) async {
    final response = await _client
        .from('reviews')
        .select('*, profiles!reviews_user_id_fkey(full_name, avatar_url)')
        .eq('target_type', 'menu_item')
        .eq('target_id', foodItemId)
        .eq('is_visible', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ReviewModel.fromJson(json))
        .toList();
  }
}
