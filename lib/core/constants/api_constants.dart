class ApiConstants {
  ApiConstants._();

  // Google OAuth scopes
  static const List<String> googleOAuthScopes = [
    'email',
    'profile',
    'https://www.googleapis.com/auth/drive.appdata',
    'https://www.googleapis.com/auth/calendar.readonly',
    'https://www.googleapis.com/auth/gmail.readonly',
  ];

  // Google API endpoints
  static const String driveApiBase = 'https://www.googleapis.com/drive/v3';
  static const String calendarApiBase =
      'https://www.googleapis.com/calendar/v3';
  static const String gmailApiBase = 'https://www.googleapis.com/gmail/v1';

  // Hugging Face model repository URLs — Gemma 4 GGUF (unsloth quantized)
  static const Map<String, ModelDownloadInfo> gemma4Models = {
    'gemma-4-e2b': ModelDownloadInfo(
      id: 'gemma-4-e2b',
      displayName: 'Gemma 4 E2B Instruct (Q4_K_M)',
      repoId: 'unsloth/gemma-4-E2B-it-GGUF',
      fileName: 'gemma-4-E2B-it-Q4_K_M.gguf',
      fileSizeMB: 2960,
      minRamMB: 4096,
      minVramMB: 0,
      description: 'Lightweight — good for low-RAM devices',
    ),
    'gemma-4-e4b': ModelDownloadInfo(
      id: 'gemma-4-e4b',
      displayName: 'Gemma 4 E4B Instruct (Q4_K_M)',
      repoId: 'unsloth/gemma-4-E4B-it-GGUF',
      fileName: 'gemma-4-E4B-it-Q4_K_M.gguf',
      fileSizeMB: 4745,
      minRamMB: 8192,
      minVramMB: 0,
      description: 'Balanced quality and speed for 8GB+ RAM',
    ),
    'gemma-4-26b-a4b': ModelDownloadInfo(
      id: 'gemma-4-26b-a4b',
      displayName: 'Gemma 4 26B-A4B Instruct (Q4_K_M)',
      repoId: 'unsloth/gemma-4-26B-A4B-it-GGUF',
      fileName: 'gemma-4-26B-A4B-it-UD-Q4_K_M.gguf',
      fileSizeMB: 16080,
      minRamMB: 20480,
      minVramMB: 0,
      description: 'MoE — 26B total, 4B active. Needs 20GB+ RAM',
    ),
  };

  // Optional generation models (all opt-in)
  static const ModelDownloadInfo sdTurboModel = ModelDownloadInfo(
    id: 'sd-turbo',
    displayName: 'Stable Diffusion Turbo',
    repoId: 'stabilityai/sd-turbo',
    fileName: 'sd-turbo.safetensors',
    fileSizeMB: 2000,
    minRamMB: 8192,
    minVramMB: 4096,
    description: 'Fast image generation (512x512)',
  );

  // DuckDuckGo search (no API key needed)
  static const String duckDuckGoSearchUrl =
      'https://api.duckduckgo.com/?format=json&q=';
}

class ModelDownloadInfo {
  final String id;
  final String displayName;
  final String repoId;
  final String fileName;
  final int fileSizeMB;
  final int minRamMB;
  final int minVramMB;
  final String description;

  const ModelDownloadInfo({
    required this.id,
    required this.displayName,
    required this.repoId,
    required this.fileName,
    required this.fileSizeMB,
    required this.minRamMB,
    required this.minVramMB,
    required this.description,
  });

  String get downloadUrl =>
      'https://huggingface.co/$repoId/resolve/main/$fileName';

  String get fileSizeDisplay {
    if (fileSizeMB >= 1000) {
      return '${(fileSizeMB / 1000).toStringAsFixed(1)} GB';
    }
    return '$fileSizeMB MB';
  }

  String get ramDisplay => '${(minRamMB / 1024).toStringAsFixed(0)} GB RAM';

  String get vramDisplay =>
      minVramMB > 0 ? '${(minVramMB / 1024).toStringAsFixed(0)} GB VRAM' : 'CPU only';
}
