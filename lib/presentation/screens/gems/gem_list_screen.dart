import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/gem_provider.dart';
import '../../widgets/gem_card.dart';
import 'gem_editor_screen.dart';

class AcornListScreen extends ConsumerWidget {
  const AcornListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acornsAsync = ref.watch(allAcornsProvider);
    final activeAcorn = ref.watch(activeAcornProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acorns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AcornEditorScreen(
                  onSaved: () {
                    ref.invalidate(allAcornsProvider);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: acornsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (acorns) {
          if (acorns.isEmpty) {
            return const Center(
              child: Text('No acorns yet', style: AppTextStyles.body),
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
            itemCount: acorns.length,
            itemBuilder: (_, index) {
              final acorn = acorns[index];
              return AcornCard(
                acorn: acorn,
                isSelected: activeAcorn?.uuid == acorn.uuid,
                onTap: () {
                  ref.read(activeAcornProvider.notifier).state = acorn;
                },
                onLongPress: () {
                  // Mobile fallback — show menu at card center
                  final box = context.findRenderObject() as RenderBox?;
                  final offset = box?.localToGlobal(Offset.zero) ?? Offset.zero;
                  _showAcornPopupMenu(context, ref, acorn, offset);
                },
                onSecondaryTapDown: (details) {
                  _showAcornPopupMenu(
                      context, ref, acorn, details.globalPosition);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAcornPopupMenu(
      BuildContext context, WidgetRef ref, dynamic acorn, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ).then((value) async {
      if (value == 'edit') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AcornEditorScreen(
              existingAcorn: acorn,
              onSaved: () {
                ref.invalidate(allAcornsProvider);
                Navigator.pop(context);
              },
            ),
          ),
        );
      } else if (value == 'delete') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Acorn?'),
            content: Text(
                'This will delete "${acorn.name}" but keep its conversations.'),
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
          await ref.read(acornRepositoryProvider).deleteAcorn(acorn.uuid);
          ref.invalidate(allAcornsProvider);
        }
      }
    });
  }
}
