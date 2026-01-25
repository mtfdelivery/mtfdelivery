/// Review model for restaurant and food reviews
class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? restaurantId;
  final String? foodItemId;
  final double rating;
  final String comment;
  final DateTime date;
  final List<String> images;
  final int helpfulCount;
  final String? reply; // Restaurant owner reply

  const ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.restaurantId,
    this.foodItemId,
    required this.rating,
    required this.comment,
    required this.date,
    this.images = const [],
    this.helpfulCount = 0,
    this.reply,
  });

  ReviewModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? restaurantId,
    String? foodItemId,
    double? rating,
    String? comment,
    DateTime? date,
    List<String>? images,
    int? helpfulCount,
    String? reply,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      restaurantId: restaurantId ?? this.restaurantId,
      foodItemId: foodItemId ?? this.foodItemId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      date: date ?? this.date,
      images: images ?? this.images,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      reply: reply ?? this.reply,
    );
  }
}
