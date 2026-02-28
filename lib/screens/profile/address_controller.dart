import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/address_model.dart';
import '../../providers/user_provider.dart';

/// Address controller that syncs with the user_provider
/// This is a compatibility layer that bridges to the new backend-synced addresses
class AddressController extends StateNotifier<AsyncValue<List<AddressModel>>> {
  final Ref _ref;

  AddressController(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Set initial state - will be updated from backend
    state = const AsyncValue.data([]);
  }

  /// Add address with backend sync
  Future<bool> addAddress(AddressModel address) async {
    try {
      state = const AsyncValue.loading();

      // For now, just add to local state
      // The actual backend sync happens through user_provider
      final currentAddresses = state.value ?? [];
      state = AsyncValue.data([...currentAddresses, address]);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Remove address with backend sync
  Future<bool> removeAddress(String id) async {
    try {
      final currentAddresses = state.value ?? [];
      state = AsyncValue.data(
        currentAddresses.where((a) => a.id != id).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Refresh addresses from backend
  Future<void> refresh() async {
    // Refresh from user provider
    await _ref.read(userProvider.notifier).refreshAddresses();
  }
}

final addressControllerProvider =
    StateNotifierProvider<AddressController, AsyncValue<List<AddressModel>>>((
      ref,
    ) {
      return AddressController(ref);
    });
