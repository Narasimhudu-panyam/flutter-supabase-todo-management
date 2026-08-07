import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import 'create_task_screen.dart';

class EditTaskScreen extends StatefulWidget {
  final TaskModel task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late DateTime? _dueDate;
  late String _priority, _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task.title);
    _description = TextEditingController(text: widget.task.description);
    _dueDate = widget.task.dueDate;
    _priority = widget.task.priority;
    _status = widget.task.status;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await context.read<TaskProvider>().updateTask(
        widget.task.copyWith(
          title: _title.text.trim(),
          description: _description.text.trim(),
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
          priority: _priority,
          status: _status,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task updated')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not update task')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TaskFormScaffold(
      title: 'Edit task',
      formKey: _form,
      titleController: _title,
      descriptionController: _description,
      dueDate: _dueDate,
      priority: _priority,
      status: _status,
      saving: _saving,
      onDate: (value) => setState(() => _dueDate = value),
      onPriority: (value) => setState(() => _priority = value),
      onStatus: (value) => setState(() => _status = value),
      onSave: _save,
    );
  }
}
