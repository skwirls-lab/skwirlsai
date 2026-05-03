import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/tool.dart';

class ToolCallCard extends StatefulWidget {
  final ToolCall call;
  final ToolResult? result;
  final bool isExecuting;
  final bool requiresConfirmation;
  final VoidCallback? onConfirm;
  final VoidCallback? onDecline;

  const ToolCallCard({
    super.key,
    required this.call,
    this.result,
    this.isExecuting = false,
    this.requiresConfirmation = false,
    this.onConfirm,
    this.onDecline,
  });

  @override
  State<ToolCallCard> createState() => _ToolCallCardState();
}

class _ToolCallCardState extends State<ToolCallCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasResult = widget.result != null;
    final isSuccess = hasResult && widget.result!.success;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.isExecuting
              ? AppColors.amber
              : hasResult
                  ? (isSuccess ? AppColors.success : AppColors.error)
                  : widget.requiresConfirmation
                      ? AppColors.warning
                      : AppColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Status icon
                  if (widget.isExecuting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (hasResult)
                    Icon(
                      isSuccess
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      size: 16,
                      color: isSuccess ? AppColors.success : AppColors.error,
                    )
                  else if (widget.requiresConfirmation)
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: AppColors.warning,
                    )
                  else
                    const Icon(
                      Icons.build_rounded,
                      size: 16,
                      color: AppColors.teal,
                    ),
                  const SizedBox(width: 8),
                  // Tool name
                  Expanded(
                    child: Text(
                      widget.call.toolName,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Execution time
                  if (hasResult)
                    Text(
                      '${widget.result!.executionTime.inMilliseconds}ms',
                      style: AppTextStyles.labelSmall,
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          // Confirmation buttons
          if (widget.requiresConfirmation && !hasResult && !widget.isExecuting)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Text(
                    'Allow this tool to run?',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onDecline,
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: widget.onConfirm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Allow'),
                  ),
                ],
              ),
            ),
          // Expanded details
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Arguments:', style: AppTextStyles.labelSmall),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SelectableText(
                      widget.call.arguments.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join('\n'),
                      style: AppTextStyles.code,
                    ),
                  ),
                  if (hasResult) ...[
                    const SizedBox(height: 8),
                    Text('Result:', style: AppTextStyles.labelSmall),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          widget.result!.output,
                          style: AppTextStyles.code.copyWith(
                            color: isSuccess
                                ? AppColors.textPrimary
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
