import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_study_planner/models/subject.dart';
import 'package:smart_study_planner/models/topic.dart';
import 'package:smart_study_planner/providers/providers.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        backgroundColor: cs.surfaceContainerHighest,
      ),
      body: subjects.isEmpty
          ? _EmptyState(
              icon: Icons.book_outlined,
              title: 'No Subjects Yet',
              message: 'Tap the button below to add your first subject.',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: subjects.length,
              itemBuilder: (ctx, i) => _SubjectCard(subject: subjects[i]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubjectSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
    );
  }

  void _showAddSubjectSheet(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child:
              Column(mainAxisSize: MainAxisSize.min, children: [
            Text('New Subject',
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: ctrl,
              autofocus: true,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: 'Subject Name',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.book),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Subject name cannot be empty';
                }
                if (v.trim().length > 100) {
                  return 'Name must be 100 characters or less';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    ref
                        .read(subjectsProvider.notifier)
                        .addSubject(ctrl.text.trim());
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Add Subject'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Subject card ──────────────────────────────────────────────────────────────
class _SubjectCard extends ConsumerStatefulWidget {
  final Subject subject;
  const _SubjectCard({required this.subject});

  @override
  ConsumerState<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends ConsumerState<_SubjectCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final topics = ref.watch(topicsForSubjectProvider(widget.subject.id));
    final completed =
        topics.where((t) => t.status == TopicStatus.completed).length;
    final total = topics.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        // ── Header ────────────────────────────────────────────────────────
        InkWell(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.book, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.subject.name,
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('$completed/$total topics completed',
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ]),
              ),
              if (total > 0)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(fit: StackFit.expand, children: [
                    CircularProgressIndicator(
                      value: completed / total,
                      backgroundColor: cs.outlineVariant,
                      color: cs.primary,
                      strokeWidth: 4,
                    ),
                    Center(
                      child: Text('${((completed / total) * 100).toInt()}%',
                          style: tt.labelSmall),
                    ),
                  ]),
                ),
              const SizedBox(width: 4),
              // Delete button
              IconButton(
                icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
                tooltip: 'Delete subject',
                onPressed: () => _confirmDelete(context),
              ),
              Icon(_expanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down),
            ]),
          ),
        ),

        // ── Topics ────────────────────────────────────────────────────────
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(children: [
            const Divider(height: 1),
            topics.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    child: Text('No topics yet. Tap "Add Topic" below.',
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  )
                : Column(
                    children: topics
                        .map((t) => _TopicRow(
                              topic: t,
                              onLongPress: () =>
                                  _showTopicSheet(context, widget.subject, t),
                            ))
                        .toList(),
                  ),
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: cs.primary),
              title: Text('Add Topic', style: TextStyle(color: cs.primary)),
              dense: true,
              onTap: () => _showTopicSheet(context, widget.subject, null),
            ),
          ]),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ]),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text(
            'This will also delete all topics for "${widget.subject.name}". This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () {
              ref
                  .read(allTopicsProvider.notifier)
                  .deleteTopicsForSubject(widget.subject.id);
              ref
                  .read(subjectsProvider.notifier)
                  .deleteSubject(widget.subject.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTopicSheet(
      BuildContext context, Subject subject, Topic? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final minsCtrl =
        TextEditingController(text: existing?.estimatedMinutes.toString() ?? '');
    TopicStatus selectedStatus = existing?.status ?? TopicStatus.notStarted;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(existing == null ? 'Add Topic' : 'Edit Topic',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'Topic Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.topic),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Topic name cannot be empty';
                  }
                  if (v.trim().length > 100) {
                    return 'Name must be 100 characters or less';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: minsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Estimated Minutes (5–480)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.timer),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null) return 'Enter a valid number';
                  if (n < 5) return 'Minimum 5 minutes';
                  if (n > 480) return 'Maximum 480 minutes (8 hours)';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TopicStatus>(
                initialValue: selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.flag),
                ),
                items: TopicStatus.values
                    .map((s) => DropdownMenuItem(
                        value: s, child: Text(_statusLabel(s))))
                    .toList(),
                onChanged: (v) => setModal(() => selectedStatus = v!),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    if (existing == null) {
                      ref.read(allTopicsProvider.notifier).addTopic(
                            subjectId: subject.id,
                            name: nameCtrl.text.trim(),
                            estimatedMinutes: int.parse(minsCtrl.text),
                            status: selectedStatus,
                          );
                    } else {
                      ref
                          .read(allTopicsProvider.notifier)
                          .updateTopicStatus(existing.id, selectedStatus);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(existing == null ? 'Add Topic' : 'Save Changes'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Topic row (tap status to cycle, long-press to edit) ──────────────────────
class _TopicRow extends ConsumerWidget {
  final Topic topic;
  final VoidCallback onLongPress;
  const _TopicRow({required this.topic, required this.onLongPress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Cycle: notStarted → inProgress → completed → notStarted
    TopicStatus nextStatus(TopicStatus current) => switch (current) {
          TopicStatus.notStarted => TopicStatus.inProgress,
          TopicStatus.inProgress => TopicStatus.completed,
          TopicStatus.completed => TopicStatus.notStarted,
        };

    return InkWell(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          // Status icon — tappable to cycle
          GestureDetector(
            onTap: () {
              final next = nextStatus(topic.status);
              ref
                  .read(allTopicsProvider.notifier)
                  .updateTopicStatus(topic.id, next);
            },
            child: Tooltip(
              message: 'Tap to change status',
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  _statusIcon(topic.status),
                  key: ValueKey(topic.status),
                  color: _statusColor(topic.status, cs),
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topic.name, style: tt.bodyMedium),
                Text(
                  'Tap icon to update status',
                  style: tt.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          Text('${topic.estimatedMinutes} min',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(width: 8),
          // Tappable status chip
          GestureDetector(
            onTap: () {
              final next = nextStatus(topic.status);
              ref
                  .read(allTopicsProvider.notifier)
                  .updateTopicStatus(topic.id, next);
            },
            child: _StatusChip(status: topic.status),
          ),
        ]),
      ),
    );
  }
}


class _StatusChip extends StatelessWidget {
  final TopicStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      TopicStatus.completed => (
          Colors.green.withValues(alpha: 0.15),
          Colors.green
        ),
      TopicStatus.inProgress => (cs.primaryContainer, cs.primary),
      TopicStatus.notStarted => (
          cs.surfaceContainerHighest,
          cs.onSurfaceVariant
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(_statusLabel(status),
          style: TextStyle(
              fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _EmptyState(
      {required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: cs.primary),
          ),
          const SizedBox(height: 24),
          Text(title,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
String _statusLabel(TopicStatus s) => switch (s) {
      TopicStatus.notStarted => 'Not Started',
      TopicStatus.inProgress => 'In Progress',
      TopicStatus.completed => 'Completed',
    };

IconData _statusIcon(TopicStatus s) => switch (s) {
      TopicStatus.notStarted => Icons.radio_button_unchecked,
      TopicStatus.inProgress => Icons.timelapse,
      TopicStatus.completed => Icons.check_circle,
    };

Color _statusColor(TopicStatus s, ColorScheme cs) => switch (s) {
      TopicStatus.notStarted => cs.onSurfaceVariant,
      TopicStatus.inProgress => cs.primary,
      TopicStatus.completed => Colors.green,
    };
