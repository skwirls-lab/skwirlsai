import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/gem.dart';
import '../../providers/gem_provider.dart';

class GemEditorScreen extends ConsumerStatefulWidget {
  final Gem? existingGem;
  final VoidCallback onSaved;

  const GemEditorScreen({
    super.key,
    this.existingGem,
    required this.onSaved,
  });

  @override
  ConsumerState<GemEditorScreen> createState() => _GemEditorScreenState();
}

class _GemEditorScreenState extends ConsumerState<GemEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _promptController;
  late String _selectedIcon;
  late String _selectedColor;
  late bool _ragEnabled;
  late bool _agentModeDefault;

  bool get _isEditing => widget.existingGem != null;

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
        TextEditingController(text: widget.existingGem?.name ?? '');
    _promptController =
        TextEditingController(text: widget.existingGem?.systemPrompt ?? '');
    _selectedIcon = widget.existingGem?.icon ?? '💎';
    _selectedColor = widget.existingGem?.color ?? '#E3AB59';
    _ragEnabled = widget.existingGem?.ragEnabled ?? false;
    _agentModeDefault = widget.existingGem?.agentModeDefault ?? false;
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
        title: Text(_isEditing ? 'Edit Gem' : 'Create Gem'),
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
                  onTap: () => setState(() => _selectedIcon = icon),
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
                labelText: 'Gem Name',
                hintText: 'e.g., Writing Assistant',
              ),
              validator: Validators.gemName,
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
                    'Define how this Gem should behave...\n\nExample: "You are a helpful writing assistant who specializes in creating engaging blog posts."',
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
                  'Enable tool use by default in this Gem'),
              value: _agentModeDefault,
              onChanged: (v) => setState(() => _agentModeDefault = v),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final gemRepo = ref.read(gemRepositoryProvider);

    if (_isEditing) {
      final gem = widget.existingGem!;
      gem.name = _nameController.text.trim();
      gem.systemPrompt = _promptController.text.trim();
      gem.icon = _selectedIcon;
      gem.color = _selectedColor;
      gem.ragEnabled = _ragEnabled;
      gem.agentModeDefault = _agentModeDefault;
      await gemRepo.updateGem(gem);
    } else {
      await gemRepo.createGem(
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
}
