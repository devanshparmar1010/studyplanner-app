import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_study_planner/models/topic.dart';
import 'package:smart_study_planner/providers/providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    final filtered = ref.watch(filteredTopicsProvider);
    final statusFilter = ref.watch(statusFilterProvider);
    final subjectFilter = ref.watch(subjectFilterProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: cs.surfaceContainerHighest,
      ),
      body: Column(children: [
        // ── Search bar ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) =>
                ref.read(searchQueryProvider.notifier).state = v,
            decoration: InputDecoration(
              hintText: 'Search topics or subjects…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              filled: true,
              fillColor: cs.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Status filter chips ──────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _FilterChip(
              label: 'All',
              selected: statusFilter == null,
              onTap: () =>
                  ref.read(statusFilterProvider.notifier).state = null,
            ),
            const SizedBox(width: 8),
            ...TopicStatus.values.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: _statusLabel(s),
                    selected: statusFilter == s,
                    onTap: () => ref.read(statusFilterProvider.notifier).state =
                        statusFilter == s ? null : s,
                    color: _statusColor(s, cs),
                  ),
                )),
          ]),
        ),
        const SizedBox(height: 8),

        // ── Subject dropdown ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            initialValue: subjectFilter,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'Filter by subject',
              prefixIcon: const Icon(Icons.book_outlined),
              filled: true,
              fillColor: cs.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('All Subjects')),
              ...subjects.map((s) =>
                  DropdownMenuItem(value: s.id, child: Text(s.name))),
            ],
            onChanged: (v) =>
                ref.read(subjectFilterProvider.notifier).state = v,
          ),
        ),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Text(
                '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                style: tt.labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ]),
        ),

        // ── Results list ─────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 64, color: cs.outlineVariant),
                      const SizedBox(height: 12),
                      Text('No topics found',
                          style: tt.bodyLarge
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final item = filtered[i];
                    return _TopicResultTile(
                        subjectName: item.subject.name,
                        topicName: item.topic.name,
                        minutes: item.topic.estimatedMinutes,
                        status: item.topic.status);
                  },
                ),
        ),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected ? (color ?? cs.primary) : cs.surfaceContainerLow;
    final fg = selected ? Colors.white : cs.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: fg, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _TopicResultTile extends StatelessWidget {
  final String subjectName, topicName;
  final int minutes;
  final TopicStatus status;
  const _TopicResultTile(
      {required this.subjectName,
      required this.topicName,
      required this.minutes,
      required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final (icon, color) = switch (status) {
      TopicStatus.completed => (Icons.check_circle, Colors.green),
      TopicStatus.inProgress => (Icons.timelapse, cs.primary),
      TopicStatus.notStarted => (
          Icons.radio_button_unchecked,
          cs.onSurfaceVariant
        ),
    };
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(topicName,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subjectName,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('$minutes min',
              style: tt.labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(width: 8),
          _StatusBadge(status: status),
        ]),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TopicStatus status;
  const _StatusBadge({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(_statusLabel(status),
          style: TextStyle(
              fontSize: 10, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

String _statusLabel(TopicStatus s) => switch (s) {
      TopicStatus.notStarted => 'Not Started',
      TopicStatus.inProgress => 'In Progress',
      TopicStatus.completed => 'Completed',
    };

Color _statusColor(TopicStatus s, ColorScheme cs) => switch (s) {
      TopicStatus.notStarted => cs.onSurfaceVariant,
      TopicStatus.inProgress => cs.primary,
      TopicStatus.completed => Colors.green,
    };
