import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/document.dart';
import '../../providers/gem_provider.dart';
import '../../providers/database_provider.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../data/services/rag_service.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return DocumentRepository(isar: isar);
});

class DocumentListScreen extends ConsumerWidget {
  final String gemId;

  const DocumentListScreen({super.key, required this.gemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docRepo = ref.watch(documentRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _addDocument(context, ref),
          ),
        ],
      ),
      body: FutureBuilder<List<Document>>(
        future: docRepo.getDocumentsForGem(gemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No documents yet',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add PDFs, text files, or markdown\nto give this Gem context',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _addDocument(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Document'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final doc = docs[index];
              return _DocumentCard(
                document: doc,
                onDelete: () => _deleteDocument(context, ref, doc),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addDocument(BuildContext context, WidgetRef ref) async {
    // TODO: Use file_picker to select document
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document picker coming soon')),
    );
  }

  Future<void> _deleteDocument(
      BuildContext context, WidgetRef ref, Document doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: Text('Remove "${doc.title}" and its indexed chunks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(documentRepositoryProvider).deleteDocument(doc.uuid);
    }
  }
}

class _DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback onDelete;

  const _DocumentCard({required this.document, required this.onDelete});

  IconData get _icon {
    switch (document.fileType) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'md':
        return Icons.article_rounded;
      case 'docx':
        return Icons.description_rounded;
      default:
        return Icons.text_snippet_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(_icon, color: AppColors.teal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${document.fileSize.fileSizeDisplay}  |  ${document.chunkCount} chunks  |  ${document.fileType.toUpperCase()}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: AppColors.textTertiary,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
