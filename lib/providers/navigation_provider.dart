import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation state notifier for managing bottom navigation
class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0);

  /// Set current index
  void setIndex(int index) {
    state = index;
  }

  /// Navigate to specific tab
  void goToHome() => setIndex(0);
  void goToSearch() => setIndex(1);
  void goToCart() => setIndex(2);
  void goToOrders() => setIndex(3);
  void goToProfile() => setIndex(4);
}

/// Navigation index provider
final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((
  ref,
) {
  return NavigationNotifier();
});
