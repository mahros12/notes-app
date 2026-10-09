import 'package:flutter/material.dart';

import '../models/note.dart';
import '../services/location_service.dart';
import '../services/note_service.dart';

class EditNoteScreen extends StatefulWidget {
  final NoteService service;
  final Note note;

  const EditNoteScreen({super.key, required this.service, required this.note});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _topicController;
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  late bool _useLocation;
  bool _saving = false;
  bool _deleting = false;
  bool _loadingLocation = false;
  LocationResult? _preloadedLocation;
  Future<LocationResult>? _pendingLocation;

  static const _suggestedTopics = ['Personal', 'Work', 'Ideas', 'Tasks', 'Study'];

  bool get _changed =>
      _titleController.text.trim() != (widget.note.title ?? '').trim() ||
      _topicController.text.trim() != (widget.note.topic ?? '').trim() ||
      _controller.text.trim() != widget.note.content.trim() ||
      _useLocation != widget.note.hasLocation ||
      _preloadedLocation != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title ?? '')..addListener(_onChanged);
    _topicController = TextEditingController(text: widget.note.topic ?? '')..addListener(_onChanged);
    _controller = TextEditingController(text: widget.note.content)..addListener(_onChanged);
    _useLocation = widget.note.hasLocation;
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _titleController.removeListener(_onChanged);
    _titleController.dispose();
    _topicController.removeListener(_onChanged);
    _topicController.dispose();
    _controller.removeListener(_onChanged);
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

    if (value && (!widget.note.hasLocation || widget.note.locationName == null)) {
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

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);

    try {
      await widget.service.updateNote(
        note: widget.note,
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: const Text('Delete this note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await widget.service.deleteNote(widget.note);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showError(_cleanError(e));
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<bool> _handleBack() async {
    if (!_changed || _saving || _deleting) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits have not been saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return leave == true;
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
    final displayPlaceName = _preloadedLocation?.placeName ?? widget.note.locationName;

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
          title: const Text('Edit note', style: TextStyle(fontWeight: FontWeight.w700)),
          actions: [
            IconButton(
              tooltip: 'Delete note',
              onPressed: (_saving || _deleting) ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
            const SizedBox(width: 8),
          ],
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
                  child: Text(
                    '${_controller.text.length}/${NoteService.maxContentLength}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 18),
                _LocationTile(
                  enabled: _useLocation,
                  disabled: _saving || _deleting,
                  loading: _loadingLocation,
                  placeName: displayPlaceName,
                  onChanged: _onToggleLocation,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: (!_changed || _saving || _deleting) ? null : _update,
                    icon: _saving
                        ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_rounded),
                    label: Text(_saving ? 'Saving changes...' : 'Save changes'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: (_saving || _deleting) ? null : _delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete note'),
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
    this.placeName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final name = placeName?.trim();

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
        title: const Text('Attach current location', style: TextStyle(fontWeight: FontWeight.w600)),
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
                enabled && name != null && name.isNotEmpty ? name : 'Optional',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}
