import 'package:hive/hive.dart';

part 'study_session.g.dart';

@HiveType(typeId: 3)
class StudySession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String subjectId;

  @HiveField(2)
  String topicId;

  @HiveField(3)
  DateTime scheduledAt;

  @HiveField(4)
  int durationMinutes;

  StudySession({
    required this.id,
    required this.subjectId,
    required this.topicId,
    required this.scheduledAt,
    required this.durationMinutes,
  });
}
