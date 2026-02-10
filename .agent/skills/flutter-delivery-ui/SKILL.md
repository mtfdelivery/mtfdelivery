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
- **State Management**: Provider (check `lib/` for existing providers)
- **Backend**: Supabase for data and Firebase for authentication
- **UI Framework**: Material Design with custom theming
- **Navigation**: Named routes with route management

## UI Design Principles

### 1. Mobile-First Approach
All components should be optimized for mobile devices:
- Touch-friendly tap targets (minimum 48x48 logical pixels)
- Appropriate spacing for thumbs (avoid elements at screen edges)
- Responsive layouts that adapt to different screen sizes
- No web-specific hover effects (use `InkWell` or `GestureDetector` for feedback)

### 2. Visual Hierarchy
- Use consistent spacing (8px grid system: 8, 16, 24, 32, 40)
- Implement proper elevation for cards and overlays
- Use color to guide attention (primary actions, status indicators)
- Typography scale: Headlines (24-32), Body (14-16), Captions (12)

### 3. Performance Optimization
- Use `const` constructors wherever possible
- Implement `ListView.builder` for scrollable lists
- Lazy-load images with `CachedNetworkImage`
- Avoid rebuilding entire widget trees (use `Consumer` or `Selector`)

## Common Component Patterns

### Restaurant Card
```dart
// Compact, image-focused card with essential info
// - Image with rounded corners (BorderRadius.circular(12))
// - Restaurant name, rating, delivery time
// - Cuisine tags as chips
// - Favorite/bookmark icon overlay
```

### Order Status Card
```dart
// Timeline-based status display
// - Current status highlighted
// - Estimated delivery time
// - Courier information (name, photo, contact)
// - Live tracking button
```

### Cart Item
```dart
// Swipeable item with quantity controls
// - Item image (small, 60x60)
// - Name, price, customizations
// - Increment/decrement buttons
// - Swipe-to-delete gesture
```

## Color Scheme Guidelines

Reference the app's existing theme:
- **Primary**: Check `lib/theme/` or `main.dart` for `primaryColor`
- **Accent**: For CTAs and important actions
- **Background**: Light mode and dark mode support
- **Error**: For validation and error states
- **Success**: For confirmations and completed orders

## Navigation Patterns

### Screen Transitions
- Use `Navigator.pushNamed()` for named routes
- Implement hero animations for images (restaurant → detail)
- Bottom sheet for filters and quick actions
- Modal dialogs for confirmations

### Bottom Navigation
- Keep 3-5 main sections (Home, Search, Orders, Profile)
- Use clear, recognizable icons
- Highlight active tab with color and icon fill

## Data Integration

### Supabase Queries
```dart
// Fetch restaurants with filters
final response = await supabase
  .from('restaurants')
  .select()
  .eq('is_active', true)
  .order('rating', ascending: false);
```

### State Management
```dart
// Use Provider for app-wide state
// Create specific providers for:
// - CartProvider (manage cart items)
// - RestaurantProvider (fetch and cache restaurants)
// - OrderProvider (track active orders)
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
