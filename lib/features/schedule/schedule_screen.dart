import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_study_planner/models/subject.dart';
import 'package:smart_study_planner/models/study_session.dart';
import 'package:smart_study_planner/models/topic.dart';
import 'package:smart_study_planner/providers/providers.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  Subject? _selectedSubject;
  Topic? _selectedTopic;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final _durationCtrl = TextEditingController(text: '60');

  @override
  void dispose() {
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    final topics = _selectedSubject != null
        ? ref.watch(topicsForSubjectProvider(_selectedSubject!.id))
        : <Topic>[];
    final sessions = ref.watch(upcomingSessionsProvider);
    final allSubjects = ref.watch(subjectsProvider);
    final allTopics = ref.watch(allTopicsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Group sessions by date label
    final grouped = <String, List<StudySession>>{};
    for (final s in sessions) {
      grouped.putIfAbsent(_dateLabel(s.scheduledAt), () => []).add(s);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: cs.surfaceContainerHighest,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Form card ────────────────────────────────────────────────────
          Card(
            elevation: 0,
            color: cs.surfaceContainerLow,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New Session',
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // Subject dropdown
                      DropdownButtonFormField<Subject>(
                        initialValue: _selectedSubject,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.book),
                        ),
                        items: subjects
                            .map((s) => DropdownMenuItem(
                                value: s, child: Text(s.name)))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedSubject = v;
                          _selectedTopic = null;
                        }),
                        validator: (v) =>
                            v == null ? 'Select a subject' : null,
                      ),
                      const SizedBox(height: 12),

                      // Topic dropdown — rebuilds when subject changes
                      DropdownButtonFormField<Topic>(
                        key: ValueKey(_selectedSubject?.id),
                        initialValue: _selectedTopic,
                        decoration: InputDecoration(
                          labelText: 'Topic',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.topic),
                        ),
                        items: topics
                            .map((t) => DropdownMenuItem(
                                value: t, child: Text(t.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedTopic = v),
                        validator: (v) =>
                            v == null ? 'Select a topic' : null,
                      ),
                      const SizedBox(height: 12),

                      // Date + Time
                      Row(children: [
                        Expanded(
                          child: _PickerField(
                            label: DateFormat('MMM d, yyyy')
                                .format(_selectedDate),
                            icon: Icons.calendar_today,
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (d != null) {
                                setState(() => _selectedDate = d);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PickerField(
                            label: _selectedTime.format(context),
                            icon: Icons.access_time,
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                              );
                              if (t != null) {
                                setState(() => _selectedTime = t);
                              }
                            },
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),

                      // Duration
                      TextFormField(
                        controller: _durationCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          labelText: 'Duration (minutes)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.timer),
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || v!.isEmpty) return 'Enter duration';
                          if (n < 5) return 'Minimum 5 minutes';
                          if (n > 480) return 'Maximum 480 minutes (8 hours)';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _submitForm,
                          icon: const Icon(Icons.add_alarm),
                          label: const Text('Schedule Session'),
                        ),
                      ),
                    ]),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Upcoming sessions ─────────────────────────────────────────
          Text('Upcoming Sessions',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (grouped.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No sessions scheduled.',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            )
          else
            ...grouped.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(entry.key,
                          style: tt.labelLarge?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.bold)),
                    ),
                    ...entry.value.map((s) => _SessionTile(
                          session: s,
                          subjectName: allSubjects
                              .where((sub) => sub.id == s.subjectId)
                              .firstOrNull
                              ?.name ?? 'Unknown',
                          topicName: allTopics
                              .where((t) => t.id == s.topicId)
                              .firstOrNull
                              ?.name ?? 'Unknown',
                        )),
                    const SizedBox(height: 16),
                  ],
                )),
        ]),
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final scheduled = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Warn if past — but still allow
    if (scheduled.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              '⚠️ The selected time is in the past. Session still scheduled.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    ref.read(sessionsProvider.notifier).scheduleSession(
          subjectId: _selectedSubject!.id,
          topicId: _selectedTopic!.id,
          scheduledAt: scheduled,
          durationMinutes: int.tryParse(_durationCtrl.text) ?? 60,
        );

    if (scheduled.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Session scheduled successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    setState(() {
      _selectedSubject = null;
      _selectedTopic = null;
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _durationCtrl.text = '60';
    });
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return 'Today';
    if (date == today.add(const Duration(days: 1))) return 'Tomorrow';
    return DateFormat('EEEE, MMM d').format(dt);
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PickerField(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium)),
        ]),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final StudySession session;
  final String subjectName;
  final String topicName;
  const _SessionTile(
      {required this.session,
      required this.subjectName,
      required this.topicName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Text(
            DateFormat('HH:mm').format(session.scheduledAt),
            style: tt.labelSmall?.copyWith(color: cs.primary),
          ),
        ),
        title: Text(topicName,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subjectName,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cs.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${session.durationMinutes} min',
              style: tt.labelSmall
                  ?.copyWith(color: cs.onTertiaryContainer)),
        ),
      ),
    );
  }
}
