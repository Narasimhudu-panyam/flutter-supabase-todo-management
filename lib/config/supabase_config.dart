import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static String get url {
    final value = dotenv.env['SUPABASE_URL'];

    if (value == null || value.trim().isEmpty) {
      throw StateError('SUPABASE_URL is missing from .env');
    }

    final uri = Uri.tryParse(value);

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError(
        'Invalid SUPABASE_URL. Expected: https://<project-ref>.supabase.co',
      );
    }

    return value;
  }

  static String get publishableKey {
    final value =
        dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
        dotenv.env['SUPABASE_ANON_KEY'];

    if (value == null || value.trim().isEmpty) {
      throw StateError('SUPABASE_PUBLISHABLE_KEY is missing from .env');
    }

    return value;
  }

  static SupabaseClient get client => Supabase.instance.client;
}
