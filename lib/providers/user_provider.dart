import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/mock/mock_users.dart';

/// User state notifier for managing user data
class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(MockUsers.currentUser);

  /// Update user profile
  void updateProfile({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
  }) {
    if (state != null) {
      state = state!.copyWith(
        name: name,
        email: email,
        phone: phone,
        avatarUrl: avatarUrl,
      );
    }
  }

  /// Add address
  void addAddress(AddressModel address) {
    if (state != null) {
      final addresses = [...state!.addresses, address];
      state = state!.copyWith(addresses: addresses);
    }
  }

  /// Remove address
  void removeAddress(String addressId) {
    if (state != null) {
      final addresses =
          state!.addresses.where((a) => a.id != addressId).toList();
      state = state!.copyWith(addresses: addresses);
    }
  }

  /// Set default address
  void setDefaultAddress(String addressId) {
    if (state != null) {
      final addresses =
          state!.addresses.map((a) {
            if (a.id == addressId) {
              return AddressModel(
                id: a.id,
                label: a.label,
                street: a.street,
                city: a.city,
                zipCode: a.zipCode,
                landmark: a.landmark,
                latitude: a.latitude,
                longitude: a.longitude,
                isDefault: true,
              );
            } else {
              return AddressModel(
                id: a.id,
                label: a.label,
                street: a.street,
                city: a.city,
                zipCode: a.zipCode,
                landmark: a.landmark,
                latitude: a.latitude,
                longitude: a.longitude,
                isDefault: false,
              );
            }
          }).toList();
      state = state!.copyWith(addresses: addresses);
    }
  }

  /// Logout (clear user)
  void logout() {
    state = null;
  }

  /// Login (set mock user)
  void login() {
    state = MockUsers.currentUser;
  }
}

/// User provider
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier();
});

/// Current user addresses provider
final userAddressesProvider = Provider<List<AddressModel>>((ref) {
  final user = ref.watch(userProvider);
  return user?.addresses ?? [];
});

/// Default address provider
final defaultAddressProvider = Provider<AddressModel?>((ref) {
  final addresses = ref.watch(userAddressesProvider);
  return addresses.cast<AddressModel?>().firstWhere(
    (a) => a?.isDefault == true,
    orElse: () => addresses.isNotEmpty ? addresses.first : null,
  );
});

/// Selected delivery address for checkout
final selectedAddressProvider = StateProvider<AddressModel?>((ref) {
  return ref.watch(defaultAddressProvider);
});
