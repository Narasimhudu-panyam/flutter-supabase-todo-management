import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_model.dart';

Color priorityColor(String priority) => switch (priority.toLowerCase()) {
      'high' => Colors.red,
      'medium' => Colors.orange,
      _ => Colors.green,
    };

Color statusColor(String status) {
  const colors = [Colors.indigo, Colors.teal, Colors.purple, Colors.blue];
  return colors[
      status.codeUnits.fold(0, (value, unit) => value + unit) % colors.length];
}

class PriorityChip extends StatelessWidget {
  const PriorityChip({super.key, required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) => _Tag(
        label: priority[0].toUpperCase() + priority.substring(1),
        color: priorityColor(priority),
      );
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) => _Tag(
        label: status,
        color: statusColor(status),
      );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(label),
        labelStyle: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: color.withValues(alpha: .25)),
        backgroundColor: color.withValues(alpha: .10),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      );
}

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  Future<bool> _confirmDelete(BuildContext context) => showConfirmationDialog(
        context,
        title: 'Delete task?',
        message: 'This task will be permanently deleted.',
      );

  Future<void> _deleteFromButton(BuildContext context) async {
    debugPrint('TASK DELETE: delete icon pressed for ${task.id}');
    if (await _confirmDelete(context)) {
      debugPrint('TASK DELETE: confirmed from delete icon for ${task.id}');
      onDelete();
    } else {
      debugPrint('TASK DELETE: cancelled from delete icon for ${task.id}');
    }
  }

  @override
  Widget build(BuildContext context) => Dismissible(
        key: ValueKey(task.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          debugPrint('TASK DELETE: swipe requested for ${task.id}');
          return _confirmDelete(context);
        },
        onDismissed: (_) {
          debugPrint('TASK DELETE: confirmed from swipe for ${task.id}');
          onDelete();
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: Opacity(
          opacity: task.isCompleted ? .56 : 1,
          child: Card(
            elevation: 1.5,
            shadowColor: Colors.black26,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onToggle,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          task.isCompleted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          key: ValueKey(task.isCompleted),
                          color: task.isCompleted
                              ? Colors.green
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                          ),
                          if (task.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 5),
                            Text(
                              task.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              PriorityChip(priority: task.priority),
                              StatusChip(status: task.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            children: [
                              if (task.dueDate != null)
                                _DateLabel(
                                  icon: Icons.event_outlined,
                                  value:
                                      'Due ${DateFormat.MMMd().format(task.dueDate!)}',
                                ),
                              _DateLabel(
                                icon: Icons.schedule,
                                value: DateFormat.MMMd().format(task.createdAt),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteFromButton(context),
                      tooltip: 'Delete task',
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 3),
          Text(value, style: Theme.of(context).textTheme.labelSmall),
        ],
      );
}

Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
    false;
