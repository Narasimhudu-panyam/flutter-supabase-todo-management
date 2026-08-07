import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/task_history_provider.dart';

class TaskHistoryScreen extends StatefulWidget {
  final String taskId;

  const TaskHistoryScreen({super.key, required this.taskId});

  @override
  State<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<TaskHistoryProvider>().loadHistory(widget.taskId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskHistoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Task history')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.history.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28.0),
                  child: Text(
                    'No changes were recorded yet. Your task history will appear here once edits are made.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: provider.history.length,
                itemBuilder: (context, index) {
                  final entry = provider.history[index];
                  final timestamp = DateFormat.yMMMd().add_jm().format(
                    entry.changedAt,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.history,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.action[0].toUpperCase() +
                                      entry.action.substring(1),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  timestamp,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                                if (entry.oldValue != null ||
                                    entry.newValue != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    entry.oldValue != null
                                        ? 'Before: ${entry.oldValue}'
                                        : 'Updated value: ${entry.newValue}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
