import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/conversation.dart';
import '../../data/models/message.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/repositories/sync_queue_repository.dart';
import 'database_provider.dart';

final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return SyncQueueRepository(isar: isar);
});

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  final isar = ref.watch(isarProvider);
  final syncQueue = ref.watch(syncQueueRepositoryProvider);
  return ConversationRepository(isar: isar, syncQueue: syncQueue);
});

final conversationsForAcornProvider =
    FutureProvider.family<List<Conversation>, String>((ref, acornId) async {
  final repo = ref.watch(conversationRepositoryProvider);
  return repo.getConversationsForAcorn(acornId);
});

final activeConversationProvider = StateProvider<Conversation?>((ref) => null);

final messagesForConversationProvider =
    FutureProvider.family<List<Message>, String>((ref, conversationId) async {
  final repo = ref.watch(conversationRepositoryProvider);
  return repo.getMessages(conversationId);
});

final searchResultsProvider =
    FutureProvider.family<List<Conversation>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repo = ref.watch(conversationRepositoryProvider);
  return repo.searchConversations(query);
});
