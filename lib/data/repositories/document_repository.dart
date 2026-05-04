import 'package:isar/isar.dart';
import '../../core/utils/logger.dart';
import '../models/document.dart';

class DocumentRepository {
  static const _tag = 'DocumentRepo';
  final Isar _isar;

  DocumentRepository({required Isar isar}) : _isar = isar;

  /// Get all documents for an acorn
  Future<List<Document>> getDocumentsForAcorn(String acornId) async {
    return _isar.documents.filter().acornIdEqualTo(acornId).findAll();
  }

  /// Get a document by UUID
  Future<Document?> getDocument(String uuid) async {
    return _isar.documents.filter().uuidEqualTo(uuid).findFirst();
  }

  /// Delete a document and all its chunks
  Future<void> deleteDocument(String uuid) async {
    final doc = await getDocument(uuid);
    if (doc == null) return;

    await _isar.writeTxn(() async {
      final chunks = await _isar.chunks
          .filter()
          .documentIdEqualTo(uuid)
          .findAll();
      await _isar.chunks.deleteAll(chunks.map((c) => c.id).toList());
      await _isar.documents.delete(doc.id);
    });

    Log.i(_tag, 'Deleted document: ${doc.title}');
  }

  /// Get total document count across all acorns
  Future<int> getTotalDocumentCount() async {
    return _isar.documents.count();
  }

  /// Get total chunk count across all documents
  Future<int> getTotalChunkCount() async {
    return _isar.chunks.count();
  }
}
