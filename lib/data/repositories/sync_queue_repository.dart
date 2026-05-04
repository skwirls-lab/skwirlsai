import 'dart:convert';
import 'package:isar/isar.dart';
import '../../core/utils/logger.dart';
import '../models/sync_queue.dart';

/// Helper to enqueue local changes for background sync to Google Drive.
class SyncQueueRepository {
  static const _tag = 'SyncQueueRepo';
  final Isar _isar;

  SyncQueueRepository({required Isar isar}) : _isar = isar;

  /// Enqueue a create/update/delete action for later sync
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required SyncAction action,
    required Map<String, dynamic> entityJson,
  }) async {
    final item = SyncQueueItem()
      ..entityType = entityType
      ..entityId = entityId
      ..action = action
      ..entityJson = jsonEncode(entityJson)
      ..timestamp = DateTime.now()
      ..status = SyncStatus.pending;

    await _isar.writeTxn(() async {
      await _isar.syncQueueItems.put(item);
    });

    Log.d(_tag, 'Enqueued $action for $entityType:$entityId');
  }

  /// Get count of pending items
  Future<int> pendingCount() async {
    return _isar.syncQueueItems
        .filter()
        .statusEqualTo(SyncStatus.pending)
        .count();
  }

  /// Clear completed items
  Future<void> clearCompleted() async {
    final completed = await _isar.syncQueueItems
        .filter()
        .statusEqualTo(SyncStatus.completed)
        .findAll();

    if (completed.isNotEmpty) {
      await _isar.writeTxn(() async {
        await _isar.syncQueueItems
            .deleteAll(completed.map((i) => i.id).toList());
      });
    }
  }

  /// Clear all failed items (after user acknowledgment)
  Future<void> clearFailed() async {
    final failed = await _isar.syncQueueItems
        .filter()
        .statusEqualTo(SyncStatus.failed)
        .findAll();

    if (failed.isNotEmpty) {
      await _isar.writeTxn(() async {
        await _isar.syncQueueItems
            .deleteAll(failed.map((i) => i.id).toList());
      });
    }
  }
}
