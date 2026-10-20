import 'dart:math';

import 'package:gymgen_ai/models/workout_models.dart';
import 'package:gymgen_ai/models/assessment_model.dart';

class WorkoutGeneratorService {
  WorkoutGeneratorService._();
  static final WorkoutGeneratorService instance = WorkoutGeneratorService._();

  WorkoutPlan generatePlan(Assessment assessment) {
    final days = <WorkoutDay>[];
    final splits = _getSplits(assessment.goal, assessment.workoutDays);

    for (int i = 0; i < assessment.workoutDays; i++) {
      final split = splits[i % splits.length];
      days.add(WorkoutDay(
        dayLabel: _dayLabel(i, assessment.workoutDays),
        focus: split,
        exercises: _getExercises(
          split,
          assessment.experience,
          assessment.equipment,
        ),
        durationMinutes: _getDuration(assessment.experience),
      ));
    }

    return WorkoutPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${assessment.goal} Plan',
      goal: assessment.goal,
      days: days,
      createdAt: DateTime.now(),
    );
  }

  String _dayLabel(int index, int workoutDays) {
    const labels = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final safeWorkoutDays = workoutDays.clamp(1, labels.length);
    final weekdayIndex =
        (index * labels.length ~/ safeWorkoutDays) % labels.length;
    return labels[weekdayIndex];
  }

  int _getDuration(String experience) {
    switch (experience) {
      case 'Beginner':
        return 30;
      case 'Intermediate':
        return 45;
      case 'Advanced':
        return 60;
      default:
        return 45;
    }
  }

  List<String> _getSplits(String goal, int days) {
    if (goal == 'Build muscle' || goal == 'Improve strength') {
      if (days <= 3) return ['Full Body', 'Full Body', 'Full Body'];
      if (days == 4) return ['Upper Body', 'Lower Body', 'Push', 'Pull & Legs'];
      return ['Push', 'Pull', 'Legs', 'Upper Body', 'Lower Body', 'Full Body'];
    } else if (goal == 'Lose fat' || goal == 'Improve endurance') {
      return [
        'Full Body HIIT',
        'Cardio + Core',
        'Upper Body',
        'Lower Body',
        'HIIT',
        'Active Recovery',
      ];
    } else {
      return [
        'Full Body',
        'Upper Body',
        'Lower Body',
        'Core & Cardio',
        'Full Body',
        'Active Recovery',
      ];
    }
  }

  List<Exercise> _getExercises(
    String split,
    String experience,
    String equipment,
  ) {
    final useGym = equipment == 'Gym access';
    final bodyweightOnly = equipment == 'Bodyweight only' ||
        equipment == 'No equipment' ||
        equipment.isEmpty;

    final Map<String, List<Exercise>> exercises = {
      'Upper Body': [
        Exercise(
          id: _id(),
          name: 'Push Ups',
          sets: 3,
          reps: '12 Reps',
          rest: '60 sec',
          targetMuscle: 'Chest',
          description: 'Classic chest exercise.',
        ),
        Exercise(
          id: _id(),
          name: useGym ? 'Bench Press' : 'Dumbbell Press',
          sets: 4,
          reps: '10 Reps',
          rest: '90 sec',
          targetMuscle: 'Chest & Triceps',
        ),
        Exercise(
          id: _id(),
          name: useGym ? 'Lat Pulldown' : 'Resistance Band Row',
          sets: 3,
          reps: '12 Reps',
          rest: '60 sec',
          targetMuscle: 'Back',
        ),
        Exercise(
          id: _id(),
          name: 'Shoulder Press',
          sets: 3,
          reps: '10 Reps',
          rest: '60 sec',
          targetMuscle: 'Shoulders',
        ),
        Exercise(
          id: _id(),
          name: 'Tricep Dips',
          sets: 3,
          reps: '15 Reps',
          rest: '45 sec',
          targetMuscle: 'Triceps',
        ),
        Exercise(
          id: _id(),
          name: 'Bicep Curls',
          sets: 3,
          reps: '12 Reps',
          rest: '45 sec',
          targetMuscle: 'Biceps',
        ),
      ],
      'Lower Body': [
        Exercise(
          id: _id(),
          name: 'Squats',
          sets: 4,
          reps: '15 Reps',
          rest: '90 sec',
          targetMuscle: 'Quads & Glutes',
          description: 'Keep back straight.',
        ),
        Exercise(
          id: _id(),
          name: 'Lunges',
          sets: 3,
          reps: '12 Reps each',
          rest: '60 sec',
          targetMuscle: 'Quads',
        ),
        Exercise(
          id: _id(),
          name: useGym ? 'Leg Press' : 'Bulgarian Split Squat',
          sets: 3,
          reps: '12 Reps',
          rest: '90 sec',
          targetMuscle: 'Quads & Glutes',
        ),
        Exercise(
          id: _id(),
          name: 'Glute Bridge',
          sets: 3,
          reps: '15 Reps',
          rest: '60 sec',
          targetMuscle: 'Glutes',
        ),
        Exercise(
          id: _id(),
          name: 'Calf Raises',
          sets: 4,
          reps: '20 Reps',
          rest: '45 sec',
          targetMuscle: 'Calves',
        ),
      ],
      'Full Body': [
        Exercise(
          id: _id(),
          name: 'Burpees',
          sets: 3,
          reps: '10 Reps',
          rest: '60 sec',
          targetMuscle: 'Full Body',
        ),
        Exercise(
          id: _id(),
          name: 'Squats',
          sets: 3,
          reps: '15 Reps',
          rest: '60 sec',
          targetMuscle: 'Legs',
        ),
        Exercise(
          id: _id(),
          name: 'Push Ups',
          sets: 3,
          reps: '12 Reps',
          rest: '60 sec',
          targetMuscle: 'Chest',
        ),
        Exercise(
          id: _id(),
          name: 'Plank',
          sets: 3,
          reps: '45 sec',
          rest: '45 sec',
          targetMuscle: 'Core',
        ),
        Exercise(
          id: _id(),
          name: 'Mountain Climbers',
          sets: 3,
          reps: '30 sec',
          rest: '30 sec',
          targetMuscle: 'Core & Cardio',
        ),
      ],
      'Push': [
        Exercise(
          id: _id(),
          name: useGym ? 'Bench Press' : 'Push Ups',
          sets: 4,
          reps: '10 Reps',
          rest: '90 sec',
          targetMuscle: 'Chest',
        ),
        Exercise(
          id: _id(),
          name: 'Overhead Press',
          sets: 3,
          reps: '10 Reps',
          rest: '90 sec',
          targetMuscle: 'Shoulders',
        ),
        Exercise(
          id: _id(),
          name: 'Incline Push Ups',
          sets: 3,
          reps: '12 Reps',
          rest: '60 sec',
          targetMuscle: 'Upper Chest',
        ),
        Exercise(
          id: _id(),
          name: 'Lateral Raises',
          sets: 3,
          reps: '15 Reps',
          rest: '45 sec',
          targetMuscle: 'Side Delts',
        ),
        Exercise(
          id: _id(),
          name: 'Tricep Pushdown',
          sets: 3,
          reps: '15 Reps',
          rest: '45 sec',
          targetMuscle: 'Triceps',
        ),
      ],
      'Pull': [
        Exercise(
          id: _id(),
          name: useGym ? 'Deadlift' : 'Good Mornings',
          sets: 4,
          reps: '8 Reps',
          rest: '120 sec',
          targetMuscle: 'Back & Hamstrings',
        ),
        Exercise(
          id: _id(),
          name: useGym ? 'Barbell Row' : 'Dumbbell Row',
          sets: 3,
          reps: '10 Reps',
          rest: '90 sec',
          targetMuscle: 'Back',
        ),
        Exercise(
          id: _id(),
          name: 'Pull Ups',
          sets: 3,
          reps: '8 Reps',
          rest: '90 sec',
          targetMuscle: 'Back & Biceps',
        ),
        Exercise(
          id: _id(),
          name: 'Face Pulls',
          sets: 3,
          reps: '15 Reps',
          rest: '45 sec',
          targetMuscle: 'Rear Delts',
        ),
        Exercise(
          id: _id(),
          name: 'Hammer Curls',
          sets: 3,
          reps: '12 Reps',
          rest: '45 sec',
          targetMuscle: 'Biceps',
        ),
      ],
      'Legs': [
        Exercise(
          id: _id(),
          name: useGym ? 'Barbell Squats' : 'Goblet Squats',
          sets: 4,
          reps: '12 Reps',
          rest: '120 sec',
          targetMuscle: 'Quads',
        ),
        Exercise(
          id: _id(),
          name: useGym ? 'Leg Press' : 'Split Squats',
          sets: 3,
          reps: '12 Reps',
          rest: '90 sec',
          targetMuscle: 'Quads',
        ),
        Exercise(
          id: _id(),
          name: 'Romanian Deadlift',
          sets: 3,
          reps: '10 Reps',
          rest: '90 sec',
          targetMuscle: 'Hamstrings',
        ),
        Exercise(
          id: _id(),
          name: 'Hip Thrusts',
          sets: 3,
          reps: '15 Reps',
          rest: '60 sec',
          targetMuscle: 'Glutes',
        ),
        Exercise(
          id: _id(),
          name: 'Calf Raises',
          sets: 4,
          reps: '20 Reps',
          rest: '30 sec',
          targetMuscle: 'Calves',
        ),
      ],
      'Full Body HIIT': [
        Exercise(
          id: _id(),
          name: 'Jumping Jacks',
          sets: 3,
          reps: '45 sec',
          rest: '15 sec',
          targetMuscle: 'Full Body',
        ),
        Exercise(
          id: _id(),
          name: 'Burpees',
          sets: 3,
          reps: '30 sec',
          rest: '30 sec',
          targetMuscle: 'Full Body',
        ),
        Exercise(
          id: _id(),
          name: 'High Knees',
          sets: 3,
          reps: '45 sec',
          rest: '15 sec',
          targetMuscle: 'Cardio',
        ),
        Exercise(
          id: _id(),
          name: 'Push Ups',
          sets: 3,
          reps: '12 Reps',
          rest: '30 sec',
          targetMuscle: 'Chest',
        ),
        Exercise(
          id: _id(),
          name: 'Jump Squats',
          sets: 3,
          reps: '15 Reps',
          rest: '30 sec',
          targetMuscle: 'Legs',
        ),
        Exercise(
          id: _id(),
          name: 'Plank',
          sets: 3,
          reps: '45 sec',
          rest: '30 sec',
          targetMuscle: 'Core',
        ),
      ],
      'Cardio + Core': [
        Exercise(
          id: _id(),
          name: 'Running in Place',
          sets: 1,
          reps: '5 min',
          rest: '0 sec',
          targetMuscle: 'Cardio',
        ),
        Exercise(
          id: _id(),
          name: 'Plank',
          sets: 3,
          reps: '60 sec',
          rest: '30 sec',
          targetMuscle: 'Core',
        ),
        Exercise(
          id: _id(),
          name: 'Crunches',
          sets: 3,
          reps: '20 Reps',
          rest: '30 sec',
          targetMuscle: 'Abs',
        ),
        Exercise(
          id: _id(),
          name: 'Bicycle Crunches',
          sets: 3,
          reps: '20 Reps',
          rest: '30 sec',
          targetMuscle: 'Obliques',
        ),
        Exercise(
          id: _id(),
          name: 'Leg Raises',
          sets: 3,
          reps: '15 Reps',
          rest: '30 sec',
          targetMuscle: 'Lower Abs',
        ),
      ],
      'Core & Cardio': [
        Exercise(
          id: _id(),
          name: 'Plank',
          sets: 3,
          reps: '60 sec',
          rest: '30 sec',
          targetMuscle: 'Core',
        ),
        Exercise(
          id: _id(),
          name: 'Russian Twists',
          sets: 3,
          reps: '20 Reps',
          rest: '30 sec',
          targetMuscle: 'Obliques',
        ),
        Exercise(
          id: _id(),
          name: 'Flutter Kicks',
          sets: 3,
          reps: '45 sec',
          rest: '30 sec',
          targetMuscle: 'Lower Abs',
        ),
        Exercise(
          id: _id(),
          name: 'Jumping Jacks',
          sets: 3,
          reps: '45 sec',
          rest: '15 sec',
          targetMuscle: 'Cardio',
        ),
        Exercise(
          id: _id(),
          name: 'Mountain Climbers',
          sets: 3,
          reps: '30 sec',
          rest: '30 sec',
          targetMuscle: 'Core',
        ),
      ],
      'Active Recovery': [
        Exercise(
          id: _id(),
          name: 'Light Walking',
          sets: 1,
          reps: '10 min',
          rest: '0 sec',
          targetMuscle: 'Full Body',
        ),
        Exercise(
          id: _id(),
          name: 'Cat-Cow Stretch',
          sets: 2,
          reps: '10 Reps',
          rest: '30 sec',
          targetMuscle: 'Spine',
        ),
        Exercise(
          id: _id(),
          name: 'Hip Flexor Stretch',
          sets: 2,
          reps: '30 sec',
          rest: '15 sec',
          targetMuscle: 'Hips',
        ),
        Exercise(
          id: _id(),
          name: 'Hamstring Stretch',
          sets: 2,
          reps: '30 sec',
          rest: '15 sec',
          targetMuscle: 'Hamstrings',
        ),
        Exercise(
          id: _id(),
          name: 'Chest Opener',
          sets: 2,
          reps: '30 sec',
          rest: '15 sec',
          targetMuscle: 'Chest',
        ),
      ],
      'Pull & Legs': [
        Exercise(
          id: _id(),
          name: useGym ? 'Deadlift' : 'Good Mornings',
          sets: 3,
          reps: '8 Reps',
          rest: '120 sec',
          targetMuscle: 'Back',
        ),
        Exercise(
          id: _id(),
          name: 'Pull Ups',
          sets: 3,
          reps: '8 Reps',
          rest: '90 sec',
          targetMuscle: 'Back',
        ),
        Exercise(
          id: _id(),
          name: 'Squats',
          sets: 4,
          reps: '12 Reps',
          rest: '90 sec',
          targetMuscle: 'Legs',
        ),
        Exercise(
          id: _id(),
          name: 'Bicep Curls',
          sets: 3,
          reps: '12 Reps',
          rest: '45 sec',
          targetMuscle: 'Biceps',
        ),
        Exercise(
          id: _id(),
          name: 'Calf Raises',
          sets: 3,
          reps: '20 Reps',
          rest: '30 sec',
          targetMuscle: 'Calves',
        ),
      ],
      'HIIT': [
        Exercise(
          id: _id(),
          name: 'Sprint Intervals',
          sets: 8,
          reps: '30 sec',
          rest: '30 sec',
          targetMuscle: 'Cardio',
        ),
        Exercise(
          id: _id(),
          name: 'Burpees',
          sets: 3,
          reps: '10 Reps',
          rest: '30 sec',
          targetMuscle: 'Full Body',
        ),
        Exercise(
          id: _id(),
          name: 'Jump Squats',
          sets: 4,
          reps: '15 Reps',
          rest: '30 sec',
          targetMuscle: 'Legs',
        ),
        Exercise(
          id: _id(),
          name: 'Push Ups',
          sets: 3,
          reps: '15 Reps',
          rest: '30 sec',
          targetMuscle: 'Chest',
        ),
      ],
    };

    final selected = exercises[split] ?? exercises['Full Body']!;
    return selected.map((exercise) {
      var name = exercise.name;
      if (bodyweightOnly) {
        name = switch (name) {
          'Dumbbell Press' || 'Bench Press' => 'Push Ups',
          'Resistance Band Row' || 'Dumbbell Row' || 'Barbell Row' =>
            'Prone Y-T-W Raises',
          'Shoulder Press' || 'Overhead Press' => 'Pike Push Ups',
          'Bicep Curls' || 'Hammer Curls' => 'Self-Resisted Curls',
          'Tricep Pushdown' => 'Close-Grip Push Ups',
          'Lateral Raises' => 'Arm Circles',
          'Lat Pulldown' || 'Pull Ups' => 'Superman Pulls',
          'Deadlift' || 'Romanian Deadlift' => 'Bodyweight Hip Hinge',
          'Leg Press' || 'Barbell Squats' || 'Goblet Squats' =>
            'Bodyweight Squats',
          _ => name,
        };
      }

      final sets = experience == 'Beginner'
          ? exercise.sets.clamp(1, 3).toInt()
          : exercise.sets;

      return Exercise(
        id: exercise.id,
        name: name,
        sets: sets,
        reps: exercise.reps,
        rest: exercise.rest,
        targetMuscle: exercise.targetMuscle,
        description: exercise.description,
      );
    }).toList();
  }

  String _id() => Random().nextInt(999999).toString();
}