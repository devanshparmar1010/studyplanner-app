import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_study_planner/models/topic.dart';
import 'package:smart_study_planner/providers/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final subjects = ref.watch(subjectsProvider);
    final allTopics = ref.watch(allTopicsProvider);
    final todaySessions = ref.watch(todaySessionsProvider);
    final overall = ref.watch(overallCompletionProvider);
    final nextStudy = ref.watch(nextToStudyProvider);

    final completedTopics =
        allTopics.where((t) => t.status == TopicStatus.completed).length;
    final pendingTopics = allTopics.length - completedTopics;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────
          SliverAppBar.large(
            title: const Text('Dashboard'),
            backgroundColor: cs.surfaceContainerHighest,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, cs.tertiary],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Stat cards ────────────────────────────────────────
                Row(
                  children: [
                    _StatCard(
                        label: 'Subjects',
                        value: '${subjects.length}',
                        icon: Icons.book,
                        color: cs.primary),
                    _StatCard(
                        label: 'Completed',
                        value: '$completedTopics',
                        icon: Icons.check_circle,
                        color: Colors.green),
                    _StatCard(
                        label: 'Pending',
                        value: '$pendingTopics',
                        icon: Icons.pending,
                        color: cs.error),
                    _StatCard(
                        label: 'Today',
                        value: '${todaySessions.length}',
                        icon: Icons.today,
                        color: cs.tertiary),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Overall progress ──────────────────────────────────
                _SectionCard(
                  title: 'Overall Completion',
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Progress', style: tt.bodyMedium),
                            Text(
                              '${(overall * 100).toStringAsFixed(0)}%',
                              style: tt.titleMedium?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: overall,
                            minHeight: 12,
                            backgroundColor: cs.primaryContainer,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(cs.primary),
                          ),
                        ),
                      ]),
                ),
                const SizedBox(height: 20),

                // ── Bar chart ─────────────────────────────────────────
                if (subjects.isNotEmpty)
                  _SectionCard(
                    title: 'Per-Subject Completion',
                    child: SizedBox(
                      height: 200,
                      child: _SubjectBarChart(
                        subjects: subjects
                            .map((s) => (
                                  s.name,
                                  ref.watch(subjectCompletionProvider(s.id))
                                ))
                            .toList(),
                        cs: cs,
                      ),
                    ),
                  ),
                if (subjects.isNotEmpty) const SizedBox(height: 20),

                // ── Next to study ─────────────────────────────────────
                nextStudy != null
                    ? _NextStudyCard(
                        subjectName: nextStudy.subject.name,
                        topicName: nextStudy.topic.name,
                        minutes: nextStudy.topic.estimatedMinutes,
                        status: nextStudy.topic.status,
                        cs: cs,
                        tt: tt,
                      )
                    : _EmptyNextStudyCard(cs: cs, tt: tt),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Card(
          elevation: 0,
          color: color.withValues(alpha: 0.12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value,
                  style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: tt.labelSmall,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────
class _SubjectBarChart extends StatelessWidget {
  final List<(String, double)> subjects;
  final ColorScheme cs;
  const _SubjectBarChart({required this.subjects, required this.cs});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) => Text('${(v * 100).toInt()}%',
                  style: const TextStyle(fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= subjects.length) {
                  return const SizedBox();
                }
                final name = subjects[idx].$1;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    name.length > 4 ? name.substring(0, 4) : name,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 0.25,
          getDrawingHorizontalLine: (_) => FlLine(
              color: cs.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          subjects.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: subjects[i].$2,
                gradient: LinearGradient(
                  colors: [cs.primary, cs.tertiary],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 20,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Next to study card ────────────────────────────────────────────────────────
class _NextStudyCard extends StatelessWidget {
  final String subjectName, topicName;
  final int minutes;
  final TopicStatus status;
  final ColorScheme cs;
  final TextTheme tt;
  const _NextStudyCard({
    required this.subjectName,
    required this.topicName,
    required this.minutes,
    required this.status,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lightbulb, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Next to Study',
                style: tt.labelLarge?.copyWith(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(topicName,
                style: tt.titleMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('$subjectName · $minutes min',
                style: tt.bodySmall?.copyWith(color: Colors.white70)),
          ]),
        ),
        const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
      ]),
    );
  }
}

class _EmptyNextStudyCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _EmptyNextStudyCard({required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Icon(Icons.celebration, color: cs.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('All caught up!',
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Add subjects & topics to get started.',
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ]),
          ),
        ]),
      ),
    );
  }
}
