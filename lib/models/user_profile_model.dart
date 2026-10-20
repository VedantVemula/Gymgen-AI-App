class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? avatarPath;
  final double weightKg;
  final double heightCm;
  final int age;
  final String gender;
  final String goal;
  final String experience;
  final String equipment;
  final int workoutDays;
  final String dietPreference;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarPath,
    this.weightKg = 0,
    this.heightCm = 0,
    this.age = 0,
    this.gender = '',
    this.goal = '',
    this.experience = '',
    this.equipment = '',
    this.workoutDays = 0,
    this.dietPreference = '',
    required this.createdAt,
  });

  UserProfile copyWith({
    String? name,
    String? avatarPath,
    double? weightKg,
    double? heightCm,
    int? age,
    String? gender,
    String? goal,
    String? experience,
    String? equipment,
    int? workoutDays,
    String? dietPreference,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email,
      avatarPath: avatarPath ?? this.avatarPath,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      equipment: equipment ?? this.equipment,
      workoutDays: workoutDays ?? this.workoutDays,
      dietPreference: dietPreference ?? this.dietPreference,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'avatarPath': avatarPath,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'age': age,
        'gender': gender,
        'goal': goal,
        'experience': experience,
        'equipment': equipment,
        'workoutDays': workoutDays,
        'dietPreference': dietPreference,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'] as String? ?? '',
        name: json['name'] as String? ?? 'Athlete',
        email: json['email'] as String? ?? '',
        avatarPath: json['avatarPath'] as String?,
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
        heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
        age: (json['age'] as num?)?.toInt() ?? 0,
        gender: json['gender'] as String? ?? '',
        goal: json['goal'] as String? ?? '',
        experience: json['experience'] as String? ?? '',
        equipment: json['equipment'] as String? ?? '',
        workoutDays: (json['workoutDays'] as num?)?.toInt() ?? 0,
        dietPreference: json['dietPreference'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}