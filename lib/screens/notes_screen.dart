import 'package:flutter/material.dart';
import 'package:shake/shake.dart';

import '../models/note.dart';
import '../services/note_service.dart';
import '../widgets/note_card.dart';
import 'add_note_screen.dart';
import 'edit_note_screen.dart';

class NotesScreen extends StatefulWidget {
  final NoteService service;

  const NotesScreen({super.key, required this.service});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late final ShakeDetector _shakeDetector;
  final _searchController = TextEditingController();
  final Set<int> _selectedIds = {};
  bool _searching = false;
  String _query = '';
  bool _deletingAll = false;

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (_) => _deleteAllFromShake(),
      minimumShakeCount: 2,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 1000,
    );
    _searchController.addListener(() {
      if (mounted) setState(() => _query = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _shakeDetector.stopListening();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<Note> notes) {
    setState(() {
      if (_selectedIds.length == notes.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(notes.map((n) => n.id!).whereType<int>());
      }
    });
  }

  void _exitSelectionMode() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _deleteSelectedNotes(List<Note> allNotes) async {
    final selectedNotes = allNotes.where((n) => n.id != null && _selectedIds.contains(n.id)).toList();
    if (selectedNotes.isEmpty) return;

    final count = selectedNotes.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_rounded, size: 36),
        title: Text('Delete $count ${count == 1 ? 'note' : 'notes'}?'),
        content: const Text('This action will delete the selected notes. You can undo immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    _exitSelectionMode();

    try {
      await widget.service.deleteNotes(selectedNotes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('$count ${count == 1 ? 'note' : 'notes'} deleted.'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              try {
                await widget.service.restoreNotes(selectedNotes);
              } catch (e) {
                _showMessage('Failed to restore: ${_cleanError(e)}');
              }
            },
          ),
        ),
      );
    } catch (e) {
      _showMessage(_cleanError(e));
    }
  }

  Future<void> _deleteAllFromShake() async {
    if (_deletingAll) return;
    final count = await widget.service.countNotes();
    if (!mounted || count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.vibration_rounded, size: 36),
        title: const Text('Shake detected'),
        content: Text(
          'Do you want to permanently delete all $count ${count == 1 ? 'note' : 'notes'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingAll = true);
    try {
      await widget.service.deleteAllNotes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('$count ${count == 1 ? 'note' : 'notes'} deleted.'),
        ),
      );
    } catch (e) {
      _showMessage(_cleanError(e));
    } finally {
      if (mounted) setState(() => _deletingAll = false);
    }
  }

  Future<void> _openAdd() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddNoteScreen(service: widget.service)),
    );
  }

  Future<void> _openEdit(Note note) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditNoteScreen(service: widget.service, note: note),
      ),
    );
  }

  Future<void> _deleteNoteImmediately(Note note) async {
    try {
      await widget.service.deleteNote(note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: const Text('Note deleted.'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              try {
                await widget.service.restoreNote(note);
              } catch (e) {
                _showMessage('Failed to restore: ${_cleanError(e)}');
              }
            },
          ),
        ),
      );
    } catch (e) {
      _showMessage(_cleanError(e));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: StreamBuilder<List<Note>>(
        stream: widget.service.watchNotes(),
        builder: (context, snapshot) {
          final allNotes = snapshot.data ?? [];
          final query = _query.toLowerCase();
          final notes = query.isEmpty
              ? allNotes
              : allNotes
                  .where((note) =>
                      (note.title?.toLowerCase().contains(query) ?? false) ||
                      (note.topic?.toLowerCase().contains(query) ?? false) ||
                      note.content.toLowerCase().contains(query) ||
                      (note.locationName?.toLowerCase().contains(query) ?? false))
                  .toList();

          return Scaffold(
            appBar: _isSelectionMode
                ? AppBar(
                    leading: IconButton(
                      tooltip: 'Cancel selection',
                      icon: const Icon(Icons.close),
                      onPressed: _exitSelectionMode,
                    ),
                    title: Text(
                      '${_selectedIds.length} selected',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 21),
                    ),
                    actions: [
                      IconButton(
                        tooltip: _selectedIds.length == notes.length ? 'Deselect all' : 'Select all',
                        icon: Icon(
                          _selectedIds.length == notes.length
                              ? Icons.deselect_rounded
                              : Icons.select_all_rounded,
                        ),
                        onPressed: () => _selectAll(notes),
                      ),
                      IconButton(
                        tooltip: 'Delete selected',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: _selectedIds.isEmpty
                            ? null
                            : () => _deleteSelectedNotes(allNotes),
                      ),
                      const SizedBox(width: 8),
                    ],
                  )
                : AppBar(
                    title: _searching
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search notes or places...',
                              border: InputBorder.none,
                              filled: false,
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _query = '');
                                      },
                                    )
                                  : null,
                            ),
                          )
                        : const Text(
                            'My Notes',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 25),
                          ),
                    actions: [
                      IconButton(
                        tooltip: _searching ? 'Close search' : 'Search',
                        onPressed: () {
                          setState(() {
                            _searching = !_searching;
                            if (!_searching) {
                              _searchController.clear();
                              _query = '';
                            }
                          });
                        },
                        icon: Icon(_searching ? Icons.close : Icons.search),
                      ),
                      if (!_searching && allNotes.isNotEmpty)
                        IconButton(
                          tooltip: 'Select multiple',
                          onPressed: () {
                            if (notes.isNotEmpty) {
                              _toggleSelection(notes.first.id!);
                            }
                          },
                          icon: const Icon(Icons.checklist_rounded),
                        ),
                      if (!_searching)
                        IconButton(
                          tooltip: 'Add note',
                          onPressed: _openAdd,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      const SizedBox(width: 8),
                    ],
                  ),
            body: Builder(
              builder: (context) {
                if (snapshot.hasError) {
                  return _ErrorState(message: _cleanError(snapshot.error!));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (allNotes.isEmpty) return _EmptyState(onAdd: _openAdd);
                if (notes.isEmpty) {
                  return _NoSearchResults(
                    query: _query,
                    onClear: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                      child: Text(
                        _query.isEmpty
                            ? '${allNotes.length} ${allNotes.length == 1 ? 'note' : 'notes'}'
                            : '${notes.length} result${notes.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                        itemCount: notes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          final isSelected = _selectedIds.contains(note.id);

                          return Dismissible(
                            key: ValueKey(note.id),
                            direction: _isSelectionMode
                                ? DismissDirection.none
                                : DismissDirection.endToStart,
                            onDismissed: (_) => _deleteNoteImmediately(note),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                            child: NoteCard(
                              note: note,
                              isSelectionMode: _isSelectionMode,
                              isSelected: isSelected,
                              onTap: () {
                                if (_isSelectionMode && note.id != null) {
                                  _toggleSelection(note.id!);
                                } else {
                                  _openEdit(note);
                                }
                              },
                              onLongPress: () {
                                if (note.id != null) {
                                  _toggleSelection(note.id!);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            floatingActionButton: _isSelectionMode
                ? null
                : FloatingActionButton.extended(
                    onPressed: _openAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('New note'),
                  ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notes_rounded, size: 46, color: color),
            ),
            const SizedBox(height: 22),
            const Text(
              'Nothing here yet',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Save your first thought, reminder, or idea.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create a note'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _NoSearchResults({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 60),
            const SizedBox(height: 14),
            const Text(
              'No matching notes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            Text('Nothing matches “$query”.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onClear,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 54),
            const SizedBox(height: 14),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
