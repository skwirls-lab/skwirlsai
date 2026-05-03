import 'package:isar/isar.dart';

part 'conversation.g.dart';

@collection
class Conversation {
  Id id = Isar.autoIncrement;

  @Index()
  late String uuid;

  @Index()
  late String gemId;

  late String title;

  late DateTime createdAt;
  late DateTime updatedAt;

  DateTime? lastSyncedAt;

  bool isPinned = false;
  bool isArchived = false;

  /// Device ID that last modified this conversation (for conflict detection)
  late String lastModifiedBy;

  /// Sync version counter, incremented on each local change
  int syncVersion = 0;

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'gemId': gemId,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'isPinned': isPinned,
        'isArchived': isArchived,
        'lastModifiedBy': lastModifiedBy,
        'syncVersion': syncVersion,
      };

  static Conversation fromJson(Map<String, dynamic> json) {
    return Conversation()
      ..uuid = json['uuid'] as String
      ..gemId = json['gemId'] as String
      ..title = json['title'] as String
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..updatedAt = DateTime.parse(json['updatedAt'] as String)
      ..lastSyncedAt = json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null
      ..isPinned = json['isPinned'] as bool? ?? false
      ..isArchived = json['isArchived'] as bool? ?? false
      ..lastModifiedBy = json['lastModifiedBy'] as String? ?? ''
      ..syncVersion = json['syncVersion'] as int? ?? 0;
  }
}
