---
name: flutter-delivery-ui
description: Expert guidance for building delivery app UI components in Flutter. Use when creating restaurant cards, order tracking screens, cart interfaces, or any delivery-specific UI patterns.
---

# Flutter Delivery App UI Skill

Expert skill for building beautiful, performant UI components specific to food delivery applications in Flutter.

## When to Use This Skill

Use this skill when:
- Creating restaurant listing cards and grids
- Building order tracking interfaces
- Designing cart and checkout flows
- Implementing delivery status screens
- Creating user profile and settings pages
- Building search and filter interfaces for restaurants

## Project Context

This skill is designed for the **MTF Delivery** Flutter application, which uses:
- **State Management**: Riverpod (check `lib/providers/` for existing providers)
- **Backend**: Supabase for data and Firebase for authentication
- **UI Framework**: Material Design 3 with custom theming
- **Navigation**: go_router with named routes

## UI Design Principles

### 1. Mobile-First Approach
All components should be optimized for mobile devices:
- Touch-friendly tap targets (minimum 48x48 logical pixels)
- Appropriate spacing for thumbs (avoid elements at screen edges)
- Responsive layouts that adapt to different screen sizes (use `ScreenUtil`)
- No web-specific hover effects (use `InkWell` or `GestureDetector` for feedback)

### 2. Visual Hierarchy
- Use consistent spacing (AppDimensions: Sm=8, Md=16, Lg=24, etc.)
- Implement proper elevation for cards and overlays
- Use color to guide attention (AppColors: primary, secondary)
- Typography scale (AppTextStyles): Headlines, Body, Captions

### 3. Performance Optimization
- Use `const` constructors wherever possible
- Implement `ListView.builder` or `SliverList` for scrollable lists
- Lazy-load images with `CachedNetworkImage`
- Avoid rebuilding entire widget trees (use `ConsumerWidget` or `ref.watch`)

## Common Component Patterns

### Restaurant Card
- Compact, image-focused card with essential info
- Image with rounded corners (BorderRadius.circular(20))
- Restaurant name, rating, delivery time
- Cuisine tags as chips

### Order Status Card
- Timeline-based status display
- Estimated delivery time
- Courier information (name, photo, contact)
- Live tracking button

### Cart Item
- Swipeable item with quantity controls
- Item image (small, 60x60)
- Name, price, customizations
- Increment/decrement buttons

## Data Integration

### Supabase Queries
```dart
final response = await supabase
  .from('restaurants')
  .select()
  .eq('is_active', true)
  .order('rating', descending: true);
```

### State Management (Riverpod)
```dart
// Use ConsumerWidget for functional components
class RestaurantList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurants = ref.watch(restaurantProvider);
    return restaurants.when(...);
  }
}
```

## Accessibility

- Add semantic labels to icons and images
- Ensure sufficient color contrast (WCAG AA: 4.5:1 for text)
- Support text scaling (avoid fixed heights for text containers)
- Provide haptic feedback for important actions

## Testing Recommendations

- Test on multiple screen sizes (small phones, tablets)
- Verify performance with large lists (100+ items)
- Test with slow network conditions
- Validate dark mode appearance

## Common Pitfalls to Avoid

- ❌ Hardcoding colors instead of using theme
- ❌ Not handling loading and error states
- ❌ Forgetting to dispose controllers and streams
- ❌ Using `ListView` instead of `ListView.builder` for long lists
- ❌ Not optimizing images (use appropriate sizes and caching)

## File Organization

Place new UI components in:
- `lib/screens/` - Full screen widgets
- `lib/widgets/` - Reusable components
- `lib/models/` - Data models
- `lib/providers/` - State management
- `lib/services/` - API and backend services

## Example: Creating a Restaurant Card

```dart
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  
  const RestaurantCard({Key? key, required this.restaurant}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context, 
          '/restaurant-detail',
          arguments: restaurant.id,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with hero animation
            Hero(
              tag: 'restaurant-${restaurant.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: restaurant.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('${restaurant.rating}'),
                      SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16),
                      SizedBox(width: 4),
                      Text('${restaurant.deliveryTime} min'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Material Design Guidelines](https://material.io/design)
- [Supabase Flutter SDK](https://supabase.com/docs/reference/dart/introduction)
- Project-specific: Check `lib/widgets/` for existing reusable components
