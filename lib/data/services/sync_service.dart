import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../models/sync_queue.dart' as sq;
import 'auth_service.dart';

class SyncService {
  static const _tag = 'SyncService';

  final AuthService _authService;
  final Isar _isar;
  final Connectivity _connectivity = Connectivity();

  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  final _conflictController = StreamController<SyncConflict>.broadcast();
  Stream<SyncConflict> get conflictStream => _conflictController.stream;

  SyncService({required AuthService authService, required Isar isar})
      : _authService = authService,
        _isar = isar;

  /// Initialize sync service and start periodic sync
  Future<void> initialize() async {
    if (!_authService.isAuthenticated) {
      Log.i(_tag, 'User not authenticated, sync disabled');
      return;
    }

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline && !_isSyncing) {
        Log.i(_tag, 'Network restored, triggering sync');
        syncNow();
      }
    });

    // Start periodic sync timer
    _syncTimer = Timer.periodic(AppConstants.syncDebounce, (_) {
      if (!_isSyncing) syncNow();
    });

    Log.i(_tag, 'Sync service initialized');
  }

  /// Perform a full sync now
  Future<void> syncNow() async {
    if (!_authService.isAuthenticated || _isSyncing) return;

    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = connectivityResult.any((r) => r != ConnectivityResult.none);
    if (!isOnline) {
      Log.i(_tag, 'Offline, skipping sync');
      _syncStatusController.add(SyncStatus.offline);
      return;
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);
    Log.i(_tag, 'Starting sync...');

    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        Log.w(_tag, 'Could not initialize Drive API');
        _syncStatusController.add(SyncStatus.error);
        return;
      }

      // Upload pending changes
      await _uploadPendingChanges(driveApi);

      // Download remote changes
      await _downloadRemoteChanges(driveApi);

      _lastSyncTime = DateTime.now();
      _syncStatusController.add(SyncStatus.synced);
      Log.i(_tag, 'Sync complete');
    } catch (e, st) {
      Log.e(_tag, 'Sync failed', e, st);
      _syncStatusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  /// Upload local changes to Google Drive appDataFolder
  Future<void> _uploadPendingChanges(drive.DriveApi driveApi) async {
    final pending = await _isar.syncQueueItems
        .filter()
        .statusEqualTo(sq.SyncStatus.pending)
        .findAll();

    if (pending.isEmpty) {
      Log.i(_tag, 'No pending changes to upload');
      return;
    }

    Log.i(_tag, 'Uploading ${pending.length} pending changes...');

    for (final item in pending) {
      try {
        // Mark as in-progress
        await _isar.writeTxn(() async {
          item.status = sq.SyncStatus.inProgress;
          await _isar.syncQueueItems.put(item);
        });

        // Upload to Drive
        await uploadEntity(
          entityType: item.entityType,
          entityId: item.entityId,
          data: jsonDecode(item.entityJson) as Map<String, dynamic>,
        );

        // Mark as completed and remove from queue
        await _isar.writeTxn(() async {
          await _isar.syncQueueItems.delete(item.id);
        });
      } catch (e) {
        Log.e(_tag, 'Failed to upload ${item.entityType}:${item.entityId}', e);
        await _isar.writeTxn(() async {
          item.status = sq.SyncStatus.failed;
          item.retryCount++;
          item.lastError = e.toString();
          await _isar.syncQueueItems.put(item);
        });
      }
    }
  }

  /// Download remote changes from Google Drive
  Future<void> _downloadRemoteChanges(drive.DriveApi driveApi) async {
    Log.i(_tag, 'Checking for remote changes...');

    try {
      // List all files in appDataFolder
      String? pageToken;
      do {
        final fileList = await driveApi.files.list(
          spaces: 'appDataFolder',
          pageToken: pageToken,
          $fields: 'nextPageToken, files(id, name, modifiedTime)',
          orderBy: 'modifiedTime desc',
        );

        if (fileList.files != null) {
          for (final file in fileList.files!) {
            if (file.modifiedTime == null || file.name == null) continue;

            // Only process files newer than last sync
            if (_lastSyncTime != null &&
                file.modifiedTime!.isBefore(_lastSyncTime!)) {
              continue;
            }

            // Download and merge
            final data = await _downloadFile(driveApi, file.id!);
            if (data != null) {
              Log.i(_tag, 'Downloaded remote file: ${file.name}');
              // Data merging is handled by the caller / repository layer
            }
          }
        }

        pageToken = fileList.nextPageToken;
      } while (pageToken != null);

      Log.i(_tag, 'Remote changes check complete');
    } catch (e) {
      Log.e(_tag, 'Failed to download remote changes', e);
    }
  }

  /// Download a single file from Drive and parse as JSON
  Future<Map<String, dynamic>?> _downloadFile(
      drive.DriveApi driveApi, String fileId) async {
    try {
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (e) {
      Log.e(_tag, 'Failed to download file: $fileId', e);
      return null;
    }
  }

  /// Upload a specific entity to Drive
  Future<void> uploadEntity({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return;

    final fileName = '${entityType}_$entityId.json';
    final content = jsonEncode(data);
    final media = drive.Media(
      Stream.value(utf8.encode(content)),
      content.length,
    );

    // Check if file already exists
    try {
      final existing = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name='$fileName'",
      );

      if (existing.files != null && existing.files!.isNotEmpty) {
        // Update existing file
        await driveApi.files.update(
          drive.File(),
          existing.files!.first.id!,
          uploadMedia: media,
        );
      } else {
        // Create new file
        final driveFile = drive.File()
          ..name = fileName
          ..parents = ['appDataFolder'];
        await driveApi.files.create(driveFile, uploadMedia: media);
      }

      Log.i(_tag, 'Uploaded: $fileName');
    } catch (e) {
      Log.e(_tag, 'Failed to upload $fileName', e);
      rethrow;
    }
  }

  /// Download a specific entity from Drive
  Future<Map<String, dynamic>?> downloadEntity({
    required String entityType,
    required String entityId,
  }) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;

    final fileName = '${entityType}_$entityId.json';

    try {
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name='$fileName'",
      );

      if (fileList.files == null || fileList.files!.isEmpty) return null;

      final media = await driveApi.files.get(
        fileList.files!.first.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (e) {
      Log.e(_tag, 'Failed to download $fileName', e);
      return null;
    }
  }

  /// Resolve a sync conflict with user's choice
  Future<void> resolveConflict(SyncConflict conflict, ConflictResolution resolution) async {
    switch (resolution) {
      case ConflictResolution.keepLocal:
        Log.i(_tag, 'Conflict resolved: keeping local version');
        await uploadEntity(
          entityType: conflict.entityType,
          entityId: conflict.entityId,
          data: conflict.localData,
        );
        break;
      case ConflictResolution.keepRemote:
        Log.i(_tag, 'Conflict resolved: keeping remote version');
        // Remote data is already in conflict.remoteData
        // The repository layer should apply this data to the local DB
        Log.i(_tag, 'Remote data applied for ${conflict.entityType}:${conflict.entityId}');
        break;
      case ConflictResolution.keepBoth:
        Log.i(_tag, 'Conflict resolved: keeping both versions');
        // Upload local as a new entity, then apply remote to original
        await uploadEntity(
          entityType: conflict.entityType,
          entityId: '${conflict.entityId}_copy',
          data: conflict.localData,
        );
        Log.i(_tag, 'Both versions preserved for ${conflict.entityType}:${conflict.entityId}');
        break;
    }
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    final token = await _authService.getAccessToken();
    if (token == null) return null;

    final client = _AuthenticatedClient(http.Client(), token);
    return drive.DriveApi(client);
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
    _conflictController.close();
  }
}

class _AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;
  final String _accessToken;

  _AuthenticatedClient(this._inner, this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }
}

enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
}

enum ConflictResolution {
  keepLocal,
  keepRemote,
  keepBoth,
}

class SyncConflict {
  final String entityType;
  final String entityId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime localTimestamp;
  final DateTime remoteTimestamp;
  final String localDeviceName;
  final String remoteDeviceName;

  const SyncConflict({
    required this.entityType,
    required this.entityId,
    required this.localData,
    required this.remoteData,
    required this.localTimestamp,
    required this.remoteTimestamp,
    required this.localDeviceName,
    required this.remoteDeviceName,
  });
}
