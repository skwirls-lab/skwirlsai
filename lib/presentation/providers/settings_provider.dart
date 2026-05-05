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

/// Permission flags for a single SkwirlSkill
class SkillPermission {
  final bool read;
  final bool write;
  final bool network;

  const SkillPermission({
    this.read = true,
    this.write = false,
    this.network = false,
  });

  SkillPermission copyWith({bool? read, bool? write, bool? network}) =>
      SkillPermission(
        read: read ?? this.read,
        write: write ?? this.write,
        network: network ?? this.network,
      );

  Map<String, dynamic> toJson() => {
        'read': read,
        'write': write,
        'network': network,
      };

  factory SkillPermission.fromJson(Map<String, dynamic> json) =>
      SkillPermission(
        read: json['read'] as bool? ?? true,
        write: json['write'] as bool? ?? false,
        network: json['network'] as bool? ?? false,
      );

  /// Whether any permission is granted
  bool get isAllowed => read || write || network;
}

/// Default permissions per skill (safe defaults — read-only local tools on)
const _defaultSkillPermissions = <String, SkillPermission>{
  'search_svl_docs': SkillPermission(read: true),
  'read_file': SkillPermission(read: true),
  'list_files': SkillPermission(read: true),
  'write_file': SkillPermission(write: false),
  'web_search': SkillPermission(network: false),
  'list_google_calendar_events': SkillPermission(read: false, network: false),
  'search_gmail': SkillPermission(read: false, network: false),
  'get_recent_emails': SkillPermission(read: false, network: false),
  'generate_image': SkillPermission(read: true),
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

  Future<void> toggleRead(String skillName) async {
    final current = state[skillName] ?? const SkillPermission();
    await setPermission(skillName, current.copyWith(read: !current.read));
  }

  Future<void> toggleWrite(String skillName) async {
    final current = state[skillName] ?? const SkillPermission();
    await setPermission(skillName, current.copyWith(write: !current.write));
  }

  Future<void> toggleNetwork(String skillName) async {
    final current = state[skillName] ?? const SkillPermission();
    await setPermission(
        skillName, current.copyWith(network: !current.network));
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
