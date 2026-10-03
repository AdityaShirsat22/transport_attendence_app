import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fleettrack/core/config/supabase_config.dart';
import 'package:fleettrack/features/settings/domain/company_settings.dart';

abstract class CompanySettingsRepository {
  Future<CompanySettings> getSettings();
  Future<void> saveSettings(CompanySettings settings);
  Future<CompanySettings> resetToDefaults();
}

class SupabaseCompanySettingsRepository implements CompanySettingsRepository {
  static const _defaultSettings = CompanySettings(
    id: 'default',
    companyName: 'FleetTrack Transport Co.',
    tagline: 'Fleet Logistics, Heavy Cargo & Transport Services',
    phone: '+91 91374 78077',
    city: 'Transport Nagar, Logistics Hub',
    currency: '₹',
    standardMonthDays: 30,
  );

  CompanySettings _cachedSettings = _defaultSettings;

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CompanySettings> getSettings() async {
    final client = _client;
    if (!SupabaseConfig.isConfigured || client == null) {
      return _cachedSettings;
    }

    try {
      final response = await client
          .from('company_settings')
          .select()
          .eq('id', 'default')
          .maybeSingle();

      if (response != null) {
        _cachedSettings = CompanySettings.fromJson(response);
        return _cachedSettings;
      } else {
        await saveSettings(_defaultSettings);
        return _defaultSettings;
      }
    } catch (e) {
      debugPrint('Failed to load settings from Supabase, using fallback: $e');
      return _cachedSettings;
    }
  }

  @override
  Future<void> saveSettings(CompanySettings settings) async {
    _cachedSettings = settings;

    final client = _client;
    if (!SupabaseConfig.isConfigured || client == null) return;

    try {
      await client
          .from('company_settings')
          .upsert(settings.toJson());
    } catch (e) {
      debugPrint('Failed to save settings to Supabase: $e');
      rethrow;
    }
  }

  @override
  Future<CompanySettings> resetToDefaults() async {
    _cachedSettings = _defaultSettings;

    final client = _client;
    if (SupabaseConfig.isConfigured && client != null) {
      try {
        await client
            .from('company_settings')
            .upsert(_defaultSettings.toJson());
      } catch (e) {
        debugPrint('Failed to reset settings in Supabase: $e');
      }
    }
    return _defaultSettings;
  }
}
