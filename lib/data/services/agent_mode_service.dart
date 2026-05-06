import 'dart:async';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/tool.dart';
import 'inference_service.dart';
import 'tool_registry.dart';

class AgentModeService {
  static const _tag = 'AgentModeService';

  final InferenceService _inferenceService;
  final ToolRegistry _toolRegistry;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  int _currentIteration = 0;
  int get currentIteration => _currentIteration;

  final _agentEventController = StreamController<AgentEvent>.broadcast();
  Stream<AgentEvent> get agentEvents => _agentEventController.stream;

  /// Callback for requesting user confirmation on sensitive tools
  Future<bool> Function(ToolCall call)? onConfirmationRequired;

  AgentModeService({
    required InferenceService inferenceService,
    required ToolRegistry toolRegistry,
  })  : _inferenceService = inferenceService,
        _toolRegistry = toolRegistry;

  /// Run agent mode: generate, parse tool calls, execute, loop
  /// If [allowedToolNames] is provided, only those tools are made available.
  Stream<AgentEvent> run({
    required List<ChatMessage> messages,
    String? systemPrompt,
    Set<String>? allowedToolNames,
  }) async* {
    _isRunning = true;
    _currentIteration = 0;

    final conversationMessages = List<ChatMessage>.from(messages);
    // Track consecutive failures to detect stuck loops
    int consecutiveFailures = 0;
    String lastFullResponse = '';

    try {
      while (_isRunning && _currentIteration < AppConstants.maxAgentIterations) {
        _currentIteration++;
        Log.i(_tag, 'Agent iteration $_currentIteration/${AppConstants.maxAgentIterations}');

        yield AgentEvent.thinking(iteration: _currentIteration);

        // Generate response — buffer silently, do NOT stream tokens yet
        final responseBuffer = StringBuffer();
        String? thinkingContent;
        bool timedOut = false;

        final toolSchemas = allowedToolNames != null
            ? _toolRegistry.getFilteredToolSchemas(allowedToolNames)
            : _toolRegistry.toolSchemas;

        // Add a timeout to prevent generation from hanging indefinitely
        try {
          await for (final token in _inferenceService.generateStream(
            messages: conversationMessages,
            agentMode: true,
            systemPrompt: systemPrompt,
            tools: toolSchemas,
          ).timeout(AppConstants.agentGenerationTimeout)) {
            if (!_isRunning) break;
            responseBuffer.write(token);
          }
        } on TimeoutException {
          Log.w(_tag, 'Generation timed out on iteration $_currentIteration');
          timedOut = true;
        }

        final fullResponse = responseBuffer.toString();
        lastFullResponse = fullResponse;
        Log.i(_tag, 'Response length: ${fullResponse.length} chars (timeout: $timedOut)');

        // If timed out with no content, break out
        if (timedOut && fullResponse.trim().isEmpty) {
          yield AgentEvent.finalAnswer('');
          break;
        }

        // Extract thinking content if present
        final thinkRegex = RegExp(r'<think>(.*?)</think>', dotAll: true);
        final thinkMatch = thinkRegex.firstMatch(fullResponse);
        if (thinkMatch != null) {
          thinkingContent = thinkMatch.group(1)?.trim();
          yield AgentEvent.thinkingContent(thinkingContent ?? '');
        }

        // Parse tool calls from the response
        final toolCalls = _toolRegistry.parseToolCalls(fullResponse);

        if (toolCalls.isEmpty) {
          // No tool calls = the model decided to give a final answer
          yield AgentEvent.finalAnswer(fullResponse);
          break;
        }

        // Add the assistant message (contains tool call(s))
        conversationMessages.add(ChatMessage(
          role: 'assistant',
          content: fullResponse,
        ));

        // Execute tool calls
        bool allFailed = true;
        for (final call in toolCalls) {
          // Check if confirmation is needed
          if (_toolRegistry.requiresConfirmation(call.toolName)) {
            yield AgentEvent.confirmationRequired(call);

            if (onConfirmationRequired != null) {
              final confirmed = await onConfirmationRequired!(call);
              if (!confirmed) {
                yield AgentEvent.toolResult(ToolResult(
                  toolName: call.toolName,
                  callId: call.id,
                  success: false,
                  output: 'User declined to execute this tool.',
                  executionTime: Duration.zero,
                ));

                conversationMessages.add(ChatMessage(
                  role: 'tool',
                  content: 'Tool ${call.toolName} was declined by the user.',
                ));
                continue;
              }
            }
          }

          // Execute the tool
          yield AgentEvent.toolExecuting(call);

          final result = await _toolRegistry.executeTool(call);
          yield AgentEvent.toolResult(result);

          if (result.success) allFailed = false;

          // Add tool result to conversation for next iteration
          final statusLabel = result.success ? 'SUCCESS' : 'FAILED';
          conversationMessages.add(ChatMessage(
            role: 'tool',
            content: '[$statusLabel] ${call.toolName} result: ${result.output}',
          ));
        }

        // Track consecutive all-fail iterations
        if (allFailed) {
          consecutiveFailures++;
          Log.w(_tag, 'All tool calls failed ($consecutiveFailures consecutive)');
          if (consecutiveFailures >= 3) {
            Log.w(_tag, 'Too many consecutive failures — breaking');
            yield AgentEvent.finalAnswer(lastFullResponse);
            break;
          }
        } else {
          consecutiveFailures = 0; // reset on any success
        }
      }

      if (_currentIteration >= AppConstants.maxAgentIterations) {
        Log.w(_tag, 'Agent reached max iterations');
        yield AgentEvent.finalAnswer(lastFullResponse);
        yield AgentEvent.maxIterationsReached();
      }
    } catch (e, st) {
      Log.e(_tag, 'Agent mode error', e, st);
      yield AgentEvent.error(e.toString());
    } finally {
      _isRunning = false;
      _currentIteration = 0;
    }
  }

  /// Stop the agent mid-execution
  void stop() {
    if (_isRunning) {
      _isRunning = false;
      _inferenceService.stopGeneration();
      Log.i(_tag, 'Agent stopped by user');
      _agentEventController.add(AgentEvent.stopped());
    }
  }

  void dispose() {
    _agentEventController.close();
  }
}

enum AgentEventType {
  thinking,
  thinkingContent,
  token,
  confirmationRequired,
  toolExecuting,
  toolResult,
  finalAnswer,
  maxIterationsReached,
  stopped,
  error,
}

class AgentEvent {
  final AgentEventType type;
  final String? text;
  final int? iteration;
  final ToolCall? toolCall;
  final ToolResult? result;

  const AgentEvent._({
    required this.type,
    this.text,
    this.iteration,
    this.toolCall,
    this.result,
  });

  factory AgentEvent.thinking({required int iteration}) =>
      AgentEvent._(type: AgentEventType.thinking, iteration: iteration);

  factory AgentEvent.thinkingContent(String content) =>
      AgentEvent._(type: AgentEventType.thinkingContent, text: content);

  factory AgentEvent.token(String token) =>
      AgentEvent._(type: AgentEventType.token, text: token);

  factory AgentEvent.confirmationRequired(ToolCall call) =>
      AgentEvent._(type: AgentEventType.confirmationRequired, toolCall: call);

  factory AgentEvent.toolExecuting(ToolCall call) =>
      AgentEvent._(type: AgentEventType.toolExecuting, toolCall: call);

  factory AgentEvent.toolResult(ToolResult result) =>
      AgentEvent._(type: AgentEventType.toolResult, result: result);

  factory AgentEvent.finalAnswer(String answer) =>
      AgentEvent._(type: AgentEventType.finalAnswer, text: answer);

  factory AgentEvent.maxIterationsReached() =>
      const AgentEvent._(type: AgentEventType.maxIterationsReached);

  factory AgentEvent.stopped() =>
      const AgentEvent._(type: AgentEventType.stopped);

  factory AgentEvent.error(String message) =>
      AgentEvent._(type: AgentEventType.error, text: message);
}
