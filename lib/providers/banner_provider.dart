import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category_model.dart';
import '../data/repositories/banners_repository.dart';

final bannersRepositoryProvider = Provider<BannersRepository>((ref) {
  return BannersRepository();
});

final bannersProvider = FutureProvider<List<PromoBannerModel>>((ref) async {
  final repository = ref.watch(bannersRepositoryProvider);
  return repository.fetchBanners();
});
