import 'dart:async';
import 'dart:isolate';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

/// Runs llama.cpp inference in a background isolate so the UI thread
/// is never blocked by synchronous FFI calls (setPrompt / getNext).
class IsolateInferenceWorker {
  Isolate? _isolate;
  SendPort? _commandPort;
  ReceivePort? _responsePort;
  StreamSubscription? _responseSub;

  StreamController<String>? _tokenController;
  Completer<void>? _loadCompleter;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// Spawn a worker isolate and load the model inside it.
  Future<void> loadModel({
    required String modelPath,
    String? libraryPath,
    required int nCtx,
    required int nGpuLayers,
    required int mainGpu,
    required int nThreads,
  }) async {
    await dispose();

    _responsePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _workerMain,
      _responsePort!.sendPort,
    );

    _loadCompleter = Completer<void>();

    _responseSub = _responsePort!.listen((message) {
      if (message is SendPort) {
        _commandPort = message;
        _commandPort!.send({
          'cmd': 'load',
          'modelPath': modelPath,
          'libraryPath': libraryPath,
          'nCtx': nCtx,
          'nGpuLayers': nGpuLayers,
          'mainGpu': mainGpu,
          'nThreads': nThreads,
        });
      } else if (message is Map) {
        _handleResponse(message);
      }
    });

    return _loadCompleter!.future;
  }

  void _handleResponse(Map response) {
    final type = response['type'] as String;
    switch (type) {
      case 'loaded':
        _isLoaded = true;
        _loadCompleter?.complete();
        _loadCompleter = null;
        break;
      case 'token':
        _tokenController?.add(response['text'] as String);
        break;
      case 'done':
        _tokenController?.close();
        _tokenController = null;
        break;
      case 'error':
        final error = response['message'] as String;
        if (_loadCompleter != null && !_loadCompleter!.isCompleted) {
          _isLoaded = false;
          _loadCompleter!.completeError(Exception(error));
          _loadCompleter = null;
        } else if (_tokenController != null) {
          _tokenController!.addError(Exception(error));
          _tokenController!.close();
          _tokenController = null;
        }
        break;
    }
  }

  /// Start generating tokens. Returns a stream that emits each token
  /// as it is produced in the background isolate.
  Stream<String> generate(String prompt, int maxTokens) {
    if (_commandPort == null || !_isLoaded) {
      throw StateError('Model not loaded');
    }

    _tokenController = StreamController<String>();

    _commandPort!.send({
      'cmd': 'generate',
      'prompt': prompt,
      'maxTokens': maxTokens,
    });

    return _tokenController!.stream;
  }

  /// Request the worker to stop generating after the current token.
  void stop() {
    _commandPort?.send({'cmd': 'stop'});
  }

  /// Kill the isolate and free resources.
  Future<void> dispose() async {
    if (_commandPort != null) {
      _commandPort!.send({'cmd': 'dispose'});
    }
    await _responseSub?.cancel();
    _responsePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _commandPort = null;
    _responsePort = null;
    _isLoaded = false;
    _tokenController?.close();
    _tokenController = null;
    _loadCompleter = null;
  }
}

// ---------------------------------------------------------------------------
// Worker isolate entry point (must be top-level)
// ---------------------------------------------------------------------------

void _workerMain(SendPort mainPort) {
  final commandPort = ReceivePort();
  mainPort.send(commandPort.sendPort);

  Llama? llama;
  bool stopRequested = false;

  commandPort.listen((message) {
    if (message is! Map) return;
    final cmd = message['cmd'] as String;

    switch (cmd) {
      case 'load':
        try {
          final libraryPath = message['libraryPath'] as String?;
          if (libraryPath != null) {
            Llama.libraryPath = libraryPath;
          }

          final modelParams = ModelParams();
          modelParams.nGpuLayers = message['nGpuLayers'] as int;
          modelParams.mainGpu = message['mainGpu'] as int;

          final nCtx = message['nCtx'] as int;
          final nThreads = message['nThreads'] as int;

          final contextParams = ContextParams();
          contextParams.nCtx = nCtx;
          contextParams.nBatch = nCtx;
          contextParams.nThreads = nThreads;
          contextParams.nThreadsBatch = nThreads;
          contextParams.nPredict = -1;

          llama = Llama(
            message['modelPath'] as String,
            modelParams: modelParams,
            contextParams: contextParams,
            verbose: true,
          );

          mainPort.send({'type': 'loaded'});
        } catch (e) {
          mainPort.send({'type': 'error', 'message': e.toString()});
        }
        break;

      case 'generate':
        stopRequested = false;
        _runGeneration(
          llama!,
          message['prompt'] as String,
          message['maxTokens'] as int,
          mainPort,
          () => stopRequested,
        );
        break;

      case 'stop':
        stopRequested = true;
        break;

      case 'dispose':
        llama?.dispose();
        llama = null;
        commandPort.close();
        break;
    }
  });
}

/// Async generation loop — yields to the isolate event loop between tokens
/// so that 'stop' commands can be received.
Future<void> _runGeneration(
  Llama llama,
  String prompt,
  int maxTokens,
  SendPort port,
  bool Function() shouldStop,
) async {
  try {
    llama.setPrompt(prompt);

    int tokenCount = 0;
    while (tokenCount < maxTokens && !shouldStop()) {
      final (text, isDone) = llama.getNext();

      if (text.isNotEmpty) {
        tokenCount++;
        port.send({'type': 'token', 'text': text});
      }

      if (isDone) break;

      // Yield every token so the isolate event loop can process stop commands
      await Future.delayed(Duration.zero);
    }

    port.send({'type': 'done'});
  } catch (e) {
    port.send({'type': 'error', 'message': e.toString()});
  }
}
