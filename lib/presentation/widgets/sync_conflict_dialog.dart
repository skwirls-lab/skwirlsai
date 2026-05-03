import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/sync_service.dart';

class SyncConflictDialog extends StatelessWidget {
  final SyncConflict conflict;
  final void Function(ConflictResolution) onResolved;

  const SyncConflictDialog({
    super.key,
    required this.conflict,
    required this.onResolved,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sync Conflict'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This ${conflict.entityType} was modified on two devices:',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            // Local version
            _ConflictCard(
              title: 'This Device',
              subtitle: conflict.localDeviceName,
              timestamp: conflict.localTimestamp,
              color: AppColors.amber,
            ),
            const SizedBox(height: 8),
            const Center(child: Text('vs', style: AppTextStyles.label)),
            const SizedBox(height: 8),
            // Remote version
            _ConflictCard(
              title: 'Other Device',
              subtitle: conflict.remoteDeviceName,
              timestamp: conflict.remoteTimestamp,
              color: AppColors.teal,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onResolved(ConflictResolution.keepBoth);
          },
          child: const Text('Keep Both'),
        ),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
            onResolved(ConflictResolution.keepRemote);
          },
          child: const Text('Use Other Device'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onResolved(ConflictResolution.keepLocal);
          },
          child: const Text('Use This Device'),
        ),
      ],
    );
  }
}

class _ConflictCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final Color color;

  const _ConflictCard({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.devices_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(subtitle, style: AppTextStyles.bodySmall),
                Text(
                  'Modified: ${timestamp.toLocal().toString().substring(0, 19)}',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
