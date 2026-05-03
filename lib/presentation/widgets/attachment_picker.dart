import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AttachmentPicker extends StatelessWidget {
  final VoidCallback onImagePicked;
  final VoidCallback onAudioPicked;
  final VoidCallback onVideoPicked;
  final VoidCallback onDocumentPicked;
  final VoidCallback onCameraCapture;
  final VoidCallback onDismiss;

  const AttachmentPicker({
    super.key,
    required this.onImagePicked,
    required this.onAudioPicked,
    required this.onVideoPicked,
    required this.onDocumentPicked,
    required this.onCameraCapture,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Attach', style: AppTextStyles.h3),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AttachmentOption(
                icon: Icons.image_rounded,
                label: 'Image',
                color: AppColors.amber,
                onTap: onImagePicked,
              ),
              _AttachmentOption(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                color: AppColors.teal,
                onTap: onCameraCapture,
              ),
              _AttachmentOption(
                icon: Icons.audio_file_rounded,
                label: 'Audio',
                color: AppColors.info,
                onTap: onAudioPicked,
              ),
              _AttachmentOption(
                icon: Icons.video_file_rounded,
                label: 'Video',
                color: AppColors.warning,
                onTap: onVideoPicked,
              ),
              _AttachmentOption(
                icon: Icons.description_rounded,
                label: 'Document',
                color: AppColors.success,
                onTap: onDocumentPicked,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }
}
