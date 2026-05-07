import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_study_planner/models/topic.dart';

class TopicNotifier extends StateNotifier<List<Topic>> {
  TopicNotifier()
      : super(Hive.box<Topic>('topics').values.toList());

  final Box<Topic> _box = Hive.box<Topic>('topics');

  Future<void> addTopic({
    required String subjectId,
    required String name,
    required int estimatedMinutes,
    TopicStatus status = TopicStatus.notStarted,
  }) async {
    final topic = Topic(
      id: const Uuid().v4(),
      subjectId: subjectId,
      name: name,
      estimatedMinutes: estimatedMinutes,
      status: status,
    );
    await _box.put(topic.id, topic);
    state = _box.values.toList();
  }

  Future<void> updateTopicStatus(String topicId, TopicStatus status) async {
    final topic = _box.get(topicId);
    if (topic != null) {
      topic.status = status;
      await topic.save();
      state = List.from(_box.values);
    }
  }

  Future<void> deleteTopic(String id) async {
    await _box.delete(id);
    state = _box.values.toList();
  }
}

final allTopicsProvider =
    StateNotifierProvider<TopicNotifier, List<Topic>>(
  (ref) => TopicNotifier(),
);

final topicsForSubjectProvider =
    Provider.family<List<Topic>, String>((ref, subjectId) {
  return ref
      .watch(allTopicsProvider)
      .where((t) => t.subjectId == subjectId)
      .toList();
});
