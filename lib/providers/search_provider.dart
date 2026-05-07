import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_study_planner/models/study_session.dart';
import 'package:smart_study_planner/models/subject.dart';
import 'package:smart_study_planner/models/topic.dart';
import 'package:smart_study_planner/providers/session_provider.dart';
import 'package:smart_study_planner/providers/subject_provider.dart';
import 'package:smart_study_planner/providers/topic_provider.dart';

// ── Topic search filters ───────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');
final statusFilterProvider = StateProvider<TopicStatus?>((ref) => null);
final subjectFilterProvider = StateProvider<String?>((ref) => null);

// ── Session date filter ────────────────────────────────────────────────────
/// Null means "all dates"
final sessionDateFilterProvider = StateProvider<DateTime?>((ref) => null);

typedef TopicResult = ({Subject subject, Topic topic});
typedef SessionResult = ({StudySession session, String subjectName, String topicName});

// ── Filtered topics (name + status + subject) ─────────────────────────────
final filteredTopicsProvider = Provider<List<TopicResult>>((ref) {
  final subjects = ref.watch(subjectsProvider);
  final allTopics = ref.watch(allTopicsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(statusFilterProvider);
  final subjectFilter = ref.watch(subjectFilterProvider);

  final subjectMap = {for (final s in subjects) s.id: s};
  final results = <TopicResult>[];

  for (final t in allTopics) {
    final subject = subjectMap[t.subjectId];
    if (subject == null) continue;
    final matchQuery = query.isEmpty ||
        t.name.toLowerCase().contains(query) ||
        subject.name.toLowerCase().contains(query);
    final matchStatus = statusFilter == null || t.status == statusFilter;
    final matchSubject =
        subjectFilter == null || t.subjectId == subjectFilter;
    if (matchQuery && matchStatus && matchSubject) {
      results.add((subject: subject, topic: t));
    }
  }
  return results;
});

// ── Filtered sessions by date ─────────────────────────────────────────────
final filteredSessionsProvider = Provider<List<SessionResult>>((ref) {
  final sessions = ref.watch(sessionsProvider);
  final subjects = ref.watch(subjectsProvider);
  final allTopics = ref.watch(allTopicsProvider);
  final dateFilter = ref.watch(sessionDateFilterProvider);

  final subjectMap = {for (final s in subjects) s.id: s};
  final topicMap = {for (final t in allTopics) t.id: t};

  final filtered = dateFilter == null
      ? sessions
      : sessions.where((s) {
          final d = s.scheduledAt;
          return d.year == dateFilter.year &&
              d.month == dateFilter.month &&
              d.day == dateFilter.day;
        }).toList();

  return filtered
      .map((s) => (
            session: s,
            subjectName: subjectMap[s.subjectId]?.name ?? 'Unknown',
            topicName: topicMap[s.topicId]?.name ?? 'Unknown',
          ))
      .toList()
    ..sort((a, b) =>
        a.session.scheduledAt.compareTo(b.session.scheduledAt));
});
