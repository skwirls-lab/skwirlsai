import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import 'inference_provider.dart';

/// Remote LLM inference via OpenAI-compatible API.
///
/// Works with:
///   - Ollama (http://localhost:11434)
///   - vLLM, LM Studio, LocalAI, text-generation-webui
///   - OpenAI, Anthropic (via compatible proxy), Groq, Together, etc.
///   - Any endpoint that speaks the /v1/chat/completions SSE protocol
class RemoteInferenceProvider implements InferenceProvider {
  static const _tag = 'RemoteInference';

  String? _baseUrl;
  String? _apiKey;
  String? _modelName;
  bool _isReady = false;
  bool _isGenerating = false;
  http.Client? _activeClient;

  @override
  String get providerName => 'Remote ($_baseUrl)';

  @override
  bool get isReady => _isReady;

  @override
  bool get isGenerating => _isGenerating;

  String? get baseUrl => _baseUrl;
  String? get modelName => _modelName;

  @override
  Future<void> initialize(ModelConfig config) async {
    if (config.source != ModelSource.remote || config.baseUrl == null) {
      throw ArgumentError('RemoteInferenceProvider requires a base URL');
    }

    _baseUrl = config.baseUrl!.endsWith('/') ? config.baseUrl!.substring(0, config.baseUrl!.length - 1) : config.baseUrl!;
    _apiKey = config.apiKey;
    _modelName = config.modelName;

    Log.i(_tag, 'Connecting to: $_baseUrl (model: $_modelName)');

    // Verify endpoint is reachable
    try {
      final testUrl = _isOllamaEndpoint
          ? '$_baseUrl/api/tags'
          : '$_baseUrl/v1/models';

      final response = await http.get(
        Uri.parse(testUrl),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        Log.i(_tag, 'Endpoint reachable. Status: ${response.statusCode}');
        _isReady = true;
      } else {
        Log.w(_tag, 'Endpoint returned ${response.statusCode}: ${response.body}');
        // Still mark ready — some endpoints don't support /v1/models
        _isReady = true;
      }
    } catch (e) {
      Log.w(_tag, 'Could not verify endpoint: $e — marking ready anyway');
      // Mark ready anyway since the endpoint might only support /chat/completions
      _isReady = true;
    }
  }

  @override
  Future<void> shutdown() async {
    _activeClient?.close();
    _activeClient = null;
    _isReady = false;
    _isGenerating = false;
    Log.i(_tag, 'Disconnected');
  }

  @override
  Stream<String> generateStream({
    required List<ChatMessage> messages,
    String? systemPrompt,
    GenerationParams? params,
  }) async* {
    if (!_isReady) {
      throw StateError('Remote endpoint not initialized. Call initialize() first.');
    }
    if (_isGenerating) {
      throw StateError('Already generating.');
    }

    _isGenerating = true;
    final p = params ?? const GenerationParams();

    try {
      // Build messages array
      final apiMessages = <Map<String, dynamic>>[];

      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        apiMessages.add({'role': 'system', 'content': systemPrompt});
      }

      for (final msg in messages) {
        apiMessages.add(msg.toJson());
      }

      // Use the appropriate API format
      if (_isOllamaEndpoint) {
        yield* _generateOllama(apiMessages, p);
      } else {
        yield* _generateOpenAICompat(apiMessages, p);
      }
    } catch (e, st) {
      Log.e(_tag, 'Generation failed', e, st);
      rethrow;
    } finally {
      _isGenerating = false;
      _activeClient?.close();
      _activeClient = null;
    }
  }

  /// OpenAI-compatible /v1/chat/completions with SSE streaming
  Stream<String> _generateOpenAICompat(
    List<Map<String, dynamic>> messages,
    GenerationParams params,
  ) async* {
    final url = '$_baseUrl/v1/chat/completions';

    final body = jsonEncode({
      'model': _modelName ?? 'default',
      'messages': messages,
      'stream': true,
      'temperature': params.temperature,
      'top_p': params.topP,
      'max_tokens': params.maxTokens,
      'repeat_penalty': params.repeatPenalty,
    });

    Log.i(_tag, 'POST $url (${messages.length} messages)');

    _activeClient = http.Client();
    final request = http.Request('POST', Uri.parse(url));
    request.headers.addAll({
      'Content-Type': 'application/json',
      ..._headers,
    });
    request.body = body;

    final response = await _activeClient!.send(request);

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception('API error ${response.statusCode}: $errorBody');
    }

    // Parse SSE stream
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed == 'data: [DONE]') continue;
        if (!trimmed.startsWith('data: ')) continue;

        try {
          final json = jsonDecode(trimmed.substring(6)) as Map<String, dynamic>;
          final choices = json['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          }
        } catch (_) {
          // Skip malformed SSE lines
        }
      }
    }
  }

  /// Ollama native /api/chat with streaming
  Stream<String> _generateOllama(
    List<Map<String, dynamic>> messages,
    GenerationParams params,
  ) async* {
    final url = '$_baseUrl/api/chat';

    final body = jsonEncode({
      'model': _modelName ?? 'llama3',
      'messages': messages,
      'stream': true,
      'options': {
        'temperature': params.temperature,
        'top_p': params.topP,
        'top_k': params.topK,
        'num_predict': params.maxTokens,
        'repeat_penalty': params.repeatPenalty,
      },
    });

    Log.i(_tag, 'POST $url (model: $_modelName, ${messages.length} messages)');

    _activeClient = http.Client();
    final request = http.Request('POST', Uri.parse(url));
    request.headers['Content-Type'] = 'application/json';
    request.body = body;

    final response = await _activeClient!.send(request);

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception('Ollama error ${response.statusCode}: $errorBody');
    }

    // Ollama streams newline-delimited JSON
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        if (line.trim().isEmpty) continue;

        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final message = json['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            yield content;
          }

          // Check if done
          if (json['done'] == true) return;
        } catch (_) {
          // Skip malformed lines
        }
      }
    }
  }

  @override
  void stopGeneration() {
    if (_isGenerating) {
      _activeClient?.close();
      _activeClient = null;
      _isGenerating = false;
      Log.i(_tag, 'Generation stopped');
    }
  }

  /// Detect if this is an Ollama endpoint (port 11434 is the giveaway)
  bool get _isOllamaEndpoint {
    if (_baseUrl == null) return false;
    final uri = Uri.tryParse(_baseUrl!);
    return uri != null && uri.port == 11434;
  }

  Map<String, String> get _headers {
    final h = <String, String>{};
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_apiKey';
    }
    return h;
  }
}
