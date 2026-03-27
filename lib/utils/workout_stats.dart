import '../models/workout.dart';

class WorkoutStats {
  const WorkoutStats({
    required this.sessionsLast7Days,
    required this.volumeLast7DaysKg,
    required this.totalSessions,
  });

  final int sessionsLast7Days;
  final double volumeLast7DaysKg;
  final int totalSessions;

  static WorkoutStats fromWorkouts(List<Workout> all, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final weekAgo = t.subtract(const Duration(days: 7));
    var sessions = 0;
    var vol = 0.0;
    for (final w in all) {
      if (!w.completedAt.isBefore(weekAgo)) {
        sessions++;
        vol += w.volumeKg;
      }
    }
    return WorkoutStats(
      sessionsLast7Days: sessions,
      volumeLast7DaysKg: vol,
      totalSessions: all.length,
    );
  }
}
