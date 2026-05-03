import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/message.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isStreaming;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRegenerate;

  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.onCopy,
    this.onEdit,
    this.onDelete,
    this.onRegenerate,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _hovering = false;

  bool get _isUser => widget.message.role == MessageRole.user;
  bool get _isSystem => widget.message.role == MessageRole.system;
  bool get _isTool => widget.message.role == MessageRole.tool;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        width: double.infinity,
        color: _isUser ? Colors.transparent : AppColors.surface,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  _Avatar(isUser: _isUser, isSystem: _isSystem, isTool: _isTool),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Role label
                        Text(
                          _isUser
                              ? 'You'
                              : _isSystem
                                  ? 'System'
                                  : _isTool
                                      ? 'Tool'
                                      : 'SkwirlsAI',
                          style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Thinking (collapsible)
                        if (widget.message.thinkingContent != null &&
                            widget.message.thinkingContent!.isNotEmpty)
                          _ThinkingSection(
                              content: widget.message.thinkingContent!),
                        // Message content — markdown for assistant, plain for user
                        if (_isUser)
                          SelectableText(
                            widget.message.content,
                            style: AppTextStyles.chatMessage,
                          )
                        else
                          MarkdownBody(
                            data: widget.message.content,
                            selectable: true,
                            styleSheet: _markdownStyleSheet(context),
                          ),
                        // Streaming indicator
                        if (widget.isStreaming &&
                            widget.message.content.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _StreamingDots(),
                          ),
                        if (widget.isStreaming &&
                            widget.message.content.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _StreamingCursor(),
                          ),
                        // Edited
                        if (widget.message.isEdited)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'edited',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        // Actions row — show on hover or always on mobile
                        if (_hovering || widget.isStreaming)
                          _ActionsRow(
                            isUser: _isUser,
                            isSystem: _isSystem,
                            isTool: _isTool,
                            content: widget.message.content,
                            onCopy: widget.onCopy,
                            onEdit: widget.onEdit,
                            onDelete: widget.onDelete,
                            onRegenerate: widget.onRegenerate,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  MarkdownStyleSheet _markdownStyleSheet(BuildContext context) {
    return MarkdownStyleSheet(
      p: AppTextStyles.chatMessage,
      h1: AppTextStyles.h1,
      h2: AppTextStyles.h2,
      h3: AppTextStyles.h3,
      h4: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w600, fontSize: 15),
      h5: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w600, fontSize: 14),
      h6: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w500, fontSize: 13),
      em: AppTextStyles.chatMessage.copyWith(fontStyle: FontStyle.italic),
      strong:
          AppTextStyles.chatMessage.copyWith(fontWeight: FontWeight.w700),
      blockquote: AppTextStyles.chatMessage.copyWith(
        color: AppColors.textSecondary,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.amber.withAlpha(120),
            width: 3,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      code: TextStyle(
        fontFamily: 'Consolas',
        fontSize: 13,
        color: AppColors.amber,
        backgroundColor: AppColors.surfaceHighlight,
      ),
      codeblockDecoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      codeblockPadding: const EdgeInsets.all(14),
      listBullet: AppTextStyles.chatMessage,
      tableHead: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
      tableBody: AppTextStyles.body,
      tableBorder: TableBorder.all(color: AppColors.divider, width: 1),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      a: AppTextStyles.chatMessage.copyWith(
        color: AppColors.teal,
        decoration: TextDecoration.underline,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool isUser;
  final bool isSystem;
  final bool isTool;

  const _Avatar({
    required this.isUser,
    required this.isSystem,
    required this.isTool,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isUser
            ? AppColors.amber.withAlpha(40)
            : isSystem
                ? AppColors.teal.withAlpha(40)
                : AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Icon(
          isUser
              ? Icons.person_rounded
              : isSystem
                  ? Icons.info_outline_rounded
                  : isTool
                      ? Icons.build_rounded
                      : Icons.auto_awesome_rounded,
          size: 16,
          color: isUser
              ? AppColors.amber
              : isSystem
                  ? AppColors.teal
                  : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final bool isUser;
  final bool isSystem;
  final bool isTool;
  final String content;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRegenerate;

  const _ActionsRow({
    required this.isUser,
    required this.isSystem,
    required this.isTool,
    required this.content,
    this.onCopy,
    this.onEdit,
    this.onDelete,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    if (isSystem || isTool) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionButton(
            icon: Icons.content_copy_rounded,
            tooltip: 'Copy',
            onTap: () {
              Clipboard.setData(ClipboardData(text: content));
              onCopy?.call();
            },
          ),
          if (isUser)
            _ActionButton(
              icon: Icons.edit_outlined,
              tooltip: 'Edit',
              onTap: onEdit,
            ),
          if (!isUser)
            _ActionButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Regenerate',
              onTap: onRegenerate,
            ),
        ],
      ),
    );
  }
}

class _ThinkingSection extends StatefulWidget {
  final String content;

  const _ThinkingSection({required this.content});

  @override
  State<_ThinkingSection> createState() => _ThinkingSectionState();
}

class _ThinkingSectionState extends State<_ThinkingSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  _isExpanded ? 'Hide thinking' : 'Show thinking',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              widget.content,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        if (!_isExpanded) const SizedBox(height: 6),
      ],
    );
  }
}

class _StreamingDots extends StatefulWidget {
  @override
  State<_StreamingDots> createState() => _StreamingDotsState();
}

class _StreamingDotsState extends State<_StreamingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final opacity =
                ((_controller.value + delay) % 1.0 > 0.5) ? 1.0 : 0.3;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _StreamingCursor extends StatefulWidget {
  @override
  State<_StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<_StreamingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Opacity(
        opacity: _controller.value,
        child: Container(
          width: 2,
          height: 16,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 15, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
