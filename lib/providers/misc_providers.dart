import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for selected location string
final selectedLocationProvider = StateProvider<String>((ref) => 'Sousse');

// Mock/Placeholder Supabase client provider
final supabaseClientProvider = Provider<dynamic>((ref) {
  return _MockSupabaseClient();
});

class _MockSupabaseClient {
  _MockQueryBuilder from(String table) => _MockQueryBuilder();
}

class _MockQueryBuilder implements Future<List<Map<String, dynamic>>> {
  _MockQueryBuilder select() => this;
  _MockQueryBuilder order(String field, {bool ascending = true}) => this;

  final Future<List<Map<String, dynamic>>> _future = Future.value([]);

  @override
  Future<T> then<T>(
    FutureOr<T> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Stream<List<Map<String, dynamic>>> asStream() => _future.asStream();

  @override
  Future<List<Map<String, dynamic>>> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) => _future.catchError(onError, test: test);

  @override
  Future<List<Map<String, dynamic>>> timeout(
    Duration timeLimit, {
    FutureOr<List<Map<String, dynamic>>> Function()? onTimeout,
  }) => _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<List<Map<String, dynamic>>> whenComplete(
    FutureOr<void> Function() action,
  ) => _future.whenComplete(action);
}
