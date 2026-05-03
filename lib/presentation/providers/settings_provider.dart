import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

class SettingsState {
  final double temperature;
  final double topP;
  final int topK;
  final int maxTokens;
  final double repeatPenalty;
  final int contextSize;
  final double fontSize;
  final bool compactMessages;
  final bool agentModeDefault;
  final bool ragEnabled;
  final bool hasCompletedOnboarding;

  const SettingsState({
    this.temperature = AppConstants.defaultTemperature,
    this.topP = AppConstants.defaultTopP,
    this.topK = AppConstants.defaultTopK,
    this.maxTokens = AppConstants.defaultMaxTokens,
    this.repeatPenalty = AppConstants.defaultRepeatPenalty,
    this.contextSize = AppConstants.defaultContextSize,
    this.fontSize = 15.0,
    this.compactMessages = false,
    this.agentModeDefault = false,
    this.ragEnabled = true,
    this.hasCompletedOnboarding = false,
  });

  SettingsState copyWith({
    double? temperature,
    double? topP,
    int? topK,
    int? maxTokens,
    double? repeatPenalty,
    int? contextSize,
    double? fontSize,
    bool? compactMessages,
    bool? agentModeDefault,
    bool? ragEnabled,
    bool? hasCompletedOnboarding,
  }) {
    return SettingsState(
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      maxTokens: maxTokens ?? this.maxTokens,
      repeatPenalty: repeatPenalty ?? this.repeatPenalty,
      contextSize: contextSize ?? this.contextSize,
      fontSize: fontSize ?? this.fontSize,
      compactMessages: compactMessages ?? this.compactMessages,
      agentModeDefault: agentModeDefault ?? this.agentModeDefault,
      ragEnabled: ragEnabled ?? this.ragEnabled,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs) : super(const SettingsState()) {
    _load();
  }

  void _load() {
    state = SettingsState(
      temperature: _prefs.getDouble('temperature') ?? AppConstants.defaultTemperature,
      topP: _prefs.getDouble('topP') ?? AppConstants.defaultTopP,
      topK: _prefs.getInt('topK') ?? AppConstants.defaultTopK,
      maxTokens: _prefs.getInt('maxTokens') ?? AppConstants.defaultMaxTokens,
      repeatPenalty: _prefs.getDouble('repeatPenalty') ?? AppConstants.defaultRepeatPenalty,
      contextSize: _prefs.getInt('contextSize') ?? AppConstants.defaultContextSize,
      fontSize: _prefs.getDouble('fontSize') ?? 15.0,
      compactMessages: _prefs.getBool('compactMessages') ?? false,
      agentModeDefault: _prefs.getBool('agentModeDefault') ?? false,
      ragEnabled: _prefs.getBool('ragEnabled') ?? true,
      hasCompletedOnboarding: _prefs.getBool('hasCompletedOnboarding') ?? false,
    );
  }

  Future<void> setTemperature(double value) async {
    await _prefs.setDouble('temperature', value);
    state = state.copyWith(temperature: value);
  }

  Future<void> setTopP(double value) async {
    await _prefs.setDouble('topP', value);
    state = state.copyWith(topP: value);
  }

  Future<void> setTopK(int value) async {
    await _prefs.setInt('topK', value);
    state = state.copyWith(topK: value);
  }

  Future<void> setMaxTokens(int value) async {
    await _prefs.setInt('maxTokens', value);
    state = state.copyWith(maxTokens: value);
  }

  Future<void> setRepeatPenalty(double value) async {
    await _prefs.setDouble('repeatPenalty', value);
    state = state.copyWith(repeatPenalty: value);
  }

  Future<void> setContextSize(int value) async {
    await _prefs.setInt('contextSize', value);
    state = state.copyWith(contextSize: value);
  }

  Future<void> setFontSize(double value) async {
    await _prefs.setDouble('fontSize', value);
    state = state.copyWith(fontSize: value);
  }

  Future<void> setCompactMessages(bool value) async {
    await _prefs.setBool('compactMessages', value);
    state = state.copyWith(compactMessages: value);
  }

  Future<void> setAgentModeDefault(bool value) async {
    await _prefs.setBool('agentModeDefault', value);
    state = state.copyWith(agentModeDefault: value);
  }

  Future<void> setRagEnabled(bool value) async {
    await _prefs.setBool('ragEnabled', value);
    state = state.copyWith(ragEnabled: value);
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool('hasCompletedOnboarding', true);
    state = state.copyWith(hasCompletedOnboarding: true);
  }

  Future<void> resetToDefaults() async {
    await _prefs.remove('temperature');
    await _prefs.remove('topP');
    await _prefs.remove('topK');
    await _prefs.remove('maxTokens');
    await _prefs.remove('repeatPenalty');
    await _prefs.remove('contextSize');
    state = state.copyWith(
      temperature: AppConstants.defaultTemperature,
      topP: AppConstants.defaultTopP,
      topK: AppConstants.defaultTopK,
      maxTokens: AppConstants.defaultMaxTokens,
      repeatPenalty: AppConstants.defaultRepeatPenalty,
      contextSize: AppConstants.defaultContextSize,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SettingsNotifier(prefs);
});
