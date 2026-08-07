import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final bool filtered;
  final String? title;
  final String? description;

  const EmptyState({
    super.key,
    this.filtered = false,
    this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: .8);
    final defaultTitle = filtered ? 'No matching tasks' : 'No tasks yet';
    final defaultDescription = filtered
        ? 'Try adjusting your filters or search keywords.'
        : 'Create your first task to get started with a more productive day.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: .12),
              ),
              child: Icon(
                filtered ? Icons.search_off_rounded : Icons.task_alt_rounded,
                size: 48,
                color: color,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title ?? defaultTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              description ?? defaultDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
