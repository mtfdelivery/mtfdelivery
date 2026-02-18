import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase service — call [initialize] once in main() before runApp().
class SupabaseService {
  SupabaseService._();

  /// Initializes the Supabase client from .env values.
  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (url.isEmpty || anonKey.isEmpty) {
      debugPrint(
        '[SupabaseService] WARNING: SUPABASE_URL or SUPABASE_ANON_KEY is missing from .env',
      );
    }

    await Supabase.initialize(url: url, anonKey: anonKey, debug: kDebugMode);

    debugPrint('[SupabaseService] Initialized — connected to $url');
  }

  /// Convenience accessor for the Supabase client.
  static SupabaseClient get client => Supabase.instance.client;
}
