class Workout {
  const Workout({
    required this.id,
    required this.title,
    required this.completedAt,
    required this.durationMinutes,
    required this.volumeKg,
    required this.exerciseCount,
    required this.notes,
    required this.exerciseNames,
    this.intensityLabel,
    this.machine,
    this.reps,
    this.sets,
  });

  final String id;
  final String title;
  final DateTime completedAt;
  final int durationMinutes;
  final double volumeKg;
  final int exerciseCount;
  final String notes;
  final List<String> exerciseNames;
  final String? intensityLabel;
  final String? machine;
  final int? reps;
  final int? sets;

  double get volumeTonnes => volumeKg / 1000;

  factory Workout.fromServerJson(Map<String, dynamic> json) {
    final durationSec = (json['duration_sec'] as num?)?.toDouble() ?? 0;
    final weightKg = (json['weight_kg'] as num?)?.toInt() ?? 0;
    final reps = (json['reps'] as num?)?.toInt() ?? 0;
    final sets = (json['sets'] as num?)?.toInt() ?? 0;
    final workoutType = json['workout_type'] as String? ?? 'strength';
    final machine = json['machine'] as String? ?? '';
    final completedAtEpoch = (json['completed_at'] as num?)?.toInt() ?? 0;

    final volumeKgTotal = (weightKg * reps).toDouble();

    String title = workoutType[0].toUpperCase() + workoutType.substring(1);
    if (machine.isNotEmpty) title = '$title - $machine';

    return Workout(
      id: (json['id'] as num?)?.toString() ?? '0',
      title: title,
      completedAt: completedAtEpoch > 0
          ? DateTime.fromMillisecondsSinceEpoch(completedAtEpoch * 1000)
          : DateTime.now(),
      durationMinutes: (durationSec / 60).round(),
      volumeKg: volumeKgTotal,
      exerciseCount: 1,
      notes: '$reps reps, $sets sets @ ${weightKg}kg',
      exerciseNames: [title],
      intensityLabel: null,
      machine: machine,
      reps: reps,
      sets: sets,
    );
  }
}
