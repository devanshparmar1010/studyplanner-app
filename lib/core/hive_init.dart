import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_study_planner/models/subject.dart';
import 'package:smart_study_planner/models/topic.dart';
import 'package:smart_study_planner/models/study_session.dart';

Future<void> initHive() async {
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(SubjectAdapter());
  Hive.registerAdapter(TopicStatusAdapter());
  Hive.registerAdapter(TopicAdapter());
  Hive.registerAdapter(StudySessionAdapter());

  // Open boxes
  await Hive.openBox<Subject>('subjects');
  await Hive.openBox<Topic>('topics');
  await Hive.openBox<StudySession>('study_sessions');
}
