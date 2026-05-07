import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_study_planner/models/subject.dart';

class SubjectNotifier extends StateNotifier<List<Subject>> {
  SubjectNotifier()
      : super(Hive.box<Subject>('subjects').values.toList());

  final Box<Subject> _box = Hive.box<Subject>('subjects');

  Future<void> addSubject(String name) async {
    final subject = Subject(id: const Uuid().v4(), name: name);
    await _box.put(subject.id, subject);
    state = _box.values.toList();
  }

  Future<void> deleteSubject(String id) async {
    await _box.delete(id);
    state = _box.values.toList();
  }
}

final subjectsProvider =
    StateNotifierProvider<SubjectNotifier, List<Subject>>(
  (ref) => SubjectNotifier(),
);
