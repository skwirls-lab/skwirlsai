import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
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

  /// Console-visible logging (debugPrint goes to flutter run terminal)
  void _log(String msg) => debugPrint('[Agent] $msg');

  /// Run agent mode: generate, parse tool calls, execute, loop.
  ///
  /// Key design: the agent loop tracks ALL tool calls and their results
  /// across iterations. If the model tries the exact same call again,
  /// we inject the cached result instead of re-executing. If the model
  /// is stuck in a loop (same call 2+ times), we inject a nudge telling
  /// it to try a different approach.
  Stream<AgentEvent> run({
    required List<ChatMessage> messages,
    String? systemPrompt,
    Set<String>? allowedToolNames,
  }) async* {
    _isRunning = true;
    _currentIteration = 0;

    final conversationMessages = List<ChatMessage>.from(messages);
    String lastFullResponse = '';

    // Cross-iteration tool call cache: key → result output
    final toolCallCache = <String, String>{};
    // Count how many times each tool call key was attempted
    final toolCallCounts = <String, int>{};
    // Discovered paths from search_files results (leaf name → full path)
    final discoveredPaths = <String, String>{};

    final toolSchemas = allowedToolNames != null
        ? _toolRegistry.getFilteredToolSchemas(allowedToolNames)
        : _toolRegistry.toolSchemas;

    try {
      while (_isRunning && _currentIteration < AppConstants.maxAgentIterations) {
        _currentIteration++;
        _log('Iteration $_currentIteration/${AppConstants.maxAgentIterations} (${conversationMessages.length} msgs)');

        yield AgentEvent.thinking(iteration: _currentIteration);

        // ── Generate response ──────────────────────────────────────
        final responseBuffer = StringBuffer();
        String? thinkingContent;
        bool timedOut = false;

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
          _log('Generation timed out');
          timedOut = true;
        }

        if (!_isRunning) {
          _log('Stopped by user during generation');
          break;
        }

        final fullResponse = responseBuffer.toString();
        lastFullResponse = fullResponse;

        final preview = fullResponse.length > 300
            ? '${fullResponse.substring(0, 300)}...'
            : fullResponse;
        _log('Response (${fullResponse.length} chars): $preview');

        if (timedOut && fullResponse.trim().isEmpty) {
          yield AgentEvent.finalAnswer('');
          break;
        }

        // ── Extract thinking ──────────────────────────────────────
        final thinkMatch = RegExp(r'<think>(.*?)</think>', dotAll: true)
            .firstMatch(fullResponse);
        if (thinkMatch != null) {
          thinkingContent = thinkMatch.group(1)?.trim();
          yield AgentEvent.thinkingContent(thinkingContent ?? '');
        }

        // ── Parse tool calls ──────────────────────────────────────
        final toolCalls = _toolRegistry.parseToolCalls(fullResponse);
        _log('Parsed ${toolCalls.length} tool call(s): ${toolCalls.map((c) => c.toolName).join(', ')}');

        if (toolCalls.isEmpty) {
          _log('No tool calls → final answer');
          yield AgentEvent.finalAnswer(fullResponse);
          break;
        }

        // ── Deduplicate within this response ──────────────────────
        final seen = <String>{};
        final uniqueCalls = <ToolCall>[];
        for (final call in toolCalls) {
          final key = '${call.toolName}:${call.arguments}';
          if (seen.add(key)) uniqueCalls.add(call);
        }

        // ── Strip narrative, keep only tool_call blocks ───────────
        final toolCallBlocks = RegExp(
            r'```tool_call[\s\S]*?```|<tool_call>[\s\S]*?</tool_call>')
            .allMatches(fullResponse)
            .map((m) => m.group(0))
            .join('\n');
        final cleanedAssistant =
            toolCallBlocks.isNotEmpty ? toolCallBlocks : fullResponse;

        conversationMessages.add(ChatMessage(
          role: 'assistant',
          content: cleanedAssistant,
        ));

        // ── Execute tool calls ────────────────────────────────────
        bool anyExecuted = false;
        bool allRepeats = true;

        for (final call in uniqueCalls) {
          if (!_isRunning) {
            _log('Stopped by user before tool: ${call.toolName}');
            break;
          }

          final callKey = '${call.toolName}:${call.arguments}';
          toolCallCounts[callKey] = (toolCallCounts[callKey] ?? 0) + 1;
          final repeatCount = toolCallCounts[callKey]!;

          // ── Cross-iteration dedup: if we already ran this exact
          //    call, inject the cached result instead of re-running
          if (repeatCount > 1 && toolCallCache.containsKey(callKey)) {
            final cachedOutput = toolCallCache[callKey]!;
            _log('REPEAT #$repeatCount: ${call.toolName} — using cached result');

            yield AgentEvent.toolExecuting(call);
            final cachedResult = ToolResult(
              toolName: call.toolName,
              callId: call.id,
              success: true,
              output: cachedOutput,
              executionTime: Duration.zero,
            );
            yield AgentEvent.toolResult(cachedResult);

            // Add a nudge telling the model to try something different
            conversationMessages.add(ChatMessage(
              role: 'tool',
              content: '[CACHED — ALREADY CALLED] ${call.toolName} result: $cachedOutput\n\n'
                  'You already called ${call.toolName} with these exact arguments. '
                  'Do NOT call it again. Use the result above and proceed: '
                  'call a DIFFERENT tool (e.g., search_content, read_file, list_files) '
                  'or give your final answer.',
            ));
            continue;
          }

          allRepeats = false;

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

          // ── Path auto-correction ─────────────────────────
          // If the tool has a 'path' argument, check if it exists.
          // If not, try to find a discovered path with the same
          // leaf name and substitute it.
          if (call.arguments.containsKey('path')) {
            final originalPath = call.arguments['path'] as String;
            if (!await Directory(originalPath).exists() &&
                !await File(originalPath).exists()) {
              final leaf = originalPath.split(RegExp(r'[\\/]')).last.toLowerCase();
              final corrected = discoveredPaths[leaf];
              if (corrected != null && corrected != originalPath) {
                _log('PATH AUTO-CORRECT: "$originalPath" → "$corrected"');
                call.arguments['path'] = corrected;
              }
            }
          }

          // Execute the tool
          yield AgentEvent.toolExecuting(call);
          final result = await _toolRegistry.executeTool(call);
          yield AgentEvent.toolResult(result);
          anyExecuted = true;

          // Cache the result for cross-iteration dedup
          // Use the ORIGINAL callKey (before path correction) for dedup
          toolCallCache[callKey] = result.output;

          // ── Extract discovered paths from search_files results ──
          if (call.toolName == 'search_files' && result.success) {
            final dirPattern = RegExp(r'\[DIR\]\s+(.+)');
            final filePattern = RegExp(r'\[FILE\]\s+(.+)');
            for (final m in dirPattern.allMatches(result.output)) {
              final fullPath = m.group(1)!.trim();
              final leafName = fullPath.split(RegExp(r'[\\\/]')).last.toLowerCase();
              discoveredPaths[leafName] = fullPath;
              _log('Discovered dir: $leafName → $fullPath');
            }
            for (final m in filePattern.allMatches(result.output)) {
              final fullPath = m.group(1)!.trim();
              final leafName = fullPath.split(RegExp(r'[\\\/]')).last.toLowerCase();
              discoveredPaths[leafName] = fullPath;
            }
          }

          final statusLabel = result.success ? 'SUCCESS' : 'FAILED';
          conversationMessages.add(ChatMessage(
            role: 'tool',
            content: '[$statusLabel] ${call.toolName} result: ${result.output}',
          ));

          _log('Tool ${call.toolName}: $statusLabel (${result.output.length} chars)');
        }

        if (!_isRunning) break;

        // ── Stuck loop detection ──────────────────────────────────
        // If ALL calls in this iteration were repeats, the model is
        // stuck. Give it 2 chances with the nudge, then break.
        if (allRepeats) {
          final maxRepeat = toolCallCounts.values.fold(0,
              (a, b) => a > b ? a : b);
          _log('All calls were repeats (max count: $maxRepeat)');
          if (maxRepeat >= 3) {
            _log('Model stuck in loop — breaking');
            yield AgentEvent.finalAnswer(lastFullResponse);
            break;
          }
        }
      }

      if (_isRunning && _currentIteration >= AppConstants.maxAgentIterations) {
        _log('Reached max iterations');
        yield AgentEvent.finalAnswer(lastFullResponse);
        yield AgentEvent.maxIterationsReached();
      }
    } catch (e, st) {
      _log('Error: $e');
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
      _log('Stopped by user');
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
