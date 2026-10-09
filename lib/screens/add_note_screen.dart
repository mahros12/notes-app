import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../services/note_service.dart';

class AddNoteScreen extends StatefulWidget {
  final NoteService service;

  const AddNoteScreen({super.key, required this.service});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _titleController = TextEditingController();
  final _topicController = TextEditingController();
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _useLocation = false;
  bool _saving = false;
  bool _loadingLocation = false;
  LocationResult? _preloadedLocation;

  Future<LocationResult>? _pendingLocation;

  static const _suggestedTopics = ['Personal', 'Work', 'Ideas', 'Tasks', 'Study'];

  @override
  void initState() {
    super.initState();
    _topicController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onToggleLocation(bool value) {
    setState(() {
      _useLocation = value;
      if (!value) {
        _preloadedLocation = null;
        _loadingLocation = false;
        _pendingLocation = null;
      }
    });

    if (value && _preloadedLocation == null) {
      setState(() => _loadingLocation = true);
      final future = widget.service.locationService.getCurrentLocation();
      _pendingLocation = future;
      future.then((loc) {
        if (mounted && _useLocation) {
          setState(() {
            _preloadedLocation = loc;
            _loadingLocation = false;
          });
        }
      }).catchError((e) {
        if (mounted && _useLocation) {
          setState(() => _loadingLocation = false);
        }
      });
    }
  }

  Future<bool> _handleBack() async {
    final hasUnsavedData = _titleController.text.trim().isNotEmpty ||
        _topicController.text.trim().isNotEmpty ||
        _controller.text.trim().isNotEmpty;
    if (!hasUnsavedData || _saving) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard note?'),
        content: const Text('Your unsaved text will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep writing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);

    try {
      await widget.service.createNote(
        title: _titleController.text,
        topic: _topicController.text,
        content: _controller.text,
        useLocation: _useLocation,
        preloadedLocation: _preloadedLocation,
        pendingLocation: _pendingLocation,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on FormatException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(_cleanError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  String _cleanError(Object error) => error.toString().replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _handleBack();
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New note', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              children: [
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    hintText: 'Title (optional)',
                    prefixIcon: Icon(Icons.title_rounded),
                    contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _topicController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Topic / Category (optional)',
                    prefixIcon: const Icon(Icons.label_outline_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    suffixIcon: _topicController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _topicController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _suggestedTopics.map((topic) {
                    final isSelected =
                        _topicController.text.trim().toLowerCase() == topic.toLowerCase();
                    return ChoiceChip(
                      label: Text(topic),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _topicController.text = selected ? topic : '';
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controller,
                  minLines: 6,
                  maxLines: 12,
                  maxLength: NoteService.maxContentLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Write your note...',
                    alignLabelWithHint: true,
                    counterText: '',
                    contentPadding: EdgeInsets.all(18),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Write something first.';
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (_, value, __) => Text(
                      '${value.text.length}/${NoteService.maxContentLength}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _LocationTile(
                  enabled: _useLocation,
                  disabled: _saving,
                  loading: _loadingLocation,
                  placeName: _preloadedLocation?.placeName,
                  onChanged: _onToggleLocation,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_rounded),
                    label: Text(_saving ? 'Saving note...' : 'Save note'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final bool enabled;
  final bool disabled;
  final bool loading;
  final String? placeName;
  final ValueChanged<bool> onChanged;

  const _LocationTile({
    required this.enabled,
    required this.disabled,
    required this.loading,
    required this.placeName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Material(
      color: enabled ? color.withValues(alpha: 0.08) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: enabled ? color.withValues(alpha: 0.35) : const Color(0xFFE4E4EC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile.adaptive(
        value: enabled,
        onChanged: disabled ? null : onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(
          enabled ? Icons.location_on : Icons.location_on_outlined,
          color: enabled ? color : null,
        ),
        title: const Text('Add current location', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: loading
            ? const Row(
                children: [
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Detecting location...'),
                ],
              )
            : Text(
                enabled
                    ? (placeName != null && placeName!.isNotEmpty
                        ? placeName!
                        : 'A place name will be saved with your note.')
                    : 'Optional',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}
