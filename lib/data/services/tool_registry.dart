import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/tool.dart';
import 'rag_service.dart';
import 'calendar_service.dart';
import 'gmail_service.dart';

class ToolRegistry {
  static const _tag = 'ToolRegistry';

  final RagService _ragService;
  final CalendarService _calendarService;
  final GmailService _gmailService;

  final Map<String, Tool> _tools = {};
  final Map<String, Future<ToolResult> Function(Map<String, dynamic>)> _handlers = {};

  ToolRegistry({
    required RagService ragService,
    required CalendarService calendarService,
    required GmailService gmailService,
  })  : _ragService = ragService,
        _calendarService = calendarService,
        _gmailService = gmailService {
    _registerBuiltInTools();
  }

  /// Get all registered tools
  List<Tool> get tools => _tools.values.toList();

  /// Get tool schemas for LLM function calling
  List<Map<String, dynamic>> get toolSchemas =>
      _tools.values.map((t) => t.toFunctionSchema()).toList();

  /// Get filtered tool schemas for a specific set of allowed skill names
  List<Map<String, dynamic>> getFilteredToolSchemas(Set<String> allowedNames) =>
      _tools.values
          .where((t) => allowedNames.contains(t.name))
          .map((t) => t.toFunctionSchema())
          .toList();

  /// Get filtered tools by name
  List<Tool> getFilteredTools(Set<String> allowedNames) =>
      _tools.values.where((t) => allowedNames.contains(t.name)).toList();

  /// Execute a tool call with safety guardrails
  Future<ToolResult> executeTool(ToolCall call) async {
    final tool = _tools[call.toolName];
    if (tool == null) {
      return ToolResult(
        toolName: call.toolName,
        callId: call.id,
        success: false,
        output: 'Unknown tool: ${call.toolName}',
        executionTime: Duration.zero,
      );
    }

    final handler = _handlers[call.toolName];
    if (handler == null) {
      return ToolResult(
        toolName: call.toolName,
        callId: call.id,
        success: false,
        output: 'No handler registered for: ${call.toolName}',
        executionTime: Duration.zero,
      );
    }

    // Validate arguments against schema
    if (!_validateArguments(tool, call.arguments)) {
      return ToolResult(
        toolName: call.toolName,
        callId: call.id,
        success: false,
        output: 'Invalid arguments for ${call.toolName}',
        executionTime: Duration.zero,
      );
    }

    Log.i(_tag, 'Executing tool: ${call.toolName}');
    final stopwatch = Stopwatch()..start();

    try {
      final result = await handler(call.arguments)
          .timeout(AppConstants.agentToolTimeout);
      stopwatch.stop();
      return ToolResult(
        toolName: call.toolName,
        callId: call.id,
        success: result.success,
        output: result.output,
        executionTime: stopwatch.elapsed,
      );
    } on TimeoutException {
      stopwatch.stop();
      Log.w(_tag, 'Tool timed out: ${call.toolName}');
      return ToolResult(
        toolName: call.toolName,
        callId: call.id,
        success: false,
        output: 'Tool execution timed out after ${AppConstants.agentToolTimeout.inSeconds}s',
        executionTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      Log.e(_tag, 'Tool execution failed: ${call.toolName}', e);
      return ToolResult(
        toolName: call.toolName,
        callId: call.id,
        success: false,
        output: 'Error: $e',
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Check if a tool requires user confirmation before execution
  bool requiresConfirmation(String toolName) {
    final tool = _tools[toolName];
    if (tool == null) return true; // Unknown tools always need confirmation
    return tool.requiresConfirmation;
  }

  /// Parse tool calls from LLM response text
  List<ToolCall> parseToolCalls(String responseText) {
    final calls = <ToolCall>[];

    // Look for JSON function calls in the response
    final jsonPattern = RegExp(r'\{[^{}]*"name"\s*:\s*"[^"]+"\s*,\s*"arguments"\s*:\s*\{[^{}]*\}[^{}]*\}');
    final matches = jsonPattern.allMatches(responseText);

    for (final match in matches) {
      try {
        final json = jsonDecode(match.group(0)!) as Map<String, dynamic>;
        calls.add(ToolCall.fromJson(json));
      } catch (e) {
        Log.w(_tag, 'Failed to parse tool call: ${match.group(0)}');
      }
    }

    return calls;
  }

  void _registerBuiltInTools() {
    // search_svl_docs - Local RAG search
    _register(
      Tool(
        name: 'search_svl_docs',
        description: 'Search through the user\'s local documents for relevant information',
        category: ToolCategory.local,
        parameters: {
          'query': const ToolParameter(
            type: 'string',
            description: 'Search query',
            required: true,
          ),
          'acorn_id': const ToolParameter(
            type: 'string',
            description: 'Acorn ID to search within',
            required: true,
          ),
        },
      ),
      (args) async {
        final results = await _ragService.search(
          query: args['query'] as String,
          acornId: args['acorn_id'] as String,
        );
        return ToolResult(
          toolName: 'search_svl_docs',
          success: true,
          output: results.isEmpty
              ? 'No relevant documents found.'
              : results.map((r) => '[doc:${r.documentId} chunk:${r.chunkIndex}] ${r.chunkText}').join('\n\n---\n\n'),
          executionTime: Duration.zero,
        );
      },
    );

    // read_file - Read a file from disk
    _register(
      Tool(
        name: 'read_file',
        description: 'Read the contents of a file from disk. Returns the text content.',
        category: ToolCategory.local,
        parameters: {
          'path': const ToolParameter(
            type: 'string',
            description: 'Absolute file path to read',
            required: true,
          ),
        },
      ),
      (args) async {
        final path = args['path'] as String;
        try {
          final file = File(path);
          if (!await file.exists()) {
            return ToolResult(
              toolName: 'read_file',
              success: false,
              output: 'File not found: $path',
              executionTime: Duration.zero,
            );
          }
          final content = await file.readAsString();
          // Limit output to avoid blowing context
          final trimmed = content.length > 10000
              ? '${content.substring(0, 10000)}\n[...truncated at 10000 chars, file is ${content.length} chars total]'
              : content;
          return ToolResult(
            toolName: 'read_file',
            success: true,
            output: trimmed,
            executionTime: Duration.zero,
          );
        } catch (e) {
          return ToolResult(
            toolName: 'read_file',
            success: false,
            output: 'Error reading file: $e',
            executionTime: Duration.zero,
          );
        }
      },
    );

    // list_files - List directory contents
    _register(
      Tool(
        name: 'list_files',
        description: 'List files and directories at a given path. Returns names, types, and sizes.',
        category: ToolCategory.local,
        parameters: {
          'path': const ToolParameter(
            type: 'string',
            description: 'Absolute directory path to list',
            required: true,
          ),
        },
      ),
      (args) async {
        final path = args['path'] as String;
        try {
          final dir = Directory(path);
          if (!await dir.exists()) {
            return ToolResult(
              toolName: 'list_files',
              success: false,
              output: 'Directory not found: $path',
              executionTime: Duration.zero,
            );
          }
          final entries = await dir.list().take(100).toList();
          final lines = entries.map((e) {
            final stat = e.statSync();
            final type = stat.type == FileSystemEntityType.directory ? 'DIR' : 'FILE';
            final size = stat.type == FileSystemEntityType.file
                ? ' (${(stat.size / 1024).toStringAsFixed(1)} KB)'
                : '';
            return '[$type] ${e.path.split(Platform.pathSeparator).last}$size';
          }).toList();
          return ToolResult(
            toolName: 'list_files',
            success: true,
            output: lines.isEmpty ? 'Directory is empty.' : lines.join('\n'),
            executionTime: Duration.zero,
          );
        } catch (e) {
          return ToolResult(
            toolName: 'list_files',
            success: false,
            output: 'Error listing directory: $e',
            executionTime: Duration.zero,
          );
        }
      },
    );

    // write_file - Write content to a file (requires confirmation)
    _register(
      Tool(
        name: 'write_file',
        description: 'Write text content to a file. Creates the file if it does not exist, overwrites if it does.',
        category: ToolCategory.externalWrite,
        requiresConfirmation: true,
        parameters: {
          'path': const ToolParameter(
            type: 'string',
            description: 'Absolute file path to write to',
            required: true,
          ),
          'content': const ToolParameter(
            type: 'string',
            description: 'Text content to write',
            required: true,
          ),
        },
      ),
      (args) async {
        final path = args['path'] as String;
        final content = args['content'] as String;
        try {
          final file = File(path);
          await file.parent.create(recursive: true);
          await file.writeAsString(content);
          return ToolResult(
            toolName: 'write_file',
            success: true,
            output: 'Successfully wrote ${content.length} characters to $path',
            executionTime: Duration.zero,
          );
        } catch (e) {
          return ToolResult(
            toolName: 'write_file',
            success: false,
            output: 'Error writing file: $e',
            executionTime: Duration.zero,
          );
        }
      },
    );

    // list_google_calendar_events - Calendar (requires confirmation)
    _register(
      Tool(
        name: 'list_google_calendar_events',
        description: 'List upcoming events from the user\'s Google Calendar',
        category: ToolCategory.externalRead,
        requiresConfirmation: true,
        parameters: {
          'days_ahead': const ToolParameter(
            type: 'integer',
            description: 'Number of days ahead to look (default: 7)',
            defaultValue: 7,
          ),
        },
      ),
      (args) async {
        final days = args['days_ahead'] as int? ?? 7;
        final events = await _calendarService.getUpcomingEvents(daysAhead: days);
        return ToolResult(
          toolName: 'list_google_calendar_events',
          success: true,
          output: events.isEmpty
              ? 'No upcoming events found.'
              : events.map((e) => '${e['summary']} - ${e['start']}').join('\n'),
          executionTime: Duration.zero,
        );
      },
    );

    // search_gmail - Gmail search (requires confirmation)
    _register(
      Tool(
        name: 'search_gmail',
        description: 'Search the user\'s Gmail for emails matching a query',
        category: ToolCategory.externalRead,
        requiresConfirmation: true,
        parameters: {
          'query': const ToolParameter(
            type: 'string',
            description: 'Gmail search query',
            required: true,
          ),
        },
      ),
      (args) async {
        final results = await _gmailService.searchEmails(
          query: args['query'] as String,
        );
        return ToolResult(
          toolName: 'search_gmail',
          success: true,
          output: results.isEmpty
              ? 'No emails found.'
              : results.map((e) => '${e['subject']} - ${e['from']} (${e['date']})').join('\n'),
          executionTime: Duration.zero,
        );
      },
    );

    // get_recent_emails - Gmail (requires confirmation)
    _register(
      Tool(
        name: 'get_recent_emails',
        description: 'Get the most recent emails from the user\'s Gmail inbox',
        category: ToolCategory.externalRead,
        requiresConfirmation: true,
        parameters: {
          'count': const ToolParameter(
            type: 'integer',
            description: 'Number of emails to retrieve (default: 10)',
            defaultValue: 10,
          ),
        },
      ),
      (args) async {
        final count = args['count'] as int? ?? 10;
        final emails = await _gmailService.getRecentEmails(count: count);
        return ToolResult(
          toolName: 'get_recent_emails',
          success: true,
          output: emails.isEmpty
              ? 'No recent emails.'
              : emails.map((e) => '${e['subject']} - ${e['from']} (${e['date']})').join('\n'),
          executionTime: Duration.zero,
        );
      },
    );

    // web_search - DuckDuckGo (no API key needed)
    _register(
      Tool(
        name: 'web_search',
        description: 'Search the web using DuckDuckGo',
        category: ToolCategory.externalRead,
        requiresConfirmation: true,
        parameters: {
          'query': const ToolParameter(
            type: 'string',
            description: 'Search query',
            required: true,
          ),
        },
      ),
      (args) async {
        // TODO: Implement DuckDuckGo API search
        return ToolResult(
          toolName: 'web_search',
          success: false,
          output: 'Web search not yet implemented',
          executionTime: Duration.zero,
        );
      },
    );

    // generate_image - Local SD (no confirmation for generation)
    _register(
      Tool(
        name: 'generate_image',
        description: 'Generate an image using Stable Diffusion (if model is downloaded)',
        category: ToolCategory.generation,
        parameters: {
          'prompt': const ToolParameter(
            type: 'string',
            description: 'Image generation prompt',
            required: true,
          ),
          'negative_prompt': const ToolParameter(
            type: 'string',
            description: 'Negative prompt (things to avoid)',
          ),
          'steps': const ToolParameter(
            type: 'integer',
            description: 'Number of inference steps (default: 4 for Turbo)',
            defaultValue: 4,
          ),
        },
      ),
      (args) async {
        // TODO: Connect to ImageGenerationService
        return ToolResult(
          toolName: 'generate_image',
          success: false,
          output: 'Image generation model not downloaded. Go to Settings > Models to download.',
          executionTime: Duration.zero,
        );
      },
    );

    Log.i(_tag, 'Registered ${_tools.length} built-in tools');
  }

  void _register(
    Tool tool,
    Future<ToolResult> Function(Map<String, dynamic>) handler,
  ) {
    _tools[tool.name] = tool;
    _handlers[tool.name] = handler;
  }

  bool _validateArguments(Tool tool, Map<String, dynamic> args) {
    for (final entry in tool.parameters.entries) {
      if (entry.value.required && !args.containsKey(entry.key)) {
        Log.w(_tag, 'Missing required argument: ${entry.key}');
        return false;
      }
    }
    return true;
  }
}
