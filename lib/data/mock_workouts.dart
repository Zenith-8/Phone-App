import '../models/workout.dart';

/// Placeholder sessions until the app loads real data from your backend / bench.
List<Workout> mockWorkouts() {
  final now = DateTime.now();
  return [
    Workout(
      id: 'w1',
      title: 'Upper push',
      completedAt: now.subtract(const Duration(days: 1, hours: 3)),
      durationMinutes: 52,
      volumeKg: 4120,
      exerciseCount: 6,
      intensityLabel: 'Moderate',
      notes: 'Bench felt strong; kept a rep in reserve on top sets.',
      exerciseNames: const ['Barbell bench', 'Incline DB press', 'Triceps pushdown', 'Lateral raise', 'Cable fly', 'Overhead press'],
    ),
    Workout(
      id: 'w2',
      title: 'Leg day',
      completedAt: now.subtract(const Duration(days: 3, hours: 1)),
      durationMinutes: 61,
      volumeKg: 8900,
      exerciseCount: 7,
      intensityLabel: 'Hard',
      notes: 'Squat volume up slightly from last week. Knees tracked well.',
      exerciseNames: const ['Back squat', 'Romanian deadlift', 'Leg press', 'Leg curl', 'Calf raise', 'Walking lunge', 'Core plank'],
    ),
    Workout(
      id: 'w3',
      title: 'Pull + arms',
      completedAt: now.subtract(const Duration(days: 5)),
      durationMinutes: 48,
      volumeKg: 3650,
      exerciseCount: 5,
      intensityLabel: 'Moderate',
      notes: 'Pulled a bit light to focus on scapular control.',
      exerciseNames: const ['Pull-up', 'Barbell row', 'Face pull', 'EZ bar curl', 'Hammer curl'],
    ),
    Workout(
      id: 'w4',
      title: 'Full body — deload',
      completedAt: now.subtract(const Duration(days: 8)),
      durationMinutes: 40,
      volumeKg: 2400,
      exerciseCount: 4,
      intensityLabel: 'Light',
      notes: 'Scheduled deload; reduced loads ~15% across the board.',
      exerciseNames: const ['Goblet squat', 'DB bench', 'Cable row', 'Farmer carry'],
    ),
  ];
}
