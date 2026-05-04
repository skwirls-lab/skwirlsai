import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/conversation.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final void Function(TapDownDetails)? onSecondaryTapDown;

  const ConversationTile({
    super.key,
    required this.conversation,
    this.isSelected = false,
    required this.onTap,
    this.onLongPress,
    this.onSecondaryTapDown,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: onSecondaryTapDown,
      child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.amber.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppColors.amber.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            if (conversation.isPinned)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.push_pin,
                  size: 14,
                  color: AppColors.amber.withOpacity(0.7),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.updatedAt.timeAgo,
                    style: AppTextStyles.chatTimestamp,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
