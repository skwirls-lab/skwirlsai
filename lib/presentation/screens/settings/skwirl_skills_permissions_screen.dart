import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/tool.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tool_provider.dart';

class SkwirlSkillsPermissionsScreen extends ConsumerWidget {
  const SkwirlSkillsPermissionsScreen({super.key});

  static const _toolDisplayNames = {
    'search_svl_docs': 'Search Knowledge Base',
    'read_file': 'Read Files',
    'list_files': 'List Directories',
    'search_files': 'Search Files by Name',
    'search_content': 'Search File Contents',
    'write_file': 'Write Files',
    'web_search': 'Web Search',
    'list_google_calendar_events': 'Google Calendar',
    'search_gmail': 'Search Gmail',
    'get_recent_emails': 'Recent Emails',
    'generate_image': 'Image Generation',
  };

  static const _toolIcons = {
    'search_svl_docs': Icons.search_rounded,
    'read_file': Icons.file_open_outlined,
    'list_files': Icons.folder_open_rounded,
    'search_files': Icons.find_in_page_rounded,
    'search_content': Icons.manage_search_rounded,
    'write_file': Icons.edit_note_rounded,
    'web_search': Icons.language_rounded,
    'list_google_calendar_events': Icons.calendar_month_rounded,
    'search_gmail': Icons.email_outlined,
    'get_recent_emails': Icons.inbox_rounded,
    'generate_image': Icons.image_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(skillPermissionsProvider);
    final permNotifier = ref.read(skillPermissionsProvider.notifier);
    final toolRegistry = ref.read(toolRegistryProvider);
    final allTools = toolRegistry.tools;

    // Group tools by category
    final localTools =
        allTools.where((t) => t.category == ToolCategory.local).toList();
    final externalTools = allTools
        .where((t) =>
            t.category == ToolCategory.externalRead ||
            t.category == ToolCategory.externalWrite)
        .toList();
    final genTools =
        allTools.where((t) => t.category == ToolCategory.generation).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkwirlSkills Permissions'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.teal.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined,
                    size: 20, color: AppColors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These are global permissions. If a skill is off here, '
                    'no Acorn can use it. Toggle a skill on to allow '
                    'individual Acorns to enable it.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.teal,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Local Skills
          if (localTools.isNotEmpty) ...[
            _buildSectionHeader('Local Skills'),
            ...localTools
                .map((t) => _buildSkillTile(t, permissions, permNotifier)),
            const Divider(height: 24),
          ],

          // External Skills
          if (externalTools.isNotEmpty) ...[
            _buildSectionHeader('External Services'),
            ...externalTools
                .map((t) => _buildSkillTile(t, permissions, permNotifier)),
            const Divider(height: 24),
          ],

          // Generation Skills
          if (genTools.isNotEmpty) ...[
            _buildSectionHeader('Generation'),
            ...genTools
                .map((t) => _buildSkillTile(t, permissions, permNotifier)),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.amber,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSkillTile(
    Tool tool,
    Map<String, SkillPermission> permissions,
    SkillPermissionsNotifier notifier,
  ) {
    final perm = permissions[tool.name] ?? const SkillPermission();
    final displayName = _toolDisplayNames[tool.name] ?? tool.name;
    final icon = _toolIcons[tool.name] ?? Icons.extension_rounded;

    return SwitchListTile(
      secondary: Icon(icon,
          size: 22,
          color: perm.isAllowed ? AppColors.teal : AppColors.textTertiary),
      title: Text(displayName,
          style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: perm.isAllowed ? null : AppColors.textTertiary)),
      subtitle: Text(tool.description,
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textTertiary, fontSize: 11)),
      value: perm.isAllowed,
      activeColor: AppColors.teal,
      onChanged: (_) => notifier.toggleAllowed(tool.name),
    );
  }
}
