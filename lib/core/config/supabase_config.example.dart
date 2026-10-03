/// Supabase configuration template for FleetTrack.
/// 
/// Instructions for new setups:
/// 1. Copy this file to `lib/core/config/supabase_config.dart`
/// 2. Replace the placeholder values with your actual Supabase URL and anon key:
///    - URL found in Supabase Dashboard > Settings > API
///    - anon key found in Supabase Dashboard > Settings > API
/// 3. Run the SQL migrations from `supabase/migrations/` in your Supabase SQL Editor.
class SupabaseConfig {
  SupabaseConfig._();

  /// Your Supabase project URL (e.g. 'https://xyzcompany.supabase.co')
  static const String url = 'YOUR_SUPABASE_PROJECT_URL';

  /// Your Supabase anonymous (public) API key
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';

  /// Returns true if valid Supabase credentials have been provided
  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      !url.contains('YOUR_SUPABASE_') &&
      !anonKey.contains('YOUR_SUPABASE_');
}
