import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/document.dart';
import '../../../data/models/gem.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../data/services/rag_service.dart';
import '../../providers/database_provider.dart';
import '../../providers/gem_provider.dart';

class AcornEditorScreen extends ConsumerStatefulWidget {
  final Acorn? existingAcorn;
  final VoidCallback onSaved;

  const AcornEditorScreen({
    super.key,
    this.existingAcorn,
    required this.onSaved,
  });

  @override
  ConsumerState<AcornEditorScreen> createState() => _AcornEditorScreenState();
}

class _AcornEditorScreenState extends ConsumerState<AcornEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _promptController;
  late String _selectedIcon;
  late String _selectedColor;
  late bool _ragEnabled;
  late bool _agentModeDefault;
  List<Document> _documents = [];
  bool _loadingDocs = false;

  bool get _isEditing => widget.existingAcorn != null;

  static const _iconOptions = [
    '🤖', '💻', '📱', '📊', '📝', '🎨', '🎵', '📸',
    '💡', '🔧', '📚', '🎯', '💎', '🚀', '🧠', '🌐',
    '✍️', '📈', '🔍', '💼', '🎬', '🎤', '📋', '⚡',
  ];

  static const _colorOptions = [
    '#E3AB59', '#58AFAE', '#EF5350', '#42A5F5',
    '#66BB6A', '#AB47BC', '#FF7043', '#26C6DA',
    '#FFCA28', '#8D6E63', '#78909C', '#EC407A',
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingAcorn?.name ?? '');
    _promptController =
        TextEditingController(text: widget.existingAcorn?.systemPrompt ?? '');
    _selectedIcon = widget.existingAcorn?.icon ?? '🌰';
    _selectedColor = widget.existingAcorn?.color ?? '#E3AB59';
    _ragEnabled = widget.existingAcorn?.ragEnabled ?? false;
    _agentModeDefault = widget.existingAcorn?.agentModeDefault ?? false;
    if (_isEditing) _loadDocuments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Acorn' : 'Create Acorn'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Icon picker
            Text('Icon', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconOptions.map((icon) {
                final isSelected = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedIcon = isSelected ? '🌰' : icon;
                  }),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.amber.withOpacity(0.2)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: AppColors.amber, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Acorn Name',
                hintText: 'e.g., Writing Assistant',
              ),
              validator: Validators.acornName,
            ),
            const SizedBox(height: 16),
            // Color picker
            Text('Accent Color', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((hex) {
                final isSelected = hex == _selectedColor;
                final color = Color(
                    int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // System prompt
            TextFormField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'System Prompt',
                hintText:
                    'Define how this Acorn should behave...\n\nExample: "You are a helpful writing assistant who specializes in creating engaging blog posts."',
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              minLines: 4,
              validator: Validators.systemPrompt,
            ),
            const SizedBox(height: 20),
            // Toggles
            SwitchListTile(
              title: const Text('Enable RAG Documents'),
              subtitle: const Text(
                  'Attach documents for context-aware responses'),
              value: _ragEnabled,
              onChanged: (v) => setState(() => _ragEnabled = v),
            ),
            SwitchListTile(
              title: const Text('Agent Mode Default'),
              subtitle: const Text(
                  'Enable tool use by default in this Acorn'),
              value: _agentModeDefault,
              onChanged: (v) => setState(() => _agentModeDefault = v),
            ),
            if (_ragEnabled) ..._buildKnowledgeBaseSection(),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final acornRepo = ref.read(acornRepositoryProvider);

    if (_isEditing) {
      final acorn = widget.existingAcorn!;
      acorn.name = _nameController.text.trim();
      acorn.systemPrompt = _promptController.text.trim();
      acorn.icon = _selectedIcon;
      acorn.color = _selectedColor;
      acorn.ragEnabled = _ragEnabled;
      acorn.agentModeDefault = _agentModeDefault;
      await acornRepo.updateAcorn(acorn);
    } else {
      await acornRepo.createAcorn(
        name: _nameController.text.trim(),
        systemPrompt: _promptController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        ragEnabled: _ragEnabled,
        agentModeDefault: _agentModeDefault,
      );
    }

    widget.onSaved();
  }

  Future<void> _loadDocuments() async {
    if (widget.existingAcorn == null) return;
    setState(() => _loadingDocs = true);
    final isar = ref.read(isarProvider);
    final ragService = RagService(isar: isar);
    final docs = await ragService.getDocumentsForAcorn(widget.existingAcorn!.uuid);
    if (mounted) setState(() { _documents = docs; _loadingDocs = false; });
  }

  Future<void> _addDocuments() async {
    final acornId = widget.existingAcorn?.uuid;
    if (acornId == null) {
      showTopSnackBar(context, 'Save the Acorn first, then add documents.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'pdf', 'docx', 'csv', 'json'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    final isar = ref.read(isarProvider);
    final ragService = RagService(isar: isar);
    int ingested = 0;
    for (final file in result.files) {
      if (file.path == null) continue;
      try {
        await ragService.ingestDocument(filePath: file.path!, acornId: acornId);
        ingested++;
      } catch (e) {
        if (mounted) showTopSnackBar(context, 'Failed: ${file.name}: $e', backgroundColor: AppColors.error);
      }
    }
    if (ingested > 0 && mounted) {
      showTopSnackBar(context, '$ingested document${ingested > 1 ? 's' : ''} added');
    }
    _loadDocuments();
  }

  Future<void> _deleteDocument(Document doc) async {
    final isar = ref.read(isarProvider);
    final docRepo = DocumentRepository(isar: isar);
    await docRepo.deleteDocument(doc.uuid);
    _loadDocuments();
  }

  List<Widget> _buildKnowledgeBaseSection() {
    return [
      const SizedBox(height: 20),
      Row(
        children: [
          Text('Knowledge Base', style: AppTextStyles.label),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Files'),
            onPressed: _addDocuments,
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (_loadingDocs)
        const Center(child: CircularProgressIndicator())
      else if (_documents.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            _isEditing
                ? 'No documents yet. Add files to give this Acorn context.'
                : 'Save the Acorn first, then add documents.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
        )
      else
        ...List.generate(_documents.length, (i) {
          final doc = _documents[i];
          final sizeKb = (doc.fileSize / 1024).toStringAsFixed(1);
          return ListTile(
            dense: true,
            leading: Icon(Icons.description_outlined, color: AppColors.teal, size: 20),
            title: Text(doc.title, style: AppTextStyles.bodySmall),
            subtitle: Text('${doc.chunkCount} chunks  ·  $sizeKb KB',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              onPressed: () => _deleteDocument(doc),
            ),
            contentPadding: EdgeInsets.zero,
          );
        }),
    ];
  }
}
