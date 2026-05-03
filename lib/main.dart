import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'data/models/conversation.dart';
import 'data/models/message.dart';
import 'data/models/gem.dart';
import 'data/models/document.dart';
import 'data/models/attachment.dart';
import 'data/models/sync_queue.dart';
import 'data/repositories/gem_repository.dart';
import 'data/services/auth_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/database_provider.dart';
import 'presentation/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar database
  final dir = await getApplicationSupportDirectory();
  final isar = await Isar.open(
    [
      ConversationSchema,
      MessageSchema,
      GemSchema,
      DocumentSchema,
      ChunkSchema,
      AttachmentSchema,
      SyncQueueItemSchema,
    ],
    directory: dir.path,
    name: 'skwirlsai',
  );

  // Initialize default gems
  final gemRepo = GemRepository(isar: isar);
  await gemRepo.initializeDefaults();

  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize auth service
  final authService = AuthService();
  await authService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        sharedPrefsProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(authService),
      ],
      child: const SkwirlsApp(),
    ),
  );
}
