import 'package:flutter/foundation.dart';
import '../../core/services/supabase_service.dart';
import '../models/promo_code_model.dart';

/// Repository for Supabase-backed promo code operations (public.promo_codes)
class PromoCodeRepository {
  /// Fetch all active promo codes.
  Future<List<PromoCodeModel>> fetchActivePromoCodes() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();

      final response = await SupabaseService.client
          .from('promo_codes')
          .select()
          .eq('is_active', true)
          .or('valid_until.is.null,valid_until.gte.$now')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => PromoCodeModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[PromoCodeRepository] Error fetching promo codes: $e');
      return [];
    }
  }
}
