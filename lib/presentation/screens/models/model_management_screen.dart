import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/storage_paths.dart';
import '../../../domain/entities/model_info.dart';
import '../../../data/services/inference_service.dart';
import '../../providers/model_provider.dart';

class ModelManagementScreen extends ConsumerStatefulWidget {
  const ModelManagementScreen({super.key});

  @override
  ConsumerState<ModelManagementScreen> createState() =>
      _ModelManagementScreenState();
}

class _ModelManagementScreenState
    extends ConsumerState<ModelManagementScreen> {
  bool _isConnecting = false;
  String? _connectError;

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

          if (_connectError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_connectError!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.error)),
            ),

          // Add endpoint button
          OutlinedButton.icon(
            onPressed: _isConnecting ? null : () => _showAddEndpointDialog(),
            icon: const Icon(Icons.add_link_rounded),
            label: const Text('Add Remote Endpoint'),
          ),
          const SizedBox(height: 8),

          // Quick-connect presets
          _QuickConnectCard(
            icon: Icons.computer_rounded,
            title: 'Ollama (Local)',
            subtitle: 'http://localhost:11434',
            onConnect: () => _connectRemote(
              baseUrl: 'http://localhost:11434',
              displayName: 'Ollama (Local)',
            ),
            isConnecting: _isConnecting,
          ),

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

              if (localModels.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.folder_open_rounded,
                          size: 40, color: AppColors.textTertiary),
                      const SizedBox(height: 8),
                      Text('No local models found',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        'Import a GGUF file to run models offline',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: localModels.map((model) {
                  final isConnected = inferenceService.isModelLoaded &&
                      inferenceService.loadedModelPath == model.filePath;
                  return _LocalModelCard(
                    model: model,
                    isConnected: isConnected,
                    isConnecting: _isConnecting,
                    onConnect: () => _connectLocal(model),
                    onDelete: () => _deleteModel(model),
                  );
                }).toList(),
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
              Navigator.pop(ctx);
              _connectRemote(
                baseUrl: urlController.text.trim(),
                modelName: modelController.text.trim(),
                apiKey: keyController.text.trim().isEmpty
                    ? null
                    : keyController.text.trim(),
                displayName: nameController.text.trim().isEmpty
                    ? urlController.text.trim()
                    : nameController.text.trim(),
              );
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectRemote({
    required String baseUrl,
    String? modelName,
    String? apiKey,
    String? displayName,
  }) async {
    if (baseUrl.isEmpty) return;

    setState(() {
      _isConnecting = true;
      _connectError = null;
    });

    try {
      final inferenceService = ref.read(inferenceServiceProvider);

      // If no model name specified and it's Ollama, we need to ask
      String effectiveModel = modelName ?? '';
      if (effectiveModel.isEmpty) {
        // Show a dialog to pick model name for Ollama
        if (mounted) {
          effectiveModel = await _promptForModelName() ?? '';
        }
        if (effectiveModel.isEmpty) {
          setState(() => _isConnecting = false);
          return;
        }
      }

      await inferenceService.connect(ModelConfig.remote(
        baseUrl: baseUrl,
        modelName: effectiveModel,
        apiKey: apiKey,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${displayName ?? baseUrl}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _connectError = 'Connection failed: $e');
    } finally {
      setState(() => _isConnecting = false);
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

  Future<void> _connectLocal(ModelInfo model) async {
    if (model.filePath == null) return;

    setState(() {
      _isConnecting = true;
      _connectError = null;
    });

    try {
      final inferenceService = ref.read(inferenceServiceProvider);
      await inferenceService.connect(ModelConfig.local(path: model.filePath!));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${model.displayName}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _connectError = 'Failed to load: $e');
    } finally {
      setState(() => _isConnecting = false);
    }
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only .gguf files are supported'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final modelService = ref.read(modelServiceProvider);
      await modelService.importCustomModel(path);
      ref.invalidate(availableModelsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Model imported successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
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
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected
              ? AppColors.success.withOpacity(0.3)
              : AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            color: isConnected ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Connected' : 'No Model Connected',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isConnected ? AppColors.success : AppColors.warning,
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
                    'Add a remote endpoint or load a local GGUF model',
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

  const _QuickConnectCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onConnect,
    required this.isConnecting,
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
                : const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

class _LocalModelCard extends StatelessWidget {
  final ModelInfo model;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onConnect;
  final VoidCallback onDelete;

  const _LocalModelCard({
    required this.model,
    required this.isConnected,
    required this.isConnecting,
    required this.onConnect,
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
          if (!isConnected)
            ElevatedButton(
              onPressed: isConnecting ? null : onConnect,
              child: isConnecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load'),
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
