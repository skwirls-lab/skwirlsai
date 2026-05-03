import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/model_provider.dart';
import '../../../domain/entities/model_info.dart';

class HardwareAnalysisScreen extends ConsumerStatefulWidget {
  final void Function(String modelId) onModelSelected;
  final VoidCallback onCustomModel;

  const HardwareAnalysisScreen({
    super.key,
    required this.onModelSelected,
    required this.onCustomModel,
  });

  @override
  ConsumerState<HardwareAnalysisScreen> createState() =>
      _HardwareAnalysisScreenState();
}

class _HardwareAnalysisScreenState
    extends ConsumerState<HardwareAnalysisScreen> {
  String? _selectedModelId;

  @override
  Widget build(BuildContext context) {
    final hardwareAsync = ref.watch(hardwareInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Device Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: hardwareAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Analyzing your device...', style: AppTextStyles.body),
              ],
            ),
          ),
          error: (e, _) => Center(
            child: Text('Error: $e', style: AppTextStyles.body),
          ),
          data: (hardware) {
            _selectedModelId ??= hardware.recommendedModelId;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Device', style: AppTextStyles.h2),
                const SizedBox(height: 16),
                _InfoRow('Platform', hardware.platformName),
                _InfoRow('RAM', hardware.ramDisplay),
                _InfoRow('VRAM', hardware.vramDisplay),
                _InfoRow('CPU Cores', '${hardware.cpuCores}'),
                _InfoRow('Storage', hardware.storageDisplay),
                const SizedBox(height: 24),
                Text('Choose a Model', style: AppTextStyles.h2),
                const SizedBox(height: 8),
                Text(
                  'Based on your hardware, we recommend the highlighted model.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      ...ApiConstants.gemma4Models.entries.map((entry) {
                        final info = entry.value;
                        final isRecommended =
                            entry.key == hardware.recommendedModelId;
                        final isSelected = entry.key == _selectedModelId;
                        final meetsRequirements =
                            hardware.totalRamMB >= info.minRamMB;

                        return _ModelOption(
                          info: info,
                          isRecommended: isRecommended,
                          isSelected: isSelected,
                          meetsRequirements: meetsRequirements,
                          onTap: meetsRequirements
                              ? () => setState(
                                  () => _selectedModelId = entry.key)
                              : null,
                        );
                      }),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: widget.onCustomModel,
                        icon: const Icon(Icons.folder_open_rounded),
                        label: const Text('Import Custom GGUF Model'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedModelId != null
                        ? () => widget.onModelSelected(_selectedModelId!)
                        : null,
                    child: const Text('Download & Continue'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _ModelOption extends StatelessWidget {
  final ModelDownloadInfo info;
  final bool isRecommended;
  final bool isSelected;
  final bool meetsRequirements;
  final VoidCallback? onTap;

  const _ModelOption({
    required this.info,
    required this.isRecommended,
    required this.isSelected,
    required this.meetsRequirements,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.amber.withOpacity(0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.amber
                : meetsRequirements
                    ? AppColors.divider
                    : AppColors.error.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: meetsRequirements ? (_) => onTap?.call() : null,
              activeColor: AppColors.amber,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        info.displayName,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: meetsRequirements
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Recommended',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${info.fileSizeDisplay}  |  ${info.ramDisplay}  |  ${info.vramDisplay}',
                    style: AppTextStyles.bodySmall,
                  ),
                  Text(info.description, style: AppTextStyles.bodySmall),
                  if (!meetsRequirements)
                    Text(
                      'Insufficient RAM for this model',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
