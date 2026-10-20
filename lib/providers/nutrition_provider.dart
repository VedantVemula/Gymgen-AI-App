import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymgen_ai/models/nutrition_models.dart';
import 'package:gymgen_ai/models/user_profile_model.dart';
import 'package:gymgen_ai/services/local_storage_service.dart';
import 'package:intl/intl.dart';

class NutritionProvider extends ChangeNotifier {
  DailyNutrition _today = DailyNutrition(entries: []);
  bool _loading = false;
  String? _error;
  String _uid = '';
  StreamSubscription<List<Map<String, dynamic>>>? _entriesSubscription;
  StreamSubscription<Map<String, dynamic>?>? _waterSubscription;
  StreamSubscription<Map<String, dynamic>?>? _profileSubscription;

  DailyNutrition get today => _today;
  bool get loading => _loading;
  String? get error => _error;

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> load(String uid, {UserProfile? profile}) async {
    await _entriesSubscription?.cancel();
    await _waterSubscription?.cancel();
    await _profileSubscription?.cancel();
    _uid = uid;
    _loading = true;
    _error = null;
    _today = DailyNutrition(entries: []);
    if (profile != null) _applyPersonalTargets(profile);
    notifyListeners();

    try {
      final storage = LocalStorageService.instance;
      final results = await Future.wait([
        storage.loadNutritionEntries(uid, _todayKey),
        storage.loadWater(uid, _todayKey),
      ]);
      _today = DailyNutrition(
        entries: (results[0] as List<Map<String, dynamic>>)
            .map(NutritionEntry.fromJson)
            .toList(),
        targetCalories: _today.targetCalories,
        targetProtein: _today.targetProtein,
        targetCarbs: _today.targetCarbs,
        targetFat: _today.targetFat,
        waterLitres: results[1] as double,
        targetWaterLitres: _today.targetWaterLitres,
      );

      _entriesSubscription = storage
          .watchListData(uid, 'nutrition_$_todayKey')
          .listen((data) {
        _today = _copyToday(entries: data.map(NutritionEntry.fromJson).toList());
        notifyListeners();
      }, onError: (Object error) {
        _error = 'Nutrition sync failed: $error';
        notifyListeners();
      });

      _waterSubscription = storage
          .watchMapData(uid, 'water_$_todayKey')
          .listen((data) {
        _today = _copyToday(
          waterLitres: (data?['litres'] as num?)?.toDouble() ?? 0,
        );
        notifyListeners();
      }, onError: (Object error) {
        _error = 'Water intake sync failed: $error';
        notifyListeners();
      });

      _profileSubscription = storage.watchProfile(uid).listen((data) {
        if (data == null) {
          _today = DailyNutrition(
            entries: _today.entries,
            waterLitres: _today.waterLitres,
          );
        } else {
          _applyPersonalTargets(UserProfile.fromJson(data));
        }
        notifyListeners();
      }, onError: (Object error) {
        _error = 'Nutrition target sync failed: $error';
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  void _applyPersonalTargets(UserProfile profile) {
    final weight = profile.weightKg;
    if (weight <= 0 || profile.heightCm <= 0 || profile.age <= 0) {
      _today = DailyNutrition(
        entries: _today.entries,
        waterLitres: _today.waterLitres,
      );
      return;
    }

    final sexAdjustment = switch (profile.gender.toLowerCase()) {
      'male' => 5.0,
      'female' => -161.0,
      _ => -78.0,
    };
    final bmr =
        10 * weight + 6.25 * profile.heightCm - 5 * profile.age + sexAdjustment;
    final activityFactor = 1.2 + (profile.workoutDays.clamp(0, 6) * 0.035);
    var calories = bmr * activityFactor;
    if (profile.goal.toLowerCase().contains('lose')) calories -= 300;
    if (profile.goal.toLowerCase().contains('muscle') ||
        profile.goal.toLowerCase().contains('strength')) {
      calories += 200;
    }
    final targetCalories = calories.round().clamp(1200, 6000).toInt();
    final proteinFactor = profile.goal.toLowerCase().contains('muscle') ||
            profile.goal.toLowerCase().contains('strength')
        ? 1.8
        : 1.6;
    final protein = weight * proteinFactor;
    final fat = weight * 0.8;
    final carbs = ((targetCalories - protein * 4 - fat * 9) / 4)
        .clamp(0.0, 1000.0)
        .toDouble();

    _today = DailyNutrition(
      entries: _today.entries,
      targetCalories: targetCalories,
      targetProtein: protein,
      targetCarbs: carbs,
      targetFat: fat,
      waterLitres: _today.waterLitres,
      targetWaterLitres: weight * 0.035,
    );
  }

  DailyNutrition _copyToday({
    List<NutritionEntry>? entries,
    double? waterLitres,
  }) =>
      DailyNutrition(
        entries: entries ?? _today.entries,
        targetCalories: _today.targetCalories,
        targetProtein: _today.targetProtein,
        targetCarbs: _today.targetCarbs,
        targetFat: _today.targetFat,
        waterLitres: waterLitres ?? _today.waterLitres,
        targetWaterLitres: _today.targetWaterLitres,
      );

  Future<void> addEntry(NutritionEntry entry) async {
    final entries = [..._today.entries, entry];
    _today = _copyToday(entries: entries);
    notifyListeners();
    try {
      await _saveEntries();
      _error = null;
    } catch (e) {
      _error = 'Saved on this device; cloud sync failed: $e';
    }
    notifyListeners();
  }

  Future<void> removeEntry(String id) async {
    final entries = _today.entries.where((e) => e.id != id).toList();
    _today = _copyToday(entries: entries);
    notifyListeners();
    try {
      await _saveEntries();
      _error = null;
    } catch (e) {
      _error = 'Updated on this device; cloud sync failed: $e';
    }
    notifyListeners();
  }

  Future<void> addWater(double litres) async {
    final newWater = _today.waterLitres + litres;
    _today = _copyToday(waterLitres: newWater);
    notifyListeners();
    try {
      await LocalStorageService.instance.saveWater(_uid, _todayKey, newWater);
      _error = null;
    } catch (e) {
      _error = 'Saved on this device; cloud sync failed: $e';
    }
    notifyListeners();
  }

  Future<void> _saveEntries() async {
    await LocalStorageService.instance.saveNutritionEntries(
      _uid,
      _todayKey,
      _today.entries.map((entry) => entry.toJson()).toList(),
    );
  }

  @override
  void dispose() {
    _entriesSubscription?.cancel();
    _waterSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}