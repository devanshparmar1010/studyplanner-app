import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_study_planner/models/subject.dart';
import 'package:smart_study_planner/models/topic.dart';
import 'package:smart_study_planner/providers/providers.dart';

// ── Screen ────────────────────────────────────────────────────────────────────
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 72, color: cs.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No subjects yet. Tap + to add one.',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('New Subject',
              style: Theme.of(ctx)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Subject Name',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.book),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (ctrl.text.trim().isEmpty) return;
                ref
                    .read(subjectsProvider.notifier)
                    .addSubject(ctrl.text.trim());
                Navigator.pop(ctx);
              },
              child: const Text('Add Subject'),
            ),
          ),
        ]),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(children: [
          Padding(
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
              const SizedBox(width: 8),
              Icon(_expanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down),
            ]),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(children: [
              const Divider(height: 1),
              ...topics.map((t) => _TopicRow(
                    topic: t,
                    onLongPress: () =>
                        _showTopicSheet(context, widget.subject, t),
                  )),
              ListTile(
                leading: Icon(Icons.add_circle_outline, color: cs.primary),
                title:
                    Text('Add Topic', style: TextStyle(color: cs.primary)),
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
      ),
    );
  }

  void _showTopicSheet(
      BuildContext context, Subject subject, Topic? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final minsCtrl =
        TextEditingController(text: existing?.estimatedMinutes.toString() ?? '');
    TopicStatus selectedStatus = existing?.status ?? TopicStatus.notStarted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(existing == null ? 'Add Topic' : 'Edit Topic',
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Topic Name',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.topic),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minsCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Estimated Minutes',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.timer),
              ),
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
                  if (nameCtrl.text.trim().isEmpty) return;
                  if (existing == null) {
                    ref.read(allTopicsProvider.notifier).addTopic(
                          subjectId: subject.id,
                          name: nameCtrl.text.trim(),
                          estimatedMinutes:
                              int.tryParse(minsCtrl.text) ?? 30,
                          status: selectedStatus,
                        );
                  } else {
                    ref
                        .read(allTopicsProvider.notifier)
                        .updateTopicStatus(existing.id, selectedStatus);
                  }
                  Navigator.pop(ctx);
                },
                child:
                    Text(existing == null ? 'Add Topic' : 'Save Changes'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Topic row ─────────────────────────────────────────────────────────────────
class _TopicRow extends StatelessWidget {
  final Topic topic;
  final VoidCallback onLongPress;
  const _TopicRow({required this.topic, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Icon(_statusIcon(topic.status),
              color: _statusColor(topic.status, cs), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(topic.name, style: tt.bodyMedium)),
          Text('${topic.estimatedMinutes} min',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(width: 8),
          _StatusChip(status: topic.status),
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
