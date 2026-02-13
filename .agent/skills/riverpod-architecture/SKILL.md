---
name: riverpod-architecture
description: Expert guidance on state management using Riverpod. Use for managing complex application states like cart items, live order tracking, and user authentication.
---

# Riverpod Architecture Skill

Expert patterns for managing state in Flutter using Riverpod. This skill focuses on the "Pod" way of doing things: decentralized, testable, and reactive.

## Core Concepts

### 1. The Provider Tree
- Use `ProviderScope` at the root.
- Keep providers globally accessible but scoped in their logic.
- Prefer `Notifier` and `AsyncNotifier` over `StateProvider` for complex logic.

### 2. Common Provider Types
- **Provider**: For Read-only values (e.g., constants, API clients).
- **NotifierProvider**: For complex state that can be changed synchronously.
- **AsyncNotifierProvider**: For state that depends on asynchronous operations (API calls, database).
- **FutureProvider / StreamProvider**: For consuming 1-off or stream-based data.

## Delivery App Patterns

### Cart Management
```dart
@riverpod
class Cart extends _$Cart {
  @override
  CartState build() => const CartState();

  void addItem(FoodItem item) {
    state = state.copyWith(
      items: [...state.items, item],
      total: state.total + item.price,
    );
  }
}
```

### Live Order Tracking
```dart
@riverpod
Stream<Order> orderStatus(OrderStatusRef ref, String orderId) {
  return ref.watch(supabaseClientProvider)
    .from('orders')
    .stream(primaryKey: ['id'])
    .eq('id', orderId)
    .map((data) => Order.fromJson(data.first));
}
```

## Best Practices

### Performance
- Use `ref.watch` for reactivity in `build`.
- Use `ref.read` only inside callbacks (e.g., `onPressed`).
- Use `ref.listen` for side-effects (e.g., showing a SnackBar).
- Use `ref.select` to avoid unnecessary rebuilds when only a part of the state changes.

### Clean Code
- Avoid putting UI logic in Notifiers.
- Keep Notifiers focused on a single domain (e.g., `CartNotifier`, `AuthNotifier`).
- Use `family` providers for parameterized state (e.g., `foodItemProvider(id)`).

## Resources
- [Riverpod Documentation](https://riverpod.dev)
- [Riverpod Generator](https://pub.dev/packages/riverpod_generator)
