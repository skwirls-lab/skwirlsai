import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/model_provider.dart';
import '../../../data/services/model_service.dart';

class ModelDownloadScreen extends ConsumerStatefulWidget {
  final String modelId;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const ModelDownloadScreen({
    super.key,
    required this.modelId,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  ConsumerState<ModelDownloadScreen> createState() =>
      _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends ConsumerState<ModelDownloadScreen> {
  bool _isDownloading = false;
  bool _isComplete = false;
  String? _error;
  double _progress = 0;
  String _progressText = '';

  @override
  Widget build(BuildContext context) {
    final modelInfo = ApiConstants.gemma4Models[widget.modelId];

    return Scaffold(
      appBar: AppBar(title: const Text('Download Model')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isDownloading && !_isComplete && _error == null) ...[
              Icon(
                Icons.cloud_download_rounded,
                size: 64,
                color: AppColors.amber,
              ),
              const SizedBox(height: 24),
              Text(
                modelInfo?.displayName ?? widget.modelId,
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: 8),
              Text(
                modelInfo?.description ?? '',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _InfoChip(
                Icons.storage_rounded,
                'Size: ${modelInfo?.fileSizeDisplay ?? "Unknown"}',
              ),
              const SizedBox(height: 8),
              _InfoChip(
                Icons.memory_rounded,
                'Requires: ${modelInfo?.ramDisplay ?? "Unknown"}',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startDownload,
                  child: const Text('Download Now'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onSkip,
                child: const Text('Skip for now'),
              ),
            ],
            if (_isDownloading) ...[
              Text(
                'Downloading ${modelInfo?.displayName}...',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 12),
              Text(_progressText, style: AppTextStyles.body),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _cancelDownload,
                child: const Text('Cancel'),
              ),
            ],
            if (_isComplete) ...[
              const Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: AppColors.success,
              ),
              const SizedBox(height: 16),
              Text('Download Complete!', style: AppTextStyles.h2),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onComplete,
                  child: const Text('Continue'),
                ),
              ),
            ],
            if (_error != null) ...[
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text('Download Failed', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTextStyles.body.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startDownload,
                child: const Text('Retry'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onSkip,
                child: const Text('Skip for now'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _error = null;
      _progress = 0;
    });

    try {
      final modelService = ref.read(modelServiceProvider);
      await modelService.downloadModel(
        widget.modelId,
        onProgress: (progress) {
          setState(() {
            _progress = progress.percentage;
            _progressText = progress.display;
          });
        },
      );

      await modelService.setActiveModelId(widget.modelId);

      setState(() {
        _isDownloading = false;
        _isComplete = true;
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _error = e.toString();
      });
    }
  }

  void _cancelDownload() {
    ref.read(modelServiceProvider).cancelDownload();
    setState(() {
      _isDownloading = false;
      _error = 'Download cancelled';
    });
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
