import 'package:isar/isar.dart';

part 'message.g.dart';

@collection
class Message {
  Id id = Isar.autoIncrement;

  @Index()
  late String uuid;

  @Index()
  late String conversationId;

  @enumerated
  late MessageRole role;

  late String content;

  /// Optional thinking content from agent mode (<|think|> output)
  String? thinkingContent;

  /// Tool calls made during this message (JSON-encoded list)
  String? toolCallsJson;

  /// Tool results returned (JSON-encoded list)
  String? toolResultsJson;

  late DateTime timestamp;

  /// Whether this message has been edited
  bool isEdited = false;

  /// Attachment UUIDs (comma-separated for Isar compatibility)
  String? attachmentIds;

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'conversationId': conversationId,
        'role': role.name,
        'content': content,
        'thinkingContent': thinkingContent,
        'toolCallsJson': toolCallsJson,
        'toolResultsJson': toolResultsJson,
        'timestamp': timestamp.toIso8601String(),
        'isEdited': isEdited,
        'attachmentIds': attachmentIds,
      };

  static Message fromJson(Map<String, dynamic> json) {
    return Message()
      ..uuid = json['uuid'] as String
      ..conversationId = json['conversationId'] as String
      ..role = MessageRole.values.byName(json['role'] as String)
      ..content = json['content'] as String
      ..thinkingContent = json['thinkingContent'] as String?
      ..toolCallsJson = json['toolCallsJson'] as String?
      ..toolResultsJson = json['toolResultsJson'] as String?
      ..timestamp = DateTime.parse(json['timestamp'] as String)
      ..isEdited = json['isEdited'] as bool? ?? false
      ..attachmentIds = json['attachmentIds'] as String?;
  }
}

enum MessageRole {
  user,
  assistant,
  system,
  tool,
}
