import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymgen_ai/models/progress_models.dart';
import 'package:gymgen_ai/services/local_storage_service.dart';

class ProgressProvider extends ChangeNotifier {
  List<ProgressEntry> _entries = [];
  bool _loading = false;
  String? _error;
  String _uid = '';
  StreamSubscription<List<Map<String, dynamic>>>? _entriesSubscription;

  List<ProgressEntry> get entries => _entries;
  bool get loading => _loading;
  String? get error => _error;

  List<ProgressEntry> get weeklyEntries {
    final sorted = [..._entries]
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
  }

  ProgressEntry? get latestEntry =>
      _entries.isEmpty ? null : _entries.first;

  double? get weeklyWeightChange {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final recent = _entries.where((entry) => !entry.date.isBefore(start)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (recent.length < 2) return null;
    return recent.last.weightKg - recent.first.weightKg;
  }

  Future<void> load(String uid) async {
    await _entriesSubscription?.cancel();
    if (_uid != uid) {
      _entries = [];
    }
    _uid = uid;
    _error = null;
    _loading = true;
    notifyListeners();

    try {
      final data =
          await LocalStorageService.instance.loadProgressEntries(uid);
      _entries = data.map((d) => ProgressEntry.fromJson(d)).toList();
      _entries.sort((a, b) => b.date.compareTo(a.date));
      _entriesSubscription = LocalStorageService.instance
          .watchListData(uid, 'progress')
          .listen((items) {
        _entries = items.map(ProgressEntry.fromJson).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
      }, onError: (Object error) {
        _error = 'Progress sync failed: $error';
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> addEntry(double weightKg, {String? notes}) async {
    final entry = ProgressEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      weightKg: weightKg,
      date: DateTime.now(),
      notes: notes,
    );

    _entries.insert(0, entry);
    notifyListeners();
    try {
      await _save();
      _error = null;
    } catch (e) {
      _error = 'Saved on this device; cloud sync failed: $e';
    }
    notifyListeners();
  }

  Future<void> removeEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    try {
      await _save();
      _error = null;
    } catch (e) {
      _error = 'Removed on this device; cloud sync failed: $e';
    }
    notifyListeners();
  }

  Future<void> _save() async {
    await LocalStorageService.instance.saveProgressEntries(
      _uid,
      _entries.map((e) => e.toJson()).toList(),
    );
  }

  @override
  void dispose() {
    _entriesSubscription?.cancel();
    super.dispose();
  }
}