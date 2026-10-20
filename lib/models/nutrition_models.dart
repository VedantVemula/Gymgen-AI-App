class NutritionEntry {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String mealType;
  final DateTime time;

  const NutritionEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealType,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'mealType': mealType,
        'time': time.toIso8601String(),
      };

  factory NutritionEntry.fromJson(Map<String, dynamic> json) => NutritionEntry(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
        mealType: json['mealType'] as String? ?? 'Snack',
        time: json['time'] != null
            ? DateTime.tryParse(json['time'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class DailyNutrition {
  final List<NutritionEntry> entries;
  final int targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final double waterLitres;
  final double targetWaterLitres;

  DailyNutrition({
    required this.entries,
    this.targetCalories = 0,
    this.targetProtein = 0,
    this.targetCarbs = 0,
    this.targetFat = 0,
    this.waterLitres = 0,
    this.targetWaterLitres = 0,
  });

  int get totalCalories => entries.fold(0, (sum, e) => sum + e.calories);
  double get totalProtein => entries.fold(0.0, (sum, e) => sum + e.protein);
  double get totalCarbs => entries.fold(0.0, (sum, e) => sum + e.carbs);
  double get totalFat => entries.fold(0.0, (sum, e) => sum + e.fat);

  int get remainingCalories =>
      (targetCalories - totalCalories).clamp(0, targetCalories).toInt();

  double get calorieProgress => targetCalories > 0
      ? (totalCalories / targetCalories).clamp(0.0, 1.0).toDouble()
      : 0;

  double get proteinProgress => targetProtein > 0
      ? (totalProtein / targetProtein).clamp(0.0, 1.0).toDouble()
      : 0;

  double get carbsProgress => targetCarbs > 0
      ? (totalCarbs / targetCarbs).clamp(0.0, 1.0).toDouble()
      : 0;

  double get fatProgress =>
      targetFat > 0 ? (totalFat / targetFat).clamp(0.0, 1.0).toDouble() : 0;

  double get waterProgress => targetWaterLitres > 0
      ? (waterLitres / targetWaterLitres).clamp(0.0, 1.0).toDouble()
      : 0;
}