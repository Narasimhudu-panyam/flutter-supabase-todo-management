import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/task_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  String _priority = 'medium';
  String _status = 'pending';
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await context.read<TaskProvider>().addTask(
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _dueDate,
        priority: _priority,
        status: _status,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created successfully')),
      );
    } catch (error, stackTrace) {
      debugPrint('CREATE TASK ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_createTaskErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _createTaskErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('row-level security')) {
      return 'Task could not be saved: database permissions need updating.';
    }
    if (message.contains('violates check constraint')) {
      return 'Task could not be saved: database values need updating.';
    }
    if (message.contains('No authenticated Supabase user')) {
      return 'Please sign in again before creating a task.';
    }
    return 'Could not create task. Check the debug console for details.';
  }

  @override
  Widget build(BuildContext context) {
    return TaskFormScaffold(
      title: 'New task',
      formKey: _formKey,
      titleController: _titleController,
      descriptionController: _descriptionController,
      dueDate: _dueDate,
      priority: _priority,
      status: _status,
      saving: _isSaving,
      onDate: (value) => setState(() => _dueDate = value),
      onPriority: (value) => setState(() => _priority = value),
      onStatus: (value) => setState(() => _status = value),
      onSave: _saveTask,
    );
  }
}

/// Reusable task form shell shared by create and edit flows.
class TaskFormScaffold extends StatelessWidget {
  const TaskFormScaffold({
    super.key,
    required this.title,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.saving,
    required this.onDate,
    required this.onPriority,
    required this.onStatus,
    required this.onSave,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final DateTime? dueDate;
  final String priority;
  final String status;
  final bool saving;
  final ValueChanged<DateTime?> onDate;
  final ValueChanged<String> onPriority;
  final ValueChanged<String> onStatus;
  final VoidCallback onSave;

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: const Color(0xFF7C3AED),
            onPrimary: Colors.white,
            surface: const Color(0xFF111827),
            onSurface: Colors.white,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF0F172A),
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) onDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .18),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: titleController,
                    label: 'Title *',
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'A title is required'
                        : null,
                    prefixIcon: const Icon(Icons.title_outlined),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      prefixIcon: const Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _pickDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_outlined,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              dueDate == null
                                  ? 'Set a due date'
                                  : 'Due ${MaterialLocalizations.of(context).formatMediumDate(dueDate!)}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          if (dueDate != null)
                            IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white70,
                              ),
                              onPressed: () => onDate(null),
                            )
                          else
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white70,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (value) {
                      if (value != null) onPriority(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.task_alt_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('In progress'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Completed'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onStatus(value);
                    },
                  ),
                  const SizedBox(height: 28),
                  CustomButton(
                    text: saving ? 'Saving…' : 'Save task',
                    loading: saving,
                    icon: const Icon(Icons.save_outlined),
                    onPressed: onSave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
