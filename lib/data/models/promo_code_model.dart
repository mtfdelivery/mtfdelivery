/// Model for promotional codes (public.promo_codes)
class PromoCodeModel {
  final String id;
  final String code;
  final String? description;
  final String discountType; // percentage | fixed | free_delivery
  final double discountValue;
  final double? maxDiscount;
  final double? minOrderAmount;
  final DateTime? validUntil;
  final bool isActive;

  const PromoCodeModel({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    this.minOrderAmount,
    this.validUntil,
    this.isActive = true,
  });

  factory PromoCodeModel.fromJson(Map<String, dynamic> json) {
    return PromoCodeModel(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      discountType: json['discount_type'] as String,
      discountValue: (json['discount_value'] as num).toDouble(),
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble(),
      validUntil:
          json['valid_until'] != null
              ? DateTime.parse(json['valid_until'] as String)
              : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'max_discount': maxDiscount,
      'min_order_amount': minOrderAmount,
      'valid_until': validUntil?.toIso8601String(),
      'is_active': isActive,
    };
  }
}
