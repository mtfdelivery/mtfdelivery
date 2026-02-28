import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';

class ReviewsRepository {
  final _client = Supabase.instance.client;

  Future<List<ReviewModel>> fetchReviewsByRestaurant(
    String restaurantId,
  ) async {
    final response = await _client
        .from('reviews')
        .select('*, profiles(full_name, avatar_url)')
        .eq('restaurant_id', restaurantId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ReviewModel.fromJson(json))
        .toList();
  }

  Future<List<ReviewModel>> fetchReviewsByFoodItem(String foodItemId) async {
    final response = await _client
        .from('reviews')
        .select('*, profiles(full_name, avatar_url)')
        .eq('menu_item_id', foodItemId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ReviewModel.fromJson(json))
        .toList();
  }
}
