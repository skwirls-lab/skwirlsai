import 'dart:convert';

class Tool {
  final String name;
  final String description;
  final ToolCategory category;
  final Map<String, ToolParameter> parameters;
  final bool requiresConfirmation;

  const Tool({
    required this.name,
    required this.description,
    required this.category,
    required this.parameters,
    this.requiresConfirmation = false,
  });

  /// Convert to JSON schema for LLM function calling
  Map<String, dynamic> toFunctionSchema() => {
        'type': 'function',
        'function': {
          'name': name,
          'description': description,
          'parameters': {
            'type': 'object',
            'properties': {
              for (final entry in parameters.entries)
                entry.key: entry.value.toJson(),
            },
            'required': parameters.entries
                .where((e) => e.value.required)
                .map((e) => e.key)
                .toList(),
          },
        },
      };
}

class ToolParameter {
  final String type; // 'string', 'integer', 'number', 'boolean'
  final String description;
  final bool required;
  final List<String>? enumValues;
  final dynamic defaultValue;

  const ToolParameter({
    required this.type,
    required this.description,
    this.required = false,
    this.enumValues,
    this.defaultValue,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type,
      'description': description,
    };
    if (enumValues != null) json['enum'] = enumValues;
    if (defaultValue != null) json['default'] = defaultValue;
    return json;
  }
}

enum ToolCategory {
  /// Local operations (RAG search, file access) — no confirmation needed
  local,

  /// Read-only external operations (Gmail read, Calendar read) — confirmation needed
  externalRead,

  /// Write/modify external operations — always requires confirmation
  externalWrite,

  /// Content generation (image, video, audio) — no confirmation needed
  generation,
}

class ToolCall {
  final String toolName;
  final Map<String, dynamic> arguments;
  final String? id;

  const ToolCall({
    required this.toolName,
    required this.arguments,
    this.id,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) => ToolCall(
        toolName: json['name'] as String,
        arguments: json['arguments'] is String
            ? jsonDecode(json['arguments'] as String) as Map<String, dynamic>
            : json['arguments'] as Map<String, dynamic>,
        id: json['id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': toolName,
        'arguments': arguments,
        if (id != null) 'id': id,
      };
}

class ToolResult {
  final String toolName;
  final String? callId;
  final bool success;
  final String output;
  final Duration executionTime;

  const ToolResult({
    required this.toolName,
    this.callId,
    required this.success,
    required this.output,
    required this.executionTime,
  });

  Map<String, dynamic> toJson() => {
        'toolName': toolName,
        'callId': callId,
        'success': success,
        'output': output,
        'executionTimeMs': executionTime.inMilliseconds,
      };
}
