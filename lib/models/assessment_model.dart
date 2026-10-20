class Assessment {
  final int age;
  final double heightCm;
  final double weightKg;
  final String gender;
  final String goal;
  final String experience;
  final String equipment;
  final int workoutDays;
  final String dietPreference;
  final int sleepHours;
  final String injuries;
  final DateTime createdAt;

  Assessment({
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.gender,
    required this.goal,
    required this.experience,
    required this.equipment,
    required this.workoutDays,
    required this.dietPreference,
    required this.sleepHours,
    required this.injuries,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'gender': gender,
      'goal': goal,
      'experience': experience,
      'equipment': equipment,
      'workoutDays': workoutDays,
      'dietPreference': dietPreference,
      'sleepHours': sleepHours,
      'injuries': injuries,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      age: (json['age'] as num).toInt(),
      heightCm: (json['heightCm'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      gender: json['gender'] as String,
      goal: json['goal'] as String,
      experience: json['experience'] as String,
      equipment: json['equipment'] as String,
      workoutDays: (json['workoutDays'] as num).toInt(),
      dietPreference: json['dietPreference'] as String,
      sleepHours: (json['sleepHours'] as num).toInt(),
      injuries: json['injuries'] as String,
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt'] as DateTime
          : DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
