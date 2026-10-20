class Exercise {
  final String id;
  final String name;
  final int sets;
  final String reps;
  final String rest;
  final String targetMuscle;
  final String? description;

  const Exercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.targetMuscle,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sets': sets,
        'reps': reps,
        'rest': rest,
        'targetMuscle': targetMuscle,
        'description': description,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        sets: (json['sets'] as num?)?.toInt() ?? 3,
        reps: json['reps'] as String? ?? '10 Reps',
        rest: json['rest'] as String? ?? '60 sec',
        targetMuscle: json['targetMuscle'] as String? ?? '',
        description: json['description'] as String?,
      );
}

class WorkoutDay {
  final String dayLabel;
  final String focus;
  final List<Exercise> exercises;
  final int durationMinutes;

  const WorkoutDay({
    required this.dayLabel,
    required this.focus,
    required this.exercises,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
        'dayLabel': dayLabel,
        'focus': focus,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'durationMinutes': durationMinutes,
      };

  factory WorkoutDay.fromJson(Map<String, dynamic> json) => WorkoutDay(
        dayLabel: json['dayLabel'] as String? ?? '',
        focus: json['focus'] as String? ?? '',
        exercises: (json['exercises'] as List<dynamic>? ?? [])
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 45,
      );
}

class WorkoutPlan {
  final String id;
  final String name;
  final String goal;
  final List<WorkoutDay> days;
  final DateTime createdAt;

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.goal,
    required this.days,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'goal': goal,
        'days': days.map((d) => d.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        goal: json['goal'] as String? ?? '',
        days: (json['days'] as List<dynamic>? ?? [])
            .map((d) => WorkoutDay.fromJson(d as Map<String, dynamic>))
            .toList(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class WorkoutLog {
  final String id;
  final String workoutName;
  final int durationMinutes;
  final int caloriesBurned;
  final int exercisesCompleted;
  final int exercisesPlanned;
  final DateTime date;

  const WorkoutLog({
    required this.id,
    required this.workoutName,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.exercisesCompleted,
    this.exercisesPlanned = 0,
    required this.date,
  });

  bool get isComplete =>
      exercisesPlanned > 0 && exercisesCompleted >= exercisesPlanned;

  Map<String, dynamic> toJson() => {
        'id': id,
        'workoutName': workoutName,
        'durationMinutes': durationMinutes,
        'caloriesBurned': caloriesBurned,
        'exercisesCompleted': exercisesCompleted,
        'exercisesPlanned': exercisesPlanned,
        'date': date.toIso8601String(),
      };

  factory WorkoutLog.fromJson(Map<String, dynamic> json) => WorkoutLog(
        id: json['id'] as String? ?? '',
        workoutName: json['workoutName'] as String? ?? '',
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
        caloriesBurned: (json['caloriesBurned'] as num?)?.toInt() ?? 0,
        exercisesCompleted: (json['exercisesCompleted'] as num?)?.toInt() ?? 0,
        exercisesPlanned: (json['exercisesPlanned'] as num?)?.toInt() ??
            (json['exercisesCompleted'] as num?)?.toInt() ??
            0,
        date: json['date'] != null
            ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}