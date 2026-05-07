import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_study_planner/models/topic.dart';
import 'package:smart_study_planner/providers/providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider);
    final allTopics = ref.watch(allTopicsProvider);
    final overall = ref.watch(overallCompletionProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final totalTopics = allTopics.length;
    final completedTopics =
        allTopics.where((t) => t.status == TopicStatus.completed).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        backgroundColor: cs.surfaceContainerHighest,
      ),
      body: subjects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 72, color: cs.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No data yet. Add subjects to track progress.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Summary card ───────────────────────────────────────────
                Card(
                  elevation: 0,
                  color: cs.primaryContainer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Overall Progress',
                                  style: tt.titleMedium?.copyWith(
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                  '$completedTopics of $totalTopics topics completed',
                                  style: tt.bodyMedium?.copyWith(
                                      color: cs.onPrimaryContainer
                                          .withValues(alpha: 0.8))),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: overall,
                                  minHeight: 10,
                                  backgroundColor: cs.onPrimaryContainer
                                      .withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      cs.onPrimaryContainer),
                                ),
                              ),
                            ]),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${(overall * 100).toInt()}%',
                        style: tt.displaySmall?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.bold),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                ...subjects.map((s) => _SubjectProgressCard(subjectId: s.id, subjectName: s.name)),
              ],
            ),
    );
  }
}

class _SubjectProgressCard extends ConsumerStatefulWidget {
  final String subjectId;
  final String subjectName;
  const _SubjectProgressCard(
      {required this.subjectId, required this.subjectName});

  @override
  ConsumerState<_SubjectProgressCard> createState() =>
      _SubjectProgressCardState();
}

class _SubjectProgressCardState extends ConsumerState<_SubjectProgressCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final topics = ref.watch(topicsForSubjectProvider(widget.subjectId));
    final pct = ref.watch(subjectCompletionProvider(widget.subjectId));

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.book, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.subjectName,
                          style: tt.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: cs.outlineVariant,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(cs.primary),
                        ),
                      ),
                    ]),
              ),
              const SizedBox(width: 12),
              Text('${(pct * 100).toInt()}%',
                  style: tt.labelLarge?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.bold)),
              Icon(_expanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down),
            ]),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(children: [
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...topics.map((t) => _TopicProgressRow(topic: t)),
              ]),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ]),
        ),
      ),
    );
  }
}

class _TopicProgressRow extends StatelessWidget {
  final dynamic topic;
  const _TopicProgressRow({required this.topic});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final (icon, color) = switch (topic.status as TopicStatus) {
      TopicStatus.completed => (Icons.check_circle, Colors.green),
      TopicStatus.inProgress => (Icons.timelapse, cs.primary),
      TopicStatus.notStarted => (
          Icons.radio_button_unchecked,
          cs.onSurfaceVariant
        ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
            child: Text(topic.name as String, style: tt.bodyMedium)),
        Text('${topic.estimatedMinutes as int} min',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ]),
    );
  }
}
