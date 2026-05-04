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

  // Hugging Face model repository URLs (GGUF Q4_K_M quantized)
  static const Map<String, ModelDownloadInfo> gemma4Models = {
    'gemma-2-2b': ModelDownloadInfo(
      id: 'gemma-2-2b',
      displayName: 'Gemma 2 2B Instruct (Q4_K_M)',
      repoId: 'bartowski/gemma-2-2b-it-GGUF',
      fileName: 'gemma-2-2b-it-Q4_K_M.gguf',
      fileSizeMB: 1630,
      minRamMB: 4096,
      minVramMB: 0,
      description: 'Lightweight — good for low-RAM devices',
    ),
    'gemma-2-9b': ModelDownloadInfo(
      id: 'gemma-2-9b',
      displayName: 'Gemma 2 9B Instruct (Q4_K_M)',
      repoId: 'bartowski/gemma-2-9b-it-GGUF',
      fileName: 'gemma-2-9b-it-Q4_K_M.gguf',
      fileSizeMB: 5490,
      minRamMB: 8192,
      minVramMB: 0,
      description: 'Balanced quality and speed for 8GB+ RAM',
    ),
    'gemma-2-27b': ModelDownloadInfo(
      id: 'gemma-2-27b',
      displayName: 'Gemma 2 27B Instruct (Q4_K_M)',
      repoId: 'bartowski/gemma-2-27b-it-GGUF',
      fileName: 'gemma-2-27b-it-Q4_K_M.gguf',
      fileSizeMB: 16700,
      minRamMB: 20480,
      minVramMB: 0,
      description: 'High quality — needs 20GB+ RAM',
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
