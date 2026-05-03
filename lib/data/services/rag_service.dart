import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:isar/isar.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../models/document.dart';
import 'package:uuid/uuid.dart';

class RagService {
  static const _tag = 'RagService';

  final Isar _isar;
  final _uuid = const Uuid();

  /// Whether the optional embedding model is available
  bool _embeddingModelLoaded = false;
  bool get hasEmbeddingModel => _embeddingModelLoaded;

  RagService({required Isar isar}) : _isar = isar;

  /// Ingest a document: read, chunk, index, and store
  Future<Document> ingestDocument({
    required String filePath,
    required String gemId,
  }) async {
    Log.i(_tag, 'Ingesting document: $filePath for gem: $gemId');

    final file = File(filePath);
    if (!await file.exists()) {
      throw ArgumentError('File not found: $filePath');
    }

    // Read file content
    final content = await _readFileContent(filePath);
    final fileName = filePath.split(Platform.pathSeparator).last;
    final fileType = fileName.split('.').last.toLowerCase();
    final stat = await file.stat();

    // Create document record
    final doc = Document()
      ..uuid = _uuid.v4()
      ..gemId = gemId
      ..title = fileName
      ..filePath = filePath
      ..fileType = fileType
      ..fileSize = stat.size
      ..createdAt = DateTime.now();

    // Chunk the content
    final chunks = _chunkText(
      content,
      chunkSize: AppConstants.ragChunkSize,
      overlap: AppConstants.ragChunkOverlap,
    );

    doc.chunkCount = chunks.length;

    // Store document and chunks
    await _isar.writeTxn(() async {
      await _isar.documents.put(doc);

      for (int i = 0; i < chunks.length; i++) {
        final chunk = Chunk()
          ..documentId = doc.uuid
          ..text = chunks[i]
          ..chunkIndex = i
          ..termFrequenciesJson = jsonEncode(_computeTermFrequencies(chunks[i]));

        // If embedding model is loaded, compute embeddings
        if (_embeddingModelLoaded) {
          final embedding = await _computeEmbedding(chunks[i]);
          chunk.embeddingJson = jsonEncode(embedding);
        }

        await _isar.chunks.put(chunk);
      }
    });

    Log.i(_tag, 'Ingested: $fileName (${chunks.length} chunks)');
    return doc;
  }

  /// Search for relevant chunks using BM25 keyword search
  Future<List<RagResult>> searchBM25({
    required String query,
    required String gemId,
    int topK = AppConstants.ragTopK,
  }) async {
    Log.i(_tag, 'BM25 search: "$query" in gem: $gemId');

    // Get all documents for this gem
    final docs = await _isar.documents
        .filter()
        .gemIdEqualTo(gemId)
        .findAll();

    if (docs.isEmpty) return [];

    final docIds = docs.map((d) => d.uuid).toSet();

    // Get all chunks for these documents
    final allChunks = <Chunk>[];
    for (final docId in docIds) {
      final chunks = await _isar.chunks
          .filter()
          .documentIdEqualTo(docId)
          .findAll();
      allChunks.addAll(chunks);
    }

    if (allChunks.isEmpty) return [];

    // BM25 scoring
    final queryTerms = _tokenize(query);
    final scores = <int, double>{}; // chunk id -> score

    // Document frequency for each term
    final df = <String, int>{};
    for (final chunk in allChunks) {
      final tf = chunk.termFrequenciesJson != null
          ? (jsonDecode(chunk.termFrequenciesJson!) as Map<String, dynamic>)
          : _computeTermFrequencies(chunk.text);
      for (final term in queryTerms) {
        if (tf.containsKey(term)) {
          df[term] = (df[term] ?? 0) + 1;
        }
      }
    }

    final n = allChunks.length;
    final avgDl = allChunks.map((c) => c.text.split(' ').length).reduce((a, b) => a + b) / n;
    const k1 = 1.5;
    const b = 0.75;

    for (final chunk in allChunks) {
      final tf = chunk.termFrequenciesJson != null
          ? (jsonDecode(chunk.termFrequenciesJson!) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, (v as num).toInt()))
          : _computeTermFrequencies(chunk.text);

      final dl = chunk.text.split(' ').length;
      double score = 0;

      for (final term in queryTerms) {
        final termDf = df[term] ?? 0;
        if (termDf == 0) continue;

        final idf = log((n - termDf + 0.5) / (termDf + 0.5) + 1);
        final termTf = tf[term] ?? 0;
        final tfNorm = (termTf * (k1 + 1)) / (termTf + k1 * (1 - b + b * dl / avgDl));
        score += idf * tfNorm;
      }

      if (score > 0) {
        scores[chunk.id] = score;
      }
    }

    // Sort by score and take top-k
    final sortedIds = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    final topIds = sortedIds.take(topK).toList();
    final results = <RagResult>[];

    for (final id in topIds) {
      final chunk = allChunks.firstWhere((c) => c.id == id);
      results.add(RagResult(
        chunkText: chunk.text,
        documentId: chunk.documentId,
        score: scores[id]!,
        chunkIndex: chunk.chunkIndex,
      ));
    }

    Log.i(_tag, 'BM25 found ${results.length} results');
    return results;
  }

  /// Search using embedding-based semantic search (requires embedding model)
  Future<List<RagResult>> searchSemantic({
    required String query,
    required String gemId,
    int topK = AppConstants.ragTopK,
  }) async {
    if (!_embeddingModelLoaded) {
      Log.w(_tag, 'Embedding model not loaded, falling back to BM25');
      return searchBM25(query: query, gemId: gemId, topK: topK);
    }

    Log.i(_tag, 'Semantic search: "$query" in gem: $gemId');

    final queryEmbedding = await _computeEmbedding(query);

    final docs = await _isar.documents
        .filter()
        .gemIdEqualTo(gemId)
        .findAll();

    if (docs.isEmpty) return [];

    final docIds = docs.map((d) => d.uuid).toSet();
    final allChunks = <Chunk>[];
    for (final docId in docIds) {
      final chunks = await _isar.chunks
          .filter()
          .documentIdEqualTo(docId)
          .findAll();
      allChunks.addAll(chunks);
    }

    // Compute cosine similarity for each chunk
    final scores = <int, double>{};
    for (final chunk in allChunks) {
      if (chunk.embeddingJson == null) continue;
      final chunkEmbedding = (jsonDecode(chunk.embeddingJson!) as List)
          .cast<num>()
          .map((n) => n.toDouble())
          .toList();
      scores[chunk.id] = _cosineSimilarity(queryEmbedding, chunkEmbedding);
    }

    final sortedIds = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    final topIds = sortedIds.take(topK).toList();
    final results = <RagResult>[];

    for (final id in topIds) {
      final chunk = allChunks.firstWhere((c) => c.id == id);
      results.add(RagResult(
        chunkText: chunk.text,
        documentId: chunk.documentId,
        score: scores[id]!,
        chunkIndex: chunk.chunkIndex,
      ));
    }

    Log.i(_tag, 'Semantic search found ${results.length} results');
    return results;
  }

  /// Auto-select best search strategy
  Future<List<RagResult>> search({
    required String query,
    required String gemId,
    int topK = AppConstants.ragTopK,
  }) async {
    if (_embeddingModelLoaded) {
      return searchSemantic(query: query, gemId: gemId, topK: topK);
    }
    return searchBM25(query: query, gemId: gemId, topK: topK);
  }

  /// Build context string from RAG results for injection into prompt
  String buildRagContext(List<RagResult> results) {
    if (results.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('[Relevant context from your documents:]');
    for (int i = 0; i < results.length; i++) {
      buffer.writeln('--- Document Excerpt ${i + 1} ---');
      buffer.writeln(results[i].chunkText);
    }
    buffer.writeln('[End of document context]');
    return buffer.toString();
  }

  /// Delete all documents and chunks for a gem
  Future<void> deleteDocumentsForGem(String gemId) async {
    final docs = await _isar.documents
        .filter()
        .gemIdEqualTo(gemId)
        .findAll();

    await _isar.writeTxn(() async {
      for (final doc in docs) {
        final chunks = await _isar.chunks
            .filter()
            .documentIdEqualTo(doc.uuid)
            .findAll();
        await _isar.chunks.deleteAll(chunks.map((c) => c.id).toList());
      }
      await _isar.documents.deleteAll(docs.map((d) => d.id).toList());
    });

    Log.i(_tag, 'Deleted ${docs.length} documents for gem: $gemId');
  }

  /// Get documents for a specific gem
  Future<List<Document>> getDocumentsForGem(String gemId) async {
    return _isar.documents.filter().gemIdEqualTo(gemId).findAll();
  }

  // --- Private helpers ---

  Future<String> _readFileContent(String filePath) async {
    final ext = filePath.split('.').last.toLowerCase();

    switch (ext) {
      case 'txt':
      case 'md':
        return File(filePath).readAsString();
      case 'pdf':
        // TODO: Integrate PDF parsing library
        Log.w(_tag, 'PDF parsing not yet implemented, reading as raw text');
        return File(filePath).readAsString();
      case 'docx':
        // TODO: Integrate DOCX parsing library
        Log.w(_tag, 'DOCX parsing not yet implemented, reading as raw text');
        return File(filePath).readAsString();
      default:
        return File(filePath).readAsString();
    }
  }

  List<String> _chunkText(String text, {required int chunkSize, required int overlap}) {
    final words = text.split(RegExp(r'\s+'));
    final chunks = <String>[];

    for (int i = 0; i < words.length; i += (chunkSize - overlap)) {
      final end = (i + chunkSize).clamp(0, words.length);
      chunks.add(words.sublist(i, end).join(' '));
      if (end >= words.length) break;
    }

    return chunks;
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2) // Skip very short tokens
        .toList();
  }

  Map<String, int> _computeTermFrequencies(String text) {
    final terms = _tokenize(text);
    final tf = <String, int>{};
    for (final term in terms) {
      tf[term] = (tf[term] ?? 0) + 1;
    }
    return tf;
  }

  Future<List<double>> _computeEmbedding(String text) async {
    // TODO: Connect to embedding model (ONNX Runtime or similar)
    // For now, return empty list
    return [];
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0;

    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    final denominator = sqrt(normA) * sqrt(normB);
    return denominator == 0 ? 0 : dotProduct / denominator;
  }
}

class RagResult {
  final String chunkText;
  final String documentId;
  final double score;
  final int chunkIndex;

  const RagResult({
    required this.chunkText,
    required this.documentId,
    required this.score,
    required this.chunkIndex,
  });
}
