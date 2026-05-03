import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/gem.dart';

class GemCard extends StatelessWidget {
  final Gem gem;
  final bool isSelected;
  final int conversationCount;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const GemCard({
    super.key,
    required this.gem,
    this.isSelected = false,
    this.conversationCount = 0,
    required this.onTap,
    this.onLongPress,
  });

  Color get _gemColor {
    try {
      final hex = gem.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? _gemColor.withOpacity(0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _gemColor : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              gem.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              gem.name,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? _gemColor : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (conversationCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '$conversationCount chats',
                style: AppTextStyles.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
