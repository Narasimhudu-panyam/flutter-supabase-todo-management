import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/statistics_card.dart';
import '../../widgets/task_card.dart';
import '../../widgets/task_search_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';
  String _completion = 'All';
  String _priority = 'All';
  String _status = 'All';
  String _dateFilter = 'Any time';
  String _sort = 'Newest';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TaskProvider>().startListening();
    });
  }

  List<TaskModel> _visible(List<TaskModel> all) {
    final list = all.where((t) {
      final q = _query.toLowerCase();
      final due = t.dueDate;
      final matchesDate =
          _dateFilter == 'Any time' ||
          (due != null &&
              (_dateFilter == 'Today'
                  ? DateUtils.isSameDay(due, DateTime.now())
                  : due.isBefore(DateTime.now().add(const Duration(days: 7))) &&
                        due.isAfter(
                          DateTime.now().subtract(const Duration(days: 1)),
                        )));

      return (q.isEmpty ||
              t.title.toLowerCase().contains(q) ||
              (t.description?.toLowerCase().contains(q) ?? false)) &&
          (_completion == 'All' ||
              (_completion == 'Pending' ? !t.isCompleted : t.isCompleted)) &&
          (_priority == 'All' ||
              t.priority.toLowerCase() == _priority.toLowerCase()) &&
          (_status == 'All' || t.status == _status) &&
          matchesDate;
    }).toList();

    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return switch (_sort) {
        'Oldest' => a.createdAt.compareTo(b.createdAt),
        'Priority' => _rank(b).compareTo(_rank(a)),
        'Due date' => (a.dueDate ?? DateTime(9999)).compareTo(
          b.dueDate ?? DateTime(9999),
        ),
        'Alphabetical' => a.title.toLowerCase().compareTo(
          b.title.toLowerCase(),
        ),
        _ => b.createdAt.compareTo(a.createdAt),
      };
    });

    return list;
  }

  int _rank(TaskModel t) =>
      const {'high': 3, 'medium': 2, 'low': 1}[t.priority.toLowerCase()] ?? 0;

  Future<void> _delete(TaskModel task) async {
    try {
      await context.read<TaskProvider>().deleteTask(task.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${task.title}" deleted')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not delete task')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TaskProvider>();
    final tasks = p.tasks;
    final visible = _visible(tasks);
    final statuses = [
      'All',
      ...{for (final task in tasks) task.status},
    ];
    final complete = tasks.where((t) => t.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              color: Colors.white,
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<TaskProvider>().loadTasks(),
        edgeOffset: 100,
        backgroundColor: Theme.of(context).colorScheme.surface,
        color: Theme.of(context).colorScheme.primary,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: p.isLoading && tasks.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : p.error != null && tasks.isEmpty
              ? Center(child: Text(p.error!))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                  children: [
                    const SizedBox(height: 6),
                    // Greeting and profile icon removed per request.
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          StatisticsCard(
                            label: 'Total Tasks',
                            value: '${tasks.length}',
                            icon: Icons.task_alt,
                            color: Colors.indigo,
                          ),
                          const SizedBox(width: 14),
                          StatisticsCard(
                            label: 'Completed',
                            value: '$complete',
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 14),
                          StatisticsCard(
                            label: 'Pending',
                            value: '${tasks.length - complete}',
                            icon: Icons.pending_actions,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 14),
                          StatisticsCard(
                            label: 'Completion',
                            value: tasks.isEmpty
                                ? '0%'
                                : '${(complete / tasks.length * 100).round()}%',
                            icon: Icons.pie_chart,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    TaskSearchBar(onChanged: (v) => setState(() => _query = v)),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final value in [
                            'All',
                            'Pending',
                            'Completed',
                          ]) ...[
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(value),
                                selected: _completion == value,
                                onSelected: (_) =>
                                    setState(() => _completion = value),
                                selectedColor: Colors.white24,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                labelStyle: TextStyle(
                                  color: _completion == value
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          _buildFilterMenu(
                            label: _priority,
                            items: ['All', 'Low', 'Medium', 'High'],
                            onSelected: (value) =>
                                setState(() => _priority = value),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterMenu(
                            label: _status,
                            items: statuses,
                            onSelected: (value) =>
                                setState(() => _status = value),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterMenu(
                            label: _dateFilter,
                            items: const ['Any time', 'Today', 'This Week'],
                            onSelected: (value) =>
                                setState(() => _dateFilter = value),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterMenu(
                            label: _sort,
                            items: const [
                              'Newest',
                              'Oldest',
                              'Priority',
                              'Due date',
                              'Alphabetical',
                            ],
                            onSelected: (value) =>
                                setState(() => _sort = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (visible.isEmpty)
                      SizedBox(
                        height: 300,
                        child: EmptyState(
                          filtered: tasks.isNotEmpty,
                          title: tasks.isNotEmpty ? 'No tasks match' : null,
                          description: tasks.isNotEmpty
                              ? 'Adjust your search or filters to see more tasks.'
                              : null,
                        ),
                      )
                    else
                      ...visible.map((t) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TaskCard(
                            task: t,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/details',
                              arguments: t,
                            ),
                            onToggle: () =>
                                context.read<TaskProvider>().toggleCompleted(t),
                            onDelete: () => _delete(t),
                          ),
                        );
                      }),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/tasks/create'),
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
        backgroundColor: const Color(0xFF7C3AED),
      ),
    );
  }

  Widget _buildFilterMenu({
    required String label,
    required List<String> items,
    required void Function(String) onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<String>(
        value: label,
        underline: const SizedBox(),
        dropdownColor: Theme.of(context).colorScheme.surface,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: Colors.white),
        borderRadius: BorderRadius.circular(18),
        iconEnabledColor: Colors.white70,
        items: items
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (value) {
          if (value != null) onSelected(value);
        },
      ),
    );
  }
}
