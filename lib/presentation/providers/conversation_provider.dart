import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/conversation.dart';
import '../../data/models/message.dart';
import '../../data/repositories/conversation_repository.dart';
import 'database_provider.dart';

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return ConversationRepository(isar: isar);
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
