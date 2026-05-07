import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_study_planner/models/topic.dart';
import 'package:smart_study_planner/providers/providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchCtrl;
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: cs.surfaceContainerHighest,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.topic), text: 'Topics'),
            Tab(icon: Icon(Icons.event), text: 'Sessions by Date'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _TopicsTab(searchCtrl: _searchCtrl),
          const _SessionsDateTab(),
        ],
      ),
    );
  }
}

// ── Tab 1: Topic search + status/subject filter ────────────────────────────
class _TopicsTab extends ConsumerWidget {
  final TextEditingController searchCtrl;
  const _TopicsTab({required this.searchCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider);
    final filtered = ref.watch(filteredTopicsProvider);
    final statusFilter = ref.watch(statusFilterProvider);
    final subjectFilter = ref.watch(subjectFilterProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          controller: searchCtrl,
          onChanged: (v) =>
              ref.read(searchQueryProvider.notifier).state = v,
          decoration: InputDecoration(
            hintText: 'Search topics or subjects…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchCtrl.clear();
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

      // Status chips
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
                  onTap: () =>
                      ref.read(statusFilterProvider.notifier).state =
                          statusFilter == s ? null : s,
                  color: _statusColor(s, cs),
                ),
              )),
        ]),
      ),
      const SizedBox(height: 8),

      // Subject dropdown
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

      // Results
      Expanded(
        child: filtered.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: cs.outlineVariant),
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
                    status: item.topic.status,
                  );
                },
              ),
      ),
    ]);
  }
}

// ── Tab 2: Sessions filtered by date ──────────────────────────────────────
class _SessionsDateTab extends ConsumerWidget {
  const _SessionsDateTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateFilter = ref.watch(sessionDateFilterProvider);
    final filteredSessions = ref.watch(filteredSessionsProvider);

    return Column(children: [
      // Date picker row
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                dateFilter == null
                    ? 'All Dates'
                    : DateFormat('MMM d, yyyy').format(dateFilter),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: dateFilter ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  ref.read(sessionDateFilterProvider.notifier).state = picked;
                }
              },
            ),
          ),
          if (dateFilter != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear date filter',
              onPressed: () =>
                  ref.read(sessionDateFilterProvider.notifier).state = null,
            ),
          ],
        ]),
      ),

      // Count
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Text(
            '${filteredSessions.length} session${filteredSessions.length == 1 ? '' : 's'}',
            style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (dateFilter != null)
            Text(
              ' on ${DateFormat('MMM d').format(dateFilter)}',
              style: tt.labelMedium?.copyWith(color: cs.primary),
            ),
        ]),
      ),
      const SizedBox(height: 8),

      // Sessions list
      Expanded(
        child: filteredSessions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 64, color: cs.outlineVariant),
                    const SizedBox(height: 12),
                    Text(
                      dateFilter == null
                          ? 'No sessions scheduled'
                          : 'No sessions on this date',
                      style: tt.bodyLarge
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                itemCount: filteredSessions.length,
                itemBuilder: (ctx, i) {
                  final item = filteredSessions[i];
                  return _SessionResultTile(
                    subjectName: item.subjectName,
                    topicName: item.topicName,
                    scheduledAt: item.session.scheduledAt,
                    durationMinutes: item.session.durationMinutes,
                  );
                },
              ),
      ),
    ]);
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(width: 8),
          _StatusBadge(status: status),
        ]),
      ),
    );
  }
}

class _SessionResultTile extends StatelessWidget {
  final String subjectName, topicName;
  final DateTime scheduledAt;
  final int durationMinutes;
  const _SessionResultTile(
      {required this.subjectName,
      required this.topicName,
      required this.scheduledAt,
      required this.durationMinutes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Text(
            DateFormat('HH:mm').format(scheduledAt),
            style: tt.labelSmall?.copyWith(color: cs.primary),
          ),
        ),
        title: Text(topicName,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '$subjectName · ${DateFormat('MMM d, yyyy').format(scheduledAt)}',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cs.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$durationMinutes min',
              style: tt.labelSmall
                  ?.copyWith(color: cs.onTertiaryContainer)),
        ),
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
