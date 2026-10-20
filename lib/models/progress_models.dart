class ProgressEntry {
  final String id;
  final double weightKg;
  final DateTime date;
  final String? notes;

  const ProgressEntry({
    required this.id,
    required this.weightKg,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'weightKg': weightKg,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory ProgressEntry.fromJson(Map<String, dynamic> json) => ProgressEntry(
        id: json['id'] as String? ?? '',
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
        date: json['date'] != null
            ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        notes: json['notes'] as String?,
      );
}

class UserStats {
  final int totalWorkouts;
  final int streakDays;
  final double currentWeightKg;
  final double weeklyWeightChange;
  final int totalCaloriesBurned;

  const UserStats({
    this.totalWorkouts = 0,
    this.streakDays = 0,
    this.currentWeightKg = 0,
    this.weeklyWeightChange = 0,
    this.totalCaloriesBurned = 0,
  });

  Map<String, dynamic> toJson() => {
        'totalWorkouts': totalWorkouts,
        'streakDays': streakDays,
        'currentWeightKg': currentWeightKg,
        'weeklyWeightChange': weeklyWeightChange,
        'totalCaloriesBurned': totalCaloriesBurned,
      };

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        totalWorkouts: (json['totalWorkouts'] as num?)?.toInt() ?? 0,
        streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
        currentWeightKg: (json['currentWeightKg'] as num?)?.toDouble() ?? 0,
        weeklyWeightChange:
            (json['weeklyWeightChange'] as num?)?.toDouble() ?? 0,
        totalCaloriesBurned:
            (json['totalCaloriesBurned'] as num?)?.toInt() ?? 0,
      );
}