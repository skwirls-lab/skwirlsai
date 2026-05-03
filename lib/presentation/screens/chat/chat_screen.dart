import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/message.dart';
import '../../../data/services/inference_service.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/gem_provider.dart';
import '../../providers/model_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  bool _isStreaming = false;
  bool _agentModeEnabled = false;
  String _streamBuffer = '';

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
    final activeGem = ref.watch(activeGemProvider);
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
          // Agent mode toggle
          IconButton(
            icon: Icon(
              _agentModeEnabled
                  ? Icons.auto_fix_high_rounded
                  : Icons.auto_fix_normal,
              size: 20,
              color: _agentModeEnabled
                  ? AppColors.teal
                  : AppColors.textTertiary,
            ),
            tooltip: _agentModeEnabled ? 'Agent Mode ON' : 'Agent Mode OFF',
            onPressed: () {
              setState(() => _agentModeEnabled = !_agentModeEnabled);
            },
          ),
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
          // Agent mode banner
          if (_agentModeEnabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.teal.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy_rounded,
                      size: 16, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Text(
                    'Agent Mode: AI can use tools and reason step-by-step',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
            ),
          // Messages
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error: $e')),
              data: (messages) {
                // Empty chat — show Gemini-style greeting
                if (messages.isEmpty && !_isStreaming) {
                  return _EmptyChatGreeting(gemName: activeGem?.name);
                }

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
                            decoration: InputDecoration(
                              hintText: _agentModeEnabled
                                  ? 'Ask the agent...'
                                  : 'Message SkwirlsAI...',
                              hintStyle: AppTextStyles.chatMessage.copyWith(
                                color: AppColors.textTertiary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
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
                              backgroundColor: _textController.text.trim().isEmpty
                                  ? AppColors.surfaceHighlight
                                  : AppColors.amber,
                              foregroundColor: _textController.text.trim().isEmpty
                                  ? AppColors.textTertiary
                                  : AppColors.textOnAmber,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _sendMessage,
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

    // Save user message
    final convRepo = ref.read(conversationRepositoryProvider);
    await convRepo.addMessage(
      conversationId: activeConv.uuid,
      role: MessageRole.user,
      content: text,
    );

    // Refresh messages
    ref.invalidate(messagesForConversationProvider(activeConv.uuid));
    ref.invalidate(conversationsForGemProvider(activeConv.gemId));

    // Generate response
    await _generateResponse(activeConv.uuid);

    // Auto-title after first full exchange (user + assistant)
    final updatedMessages = await convRepo.getMessages(activeConv.uuid);
    if (updatedMessages.length == 2) {
      _autoTitleWithLLM(activeConv.uuid, text);
    }
  }

  Future<void> _generateResponse(String conversationId) async {
    final inferenceService = ref.read(inferenceServiceProvider);
    if (!inferenceService.isModelLoaded) {
      _showSnackBar('No model connected. Go to Settings > Model to connect.');
      return;
    }

    final convRepo = ref.read(conversationRepositoryProvider);
    final activeGem = ref.read(activeGemProvider);
    final settings = ref.read(settingsProvider);
    final messages = await convRepo.getMessages(conversationId);

    // Build chat messages for inference — send full conversation context
    final chatMessages = messages.map((m) => ChatMessage(
          role: m.role == MessageRole.user
              ? 'user'
              : m.role == MessageRole.assistant
                  ? 'assistant'
                  : 'system',
          content: m.content,
        )).toList();

    // Build system prompt: gem prompt + app context
    final systemPrompt = _buildSystemPrompt(activeGem, settings);

    setState(() {
      _isStreaming = true;
      _streamBuffer = '';
    });

    _scrollToBottom();

    try {
      await for (final token in inferenceService.generateStream(
        messages: chatMessages,
        agentMode: _agentModeEnabled,
        systemPrompt: systemPrompt,
      )) {
        setState(() {
          _streamBuffer += token;
        });
        _scrollToBottom();
      }

      // Save assistant message
      if (_streamBuffer.isNotEmpty) {
        await convRepo.addMessage(
          conversationId: conversationId,
          role: MessageRole.assistant,
          content: _streamBuffer,
        );
      }

      ref.invalidate(messagesForConversationProvider(conversationId));
    } catch (e) {
      _showSnackBar('Generation error: $e');
    } finally {
      setState(() {
        _isStreaming = false;
        _streamBuffer = '';
      });
    }
  }

  String _buildSystemPrompt(dynamic activeGem, dynamic settings) {
    final inferenceService = ref.read(inferenceServiceProvider);
    final buf = StringBuffer();

    // Gem-specific system prompt
    if (activeGem != null && activeGem.systemPrompt != null &&
        (activeGem.systemPrompt as String).isNotEmpty) {
      buf.writeln(activeGem.systemPrompt);
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
      ref.invalidate(conversationsForGemProvider(activeConv.gemId));
    }
  }

  void _stopGeneration() {
    ref.read(inferenceServiceProvider).stopGeneration();
    setState(() => _isStreaming = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentPicker() {
    // TODO: Show attachment picker bottom sheet
    _showSnackBar('Attachment picker coming soon');
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
            conversationsForGemProvider(activeConv.gemId));
        break;
      case 'archive':
        convRepo.archiveConversation(activeConv.uuid);
        ref.read(activeConversationProvider.notifier).state = null;
        ref.invalidate(
            conversationsForGemProvider(activeConv.gemId));
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
                      conversationsForGemProvider(activeConv.gemId));
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

/// Gemini-inspired empty chat greeting with subtle gradient background
class _EmptyChatGreeting extends StatelessWidget {
  final String? gemName;

  const _EmptyChatGreeting({this.gemName});

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
                  gemName != null && gemName != 'General Assistant'
                      ? 'How can $gemName help you?'
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

/// Subtle halftone dot pattern painter (inspired by Gemini's bg)
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
