import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_study_planner/models/subject.dart';
import 'package:smart_study_planner/models/topic.dart';
import 'package:smart_study_planner/providers/subject_provider.dart';
import 'package:smart_study_planner/providers/topic_provider.dart';

/// Completion ratio (0.0–1.0) for a single subject.
final subjectCompletionProvider =
    Provider.family<double, String>((ref, subjectId) {
  final topics = ref.watch(topicsForSubjectProvider(subjectId));
  if (topics.isEmpty) return 0.0;
  final completed =
      topics.where((t) => t.status == TopicStatus.completed).length;
  return completed / topics.length;
});

/// Overall completion ratio across all subjects.
final overallCompletionProvider = Provider<double>((ref) {
  final topics = ref.watch(allTopicsProvider);
  if (topics.isEmpty) return 0.0;
  final completed =
      topics.where((t) => t.status == TopicStatus.completed).length;
  return completed / topics.length;
});

/// Subject with the lowest completion — highest priority for study.
final lowestCompletionSubjectProvider = Provider<Subject?>((ref) {
  final subjects = ref.watch(subjectsProvider);
  if (subjects.isEmpty) return null;
  Subject? lowest;
  double lowestPct = 2.0;
  for (final s in subjects) {
    final pct = ref.watch(subjectCompletionProvider(s.id));
    if (pct < lowestPct) {
      lowestPct = pct;
      lowest = s;
    }
  }
  return lowest;
});

typedef NextToStudy = ({Subject subject, Topic topic});

/// The highest-priority topic to study next (first non-completed topic
/// in the subject with the lowest completion %).
final nextToStudyProvider = Provider<NextToStudy?>((ref) {
  final subject = ref.watch(lowestCompletionSubjectProvider);
  if (subject == null) return null;
  final topics = ref.watch(topicsForSubjectProvider(subject.id));
  final next = topics
      .where((t) => t.status != TopicStatus.completed)
      .firstOrNull;
  if (next == null) return null;
  return (subject: subject, topic: next);
});
