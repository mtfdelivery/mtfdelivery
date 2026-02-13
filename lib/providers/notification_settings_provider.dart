import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage notification settings
final notificationSettingsProvider = StateProvider<bool>((ref) => true);
