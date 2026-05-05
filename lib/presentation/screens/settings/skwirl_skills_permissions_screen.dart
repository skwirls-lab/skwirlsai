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
    'write_file': Icons.edit_note_rounded,
    'web_search': Icons.language_rounded,
    'list_google_calendar_events': Icons.calendar_month_rounded,
    'search_gmail': Icons.email_outlined,
    'get_recent_emails': Icons.inbox_rounded,
    'generate_image': Icons.image_outlined,
  };

  /// Which permission types apply to each tool
  static const _toolPermissionTypes = {
    'search_svl_docs': ['read'],
    'read_file': ['read'],
    'list_files': ['read'],
    'write_file': ['write'],
    'web_search': ['network'],
    'list_google_calendar_events': ['read', 'network'],
    'search_gmail': ['read', 'network'],
    'get_recent_emails': ['read', 'network'],
    'generate_image': ['read'],
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
                    'Global permissions control what SkwirlSkills are allowed '
                    'system-wide. Individual Acorns can only use skills that '
                    'are permitted here.',
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
    final permTypes = _toolPermissionTypes[tool.name] ?? ['read'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: AppTextStyles.bodySmall
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(tool.description,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Permission toggles
            Row(
              children: [
                if (permTypes.contains('read'))
                  _buildPermChip(
                    label: 'Read',
                    icon: Icons.visibility_outlined,
                    enabled: perm.read,
                    onTap: () => notifier.toggleRead(tool.name),
                  ),
                if (permTypes.contains('write')) ...[
                  const SizedBox(width: 8),
                  _buildPermChip(
                    label: 'Write',
                    icon: Icons.edit_outlined,
                    enabled: perm.write,
                    color: AppColors.amber,
                    onTap: () => notifier.toggleWrite(tool.name),
                  ),
                ],
                if (permTypes.contains('network')) ...[
                  const SizedBox(width: 8),
                  _buildPermChip(
                    label: 'Network',
                    icon: Icons.wifi_rounded,
                    enabled: perm.network,
                    color: AppColors.error,
                    onTap: () => notifier.toggleNetwork(tool.name),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermChip({
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    Color color = AppColors.teal,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: enabled ? color.withOpacity(0.5) : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: enabled ? color : AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: enabled ? color : AppColors.textTertiary,
                fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
