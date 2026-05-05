import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/agent_mode_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/calendar_service.dart';
import '../../data/services/gmail_service.dart';
import '../../data/services/rag_service.dart';
import '../../data/services/tool_registry.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'model_provider.dart';

final toolRegistryProvider = Provider<ToolRegistry>((ref) {
  final isar = ref.read(isarProvider);
  final authService = ref.read(authServiceProvider);
  return ToolRegistry(
    ragService: RagService(isar: isar),
    calendarService: CalendarService(authService: authService),
    gmailService: GmailService(authService: authService),
  );
});

final agentModeServiceProvider = Provider<AgentModeService>((ref) {
  final inferenceService = ref.watch(inferenceServiceProvider);
  final toolRegistry = ref.watch(toolRegistryProvider);
  return AgentModeService(
    inferenceService: inferenceService,
    toolRegistry: toolRegistry,
  );
});
