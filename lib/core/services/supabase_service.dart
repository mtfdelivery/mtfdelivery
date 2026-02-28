import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase service — call [initialize] once in main() before runApp().
class SupabaseService {
  SupabaseService._();

  /// Initializes the Supabase client from .env values.
  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (url.isEmpty || anonKey.isEmpty) {
      debugPrint(
        '[SupabaseService] WARNING: SUPABASE_URL or SUPABASE_ANON_KEY is missing from .env',
      );
    }

    await Supabase.initialize(url: url, anonKey: anonKey, debug: kDebugMode);

    debugPrint('[SupabaseService] Initialized — connected to $url');
  }

  /// Convenience accessor for the Supabase client.
  static SupabaseClient get client => Supabase.instance.client;

  // ─── Auth helpers ─────────────────────────────────────────────────

  /// Sign up with email, password, and optional metadata.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    return client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      },
    );
  }

  /// Sign in with email and password.
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  /// Sign out the current user.
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Send a password-reset email.
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// The current active session (null if logged out).
  static Session? get currentSession => client.auth.currentSession;

  /// The current auth user (null if logged out).
  static User? get currentUser => client.auth.currentUser;

  /// Stream of auth state changes.
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // ─── Profile helpers ──────────────────────────────────────────────

  /// Fetch the profile row for the currently signed-in user.
  static Future<Map<String, dynamic>?> fetchProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response =
        await client.from('profiles').select().eq('id', user.id).maybeSingle();

    return response;
  }

  /// Update the profile row for the currently signed-in user.
  static Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };

    await client.from('profiles').update(updates).eq('id', user.id);
  }

  // ─── Address helpers ────────────────────────────────────────────────

  /// Fetch all addresses for the current user.
  static Future<List<Map<String, dynamic>>> fetchAddresses() async {
    final user = currentUser;
    if (user == null) return [];

    final response = await client
        .from('addresses')
        .select()
        .eq('user_id', user.id)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);

    return response;
  }

  /// Add a new address for the current user.
  static Future<Map<String, dynamic>?> addAddress({
    required String label,
    required String fullAddress,
    String? aptFloor,
    String? city,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    final user = currentUser;
    if (user == null) return null;

    // If this is the default address, unset any existing default
    if (isDefault) {
      await client
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', user.id)
          .eq('is_default', true);
    }

    final response =
        await client
            .from('addresses')
            .insert({
              'user_id': user.id,
              'label': label,
              'full_address': fullAddress,
              'apt_floor': aptFloor,
              'city': city,
              'postal_code': postalCode,
              'latitude': latitude,
              'longitude': longitude,
              'is_default': isDefault,
            })
            .select()
            .single();

    return response;
  }

  /// Update an existing address.
  static Future<void> updateAddress({
    required String addressId,
    String? label,
    String? fullAddress,
    String? aptFloor,
    String? city,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    final user = currentUser;
    if (user == null) return;

    // If this is being set as default, unset any existing default
    if (isDefault == true) {
      await client
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', user.id)
          .eq('is_default', true);
    }

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      if (label != null) 'label': label,
      if (fullAddress != null) 'full_address': fullAddress,
      if (aptFloor != null) 'apt_floor': aptFloor,
      if (city != null) 'city': city,
      if (postalCode != null) 'postal_code': postalCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (isDefault != null) 'is_default': isDefault,
    };

    await client.from('addresses').update(updates).eq('id', addressId);
  }

  /// Delete an address.
  static Future<void> deleteAddress(String addressId) async {
    await client.from('addresses').delete().eq('id', addressId);
  }

  /// Set an address as default.
  static Future<void> setDefaultAddress(String addressId) async {
    final user = currentUser;
    if (user == null) return;

    // Unset any existing default
    await client
        .from('addresses')
        .update({'is_default': false})
        .eq('user_id', user.id)
        .eq('is_default', true);

    // Set the new default
    await client
        .from('addresses')
        .update({'is_default': true})
        .eq('id', addressId);
  }
}
