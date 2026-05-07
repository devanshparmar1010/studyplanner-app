import 'package:go_router/go_router.dart';
import 'package:smart_study_planner/features/dashboard/dashboard_screen.dart';
import 'package:smart_study_planner/features/subjects/subjects_screen.dart';
import 'package:smart_study_planner/features/schedule/schedule_screen.dart';
import 'package:smart_study_planner/features/progress/progress_screen.dart';
import 'package:smart_study_planner/features/search/search_screen.dart';

final router = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/subjects',
      name: 'subjects',
      builder: (context, state) => const SubjectsScreen(),
    ),
    GoRoute(
      path: '/schedule',
      name: 'schedule',
      builder: (context, state) => const ScheduleScreen(),
    ),
    GoRoute(
      path: '/progress',
      name: 'progress',
      builder: (context, state) => const ProgressScreen(),
    ),
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) => const SearchScreen(),
    ),
  ],
);
