import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_study_planner/features/subjects/subjects_screen.dart';

// ── Dummy session model ───────────────────────────────────────────────────────
class SessionData {
  final String subjectName, topicName;
  final DateTime scheduledAt;
  final int durationMinutes;
  SessionData({
    required this.subjectName,
    required this.topicName,
    required this.scheduledAt,
    required this.durationMinutes,
  });
}

final sessionsProvider = StateProvider<List<SessionData>>((ref) {
  final now = DateTime.now();
  return [
    SessionData(
      subjectName: 'Mathematics',
      topicName: 'Calculus',
      scheduledAt: now.copyWith(hour: 9, minute: 0),
      durationMinutes: 60,
    ),
    SessionData(
      subjectName: 'Physics',
      topicName: 'Quantum Mechanics',
      scheduledAt: now.copyWith(hour: 14, minute: 30),
      durationMinutes: 90,
    ),
    SessionData(
      subjectName: 'Chemistry',
      topicName: 'Organic Chemistry',
      scheduledAt: now.add(const Duration(days: 1)).copyWith(hour: 10),
      durationMinutes: 45,
    ),
  ];
});

// ── Screen ────────────────────────────────────────────────────────────────────
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSubjectId;
  String? _selectedTopicName;
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
    final sessions = ref.watch(sessionsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Group sessions by date label
    final grouped = <String, List<SessionData>>{};
    for (final s in sessions) {
      final label = _dateLabel(s.scheduledAt);
      grouped.putIfAbsent(label, () => []).add(s);
    }

    final selectedSubject = subjects.where((s) => s.id == _selectedSubjectId).firstOrNull;
    final topicList = selectedSubject?.topics ?? [];

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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSubjectId,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.book),
                        ),
                        items: subjects
                            .map((s) => DropdownMenuItem(
                                value: s.id, child: Text(s.name)))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedSubjectId = v;
                          _selectedTopicName = null;
                        }),
                        validator: (v) =>
                            v == null ? 'Select a subject' : null,
                      ),
                      const SizedBox(height: 12),

                      // Topic dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTopicName,
                        decoration: InputDecoration(
                          labelText: 'Topic',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.topic),
                        ),
                        items: topicList
                            .map((t) => DropdownMenuItem(
                                value: t.name, child: Text(t.name)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedTopicName = v),
                        validator: (v) =>
                            v == null ? 'Select a topic' : null,
                      ),
                      const SizedBox(height: 12),

                      // Date + Time row
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
                                firstDate: DateTime.now(),
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

                      // Duration field
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
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter duration'
                            : null,
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
                    ...entry.value.map((s) => _SessionTile(session: s)),
                    const SizedBox(height: 16),
                  ],
                )),
        ]),
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    final subject = ref
        .read(subjectsProvider)
        .firstWhere((s) => s.id == _selectedSubjectId);
    final scheduled = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    ref.read(sessionsProvider.notifier).update((sessions) => [
          ...sessions,
          SessionData(
            subjectName: subject.name,
            topicName: _selectedTopicName!,
            scheduledAt: scheduled,
            durationMinutes: int.tryParse(_durationCtrl.text) ?? 60,
          ),
        ]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Session scheduled successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    setState(() {
      _selectedSubjectId = null;
      _selectedTopicName = null;
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
  final SessionData session;
  const _SessionTile({required this.session});

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
            DateFormat('HH:mm').format(session.scheduledAt),
            style: tt.labelSmall?.copyWith(color: cs.primary),
          ),
        ),
        title: Text(session.topicName,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(session.subjectName,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cs.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${session.durationMinutes} min',
              style: tt.labelSmall?.copyWith(color: cs.onTertiaryContainer)),
        ),
      ),
    );
  }
}
