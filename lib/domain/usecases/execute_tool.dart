import '../../domain/entities/tool.dart';
import '../../data/services/tool_registry.dart';

class ExecuteToolUseCase {
  final ToolRegistry _toolRegistry;

  ExecuteToolUseCase({required ToolRegistry toolRegistry})
      : _toolRegistry = toolRegistry;

  /// Execute a tool call, checking for confirmation requirement first
  Future<ToolResult> execute(ToolCall call) async {
    return _toolRegistry.executeTool(call);
  }

  /// Check if tool needs user confirmation
  bool needsConfirmation(String toolName) {
    return _toolRegistry.requiresConfirmation(toolName);
  }

  /// Parse tool calls from LLM output
  List<ToolCall> parseFromResponse(String responseText) {
    return _toolRegistry.parseToolCalls(responseText);
  }

  /// Get all available tool schemas for LLM prompt
  List<Map<String, dynamic>> get toolSchemas => _toolRegistry.toolSchemas;
}
