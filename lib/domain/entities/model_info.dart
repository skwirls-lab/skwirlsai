class ModelInfo {
  final String id;
  final String displayName;
  final ModelType type;

  // Local GGUF fields
  final String? filePath;
  final int fileSizeMB;
  final bool isCustom;
  final ModelStatus status;

  // Remote endpoint fields
  final String? baseUrl;
  final String? apiKey;
  final String? remoteModelName;

  const ModelInfo({
    required this.id,
    required this.displayName,
    this.type = ModelType.local,
    this.filePath,
    this.fileSizeMB = 0,
    this.isCustom = false,
    this.status = ModelStatus.notDownloaded,
    this.baseUrl,
    this.apiKey,
    this.remoteModelName,
  });

  bool get isLocal => type == ModelType.local;
  bool get isRemote => type == ModelType.remote;

  ModelInfo copyWith({
    String? id,
    String? displayName,
    ModelType? type,
    String? filePath,
    int? fileSizeMB,
    bool? isCustom,
    ModelStatus? status,
    String? baseUrl,
    String? apiKey,
    String? remoteModelName,
  }) =>
      ModelInfo(
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        type: type ?? this.type,
        filePath: filePath ?? this.filePath,
        fileSizeMB: fileSizeMB ?? this.fileSizeMB,
        isCustom: isCustom ?? this.isCustom,
        status: status ?? this.status,
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        remoteModelName: remoteModelName ?? this.remoteModelName,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'type': type.name,
        'filePath': filePath,
        'fileSizeMB': fileSizeMB,
        'isCustom': isCustom,
        'status': status.name,
        'baseUrl': baseUrl,
        'remoteModelName': remoteModelName,
        // Never persist API keys to plain JSON — stored in secure storage
      };

  factory ModelInfo.fromJson(Map<String, dynamic> json) => ModelInfo(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        type: ModelType.values.byName(json['type'] as String? ?? 'local'),
        filePath: json['filePath'] as String?,
        fileSizeMB: json['fileSizeMB'] as int? ?? 0,
        isCustom: json['isCustom'] as bool? ?? false,
        status: ModelStatus.values.byName(
          json['status'] as String? ?? 'notDownloaded',
        ),
        baseUrl: json['baseUrl'] as String?,
        remoteModelName: json['remoteModelName'] as String?,
      );

  /// Create a local GGUF model entry
  factory ModelInfo.local({
    required String id,
    required String displayName,
    required String filePath,
    int fileSizeMB = 0,
    bool isCustom = false,
    ModelStatus status = ModelStatus.notDownloaded,
  }) =>
      ModelInfo(
        id: id,
        displayName: displayName,
        type: ModelType.local,
        filePath: filePath,
        fileSizeMB: fileSizeMB,
        isCustom: isCustom,
        status: status,
      );

  /// Create a remote endpoint model entry
  factory ModelInfo.remote({
    required String id,
    required String displayName,
    required String baseUrl,
    required String remoteModelName,
    String? apiKey,
  }) =>
      ModelInfo(
        id: id,
        displayName: displayName,
        type: ModelType.remote,
        baseUrl: baseUrl,
        remoteModelName: remoteModelName,
        apiKey: apiKey,
        status: ModelStatus.ready,
      );
}

enum ModelType { local, remote }

enum ModelStatus {
  notDownloaded,
  downloading,
  downloaded,
  loading,
  loaded,
  ready,
  error,
}

class HardwareInfo {
  final int totalRamMB;
  final int availableRamMB;
  final int? vramMB;
  final int cpuCores;
  final String cpuArchitecture;
  final int availableStorageMB;
  final String platformName;

  const HardwareInfo({
    required this.totalRamMB,
    required this.availableRamMB,
    this.vramMB,
    required this.cpuCores,
    required this.cpuArchitecture,
    required this.availableStorageMB,
    required this.platformName,
  });

  String get recommendedModelId {
    if (totalRamMB < 4096) return 'gemma-4-e2b';
    if (totalRamMB < 8192) return 'gemma-4-e2b';
    if (totalRamMB < 20480) return 'gemma-4-e4b';
    return 'gemma-4-26b-a4b';
  }

  String get ramDisplay => '${(totalRamMB / 1024).toStringAsFixed(1)} GB';

  String get vramDisplay =>
      vramMB != null ? '${(vramMB! / 1024).toStringAsFixed(1)} GB' : 'N/A';

  String get storageDisplay =>
      '${(availableStorageMB / 1024).toStringAsFixed(1)} GB free';
}
