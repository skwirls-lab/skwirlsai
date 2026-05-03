import '../../data/services/sync_service.dart';

class SyncConversationsUseCase {
  final SyncService _syncService;

  SyncConversationsUseCase({required SyncService syncService})
      : _syncService = syncService;

  /// Trigger a full sync cycle
  Future<void> execute() async {
    await _syncService.syncNow();
  }

  /// Get current sync status stream
  Stream<SyncStatus> get statusStream => _syncService.syncStatusStream;

  /// Get conflict stream for UI resolution
  Stream<SyncConflict> get conflictStream => _syncService.conflictStream;

  /// Resolve a sync conflict
  Future<void> resolveConflict(
    SyncConflict conflict,
    ConflictResolution resolution,
  ) async {
    await _syncService.resolveConflict(conflict, resolution);
  }
}
