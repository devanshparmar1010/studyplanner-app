import 'package:hive/hive.dart';

part 'topic.g.dart';

@HiveType(typeId: 1)
enum TopicStatus {
  @HiveField(0)
  notStarted,

  @HiveField(1)
  inProgress,

  @HiveField(2)
  completed,
}

@HiveType(typeId: 2)
class Topic extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String subjectId;

  @HiveField(2)
  String name;

  @HiveField(3)
  int estimatedMinutes;

  @HiveField(4)
  TopicStatus status;

  Topic({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.estimatedMinutes,
    this.status = TopicStatus.notStarted,
  });
}
