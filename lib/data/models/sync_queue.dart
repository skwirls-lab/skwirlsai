import 'package:isar/isar.dart';

part 'sync_queue.g.dart';

@collection
class SyncQueueItem {
  Id id = Isar.autoIncrement;

  /// Type of entity: 'conversation', 'message', 'gem', 'document'
  late String entityType;

  /// UUID of the entity
  late String entityId;

  /// Action: 'create', 'update', 'delete'
  @enumerated
  late SyncAction action;

  /// JSON snapshot of the entity at time of queuing
  late String entityJson;

  late DateTime timestamp;

  int retryCount = 0;

  /// Error message from last failed sync attempt
  String? lastError;

  @enumerated
  SyncStatus status = SyncStatus.pending;
}

enum SyncAction {
  create,
  update,
  delete,
}

enum SyncStatus {
  pending,
  inProgress,
  failed,
  completed,
}
