# SkwirlsAI

A cross-platform local LLM assistant built with Flutter. Runs Gemma 4 models on-device with Google Workspace integration, offline-first sync, and multimodal content generation.

## Features

- **Local LLM Inference** — Runs Gemma 4 (2B/9B/27B) via llama.cpp, fully offline
- **Bring Your Own Model** — Import any GGUF model
- **Gems System** — Custom system prompts with per-Gem conversations and RAG
- **Google Workspace** — Calendar, Gmail, Drive sync (opt-in)
- **Agent Mode** — Tool use with chain-of-thought reasoning and safety guardrails
- **RAG** — BM25 keyword search (default) or semantic search (optional embedding model)
- **Content Generation** — Image (Stable Diffusion), video, audio generation (all opt-in downloads)
- **Offline-First Sync** — Google Drive appDataFolder with conflict resolution UI
- **SVL Branding** — Dark theme (#111111), Amber (#E3AB59), Teal (#58AFAE)

## Platforms

| Platform | Status |
|----------|--------|
| Windows  | Day 1  |
| Android  | Day 1  |
| Ubuntu Linux | Day 1 |
| macOS    | Optional |

## Prerequisites

1. **Flutter SDK** 3.x+ installed and on PATH
2. **Visual Studio 2022** with C++ Desktop Development workload (Windows builds)
3. **Android Studio** or Android SDK with NDK (Android builds)
4. **GCC/Clang + CMake** (Linux builds)
5. **Google Cloud Console** project with OAuth 2.0 Client IDs

## Getting Started

```bash
# Install dependencies
flutter pub get

# Generate Isar schemas
dart run build_runner build

# Run on current platform
flutter run

# Build release
flutter build windows --release
flutter build apk --release
flutter build linux --release
```

## Architecture

```
lib/
  core/          — Constants, theme, utilities
  data/
    models/      — Isar data models
    repositories/— Data access layer
    services/    — Business logic services
  domain/
    entities/    — Domain entities
    usecases/    — Application use cases
  presentation/
    screens/     — UI screens
    widgets/     — Reusable widgets
    providers/   — Riverpod state providers
```

## Tech Stack

- **UI**: Flutter 3.x
- **LLM**: llama_cpp_dart (FFI to llama.cpp)
- **Database**: Isar (NoSQL)
- **Auth**: Google OAuth (no Firebase)
- **State**: Riverpod
- **Sync**: Google Drive API v3

## License

Proprietary — SVL
