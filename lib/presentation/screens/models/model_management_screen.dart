import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/storage_paths.dart';
import '../../../domain/entities/model_info.dart';
import '../../../data/services/inference_service.dart';
import '../../providers/model_provider.dart';
import '../../providers/settings_provider.dart';

class ModelManagementScreen extends ConsumerStatefulWidget {
  const ModelManagementScreen({super.key});

  @override
  ConsumerState<ModelManagementScreen> createState() =>
      _ModelManagementScreenState();
}

class _ModelManagementScreenState
    extends ConsumerState<ModelManagementScreen> {
  String? _downloadingModelId;
  double _downloadProgress = 0;

  @override
  Widget build(BuildContext context) {
    final inferenceService = ref.watch(inferenceServiceProvider);
    final modelsAsync = ref.watch(availableModelsProvider);
    final hardwareAsync = ref.watch(hardwareInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Models')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connection status banner
          _ConnectionStatusBanner(
            inferenceService: inferenceService,
            onDisconnect: () async {
              await inferenceService.disconnect();
              ref.read(isModelLoadedProvider.notifier).state = false;
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          // Hardware info
          hardwareAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (hw) => Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.memory_rounded, color: AppColors.teal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hw.platformName, style: AppTextStyles.body),
                        Text(
                          '${hw.ramDisplay} RAM  |  ${hw.vramDisplay} VRAM  |  ${hw.storageDisplay}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ═══════════════════════════════════════════
          // REMOTE ENDPOINTS
          // ═══════════════════════════════════════════
          Text('Remote Endpoints', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(
            'Connect to Ollama, vLLM, OpenAI, or any OpenAI-compatible API',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),

          // Add endpoint button
          OutlinedButton.icon(
            onPressed: () => _showAddEndpointDialog(),
            icon: const Icon(Icons.add_link_rounded),
            label: const Text('Add Remote Endpoint'),
          ),
          const SizedBox(height: 8),

          // Quick-add presets
          _QuickConnectCard(
            icon: Icons.computer_rounded,
            title: 'Ollama (Local)',
            subtitle: 'http://localhost:11434',
            onConnect: () {
              // Save as endpoint; user connects from the chat dropdown
              ref.read(savedEndpointsProvider.notifier).addEndpoint(
                const SavedEndpoint(
                  name: 'Ollama (Local)',
                  baseUrl: 'http://localhost:11434',
                ),
              );
              showTopSnackBar(context,
                  'Ollama endpoint saved. Select it from the model dropdown in chat.',
                  backgroundColor: AppColors.success);
            },
            isConnecting: false,
            buttonLabel: 'Save',
          ),
          const SizedBox(height: 8),

          // Saved endpoints
          ..._buildSavedEndpoints(),

          const SizedBox(height: 24),

          // ═══════════════════════════════════════════
          // LOCAL GGUF MODELS
          // ═══════════════════════════════════════════
          Text('Local Models', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          FutureBuilder<String>(
            future: StoragePaths.modelsDir,
            builder: (_, snap) => Text(
              'Directory: ${snap.data ?? '...'}',
              style: AppTextStyles.bodySmall,
            ),
          ),
          const SizedBox(height: 12),

          modelsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (models) {
              final localModels =
                  models.where((m) => m.isLocal).toList();
              final downloadedModels = localModels
                  .where((m) => m.status == ModelStatus.downloaded)
                  .toList();
              final catalogModels = localModels
                  .where((m) => m.status == ModelStatus.notDownloaded)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Downloaded models
                  if (downloadedModels.isNotEmpty) ...[
                    Text('Downloaded',
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...downloadedModels.map((model) {
                      final isConnected =
                          inferenceService.isModelLoaded &&
                              inferenceService.loadedModelPath ==
                                  model.filePath;
                      return _LocalModelCard(
                        model: model,
                        isConnected: isConnected,
                        onDelete: () => _deleteModel(model),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                  // Catalog models available for download
                  if (catalogModels.isNotEmpty) ...[
                    Text('Available for Download',
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...catalogModels.map((model) {
                      final isDownloading =
                          _downloadingModelId == model.id;
                      return _CatalogModelCard(
                        model: model,
                        isDownloading: isDownloading,
                        downloadProgress: isDownloading
                            ? _downloadProgress
                            : 0,
                        onDownload: () =>
                            _downloadModel(model.id),
                        onCancel: _cancelDownload,
                      );
                    }),
                  ],
                  if (downloadedModels.isEmpty &&
                      catalogModels.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.folder_open_rounded,
                              size: 40,
                              color: AppColors.textTertiary),
                          const SizedBox(height: 8),
                          Text('No local models found',
                              style: AppTextStyles.body.copyWith(
                                  color:
                                      AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(
                            'Import a GGUF file or download from the catalog above',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // Import GGUF button
          OutlinedButton.icon(
            onPressed: _importCustomModel,
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Import GGUF Model'),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showAddEndpointDialog() {
    final urlController = TextEditingController();
    final modelController = TextEditingController();
    final keyController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Remote Endpoint'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'e.g., My GB10 Server',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'http://192.168.1.100:11434',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Model Name',
                  hintText: 'e.g., gemma3:27b, llama3, gpt-4o',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Key (optional)',
                  hintText: 'sk-... (leave empty for Ollama)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = urlController.text.trim();
              final model = modelController.text.trim();
              final key = keyController.text.trim();
              final name = nameController.text.trim();
              final displayName = name.isEmpty ? url : name;

              // Save the endpoint for future use
              ref.read(savedEndpointsProvider.notifier).addEndpoint(
                    SavedEndpoint(
                      name: displayName,
                      baseUrl: url,
                      modelName: model.isEmpty ? null : model,
                      apiKey: key.isEmpty ? null : key,
                    ),
                  );

              Navigator.pop(ctx);
              showTopSnackBar(context,
                  'Endpoint saved. Select it from the model dropdown in chat.',
                  backgroundColor: AppColors.success);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSavedEndpoints() {
    final saved = ref.watch(savedEndpointsProvider);
    if (saved.isEmpty) return [];

    return [
      const SizedBox(height: 8),
      Text('Saved Endpoints',
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: 4),
      ...saved.asMap().entries.map((entry) {
        final idx = entry.key;
        final ep = entry.value;
        return Card(
          color: AppColors.surfaceLight,
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            dense: true,
            leading:
                const Icon(Icons.link_rounded, size: 20, color: AppColors.teal),
            title: Text(ep.name, style: AppTextStyles.bodySmall),
            subtitle: Text(
              '${ep.baseUrl}${ep.modelName != null ? ' • ${ep.modelName}' : ''}',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textTertiary),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.textTertiary),
              tooltip: 'Remove',
              onPressed: () =>
                  ref.read(savedEndpointsProvider.notifier).removeEndpoint(idx),
            ),
          ),
        );
      }),
    ];
  }

  Future<void> _deleteModel(ModelInfo model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Model?'),
        content:
            Text('Delete "${model.displayName}"? You can re-import later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(modelServiceProvider).deleteModel(model.id);
      ref.invalidate(availableModelsProvider);
    }
  }

  Future<void> _downloadModel(String modelId) async {
    setState(() {
      _downloadingModelId = modelId;
      _downloadProgress = 0;
    });

    try {
      final modelService = ref.read(modelServiceProvider);
      await modelService.downloadModel(
        modelId,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _downloadProgress = progress.percentage);
          }
        },
      );

      ref.invalidate(availableModelsProvider);

      if (mounted) {
        showTopSnackBar(context, 'Download complete! Select it from the model dropdown in chat.',
            backgroundColor: AppColors.success);
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Download failed: $e',
            backgroundColor: AppColors.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingModelId = null;
          _downloadProgress = 0;
        });
      }
    }
  }

  void _cancelDownload() {
    ref.read(modelServiceProvider).cancelDownload();
    setState(() {
      _downloadingModelId = null;
      _downloadProgress = 0;
    });
  }

  Future<void> _importCustomModel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select a GGUF model file',
      );

      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;

      if (!path.toLowerCase().endsWith('.gguf')) {
        if (mounted) {
          showTopSnackBar(context, 'Only .gguf files are supported',
              backgroundColor: AppColors.error);
        }
        return;
      }

      final modelService = ref.read(modelServiceProvider);
      await modelService.importCustomModel(path);
      ref.invalidate(availableModelsProvider);

      if (mounted) {
        showTopSnackBar(context, 'Model imported successfully',
            backgroundColor: AppColors.success);
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Import failed: $e',
            backgroundColor: AppColors.error);
      }
    }
  }
}

class _ConnectionStatusBanner extends StatelessWidget {
  final InferenceService inferenceService;
  final VoidCallback onDisconnect;

  const _ConnectionStatusBanner({
    required this.inferenceService,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = inferenceService.isModelLoaded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isConnected
            ? AppColors.success.withOpacity(0.1)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected
              ? AppColors.success.withOpacity(0.3)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color: isConnected ? AppColors.success : AppColors.textTertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Model Active' : 'No Model Loaded',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isConnected ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
                if (isConnected) ...[
                  const SizedBox(height: 2),
                  Text(
                    inferenceService.providerName,
                    style: AppTextStyles.bodySmall,
                  ),
                  if (inferenceService.activeModelName != null)
                    Text(
                      'Model: ${inferenceService.activeModelName}',
                      style: AppTextStyles.bodySmall,
                    ),
                ] else
                  Text(
                    'Download local models or add remote endpoints below.\nUse the model selector in chat to load.',
                    style: AppTextStyles.bodySmall,
                  ),
              ],
            ),
          ),
          if (isConnected)
            TextButton(
              onPressed: onDisconnect,
              child: const Text('Disconnect'),
            ),
        ],
      ),
    );
  }
}

class _QuickConnectCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onConnect;
  final bool isConnecting;
  final String buttonLabel;

  const _QuickConnectCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onConnect,
    required this.isConnecting,
    this.buttonLabel = 'Connect',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.teal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isConnecting ? null : onConnect,
            child: isConnecting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _LocalModelCard extends StatelessWidget {
  final ModelInfo model;
  final bool isConnected;
  final VoidCallback onDelete;

  const _LocalModelCard({
    required this.model,
    required this.isConnected,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isConnected
            ? AppColors.amber.withOpacity(0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? AppColors.amber : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.check_circle_rounded : Icons.storage_rounded,
            color: isConnected ? AppColors.success : AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        model.displayName,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isConnected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Active',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.amber)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${model.fileSizeMB >= 1000 ? "${(model.fileSizeMB / 1000).toStringAsFixed(1)} GB" : "${model.fileSizeMB} MB"}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: AppColors.textTertiary,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _CatalogModelCard extends StatelessWidget {
  final ModelInfo model;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback onDownload;
  final VoidCallback onCancel;

  const _CatalogModelCard({
    required this.model,
    required this.isDownloading,
    required this.downloadProgress,
    required this.onDownload,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final catalogInfo = ApiConstants.gemma4Models[model.id];
    final sizeDisplay = model.fileSizeMB >= 1000
        ? '${(model.fileSizeMB / 1000).toStringAsFixed(1)} GB'
        : '${model.fileSizeMB} MB';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_download_outlined,
                  color: AppColors.teal, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.displayName,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$sizeDisplay${catalogInfo != null ? '  |  ${catalogInfo.description}' : ''}',
                      style: AppTextStyles.bodySmall,
                    ),
                    if (catalogInfo != null)
                      Text(
                        'Requires ${catalogInfo.ramDisplay}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textTertiary),
                      ),
                  ],
                ),
              ),
              if (!isDownloading)
                ElevatedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Download'),
                )
              else
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
            ],
          ),
          if (isDownloading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: downloadProgress / 100,
                minHeight: 6,
                backgroundColor: AppColors.divider,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.teal),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${downloadProgress.toStringAsFixed(1)}%',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
