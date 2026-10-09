import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: note.content));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Note copied to clipboard.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(note.updatedAt);
    final color = Theme.of(context).colorScheme.primary;

    return Material(
      color: isSelected ? color.withValues(alpha: 0.06) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? color : const Color(0xFFE9E9F0),
          width: isSelected ? 1.6 : 1.0,
        ),
      ),
      elevation: isSelected ? 1.5 : 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress ?? () => _copyToClipboard(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectionMode) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? color : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? color : const Color(0xFFB0B0C0),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              ],
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  note.hasLocation ? Icons.location_on_outlined : Icons.notes_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.title != null && note.title!.isNotEmpty) ...[
                      Text(
                        note.title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        note.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.35,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ] else ...[
                      Text(
                        note.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (note.topic != null && note.topic!.isNotEmpty)
                          _TopicBadge(text: note.topic!),
                        _MetaItem(
                          icon: Icons.schedule_outlined,
                          text: _formatDate(date),
                        ),
                        if (note.hasLocation)
                          _MetaItem(
                            icon: Icons.location_on_outlined,
                            text: note.locationName ?? 'Location attached',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isSelectionMode)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Icon(Icons.chevron_right_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:$minute $period';

    if (day == today) return 'Today · $time';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday · $time';
    return '${date.day}/${date.month}/${date.year} · $time';
  }
}


class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopicBadge extends StatelessWidget {
  final String text;

  const _TopicBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label_rounded, size: 12, color: color),
          const SizedBox(width: 3),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
