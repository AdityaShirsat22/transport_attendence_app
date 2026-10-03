import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleettrack/features/settings/data/company_settings_repository.dart';
import 'package:fleettrack/features/settings/domain/company_settings.dart';

final companySettingsRepositoryProvider =
    Provider<CompanySettingsRepository>((ref) {
  return SupabaseCompanySettingsRepository();
});

class CompanySettingsNotifier extends StateNotifier<AsyncValue<CompanySettings>> {
  final CompanySettingsRepository _repository;

  CompanySettingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final settings = await _repository.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings(CompanySettings newSettings) async {
    state = AsyncValue.data(newSettings);
    await _repository.saveSettings(newSettings);
  }

  Future<void> resetToDefaults() async {
    final def = await _repository.resetToDefaults();
    state = AsyncValue.data(def);
  }
}

final companySettingsProvider =
    StateNotifierProvider<CompanySettingsNotifier, AsyncValue<CompanySettings>>((ref) {
  final repo = ref.watch(companySettingsRepositoryProvider);
  return CompanySettingsNotifier(repo);
});
