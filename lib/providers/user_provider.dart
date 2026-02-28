import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../core/services/supabase_service.dart';
import 'auth_provider.dart';

/// User state notifier for managing user data with backend sync
class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null);

  /// Set the user from auth hydration
  void setUser(UserModel user) {
    state = user;
    _loadAddresses();
  }

  /// Load addresses from Supabase and update state
  Future<void> _loadAddresses() async {
    try {
      final addressesData = await SupabaseService.fetchAddresses();
      final addresses =
          addressesData.map((data) {
            return AddressModel(
              id: data['id'] as String,
              label: data['label'] as String? ?? 'Home',
              street: data['full_address'] as String? ?? '',
              city: data['city'] as String? ?? '',
              zipCode: data['postal_code'] as String? ?? '',
              landmark: data['apt_floor'] as String?,
              latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
              isDefault: data['is_default'] as bool? ?? false,
            );
          }).toList();

      if (state != null) {
        state = state!.copyWith(addresses: addresses);
        debugPrint('[UserNotifier] Loaded ${addresses.length} addresses');
      }
    } catch (e) {
      debugPrint('[UserNotifier] Error loading addresses: $e');
    }
  }

  /// Refresh addresses from backend
  Future<void> refreshAddresses() async {
    await _loadAddresses();
  }

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

  /// Add address (with backend sync)
  Future<bool> addAddress(AddressModel address) async {
    if (state == null) return false;

    try {
      final response = await SupabaseService.addAddress(
        label: address.label,
        fullAddress: address.street,
        aptFloor: address.landmark,
        city: address.city,
        postalCode: address.zipCode,
        latitude: address.latitude,
        longitude: address.longitude,
        isDefault: address.isDefault,
      );

      if (response != null) {
        // Create address with the backend-generated ID
        final newAddress = AddressModel(
          id: response['id'] as String,
          label: address.label,
          street: address.street,
          city: address.city,
          zipCode: address.zipCode,
          landmark: address.landmark,
          latitude: address.latitude,
          longitude: address.longitude,
          isDefault: address.isDefault,
        );

        // Update local state
        final addresses = [...state!.addresses, newAddress];
        state = state!.copyWith(addresses: addresses);
        debugPrint('[UserNotifier] Address added successfully');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[UserNotifier] Error adding address: $e');
      return false;
    }
  }

  /// Remove address (with backend sync)
  Future<bool> removeAddress(String addressId) async {
    if (state == null) return false;

    try {
      await SupabaseService.deleteAddress(addressId);

      final addresses =
          state!.addresses.where((a) => a.id != addressId).toList();
      state = state!.copyWith(addresses: addresses);
      debugPrint('[UserNotifier] Address removed successfully');
      return true;
    } catch (e) {
      debugPrint('[UserNotifier] Error removing address: $e');
      return false;
    }
  }

  /// Set default address (with backend sync)
  Future<bool> setDefaultAddress(String addressId) async {
    if (state == null) return false;

    try {
      await SupabaseService.setDefaultAddress(addressId);

      final addresses =
          state!.addresses.map((a) {
            return AddressModel(
              id: a.id,
              label: a.label,
              street: a.street,
              city: a.city,
              zipCode: a.zipCode,
              landmark: a.landmark,
              latitude: a.latitude,
              longitude: a.longitude,
              isDefault: a.id == addressId,
            );
          }).toList();
      state = state!.copyWith(addresses: addresses);
      debugPrint('[UserNotifier] Default address updated');
      return true;
    } catch (e) {
      debugPrint('[UserNotifier] Error setting default address: $e');
      return false;
    }
  }

  /// Logout (clear user)
  void logout() {
    state = null;
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

/// Auth state provider — derived from the real [authProvider].
final authStateProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
