import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/review_model.dart';
import '../data/repositories/reviews_repository.dart';

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository();
});

final restaurantReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, restaurantId) async {
      final repository = ref.watch(reviewsRepositoryProvider);
      return repository.fetchReviewsByRestaurant(restaurantId);
    });

final foodItemReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, foodItemId) async {
      final repository = ref.watch(reviewsRepositoryProvider);
      return repository.fetchReviewsByFoodItem(foodItemId);
    });
