import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/address_model.dart';

class AddressController extends StateNotifier<AsyncValue<List<AddressModel>>> {
  AddressController() : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Initial mock data
    state = const AsyncValue.data([
      AddressModel(
        id: '1',
        label: 'Home',
        address: '123 Avenue Habib Bourguiba, Tunis',
        name: 'Mustapha Merkich',
        phone: '+216 12 345 678',
      ),
      AddressModel(
        id: '2',
        label: 'Work',
        address: 'MTF Headquarters, Lac 2, Tunis',
        name: 'Mustapha Merkich',
        phone: '+216 12 345 678',
      ),
    ]);
  }

  void addAddress(AddressModel address) {
    if (state.hasValue) {
      state = AsyncValue.data([...state.value!, address]);
    }
  }

  void removeAddress(String id) {
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.where((a) => a.id != id).toList());
    }
  }
}

final addressControllerProvider =
    StateNotifierProvider<AddressController, AsyncValue<List<AddressModel>>>((
      ref,
    ) {
      return AddressController();
    });
