import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/model_service.dart';
import '../../data/services/inference_service.dart';
import '../../data/services/hardware_analyzer.dart';
import '../../domain/entities/model_info.dart';
import 'settings_provider.dart';

final hardwareAnalyzerProvider = Provider<HardwareAnalyzer>((ref) {
  return HardwareAnalyzer();
});

final hardwareInfoProvider = FutureProvider<HardwareInfo>((ref) async {
  final analyzer = ref.watch(hardwareAnalyzerProvider);
  return analyzer.analyze();
});

final modelServiceProvider = Provider<ModelService>((ref) {
  final service = ModelService();
  ref.onDispose(() => service.dispose());
  return service;
});

final inferenceServiceProvider = Provider<InferenceService>((ref) {
  final service = InferenceService();
  ref.onDispose(() => service.dispose());
  return service;
});

final availableModelsProvider = FutureProvider<List<ModelInfo>>((ref) async {
  final modelService = ref.watch(modelServiceProvider);
  return modelService.listAvailableModels();
});

final activeModelIdProvider = FutureProvider<String?>((ref) async {
  final modelService = ref.watch(modelServiceProvider);
  return modelService.getActiveModelId();
});

final downloadProgressProvider = StreamProvider<DownloadProgress>((ref) {
  final modelService = ref.watch(modelServiceProvider);
  return modelService.downloadProgress;
});

/// Manually toggled after connect/disconnect to keep UI in sync.
final isModelLoadedProvider = StateProvider<bool>((ref) => false);

final isGeneratingProvider = Provider<bool>((ref) {
  final inferenceService = ref.watch(inferenceServiceProvider);
  return inferenceService.isGenerating;
});

// ═══════════════════════════════════════════
// Unified model selector for the chat dropdown
// ═══════════════════════════════════════════

enum SelectableModelType { local, remote }

/// A single entry in the chat model-selector dropdown.
class SelectableModel {
  final String id;
  final String displayName;
  final SelectableModelType type;

  // Local-specific
  final String? filePath;
  final int fileSizeMB;
  final bool isDownloaded;

  // Remote-specific
  final String? baseUrl;
  final String? apiKey;
  final String? remoteModelName;

  const SelectableModel({
    required this.id,
    required this.displayName,
    required this.type,
    this.filePath,
    this.fileSizeMB = 0,
    this.isDownloaded = false,
    this.baseUrl,
    this.apiKey,
    this.remoteModelName,
  });

  bool get isLocal => type == SelectableModelType.local;
  bool get isRemote => type == SelectableModelType.remote;
}

/// Provides the combined list of selectable models:
/// downloaded local GGUF models + saved remote endpoints.
final selectableModelsProvider = Provider<List<SelectableModel>>((ref) {
  final modelsAsync = ref.watch(availableModelsProvider);
  final savedEndpoints = ref.watch(savedEndpointsProvider);

  final list = <SelectableModel>[];

  // Local models (only downloaded ones are selectable)
  modelsAsync.whenData((models) {
    for (final m in models) {
      if (m.status == ModelStatus.downloaded || m.status == ModelStatus.loaded) {
        list.add(SelectableModel(
          id: m.id,
          displayName: m.displayName,
          type: SelectableModelType.local,
          filePath: m.filePath,
          fileSizeMB: m.fileSizeMB,
          isDownloaded: true,
        ));
      }
    }
  });

  // Saved remote endpoints
  for (final ep in savedEndpoints) {
    list.add(SelectableModel(
      id: 'remote:${ep.baseUrl}:${ep.modelName ?? ""}',
      displayName: ep.name,
      type: SelectableModelType.remote,
      baseUrl: ep.baseUrl,
      apiKey: ep.apiKey,
      remoteModelName: ep.modelName,
    ));
  }

  return list;
});

/// The model the user has selected in the current chat session.
/// null = nothing selected yet (will auto-resolve from Acorn default or currently loaded).
final selectedModelIdProvider = StateProvider<String?>((ref) => null);
