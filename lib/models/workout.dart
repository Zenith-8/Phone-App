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

  double get volumeTonnes => volumeKg / 1000;
}
