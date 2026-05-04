import 'dart:io';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/logger.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import '../models/sync_queue.dart';
import 'sync_queue_repository.dart';

class ConversationRepository {
  static const _tag = 'ConversationRepo';
  final Isar _isar;
  final _uuid = const Uuid();
  SyncQueueRepository? _syncQueue;

  ConversationRepository({required Isar isar, SyncQueueRepository? syncQueue})
      : _isar = isar,
        _syncQueue = syncQueue;

  /// Create a new conversation
  Future<Conversation> createConversation({
    required String acornId,
    String title = 'New Chat',
  }) async {
    final now = DateTime.now();
    final conversation = Conversation()
      ..uuid = _uuid.v4()
      ..acornId = acornId
      ..title = title
      ..createdAt = now
      ..updatedAt = now
      ..lastModifiedBy = _deviceId;

    await _isar.writeTxn(() async {
      await _isar.conversations.put(conversation);
    });

    Log.i(_tag, 'Created conversation: ${conversation.uuid}');

    _syncQueue?.enqueue(
      entityType: 'conversation',
      entityId: conversation.uuid,
      action: SyncAction.create,
      entityJson: conversation.toJson(),
    );

    return conversation;
  }

  /// Get all conversations for an acorn, sorted by most recent
  Future<List<Conversation>> getConversationsForAcorn(
    String acornId, {
    bool includeArchived = false,
  }) async {
    var query = _isar.conversations
        .filter()
        .acornIdEqualTo(acornId);

    if (!includeArchived) {
      query = query.isArchivedEqualTo(false);
    }

    return query.sortByUpdatedAtDesc().findAll();
  }

  /// Get a single conversation by UUID
  Future<Conversation?> getConversation(String uuid) async {
    return _isar.conversations.filter().uuidEqualTo(uuid).findFirst();
  }

  /// Update conversation title
  Future<void> updateTitle(String uuid, String newTitle) async {
    final conv = await getConversation(uuid);
    if (conv == null) return;

    conv.title = newTitle;
    conv.updatedAt = DateTime.now();
    conv.lastModifiedBy = _deviceId;
    conv.syncVersion++;

    await _isar.writeTxn(() async {
      await _isar.conversations.put(conv);
    });
  }

  /// Pin/unpin a conversation
  Future<void> togglePin(String uuid) async {
    final conv = await getConversation(uuid);
    if (conv == null) return;

    conv.isPinned = !conv.isPinned;
    conv.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.conversations.put(conv);
    });
  }

  /// Archive a conversation (soft delete)
  Future<void> archiveConversation(String uuid) async {
    final conv = await getConversation(uuid);
    if (conv == null) return;

    conv.isArchived = true;
    conv.updatedAt = DateTime.now();
    conv.syncVersion++;

    await _isar.writeTxn(() async {
      await _isar.conversations.put(conv);
    });

    Log.i(_tag, 'Archived conversation: $uuid');
  }

  /// Permanently delete a conversation and all its messages
  Future<void> deleteConversation(String uuid) async {
    final conv = await getConversation(uuid);
    if (conv == null) return;

    // Delete all messages and attachments
    final messages = await getMessages(uuid);
    final messageIds = messages.map((m) => m.id).toList();

    await _isar.writeTxn(() async {
      // Delete attachments for each message
      for (final msg in messages) {
        final attachments = await _isar.attachments
            .filter()
            .messageIdEqualTo(msg.uuid)
            .findAll();
        await _isar.attachments
            .deleteAll(attachments.map((a) => a.id).toList());
      }

      await _isar.messages.deleteAll(messageIds);
      await _isar.conversations.delete(conv.id);
    });

    Log.i(_tag, 'Deleted conversation: $uuid');

    _syncQueue?.enqueue(
      entityType: 'conversation',
      entityId: uuid,
      action: SyncAction.delete,
      entityJson: {'uuid': uuid},
    );
  }

  /// Add a message to a conversation
  Future<Message> addMessage({
    required String conversationId,
    required MessageRole role,
    required String content,
    String? thinkingContent,
    String? toolCallsJson,
    String? toolResultsJson,
  }) async {
    final message = Message()
      ..uuid = _uuid.v4()
      ..conversationId = conversationId
      ..role = role
      ..content = content
      ..thinkingContent = thinkingContent
      ..toolCallsJson = toolCallsJson
      ..toolResultsJson = toolResultsJson
      ..timestamp = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.messages.put(message);

      // Update conversation's updatedAt
      final conv = await _isar.conversations
          .filter()
          .uuidEqualTo(conversationId)
          .findFirst();
      if (conv != null) {
        conv.updatedAt = DateTime.now();
        conv.lastModifiedBy = _deviceId;
        conv.syncVersion++;
        await _isar.conversations.put(conv);
      }
    });

    return message;
  }

  /// Get all messages for a conversation, ordered by timestamp
  Future<List<Message>> getMessages(String conversationId) async {
    return _isar.messages
        .filter()
        .conversationIdEqualTo(conversationId)
        .sortByTimestamp()
        .findAll();
  }

  /// Edit a message's content
  Future<void> editMessage(String uuid, String newContent) async {
    final msg = await _isar.messages.filter().uuidEqualTo(uuid).findFirst();
    if (msg == null) return;

    msg.content = newContent;
    msg.isEdited = true;

    await _isar.writeTxn(() async {
      await _isar.messages.put(msg);
    });
  }

  /// Delete a message
  Future<void> deleteMessage(String uuid) async {
    final msg = await _isar.messages.filter().uuidEqualTo(uuid).findFirst();
    if (msg == null) return;

    await _isar.writeTxn(() async {
      // Delete attachments
      final attachments = await _isar.attachments
          .filter()
          .messageIdEqualTo(uuid)
          .findAll();
      await _isar.attachments.deleteAll(attachments.map((a) => a.id).toList());
      await _isar.messages.delete(msg.id);
    });
  }

  /// Search conversations by title or message content
  Future<List<Conversation>> searchConversations(String query) async {
    final lowerQuery = query.toLowerCase();

    // Search by title
    final byTitle = await _isar.conversations
        .filter()
        .titleContains(lowerQuery, caseSensitive: false)
        .isArchivedEqualTo(false)
        .findAll();

    // Search by message content
    final messages = await _isar.messages
        .filter()
        .contentContains(lowerQuery, caseSensitive: false)
        .findAll();

    final convIds = messages.map((m) => m.conversationId).toSet();
    final byContent = <Conversation>[];
    for (final id in convIds) {
      final conv = await getConversation(id);
      if (conv != null && !conv.isArchived) byContent.add(conv);
    }

    // Merge and deduplicate
    final all = <String, Conversation>{};
    for (final c in byTitle) {
      all[c.uuid] = c;
    }
    for (final c in byContent) {
      all[c.uuid] = c;
    }

    final results = all.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return results;
  }

  /// Auto-generate a title from the first message
  Future<void> autoTitle(String conversationId) async {
    final messages = await getMessages(conversationId);
    final firstUserMsg = messages.where((m) => m.role == MessageRole.user).firstOrNull;

    if (firstUserMsg != null) {
      final title = firstUserMsg.content.length > 50
          ? '${firstUserMsg.content.substring(0, 50)}...'
          : firstUserMsg.content;
      await updateTitle(conversationId, title);
    }
  }

  String get _deviceId {
    // Simple device identifier for conflict detection
    return '${Platform.localHostname}_${Platform.operatingSystem}';
  }
}
