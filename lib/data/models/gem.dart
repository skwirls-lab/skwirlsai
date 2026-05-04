import 'package:isar/isar.dart';

part 'gem.g.dart'; // file will be renamed to acorn.g.dart

@collection
class Acorn {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String name;

  /// The system prompt that defines this Acorn's behavior
  String systemPrompt = '';

  /// Emoji or icon identifier
  String icon = '🌰';

  /// Hex color string for the Acorn's accent (e.g., '#E3AB59')
  String color = '#E3AB59';

  late DateTime createdAt;
  late DateTime updatedAt;

  /// Whether RAG document search is enabled for this Acorn
  bool ragEnabled = false;

  /// Whether agent mode is enabled by default for this Acorn
  bool agentModeDefault = false;

  /// Per-Acorn generation settings overrides (null = use global defaults)
  double? temperature;
  double? topP;
  int? topK;
  int? maxTokens;

  /// Whether this is a built-in default Acorn (cannot be deleted)
  bool isDefault = false;

  /// Sync version counter
  int syncVersion = 0;

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'name': name,
        'systemPrompt': systemPrompt,
        'icon': icon,
        'color': color,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'ragEnabled': ragEnabled,
        'agentModeDefault': agentModeDefault,
        'temperature': temperature,
        'topP': topP,
        'topK': topK,
        'maxTokens': maxTokens,
        'isDefault': isDefault,
        'syncVersion': syncVersion,
      };

  static Acorn fromJson(Map<String, dynamic> json) {
    return Acorn()
      ..uuid = json['uuid'] as String
      ..name = json['name'] as String
      ..systemPrompt = json['systemPrompt'] as String? ?? ''
      ..icon = json['icon'] as String? ?? '💎'
      ..color = json['color'] as String? ?? '#E3AB59'
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..updatedAt = DateTime.parse(json['updatedAt'] as String)
      ..ragEnabled = json['ragEnabled'] as bool? ?? false
      ..agentModeDefault = json['agentModeDefault'] as bool? ?? false
      ..temperature = (json['temperature'] as num?)?.toDouble()
      ..topP = (json['topP'] as num?)?.toDouble()
      ..topK = json['topK'] as int?
      ..maxTokens = json['maxTokens'] as int?
      ..isDefault = json['isDefault'] as bool? ?? false
      ..syncVersion = json['syncVersion'] as int? ?? 0;
  }

  /// Default Acorns that ship with the app
  static List<Acorn> get defaults {
    final now = DateTime.now();
    return [
      Acorn()
        ..uuid = 'acorn-general-assistant'
        ..name = 'General Assistant'
        ..systemPrompt = ''
        ..icon = '🤖'
        ..color = '#58AFAE'
        ..createdAt = now
        ..updatedAt = now
        ..isDefault = true,
      Acorn()
        ..uuid = 'acorn-code-helper'
        ..name = 'Code Helper'
        ..systemPrompt =
            'You are an expert software developer. Help the user write, debug, and explain code. Provide clear, concise solutions with best practices. Always include relevant code examples.'
        ..icon = '💻'
        ..color = '#E3AB59'
        ..createdAt = now
        ..updatedAt = now
        ..isDefault = true,
      Acorn()
        ..uuid = 'acorn-social-media'
        ..name = 'Social Media Creator'
        ..systemPrompt =
            'You are a social media content strategist. Help create engaging posts, captions, hashtags, scripts for short-form video, and content calendars. Tailor content for the specified platform (Instagram, TikTok, LinkedIn, X/Twitter, YouTube). Be creative, trendy, and audience-aware.'
        ..icon = '📱'
        ..color = '#E3AB59'
        ..createdAt = now
        ..updatedAt = now
        ..agentModeDefault = true
        ..isDefault = true,
      Acorn()
        ..uuid = 'acorn-business-analyst'
        ..name = 'Business Analyst'
        ..systemPrompt =
            'You are a business analyst and automation consultant. Help analyze data, create reports, develop business strategies, and design workflow automations. Be data-driven and action-oriented.'
        ..icon = '📊'
        ..color = '#58AFAE'
        ..createdAt = now
        ..updatedAt = now
        ..agentModeDefault = true
        ..isDefault = true,
    ];
  }
}
