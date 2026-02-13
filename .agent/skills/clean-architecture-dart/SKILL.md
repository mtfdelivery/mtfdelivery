---
name: clean-architecture-dart
description: Expert guidance on structuring Dart/Flutter projects using Clean Architecture principles. Use for organizing code into Data, Domain, and Presentation layers.
---

# Clean Architecture for Dart & Flutter

A standard for building scalable, testable, and maintainable software in Dart.

## Layer Structure

### 1. Domain Layer (The Core)
Contains the business logic. It is completely independent of other layers.
- **Entities**: Simple data objects (not models).
- **Use Cases**: Business logic classes (e.g., `GetRestaurantDetails`).
- **Repository Interfaces**: Abstract classes defining data operations.

### 2. Data Layer
Handles data retrieval and persistence.
- **Models**: Extensions of entities with JSON serialization logic (e.g., `RestaurantModel`).
- **Data Sources**: Remote (API/Supabase) or Local (SQL/Preferences).
- **Repository Implementations**: Implement the domain interfaces using data sources.

### 3. Presentation Layer
The UI and State Management.
- **Pages/Screens**: The Flutter widgets.
- **Widgets**: Reusable UI components.
- **Providers/Notifiers**: State management logic.

## Folder Pattern
```text
lib/
  features/
    restaurant/
      data/
        models/
        repositories/
        datasources/
      domain/
        entities/
        usecases/
        repositories/
      presentation/
        providers/
        screens/
        widgets/
  core/
    constants/
    theme/
    utils/
```

## Rules of Engagement
- **Dependencies flow inward**: Data depends on Domain. Presentation depends on Domain.
- **No UI in Data/Domain**: Keep these layers pure Dart.
- **Use Entities in UI**: The presentation layer should ideally deal with Entities, but can use Models for performance in simple cases.

## Resources
- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [ResoCoder Clean Architecture Series](https://resocoder.com/flutter-clean-architecture-tdd/)
