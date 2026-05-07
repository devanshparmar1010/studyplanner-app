import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_study_planner/models/subject.dart';
import 'package:smart_study_planner/models/topic.dart';
import 'package:smart_study_planner/providers/subject_provider.dart';
import 'package:smart_study_planner/providers/topic_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final statusFilterProvider = StateProvider<TopicStatus?>((ref) => null);
final subjectFilterProvider = StateProvider<String?>((ref) => null);

typedef TopicResult = ({Subject subject, Topic topic});

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
