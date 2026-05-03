import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/gem_provider.dart';
import '../../widgets/gem_card.dart';
import 'gem_editor_screen.dart';

class GemListScreen extends ConsumerWidget {
  const GemListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gemsAsync = ref.watch(allGemsProvider);
    final activeGem = ref.watch(activeGemProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gems'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GemEditorScreen(
                  onSaved: () {
                    ref.invalidate(allGemsProvider);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: gemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (gems) {
          if (gems.isEmpty) {
            return const Center(
              child: Text('No gems yet', style: AppTextStyles.body),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: gems.length,
            itemBuilder: (_, index) {
              final gem = gems[index];
              return GemCard(
                gem: gem,
                isSelected: activeGem?.uuid == gem.uuid,
                onTap: () {
                  ref.read(activeGemProvider.notifier).state = gem;
                },
                onLongPress: () {
                  _showGemOptions(context, ref, gem);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showGemOptions(BuildContext context, WidgetRef ref, gem) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GemEditorScreen(
                      existingGem: gem,
                      onSaved: () {
                        ref.invalidate(allGemsProvider);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
            ),
            if (!gem.isDefault)
              ListTile(
                leading: const Icon(Icons.delete_rounded,
                    color: AppColors.error),
                title: const Text('Delete',
                    style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Gem?'),
                      content: Text(
                          'This will delete "${gem.name}" but keep its conversations.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(gemRepositoryProvider).deleteGem(gem.uuid);
                    ref.invalidate(allGemsProvider);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
