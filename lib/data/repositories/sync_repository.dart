import 'package:isar/isar.dart';
import '../../core/utils/logger.dart';
import '../models/sync_queue.dart';

class SyncRepository {
  static const _tag = 'SyncRepo';
  final Isar _isar;

  SyncRepository({required Isar isar}) : _isar = isar;

  /// Add an item to the sync queue
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required SyncAction action,
    required String entityJson,
  }) async {
    final item = SyncQueueItem()
      ..entityType = entityType
      ..entityId = entityId
      ..action = action
      ..entityJson = entityJson
      ..timestamp = DateTime.now()
      ..status = SyncStatus.pending;

    await _isar.writeTxn(() async {
      await _isar.syncQueueItems.put(item);
    });

    Log.i(_tag, 'Enqueued: $entityType/$entityId (${action.name})');
  }

  /// Get all pending sync items
  Future<List<SyncQueueItem>> getPendingItems() async {
    return _isar.syncQueueItems
        .filter()
        .statusEqualTo(SyncStatus.pending)
        .sortByTimestamp()
        .findAll();
  }

  /// Get failed items for retry
  Future<List<SyncQueueItem>> getFailedItems({int maxRetries = 5}) async {
    return _isar.syncQueueItems
        .filter()
        .statusEqualTo(SyncStatus.failed)
        .retryCountLessThan(maxRetries)
        .sortByTimestamp()
        .findAll();
  }

  /// Mark an item as in progress
  Future<void> markInProgress(int id) async {
    final item = await _isar.syncQueueItems.get(id);
    if (item == null) return;

    item.status = SyncStatus.inProgress;

    await _isar.writeTxn(() async {
      await _isar.syncQueueItems.put(item);
    });
  }

  /// Mark an item as completed and remove it
  Future<void> markCompleted(int id) async {
    await _isar.writeTxn(() async {
      await _isar.syncQueueItems.delete(id);
    });
  }

  /// Mark an item as failed with error message
  Future<void> markFailed(int id, String error) async {
    final item = await _isar.syncQueueItems.get(id);
    if (item == null) return;

    item.status = SyncStatus.failed;
    item.retryCount++;
    item.lastError = error;

    await _isar.writeTxn(() async {
      await _isar.syncQueueItems.put(item);
    });

    Log.w(_tag, 'Sync failed for ${item.entityType}/${item.entityId}: $error (retry ${item.retryCount})');
  }

  /// Get count of pending items
  Future<int> getPendingCount() async {
    return _isar.syncQueueItems
        .filter()
        .statusEqualTo(SyncStatus.pending)
        .count();
  }

  /// Clear all completed items
  Future<void> clearCompleted() async {
    final items = await _isar.syncQueueItems
        .filter()
        .statusEqualTo(SyncStatus.completed)
        .findAll();

    await _isar.writeTxn(() async {
      await _isar.syncQueueItems.deleteAll(items.map((i) => i.id).toList());
    });
  }
}
