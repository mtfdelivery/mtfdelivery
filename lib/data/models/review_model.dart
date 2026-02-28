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

  /// Create from Supabase JSON (public.reviews with joined profiles)
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final targetType = json['target_type'] as String?;
    final targetId = json['target_id'] as String?;
    return ReviewModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: profile?['full_name'] as String? ?? 'Anonymous',
      userAvatar: profile?['avatar_url'] as String?,
      restaurantId: targetType == 'restaurant' ? targetId : null,
      foodItemId: targetType == 'menu_item' ? targetId : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      date:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      helpfulCount: (json['helpful_count'] as num?)?.toInt() ?? 0,
      reply: json['reply'] as String?,
    );
  }

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
