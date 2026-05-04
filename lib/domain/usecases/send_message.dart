import '../../data/models/message.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/services/inference_service.dart';
import '../../data/services/rag_service.dart';
import '../../data/models/gem.dart'; // Acorn model

class SendMessageUseCase {
  final ConversationRepository _conversationRepo;
  final InferenceService _inferenceService;
  final RagService _ragService;

  SendMessageUseCase({
    required ConversationRepository conversationRepo,
    required InferenceService inferenceService,
    required RagService ragService,
  })  : _conversationRepo = conversationRepo,
        _inferenceService = inferenceService,
        _ragService = ragService;

  /// Send a user message and generate an AI response
  Stream<String> execute({
    required String conversationId,
    required String userMessage,
    required Acorn acorn,
    bool agentMode = false,
  }) async* {
    // 1. Save user message
    await _conversationRepo.addMessage(
      conversationId: conversationId,
      role: MessageRole.user,
      content: userMessage,
    );

    // 2. Build system prompt with optional RAG context
    String? systemPrompt = acorn.systemPrompt.isNotEmpty ? acorn.systemPrompt : null;

    if (acorn.ragEnabled) {
      final ragResults = await _ragService.search(
        query: userMessage,
        acornId: acorn.uuid,
      );
      if (ragResults.isNotEmpty) {
        final ragContext = _ragService.buildRagContext(ragResults);
        systemPrompt = '${systemPrompt ?? ''}\n\n$ragContext';
      }
    }

    // 3. Get conversation history
    final messages = await _conversationRepo.getMessages(conversationId);
    final chatMessages = messages.map((m) {
      return ChatMessage(
        role: m.role == MessageRole.user
            ? 'user'
            : m.role == MessageRole.assistant
                ? 'assistant'
                : 'tool',
        content: m.content,
      );
    }).toList();

    // 4. Generate and stream response
    final responseBuffer = StringBuffer();

    await for (final token in _inferenceService.generateStream(
      messages: chatMessages,
      agentMode: agentMode,
      systemPrompt: systemPrompt,
    )) {
      responseBuffer.write(token);
      yield token;
    }

    // 5. Save assistant message
    await _conversationRepo.addMessage(
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: responseBuffer.toString(),
    );

    // 6. Auto-title on first exchange
    if (messages.length <= 1) {
      await _conversationRepo.autoTitle(conversationId);
    }
  }
}
