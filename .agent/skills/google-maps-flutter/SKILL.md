---
name: google-maps-flutter
description: Expert guidance for integrating Google Maps in Flutter. Use for delivery tracking, address selection, and location-based services.
---

# Google Maps Flutter Skill

Expert implementation guide for Google Maps in Flutter delivery applications.

## Key Features

### 1. Delivery Tracking
- Use `Marker` to represent the courier and destination.
- Use `Polyline` to show the route from restaurant to customer.
- Smoothly animate marker movements using `Interpolation`.

### 2. Address Picker
- Integrate with `google_maps_webservice` for Places Autocomplete.
- Use the map center to "reverse geocode" and get the address at the pin.

## Implementation Guidelines

### Setup
- Ensure `API_KEY` is restricted to Android/iOS/Web platforms.
- Set up necessary permissions in `AndroidManifest.xml` and `Info.plist`.

### Theming the Map
Apply a custom JSON theme to match the app's brand (e.g., dark mode or minimal style).

```dart
String mapStyle = await rootBundle.loadString('assets/map_style.json');
_controller.setMapStyle(mapStyle);
```

### Performance
- Avoid re-creating the `GoogleMap` widget unnecessarily.
- Use `CustomPainter` for complex overlays if polylines aren't enough.

## Common Code Patterns

### Live Marker Update
```dart
void updateCourierLocation(LatLng newLocation) {
  setState(() {
    _markers = _markers.map((m) {
      if (m.markerId.value == 'courier') {
        return m.copyWith(positionParam: newLocation);
      }
      return m;
    }).toSet();
  });
}
```

## Resources
- [google_maps_flutter package](https://pub.dev/packages/google_maps_flutter)
- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation)
