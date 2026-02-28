import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/supabase_service.dart';
import '../data/models/user_model.dart';
import 'user_provider.dart';

// ─── Auth state enum ────────────────────────────────────────────────

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({this.status = AuthStatus.initial, this.errorMessage});

  AuthState copyWith({AuthStatus? status, String? errorMessage}) =>
      AuthState(status: status ?? this.status, errorMessage: errorMessage);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

// ─── Auth Notifier ──────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  StreamSubscription<AuthState>? _authSub;

  AuthNotifier(this._ref) : super(const AuthState()) {
    _init();
  }

  void _init() {
    // Check existing session on boot
    final session = SupabaseService.currentSession;
    if (session != null) {
      state = const AuthState(status: AuthStatus.authenticated);
      _hydrateUser();
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }

    // Listen for auth changes
    SupabaseService.authStateChanges.listen((event) {
      final authEvent = event.event;
      if (authEvent == AuthChangeEvent.signedIn ||
          authEvent == AuthChangeEvent.tokenRefreshed) {
        state = const AuthState(status: AuthStatus.authenticated);
        _hydrateUser();
      } else if (authEvent == AuthChangeEvent.signedOut) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        _ref.read(userProvider.notifier).logout();
      }
    });
  }

  /// Pull the profile from Supabase and push it into userProvider.
  Future<void> _hydrateUser() async {
    try {
      final profile = await SupabaseService.fetchProfile();
      final authUser = SupabaseService.currentUser;
      if (authUser != null) {
        final userModel = UserModel(
          id: authUser.id,
          name:
              profile?['full_name'] ??
              authUser.userMetadata?['full_name'] ??
              '',
          email: authUser.email ?? '',
          phone: profile?['phone'] ?? authUser.phone ?? '',
          avatarUrl: profile?['avatar_url'],
          createdAt: DateTime.tryParse(authUser.createdAt) ?? DateTime.now(),
        );
        _ref.read(userProvider.notifier).setUser(userModel);
      }
    } catch (e) {
      debugPrint('[AuthNotifier] Error hydrating user: $e');
    }
  }

  // ─── Actions ────────────────────────────────────────────────────

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await SupabaseService.signIn(email: email, password: password);
      // Immediately set authenticated state to trigger router redirect
      state = state.copyWith(status: AuthStatus.authenticated);
      _hydrateUser();
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await SupabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      // Immediately set authenticated state to trigger router redirect
      state = state.copyWith(status: AuthStatus.authenticated);
      _hydrateUser();
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseService.signOut();
      // Auth listener handles the rest
    } catch (e) {
      debugPrint('[AuthNotifier] Error signing out: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await SupabaseService.resetPassword(email);
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

// ─── Provider ───────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
