import 'dart:convert';
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

/// Permission for a single SkwirlSkill (simple on/off)
class SkillPermission {
  final bool allowed;

  const SkillPermission({this.allowed = true});

  SkillPermission copyWith({bool? allowed}) =>
      SkillPermission(allowed: allowed ?? this.allowed);

  Map<String, dynamic> toJson() => {'allowed': allowed};

  factory SkillPermission.fromJson(Map<String, dynamic> json) =>
      SkillPermission(
        // Support legacy read/write/network format
        allowed: json['allowed'] as bool? ??
            ((json['read'] as bool? ?? false) ||
             (json['write'] as bool? ?? false) ||
             (json['network'] as bool? ?? false)),
      );

  bool get isAllowed => allowed;
}

/// Default permissions per skill (safe defaults — read-only local tools on)
const _defaultSkillPermissions = <String, SkillPermission>{
  'search_svl_docs': SkillPermission(allowed: true),
  'read_file': SkillPermission(allowed: true),
  'list_files': SkillPermission(allowed: true),
  'search_files': SkillPermission(allowed: true),
  'search_content': SkillPermission(allowed: true),
  'write_file': SkillPermission(allowed: false),
  'web_search': SkillPermission(allowed: false),
  'list_google_calendar_events': SkillPermission(allowed: false),
  'search_gmail': SkillPermission(allowed: false),
  'get_recent_emails': SkillPermission(allowed: false),
  'generate_image': SkillPermission(allowed: true),
};

class SkillPermissionsNotifier
    extends StateNotifier<Map<String, SkillPermission>> {
  final SharedPreferences _prefs;
  static const _key = 'skillPermissions';

  SkillPermissionsNotifier(this._prefs)
      : super(Map.from(_defaultSkillPermissions)) {
    _load();
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final loaded = <String, SkillPermission>{};
        // Start with defaults, then overlay saved values
        for (final entry in _defaultSkillPermissions.entries) {
          if (map.containsKey(entry.key)) {
            loaded[entry.key] = SkillPermission.fromJson(
                map[entry.key] as Map<String, dynamic>);
          } else {
            loaded[entry.key] = entry.value;
          }
        }
        state = loaded;
      } catch (_) {
        state = Map.from(_defaultSkillPermissions);
      }
    }
  }

  Future<void> _save() async {
    final map = state.map((k, v) => MapEntry(k, v.toJson()));
    await _prefs.setString(_key, jsonEncode(map));
  }

  Future<void> setPermission(
      String skillName, SkillPermission permission) async {
    final updated = Map<String, SkillPermission>.from(state);
    updated[skillName] = permission;
    state = updated;
    await _save();
  }

  Future<void> toggleAllowed(String skillName) async {
    final current = state[skillName] ?? const SkillPermission();
    await setPermission(
        skillName, current.copyWith(allowed: !current.allowed));
  }

  /// Check if a skill is globally permitted (any permission flag is on)
  bool isSkillPermitted(String skillName) {
    final perm = state[skillName];
    return perm?.isAllowed ?? false;
  }
}

final skillPermissionsProvider = StateNotifierProvider<
    SkillPermissionsNotifier, Map<String, SkillPermission>>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SkillPermissionsNotifier(prefs);
});

/// Saved remote endpoint
class SavedEndpoint {
  final String name;
  final String baseUrl;
  final String? modelName;
  final String? apiKey;

  const SavedEndpoint({
    required this.name,
    required this.baseUrl,
    this.modelName,
    this.apiKey,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'baseUrl': baseUrl,
        'modelName': modelName,
        'apiKey': apiKey,
      };

  factory SavedEndpoint.fromJson(Map<String, dynamic> json) => SavedEndpoint(
        name: json['name'] as String? ?? '',
        baseUrl: json['baseUrl'] as String? ?? '',
        modelName: json['modelName'] as String?,
        apiKey: json['apiKey'] as String?,
      );
}

class SavedEndpointsNotifier extends StateNotifier<List<SavedEndpoint>> {
  final SharedPreferences _prefs;
  static const _key = 'savedEndpoints';

  SavedEndpointsNotifier(this._prefs) : super([]) {
    _load();
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        state = list
            .map((e) => SavedEndpoint.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    await _prefs.setString(
        _key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  Future<void> addEndpoint(SavedEndpoint endpoint) async {
    state = [...state, endpoint];
    await _save();
  }

  Future<void> removeEndpoint(int index) async {
    final updated = List<SavedEndpoint>.from(state);
    updated.removeAt(index);
    state = updated;
    await _save();
  }
}

final savedEndpointsProvider =
    StateNotifierProvider<SavedEndpointsNotifier, List<SavedEndpoint>>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SavedEndpointsNotifier(prefs);
});
