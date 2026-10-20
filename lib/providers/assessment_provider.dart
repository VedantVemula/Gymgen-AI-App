import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymgen_ai/models/assessment_model.dart';
import 'package:gymgen_ai/services/local_storage_service.dart';

class AssessmentProvider extends ChangeNotifier {
  bool loading = false;
  bool loadingHistory = false;
  String? error;
  bool success = false;
  final List<Assessment> assessments = [];
  StreamSubscription<List<Map<String, dynamic>>>? _historySubscription;
  String _uid = '';

  Future<void> submitAssessment(
    Assessment assessment,
    String uid, {
    String name = '',
    String email = '',
  }) async {
    if (_uid != uid) {
      await _historySubscription?.cancel();
      assessments.clear();
      _uid = uid;
    }
    loading = true;
    error = null;
    success = false;
    notifyListeners();

    try {
      if (assessments.isEmpty) {
        final savedHistory = await LocalStorageService.instance
            .loadAssessmentHistory(uid);
        assessments.addAll(savedHistory.map(Assessment.fromJson));
      }
      assessments.insert(0, assessment);
      await LocalStorageService.instance.saveAssessmentHistory(
        uid,
        assessments.map((entry) => entry.toJson()).toList(),
      );

      await LocalStorageService.instance.saveProfile(uid, {
        'uid': uid,
        'email': email,
        'name': name,
        'weightKg': assessment.weightKg,
        'heightCm': assessment.heightCm,
        'age': assessment.age,
        'gender': assessment.gender,
        'goal': assessment.goal,
        'experience': assessment.experience,
        'equipment': assessment.equipment,
        'workoutDays': assessment.workoutDays,
        'dietPreference': assessment.dietPreference,
        'sleepHours': assessment.sleepHours,
        'injuries': assessment.injuries,
        'createdAt': assessment.createdAt.toIso8601String(),
      });

      success = true;
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }

  Future<void> loadAssessments(String uid) async {
    await _historySubscription?.cancel();
    if (_uid != uid) assessments.clear();
    _uid = uid;
    loadingHistory = true;
    error = null;
    notifyListeners();

    try {
      final history =
          await LocalStorageService.instance.loadAssessmentHistory(uid);
      assessments
        ..clear()
        ..addAll(history.map(Assessment.fromJson));
      _historySubscription = LocalStorageService.instance
          .watchListData(uid, 'assessmentHistory')
          .listen((items) {
        assessments
          ..clear()
          ..addAll(items.map(Assessment.fromJson));
        notifyListeners();
      }, onError: (Object error) {
        this.error = 'Assessment history sync failed: $error';
        notifyListeners();
      });
    } catch (e) {
      error = e.toString();
    }

    loadingHistory = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
  }
}