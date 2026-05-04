import 'package:isar/isar.dart';

part 'document.g.dart';

@collection
class Document {
  Id id = Isar.autoIncrement;

  @Index()
  late String uuid;

  /// Which Acorn this document belongs to
  @Index()
  late String acornId;

  late String title;

  /// Original file path on disk
  late String filePath;

  /// File type: pdf, txt, md, docx
  late String fileType;

  /// Total size in bytes
  int fileSize = 0;

  /// Number of chunks this document was split into
  int chunkCount = 0;

  late DateTime createdAt;

  /// Optional metadata JSON
  String? metadataJson;

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'acornId': acornId,
        'title': title,
        'filePath': filePath,
        'fileType': fileType,
        'fileSize': fileSize,
        'chunkCount': chunkCount,
        'createdAt': createdAt.toIso8601String(),
        'metadataJson': metadataJson,
      };

  static Document fromJson(Map<String, dynamic> json) {
    return Document()
      ..uuid = json['uuid'] as String
      ..acornId = json['acornId'] as String
      ..title = json['title'] as String
      ..filePath = json['filePath'] as String
      ..fileType = json['fileType'] as String
      ..fileSize = json['fileSize'] as int? ?? 0
      ..chunkCount = json['chunkCount'] as int? ?? 0
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..metadataJson = json['metadataJson'] as String?;
  }
}

@collection
class Chunk {
  Id id = Isar.autoIncrement;

  @Index()
  late String documentId;

  late String text;

  /// Position in the document (0-indexed)
  late int chunkIndex;

  /// BM25 pre-computed term frequencies (JSON map of term -> count)
  String? termFrequenciesJson;

  /// Optional embedding vector (stored as JSON list of doubles)
  /// Only populated if user has opted into the embedding model
  String? embeddingJson;

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'text': text,
        'chunkIndex': chunkIndex,
        'termFrequenciesJson': termFrequenciesJson,
        'embeddingJson': embeddingJson,
      };

  static Chunk fromJson(Map<String, dynamic> json) {
    return Chunk()
      ..documentId = json['documentId'] as String
      ..text = json['text'] as String
      ..chunkIndex = json['chunkIndex'] as int
      ..termFrequenciesJson = json['termFrequenciesJson'] as String?
      ..embeddingJson = json['embeddingJson'] as String?;
  }
}
