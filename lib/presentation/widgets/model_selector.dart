import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/services/inference_service.dart';
import '../providers/model_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/gem_provider.dart';

/// Compact model selector dropdown that sits above the chat input area.
/// Shows current model, lets user swap between local GGUF and saved remote endpoints.
class ModelSelector extends ConsumerStatefulWidget {
  const ModelSelector({super.key});

  @override
  ConsumerState<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends ConsumerState<ModelSelector> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final selectable = ref.watch(selectableModelsProvider);
    final selectedId = ref.watch(selectedModelIdProvider);
    final isLoaded = ref.watch(isModelLoadedProvider);
    final inferenceService = ref.watch(inferenceServiceProvider);
    final activeAcorn = ref.watch(activeAcornProvider);

    // Resolve the effective model: explicit selection > acorn default > currently loaded
    String? effectiveId = selectedId;
    if (effectiveId == null && activeAcorn != null &&
        activeAcorn.defaultModelId.isNotEmpty) {
      effectiveId = activeAcorn.defaultModelId;
    }

    // Find the currently active model label
    String activeLabel = 'Select a model';
    IconData activeIcon = Icons.smart_toy_outlined;
    bool isActiveReady = false;

    if (effectiveId != null) {
      final match = selectable.where((m) => m.id == effectiveId).firstOrNull;
      if (match != null) {
        activeLabel = match.displayName;
        activeIcon = match.isLocal
            ? Icons.memory_rounded
            : Icons.cloud_outlined;
      }
    }

    // Check if the effective model is actually loaded/connected
    if (isLoaded && inferenceService.isModelLoaded) {
      isActiveReady = true;
      // If nothing explicitly selected, show whatever is loaded
      if (effectiveId == null) {
        activeLabel = inferenceService.activeModelName ?? 'Model loaded';
        activeIcon = inferenceService.activeSource == ModelSource.local
            ? Icons.memory_rounded
            : Icons.cloud_outlined;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _isLoading ? null : () => _showModelPicker(context, selectable, effectiveId),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(activeIcon, size: 14,
                        color: isActiveReady ? AppColors.teal : AppColors.textTertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activeLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isActiveReady
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(Icons.unfold_more_rounded, size: 16,
                          color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
          ),
          // Load button for local models that aren't loaded yet
          if (effectiveId != null && !isActiveReady && !_isLoading)
            _buildLoadButton(effectiveId, selectable),
        ],
      ),
    );
  }

  Widget _buildLoadButton(String modelId, List<SelectableModel> selectable) {
    final model = selectable.where((m) => m.id == modelId).firstOrNull;
    if (model == null) return const SizedBox.shrink();

    // Remote endpoints auto-connect, so show "Connect" label
    final isRemote = model.isRemote;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: SizedBox(
        height: 30,
        child: ElevatedButton.icon(
          onPressed: () => _activateModel(model),
          icon: Icon(isRemote ? Icons.link_rounded : Icons.play_arrow_rounded,
              size: 14),
          label: Text(isRemote ? 'Connect' : 'Load',
              style: const TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  void _showModelPicker(
      BuildContext context, List<SelectableModel> models, String? currentId) {
    final locals = models.where((m) => m.isLocal).toList();
    final remotes = models.where((m) => m.isRemote).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Select Model',
                  style: AppTextStyles.h3.copyWith(fontSize: 16)),
            ),
            const SizedBox(height: 8),

            if (locals.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text('Local Models',
                    style: AppTextStyles.label.copyWith(
                        color: AppColors.textTertiary, fontSize: 11)),
              ),
              ...locals.map((m) => _modelTile(ctx, m, currentId)),
            ],

            if (remotes.isNotEmpty) ...[
              if (locals.isNotEmpty) const Divider(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text('Remote Endpoints',
                    style: AppTextStyles.label.copyWith(
                        color: AppColors.textTertiary, fontSize: 11)),
              ),
              ...remotes.map((m) => _modelTile(ctx, m, currentId)),
            ],

            if (models.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No models available.\nDownload a model or add a remote endpoint in Settings.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _modelTile(BuildContext ctx, SelectableModel model, String? currentId) {
    final isSelected = model.id == currentId;
    final inferenceService = ref.read(inferenceServiceProvider);

    // Check if this specific model is currently loaded/connected
    bool isActive = false;
    if (model.isLocal && inferenceService.loadedModelPath == model.filePath) {
      isActive = true;
    } else if (model.isRemote &&
        inferenceService.activeEndpoint == model.baseUrl) {
      isActive = true;
    }

    return ListTile(
      dense: true,
      leading: Icon(
        model.isLocal ? Icons.memory_rounded : Icons.cloud_outlined,
        size: 20,
        color: isActive
            ? AppColors.teal
            : isSelected
                ? AppColors.amber
                : AppColors.textTertiary,
      ),
      title: Text(model.displayName,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          )),
      subtitle: model.isLocal
          ? Text('${model.fileSizeMB} MB',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textTertiary))
          : Text(model.baseUrl ?? '',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textTertiary)),
      trailing: isActive
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('active',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.teal, fontSize: 10)),
            )
          : null,
      onTap: () {
        ref.read(selectedModelIdProvider.notifier).state = model.id;
        Navigator.pop(ctx);

        // Auto-activate remote endpoints immediately
        if (model.isRemote) {
          _activateModel(model);
        }
        // For local models: if a different model is loaded, user taps "Load"
        // If the same model is already loaded, we're done
        if (model.isLocal && isActive) {
          // Already loaded, nothing to do
        }
      },
    );
  }

  Future<void> _activateModel(SelectableModel model) async {
    setState(() => _isLoading = true);

    try {
      final inferenceService = ref.read(inferenceServiceProvider);

      if (model.isLocal) {
        if (model.filePath == null) return;
        final settings = ref.read(settingsProvider);
        await inferenceService.connect(ModelConfig.local(
          path: model.filePath!,
          contextSize: settings.contextSize,
        ));
      } else {
        // Remote endpoint
        final effectiveModel = model.remoteModelName ?? '';
        if (effectiveModel.isEmpty && mounted) {
          // Need to prompt for model name
          final name = await _promptForModelName();
          if (name == null || name.isEmpty) {
            setState(() => _isLoading = false);
            return;
          }
          await inferenceService.connect(ModelConfig.remote(
            baseUrl: model.baseUrl!,
            modelName: name,
            apiKey: model.apiKey,
          ));
        } else {
          await inferenceService.connect(ModelConfig.remote(
            baseUrl: model.baseUrl!,
            modelName: effectiveModel,
            apiKey: model.apiKey,
          ));
        }
      }

      ref.read(isModelLoadedProvider.notifier).state = true;

      if (mounted) {
        showTopSnackBar(context,
            '${model.isLocal ? "Loaded" : "Connected to"} ${model.displayName}',
            backgroundColor: AppColors.success);
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Failed: $e',
            backgroundColor: AppColors.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _promptForModelName() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Model Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Which model to use?',
            hintText: 'e.g., gemma3:27b, llama3:latest',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
