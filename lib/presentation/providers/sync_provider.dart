import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/sync_service.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final isar = ref.watch(isarProvider);
  final service = SyncService(authService: authService, isar: isar);
  ref.onDispose(() => service.dispose());
  return service;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.syncStatusStream;
});

final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.lastSyncTime;
});
