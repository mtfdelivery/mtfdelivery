import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/promo_code_model.dart';
import '../data/repositories/promo_code_repository.dart';

/// Provider for PromoCodeRepository
final promoCodeRepositoryProvider = Provider<PromoCodeRepository>((ref) {
  return PromoCodeRepository();
});

/// AsyncNotifier provider for the list of active promo codes
final promoCodesProvider =
    AsyncNotifierProvider<PromoCodesNotifier, List<PromoCodeModel>>(() {
      return PromoCodesNotifier();
    });

class PromoCodesNotifier extends AsyncNotifier<List<PromoCodeModel>> {
  @override
  Future<List<PromoCodeModel>> build() async {
    return _fetchPromoCodes();
  }

  Future<List<PromoCodeModel>> _fetchPromoCodes() async {
    final repository = ref.read(promoCodeRepositoryProvider);
    return repository.fetchActivePromoCodes();
  }

  /// Manually refresh the list of promo codes
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPromoCodes());
  }
}
