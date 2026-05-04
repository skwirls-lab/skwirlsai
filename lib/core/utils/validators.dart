class Validators {
  Validators._();

  static String? acornName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (value.trim().length > 50) return 'Name must be under 50 characters';
    return null;
  }

  static String? systemPrompt(String? value) {
    if (value != null && value.length > 10000) {
      return 'System prompt must be under 10,000 characters';
    }
    return null;
  }

  static String? chatMessage(String? value) {
    if (value == null || value.trim().isEmpty) return 'Message cannot be empty';
    return null;
  }

  static bool isValidGgufFile(String path) {
    return path.toLowerCase().endsWith('.gguf');
  }

  static bool isValidDocumentFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.pdf') ||
        lower.endsWith('.txt') ||
        lower.endsWith('.md') ||
        lower.endsWith('.docx');
  }

  static bool isValidImageFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  static bool isValidAudioFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.ogg');
  }

  static bool isValidVideoFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi');
  }
}
