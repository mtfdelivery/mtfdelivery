import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for selected location string
final selectedLocationProvider = StateProvider<String>((ref) => 'Sousse');
