import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/gem_provider.dart';
import '../../providers/model_provider.dart';
import '../../providers/settings_provider.dart';
import '../models/model_management_screen.dart';

Future<void> _exportChatHistory(BuildContext context, WidgetRef ref) async {
  try {
    final convRepo = ref.read(conversationRepositoryProvider);
    final acornRepo = ref.read(acornRepositoryProvider);
    final acorns = await acornRepo.getAllAcorns();

    final export = <String, dynamic>{
      'appVersion': AppConstants.appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'acorns': [],
    };

    for (final acorn in acorns) {
      final conversations = await convRepo.getConversationsForAcorn(acorn.uuid);
      final convList = <Map<String, dynamic>>[];

      for (final conv in conversations) {
        final messages = await convRepo.getMessages(conv.uuid);
        convList.add({
          'title': conv.title,
          'createdAt': conv.createdAt.toIso8601String(),
          'updatedAt': conv.updatedAt.toIso8601String(),
          'messages': messages
              .map((m) => {
                    'role': m.role.name,
                    'content': m.content,
                    'timestamp': m.timestamp.toIso8601String(),
                  })
              .toList(),
        });
      }

      (export['acorns'] as List).add({
        'name': acorn.name,
        'systemPrompt': acorn.systemPrompt,
        'conversations': convList,
      });
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(export);

    // Ask user where to save
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Chat History',
      fileName:
          'skwirlsai_export_${DateTime.now().millisecondsSinceEpoch}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (outputPath == null) return;

    await File(outputPath).writeAsString(jsonStr);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat history exported successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
}

Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Clear All Data?'),
      content: const Text(
          'This will permanently delete ALL conversations, messages, and custom Acorns. '
          'This action cannot be undone.\n\n'
          'Default Acorns will be restored.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Delete Everything'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.clear();
    });

    // Re-seed default acorns
    final acornRepo = ref.read(acornRepositoryProvider);
    await acornRepo.initializeDefaults();

    // Reset state
    ref.read(activeConversationProvider.notifier).state = null;
    ref.read(activeAcornProvider.notifier).state = null;
    ref.invalidate(allAcornsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data cleared'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear data: $e')),
      );
    }
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final user = ref.watch(currentUserProvider);
    final isAuth = ref.watch(isAuthenticatedProvider);
    final isModelLoaded = ref.watch(isModelLoadedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Account section
          _SectionHeader('Account'),
          if (isAuth && user != null)
            ListTile(
              leading: CircleAvatar(
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Text(user.displayName[0].toUpperCase())
                    : null,
              ),
              title: Text(user.displayName),
              subtitle: Text(user.email),
            )
          else
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Not signed in'),
              subtitle: const Text('Sign in to sync across devices'),
              trailing: ElevatedButton(
                onPressed: () async {
                  try {
                    await ref.read(authServiceProvider).signInWithGoogle();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sign in failed: $e')),
                      );
                    }
                  }
                },
                child: const Text('Sign In'),
              ),
            ),
          if (isAuth)
            ListTile(
              leading: const Icon(Icons.sync_rounded),
              title: const Text('Sync Status'),
              subtitle: const Text('Last synced: N/A'),
              trailing: IconButton(
                icon: const Icon(Icons.sync_rounded),
                onPressed: () {
                  // TODO: Trigger manual sync
                },
              ),
            ),
          if (isAuth)
            ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: AppColors.error),
              title: const Text('Sign Out',
                  style: TextStyle(color: AppColors.error)),
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
              },
            ),
          const Divider(),

          // Model section
          _SectionHeader('Model'),
          ListTile(
            leading: Icon(
              isModelLoaded ? Icons.check_circle_rounded : Icons.memory_rounded,
              color: isModelLoaded ? AppColors.success : null,
            ),
            title: Text(isModelLoaded
                ? ref.read(inferenceServiceProvider).providerName
                : 'No Model Connected'),
            subtitle: Text(
              isModelLoaded
                  ? (ref.read(inferenceServiceProvider).activeModelName ??
                      ref.read(inferenceServiceProvider).loadedModelPath ??
                      'Connected')
                  : 'Tap to connect a model',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ModelManagementScreen()),
              );
            },
          ),
          const Divider(),

          // Generation Settings
          _SectionHeader('Generation'),
          _SliderTile(
            title: 'Temperature',
            subtitle: '${settings.temperature.toStringAsFixed(2)}',
            value: settings.temperature,
            min: 0.0,
            max: 2.0,
            onChanged: (v) => settingsNotifier.setTemperature(v),
          ),
          _SliderTile(
            title: 'Top P',
            subtitle: '${settings.topP.toStringAsFixed(2)}',
            value: settings.topP,
            min: 0.0,
            max: 1.0,
            onChanged: (v) => settingsNotifier.setTopP(v),
          ),
          _SliderTile(
            title: 'Top K',
            subtitle: '${settings.topK}',
            value: settings.topK.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: (v) => settingsNotifier.setTopK(v.round()),
          ),
          _SliderTile(
            title: 'Max Tokens',
            subtitle: '${settings.maxTokens}',
            value: settings.maxTokens.toDouble(),
            min: 100,
            max: 8192,
            divisions: 81,
            onChanged: (v) => settingsNotifier.setMaxTokens(v.round()),
          ),
          ListTile(
            title: const Text('Reset to Defaults'),
            leading: const Icon(Icons.restart_alt_rounded),
            onTap: () => settingsNotifier.resetToDefaults(),
          ),
          const Divider(),

          // Appearance
          _SectionHeader('Appearance'),
          _SliderTile(
            title: 'Font Size',
            subtitle: '${settings.fontSize.round()}',
            value: settings.fontSize,
            min: 12,
            max: 22,
            divisions: 10,
            onChanged: (v) => settingsNotifier.setFontSize(v),
          ),
          SwitchListTile(
            title: const Text('Compact Messages'),
            value: settings.compactMessages,
            onChanged: (v) => settingsNotifier.setCompactMessages(v),
          ),
          const Divider(),

          // Advanced
          _SectionHeader('Advanced'),
          SwitchListTile(
            title: const Text('Agent Mode by Default'),
            subtitle: const Text('Enable tool use in all new conversations'),
            value: settings.agentModeDefault,
            onChanged: (v) => settingsNotifier.setAgentModeDefault(v),
          ),
          SwitchListTile(
            title: const Text('RAG Enabled'),
            subtitle: const Text('Enable document search in conversations'),
            value: settings.ragEnabled,
            onChanged: (v) => settingsNotifier.setRagEnabled(v),
          ),
          const Divider(),

          // Privacy
          _SectionHeader('Privacy & Data'),
          ListTile(
            leading: const Icon(Icons.download_rounded),
            title: const Text('Export Chat History'),
            subtitle: const Text('Save as JSON'),
            onTap: () => _exportChatHistory(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded,
                color: AppColors.error),
            title: const Text('Clear All Data',
                style: TextStyle(color: AppColors.error)),
            onTap: () => _clearAllData(context, ref),
          ),
          const Divider(),

          // About
          _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('SkwirlsAI'),
            subtitle: Text('Version ${AppConstants.appVersion}'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.amber,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(subtitle, style: AppTextStyles.label),
        ],
      ),
      subtitle: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}
