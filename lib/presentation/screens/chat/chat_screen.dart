import 'dart:io';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/message.dart';
import '../../../data/services/agent_mode_service.dart';
import '../../../data/services/inference_service.dart';
import '../../../data/services/rag_service.dart';
import '../../../domain/entities/tool.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/gem_provider.dart';
import '../../providers/model_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tool_provider.dart';
import '../../widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const _specialTokens = [
    '<|im_end|>', '<|im_start|>',
    '<end_of_turn>', '<start_of_turn>',
    '<eos>', '<bos>',
  ];

  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  bool _isStreaming = false;
  String _streamBuffer = '';
  bool _hasText = false;
  List<String> _attachedFiles = []; // file names of just-attached docs
  Map<String, String> _attachedFilePaths = {}; // name -> path

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final has = _textController.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    // Enter to send, Shift+Enter for newline
    _focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.isShiftPressed) {
        if (_hasText && !_isStreaming) {
          _sendMessage();
        }
        return KeyEventResult.handled; // consume the Enter
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeConv = ref.watch(activeConversationProvider);
    final activeAcorn = ref.watch(activeAcornProvider);
    final isModelLoaded = ref.watch(isModelLoadedProvider);

    if (activeConv == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_outlined, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                'Start a new conversation',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a chat from the sidebar or create one',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final messagesAsync =
        ref.watch(messagesForConversationProvider(activeConv.uuid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          activeConv.title,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz_rounded,
                size: 20, color: AppColors.textTertiary),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'rename', child: Text('Rename')),
              const PopupMenuItem(value: 'pin', child: Text('Pin/Unpin')),
              const PopupMenuItem(value: 'archive', child: Text('Archive')),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error: $e')),
              data: (messages) {
                // Empty chat — show Acorn-style greeting
                if (messages.isEmpty && !_isStreaming) {
                  return _EmptyChatGreeting(acornName: activeAcorn?.name);
                }

                // Scroll to bottom whenever messages data arrives
                // (covers initial load, returning to chat, new messages)
                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length + (_isStreaming ? 1 : 0),
                  itemBuilder: (_, index) {
                    if (index == messages.length && _isStreaming) {
                      // Streaming message
                      final streamMsg = Message()
                        ..uuid = 'streaming'
                        ..conversationId = activeConv.uuid
                        ..role = MessageRole.assistant
                        ..content = _streamBuffer
                        ..timestamp = DateTime.now();

                      return MessageBubble(
                        message: streamMsg,
                        isStreaming: true,
                      );
                    }

                    return MessageBubble(
                      message: messages[index],
                      onCopy: () => _showSnackBar('Copied to clipboard'),
                      onEdit: messages[index].role == MessageRole.user
                          ? () => _editMessage(messages[index])
                          : null,
                      onDelete: () => _deleteMessage(messages[index]),
                      onRegenerate:
                          messages[index].role == MessageRole.assistant
                              ? () => _regenerateMessage(messages[index])
                              : null,
                    );
                  },
                );
              },
            ),
          ),
          // Model status
          if (!isModelLoaded)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 768),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link_off_rounded,
                          size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 8),
                      Text(
                        'No model connected',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textTertiary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '- Settings > Model',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Attached file chips
          if (_attachedFiles.isNotEmpty)
            Container(
              color: AppColors.background,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 768),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _attachedFiles.map((name) {
                        return Chip(
                          avatar: const Icon(Icons.description_outlined,
                              size: 16, color: AppColors.teal),
                          label: Text(name, style: AppTextStyles.bodySmall),
                          backgroundColor: AppColors.surfaceLight,
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () {
                            setState(() {
                              _attachedFiles.remove(name);
                              _attachedFilePaths.remove(name);
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: AppColors.teal.withOpacity(0.4)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(width: 4),
                        // Attachment
                        IconButton(
                          icon: const Icon(Icons.add_rounded, size: 20),
                          color: AppColors.textTertiary,
                          onPressed: _showAttachmentPicker,
                          tooltip: 'Attach',
                        ),
                        // Text input
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            maxLines: 6,
                            minLines: 1,
                            style: AppTextStyles.chatMessage,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              hintText: 'Message SkwirlsAI...',
                              hintStyle: AppTextStyles.chatMessage.copyWith(
                                color: AppColors.textTertiary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        // Send / Stop
                        if (_isStreaming)
                          IconButton(
                            icon: const Icon(Icons.stop_rounded, size: 22),
                            color: AppColors.textSecondary,
                            onPressed: _stopGeneration,
                            tooltip: 'Stop generating',
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: _hasText
                                  ? AppColors.amber
                                  : AppColors.surfaceHighlight,
                              foregroundColor: _hasText
                                  ? AppColors.textOnAmber
                                  : AppColors.textTertiary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _hasText ? _sendMessage : null,
                            tooltip: 'Send message',
                          ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final activeConv = ref.read(activeConversationProvider);
    if (activeConv == null) return;

    _textController.clear();
    final sentFiles = List<String>.from(_attachedFiles);
    final sentFilePaths = Map<String, String>.from(_attachedFilePaths);
    debugPrint('[RAG] _sendMessage: sentFiles=$sentFiles sentFilePaths=$sentFilePaths');
    setState(() {
      _attachedFiles.clear();
      _attachedFilePaths.clear();
    });

    // Save user message (with attachment info)
    final convRepo = ref.read(conversationRepositoryProvider);
    await convRepo.addMessage(
      conversationId: activeConv.uuid,
      role: MessageRole.user,
      content: text,
      attachmentIds: sentFiles.isNotEmpty ? sentFiles.join(',') : null,
    );

    // Refresh messages
    ref.invalidate(messagesForConversationProvider(activeConv.uuid));
    ref.invalidate(conversationsForAcornProvider(activeConv.acornId));

    // Generate response
    await _generateResponse(activeConv.uuid, attachedFilePaths: sentFilePaths);

    // Auto-title after first full exchange (user + assistant)
    final updatedMessages = await convRepo.getMessages(activeConv.uuid);
    if (updatedMessages.length == 2) {
      _autoTitleWithLLM(activeConv.uuid, text);
    }
  }

  Future<void> _generateResponse(String conversationId,
      {Map<String, String> attachedFilePaths = const {}}) async {
    final inferenceService = ref.read(inferenceServiceProvider);
    final modelLoaded = ref.read(isModelLoadedProvider);
    if (!modelLoaded || !inferenceService.isModelLoaded) {
      _showSnackBar('No model connected. Go to Models to load one.');
      return;
    }

    final convRepo = ref.read(conversationRepositoryProvider);
    final activeAcorn = ref.read(activeAcornProvider);
    final settings = ref.read(settingsProvider);
    final messages = await convRepo.getMessages(conversationId);

    // Apply generation settings to inference service
    inferenceService.temperature = settings.temperature;
    inferenceService.topP = settings.topP;
    inferenceService.topK = settings.topK;
    inferenceService.maxTokens = settings.maxTokens;
    inferenceService.repeatPenalty = settings.repeatPenalty;

    // Build chat messages for inference — send full conversation context
    final chatMessages = messages.map((m) => ChatMessage(
          role: m.role == MessageRole.user
              ? 'user'
              : m.role == MessageRole.assistant
                  ? 'assistant'
                  : 'system',
          content: m.content,
        )).toList();

    // If files were attached with this prompt, read their content directly
    String? fileContext;
    if (attachedFilePaths.isNotEmpty) {
      final buf = StringBuffer();
      buf.writeln('[Attached file contents:]');
      for (final entry in attachedFilePaths.entries) {
        try {
          final file = File(entry.value);
          debugPrint('[RAG] Reading file: ${entry.value} exists=${await file.exists()}');
          final content = await file.readAsString();
          debugPrint('[RAG] File "${entry.key}" read OK, ${content.length} chars');
          buf.writeln('--- File: ${entry.key} ---');
          // Limit per file to avoid blowing the context window
          final trimmed = content.length > 8000
              ? '${content.substring(0, 8000)}\n[...truncated]'
              : content;
          buf.writeln(trimmed);
        } catch (e) {
          debugPrint('[RAG] File read error for "${entry.key}": $e');
          buf.writeln('--- File: ${entry.key} (read error: $e) ---');
        }
      }
      buf.writeln('[End of attached files]');
      fileContext = buf.toString();
      debugPrint('[RAG] fileContext length: ${fileContext.length}');
    }

    // If RAG is enabled, search documents for relevant context
    String? ragContext;
    if (activeAcorn != null) {
      final freshAcorn = await ref.read(acornRepositoryProvider).getAcorn(activeAcorn.uuid);
      if (freshAcorn != null && freshAcorn.ragEnabled) {
        final isar = ref.read(isarProvider);
        final ragService = RagService(isar: isar);
        final lastUserMsg = messages.lastWhere(
          (m) => m.role == MessageRole.user,
          orElse: () => messages.last,
        );
        final results = await ragService.searchBM25(
          query: lastUserMsg.content,
          acornId: activeAcorn.uuid,
        );
        if (results.isNotEmpty) {
          ragContext = ragService.buildRagContext(results);
        }
      }
    }

    // Combine file context with RAG context
    final combinedContext = [
      if (fileContext != null) fileContext,
      if (ragContext != null) ragContext,
    ].join('\n');

    debugPrint('[RAG] combinedContext length: ${combinedContext.length}');

    // Build system prompt: acorn prompt + RAG context + app context
    final systemPrompt = _buildSystemPrompt(activeAcorn, settings,
        ragContext: combinedContext.isNotEmpty ? combinedContext : null);
    debugPrint('[RAG] systemPrompt length: ${systemPrompt.length}');

    setState(() {
      _isStreaming = true;
      _streamBuffer = '';
    });

    _scrollToBottom();

    try {
      // Check if active acorn has any enabled + permitted skills
      final acornSkills = activeAcorn?.enabledSkills ?? '';
      debugPrint('[SkwirlSkills] activeAcorn: ${activeAcorn?.name}, enabledSkills: "$acornSkills"');
      final acornSkillSet = acornSkills.split(',')
          .where((s) => s.trim().isNotEmpty).toSet();
      final globalPerms = ref.read(skillPermissionsProvider);
      debugPrint('[SkwirlSkills] acornSkillSet: $acornSkillSet');
      debugPrint('[SkwirlSkills] globalPerms: ${globalPerms.map((k, v) => MapEntry(k, v.isAllowed))}');
      final hasSkills = acornSkillSet.any((name) {
        final perm = globalPerms[name];
        return perm != null && perm.isAllowed;
      });
      debugPrint('[SkwirlSkills] hasSkills=$hasSkills → ${hasSkills ? "AGENT MODE" : "NORMAL MODE"}');

      if (hasSkills) {
        // Acorn has SkwirlSkills: use AgentModeService for tool calling loop
        await _runAgentMode(
          conversationId: conversationId,
          chatMessages: chatMessages,
          systemPrompt: systemPrompt,
          convRepo: convRepo,
        );
      } else {
        // Normal mode: simple streaming
        await for (final token in inferenceService.generateStream(
          messages: chatMessages,
          systemPrompt: systemPrompt,
        )) {
          setState(() {
            _streamBuffer += token;
          });
          _scrollToBottom();
        }

        // Strip any leaked special tokens from the final response
        var finalText = _streamBuffer;
        for (final tok in _specialTokens) {
          finalText = finalText.replaceAll(tok, '');
        }
        finalText = finalText.trim();

        // Save assistant message
        if (finalText.isNotEmpty) {
          await convRepo.addMessage(
            conversationId: conversationId,
            role: MessageRole.assistant,
            content: finalText,
          );
        } else {
          _showSnackBar('Model returned an empty response. '
              'Try a shorter prompt or increase the context size in Settings.');
        }

        ref.invalidate(messagesForConversationProvider(conversationId));
        // Wait for the provider to rebuild before hiding the streaming bubble
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Context full') || msg.contains('Context limit') ||
          msg.contains('Prompt too large')) {
        _showSnackBar('Prompt too long for current context window. '
            'Increase Context Size in Settings or start a new conversation.');
      } else {
        _showSnackBar('Generation error: $msg');
      }
    } finally {
      setState(() {
        _isStreaming = false;
        _streamBuffer = '';
      });
      _scrollToBottom();
    }
  }

  /// Run agent mode: generate → parse tool calls → execute → loop
  Future<void> _runAgentMode({
    required String conversationId,
    required List<ChatMessage> chatMessages,
    required String systemPrompt,
    required dynamic convRepo,
  }) async {
    final agentService = ref.read(agentModeServiceProvider);
    final skillPerms = ref.read(skillPermissionsProvider);

    // Compute allowed tools: acorn enablement ∩ global permissions
    final activeAcorn = ref.read(activeAcornProvider);
    final acornSkillNames = (activeAcorn?.enabledSkills ?? '')
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .toSet();
    final allowedTools = acornSkillNames.where((name) {
      final perm = skillPerms[name];
      return perm != null && perm.isAllowed;
    }).toSet();

    debugPrint('[Agent] Allowed tools: $allowedTools');

    // Set up confirmation callback
    agentService.onConfirmationRequired = (call) async {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tool Requires Confirmation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('The agent wants to execute:',
                  style: AppTextStyles.body),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(call.toolName,
                        style: AppTextStyles.label.copyWith(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(call.arguments.toString(),
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Deny'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal),
              child: const Text('Allow'),
            ),
          ],
        ),
      );
      return result ?? false;
    };

    String finalText = '';
    String? thinkingContent;
    final toolLog = StringBuffer();

    await for (final event in agentService.run(
      messages: chatMessages,
      systemPrompt: systemPrompt,
      allowedToolNames: allowedTools.isNotEmpty ? allowedTools : null,
    )) {
      switch (event.type) {
        case AgentEventType.token:
          setState(() {
            _streamBuffer += event.text ?? '';
          });
          _scrollToBottom();
          break;

        case AgentEventType.thinking:
          debugPrint('[Agent] Iteration ${event.iteration}');
          break;

        case AgentEventType.thinkingContent:
          thinkingContent = event.text;
          break;

        case AgentEventType.toolExecuting:
          final call = event.toolCall!;
          debugPrint('[Agent] Executing tool: ${call.toolName}');
          // Show tool execution in the stream
          setState(() {
            _streamBuffer += '\n🔧 *Using ${call.toolName}...*\n';
          });
          _scrollToBottom();
          break;

        case AgentEventType.toolResult:
          final result = event.result!;
          debugPrint('[Agent] Tool result: ${result.success} (${result.output.length} chars)');
          toolLog.writeln('Tool: ${result.toolName}');
          toolLog.writeln('Success: ${result.success}');
          toolLog.writeln('Output: ${result.output.length > 200 ? '${result.output.substring(0, 200)}...' : result.output}');
          toolLog.writeln('---');
          break;

        case AgentEventType.confirmationRequired:
          debugPrint('[Agent] Confirmation required for: ${event.toolCall?.toolName}');
          break;

        case AgentEventType.finalAnswer:
          finalText = event.text ?? '';
          break;

        case AgentEventType.maxIterationsReached:
          _showSnackBar('Agent reached max iterations');
          finalText = _streamBuffer;
          break;

        case AgentEventType.stopped:
          finalText = _streamBuffer;
          break;

        case AgentEventType.error:
          _showSnackBar('Agent error: ${event.text}');
          finalText = _streamBuffer;
          break;
      }
    }

    // Strip special tokens
    for (final tok in _specialTokens) {
      finalText = finalText.replaceAll(tok, '');
    }
    // Strip tool-use indicators from final saved text
    finalText = finalText.replaceAll(RegExp(r'🔧 \*Using [^*]+\.\.\.\*\n?'), '');
    finalText = finalText.trim();

    // Save assistant message with tool info
    if (finalText.isNotEmpty) {
      await convRepo.addMessage(
        conversationId: conversationId,
        role: MessageRole.assistant,
        content: finalText,
        thinkingContent: thinkingContent,
        toolCallsJson: toolLog.isNotEmpty ? toolLog.toString() : null,
      );
    }

    ref.invalidate(messagesForConversationProvider(conversationId));
    await Future.delayed(const Duration(milliseconds: 100));
  }

  String _buildSystemPrompt(dynamic activeAcorn, dynamic settings, {String? ragContext}) {
    final inferenceService = ref.read(inferenceServiceProvider);
    final buf = StringBuffer();

    // Acorn-specific system prompt
    if (activeAcorn != null && activeAcorn.systemPrompt != null &&
        (activeAcorn.systemPrompt as String).isNotEmpty) {
      buf.writeln(activeAcorn.systemPrompt);
      buf.writeln();
    } else {
      buf.writeln(
          'You are SkwirlsAI, a helpful, knowledgeable, and concise AI assistant.');
      buf.writeln(
          'You provide clear, accurate answers. Use markdown formatting '
          'when appropriate: headings, bold, italic, code blocks, lists, etc.');
      buf.writeln();
    }

    // Model identity context
    final modelName = inferenceService.activeModelName;
    final providerName = inferenceService.providerName;
    if (modelName != null && modelName.isNotEmpty) {
      buf.writeln('You are running as model: $modelName (via $providerName).');
      buf.writeln(
          'When asked what model you are, tell the user your model name '
          'and that you are accessed through the SkwirlsAI app.');
    } else {
      buf.writeln('You are accessed through the SkwirlsAI app.');
    }
    buf.writeln();

    // App context
    buf.writeln('Current date: ${DateTime.now().toIso8601String().split('T')[0]}');
    buf.writeln('Platform: ${_getPlatformName()}');
    buf.writeln();

    // RAG context from documents
    if (ragContext != null && ragContext.isNotEmpty) {
      buf.writeln(ragContext);
      buf.writeln();
      buf.writeln('Use the above document context to inform your answer when relevant.');
      buf.writeln('If the context does not contain the answer, say so and answer from your general knowledge.');
      buf.writeln();
    }

    // Behavioral guidelines
    buf.writeln('Guidelines:');
    buf.writeln('- Format responses using Markdown when helpful');
    buf.writeln('- Use code blocks with language tags for code');
    buf.writeln('- Be concise but thorough');
    buf.writeln('- If unsure, say so honestly');

    return buf.toString();
  }

  String _getPlatformName() {
    // Simple platform detection
    try {
      if (identical(0, 0.0)) return 'Web';
    } catch (_) {}
    return 'Desktop';
  }

  Future<void> _autoTitleWithLLM(String conversationId, String userMessage) async {
    final inferenceService = ref.read(inferenceServiceProvider);
    if (!inferenceService.isModelLoaded) {
      // Fallback: truncate user message
      final convRepo = ref.read(conversationRepositoryProvider);
      await convRepo.autoTitle(conversationId);
      _refreshConversationList();
      return;
    }

    try {
      final titleBuf = StringBuffer();
      await for (final token in inferenceService.generateStream(
        messages: [
          ChatMessage(
            role: 'user',
            content: userMessage,
          ),
        ],
        systemPrompt:
            'Generate a very short title (3-6 words, no quotes, no punctuation at the end) '
            'that summarizes this conversation topic. Respond with ONLY the title, nothing else.',
      )) {
        titleBuf.write(token);
        // Safety: stop if it gets too long
        if (titleBuf.length > 60) break;
      }

      var title = titleBuf.toString().trim();
      // Clean up: remove quotes, trailing punctuation
      title = title.replaceAll(RegExp(r"""^["']+|["']+$"""), '');
      title = title.replaceAll(RegExp(r'[.!]+$'), '');
      if (title.length > 50) title = '${title.substring(0, 50)}...';
      if (title.isEmpty) title = 'New Chat';

      final convRepo = ref.read(conversationRepositoryProvider);
      await convRepo.updateTitle(conversationId, title);
      _refreshConversationList();
    } catch (e) {
      // Fallback on error
      final convRepo = ref.read(conversationRepositoryProvider);
      await convRepo.autoTitle(conversationId);
      _refreshConversationList();
    }
  }

  void _refreshConversationList() {
    final activeConv = ref.read(activeConversationProvider);
    if (activeConv != null) {
      ref.invalidate(conversationsForAcornProvider(activeConv.acornId));
    }
  }

  void _stopGeneration() {
    ref.read(inferenceServiceProvider).stopGeneration();
    setState(() => _isStreaming = false);
  }

  void _scrollToBottom({bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(target,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut);
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _showAttachmentPicker() async {
    final activeConv = ref.read(activeConversationProvider);
    if (activeConv == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'pdf', 'docx', 'csv', 'json'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      final isar = ref.read(isarProvider);
      final ragService = RagService(isar: isar);
      final acornId = activeConv.acornId;

      int ingested = 0;
      for (final file in result.files) {
        if (file.path == null) continue;
        try {
          await ragService.ingestDocument(
            filePath: file.path!,
            acornId: acornId,
          );
          ingested++;
        } catch (e) {
          _showSnackBar('Failed to ingest ${file.name}: $e');
        }
      }

      if (ingested > 0) {
        // Auto-enable RAG on this acorn if not already enabled
        final activeAcorn = ref.read(activeAcornProvider);
        if (activeAcorn != null && !activeAcorn.ragEnabled) {
          activeAcorn.ragEnabled = true;
          final acornRepo = ref.read(acornRepositoryProvider);
          await acornRepo.updateAcorn(activeAcorn);
          // Refresh the provider so _generateResponse sees ragEnabled=true
          ref.invalidate(allAcornsProvider);
        }

        // Show file chips above the input
        setState(() {
          for (final f in result.files) {
            if (f.name.isNotEmpty && !_attachedFiles.contains(f.name)) {
              _attachedFiles.add(f.name);
              if (f.path != null) _attachedFilePaths[f.name] = f.path!;
            }
          }
        });

        _showSnackBar(
          '$ingested file${ingested > 1 ? 's' : ''} attached',
        );
      }
    } catch (e) {
      _showSnackBar('File picker error: $e');
    }
  }

  void _editMessage(Message message) {
    _textController.text = message.content;
    _focusNode.requestFocus();
  }

  Future<void> _deleteMessage(Message message) async {
    final convRepo = ref.read(conversationRepositoryProvider);
    await convRepo.deleteMessage(message.uuid);
    ref.invalidate(
        messagesForConversationProvider(message.conversationId));
  }

  Future<void> _regenerateMessage(Message message) async {
    await _deleteMessage(message);
    await _generateResponse(message.conversationId);
  }

  void _handleMenuAction(String action) {
    final activeConv = ref.read(activeConversationProvider);
    if (activeConv == null) return;

    final convRepo = ref.read(conversationRepositoryProvider);

    switch (action) {
      case 'rename':
        _showRenameDialog(activeConv.uuid);
        break;
      case 'pin':
        convRepo.togglePin(activeConv.uuid);
        ref.invalidate(
            conversationsForAcornProvider(activeConv.acornId));
        break;
      case 'archive':
        convRepo.archiveConversation(activeConv.uuid);
        ref.read(activeConversationProvider.notifier).state = null;
        ref.invalidate(
            conversationsForAcornProvider(activeConv.acornId));
        break;
    }
  }

  void _showRenameDialog(String uuid) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(conversationRepositoryProvider)
                    .updateTitle(uuid, controller.text.trim());
                final activeConv = ref.read(activeConversationProvider);
                if (activeConv != null) {
                  ref.invalidate(
                      conversationsForAcornProvider(activeConv.acornId));
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (mounted) showTopSnackBar(context, message);
  }
}

/// Acorn-inspired empty chat greeting with subtle gradient background
class _EmptyChatGreeting extends StatelessWidget {
  final String? acornName;

  const _EmptyChatGreeting({this.acornName});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background — subtle amber/teal glow at bottom
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, 1.2),
                radius: 1.0,
                colors: [
                  Color(0xFF1A1510), // warm amber-tinted dark
                  Color(0xFF131616), // slight teal-tinted dark
                  Color(0xFF111111), // background
                ],
                stops: [0.0, 0.4, 0.8],
              ),
            ),
          ),
        ),
        // Dot pattern overlay near the bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 200,
          child: CustomPaint(
            painter: _DotPatternPainter(),
          ),
        ),
        // Content
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Sparkle icon
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.amber, AppColors.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                // Greeting text
                Text(
                  _getGreeting(),
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  acornName != null && acornName != 'General Assistant'
                      ? 'How can $acornName help you?'
                      : 'What can I help you with?',
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textSecondary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Subtle halftone dot pattern painter
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42); // deterministic
    final paint = Paint()..style = PaintingStyle.fill;

    // Amber dots
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = 1.0 + rng.nextDouble() * 1.5;
      final alpha = (10 + rng.nextInt(20)).clamp(0, 255);
      paint.color = AppColors.amber.withAlpha(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Teal dots
    for (int i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = 1.0 + rng.nextDouble() * 1.5;
      final alpha = (8 + rng.nextInt(16)).clamp(0, 255);
      paint.color = AppColors.teal.withAlpha(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
