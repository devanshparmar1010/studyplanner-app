import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_study_planner/core/sync_service.dart';
import 'package:smart_study_planner/models/study_session.dart';

class SessionNotifier extends StateNotifier<List<StudySession>> {
  SessionNotifier()
      : super(Hive.box<StudySession>('study_sessions').values.toList());

  final Box<StudySession> _box = Hive.box<StudySession>('study_sessions');

  Future<void> scheduleSession({
    required String subjectId,
    required String topicId,
    required DateTime scheduledAt,
    required int durationMinutes,
  }) async {
    final session = StudySession(
      id: const Uuid().v4(),
      subjectId: subjectId,
      topicId: topicId,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
    );
    await _box.put(session.id, session);
    state = _box.values.toList();
    SyncService.instance.enqueue('create', 'session', session.id);
  }

  Future<void> deleteSession(String id) async {
    await _box.delete(id);
    state = _box.values.toList();
    SyncService.instance.enqueue('delete', 'session', id);
  }
}

final sessionsProvider =
    StateNotifierProvider<SessionNotifier, List<StudySession>>(
  (ref) => SessionNotifier(),
);

final todaySessionsProvider = Provider<List<StudySession>>((ref) {
  final sessions = ref.watch(sessionsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  return sessions
      .where((s) =>
          !s.scheduledAt.isBefore(today) && s.scheduledAt.isBefore(tomorrow))
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
});

final upcomingSessionsProvider = Provider<List<StudySession>>((ref) {
  return ref.watch(sessionsProvider).toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
});
