import 'dart:convert' as dart_convert;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'database_helper.dart';

class WorkoutProvider with ChangeNotifier {
  List<RoutineModel> _routines = [];
  List<WorkoutModel> _workouts = [];
  String? _activeDraftRoutineId; // routineId of any in-progress session

  List<RoutineModel> get routines => _routines;
  List<WorkoutModel> get workouts => _workouts;
  String? get activeDraftRoutineId => _activeDraftRoutineId;

  WorkoutProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _routines = await DatabaseHelper.instance.getRoutines();
    _workouts = await DatabaseHelper.instance.getWorkouts();
    await _refreshDraftId();
    notifyListeners();
  }

  /// Re-read the draft key and update the cached routineId.
  Future<void> refreshDraft() async {
    await _refreshDraftId();
    notifyListeners();
  }

  Future<void> _refreshDraftId() async {
    final json = await DatabaseHelper.instance.getUserSetting('active_workout_draft');
    if (json == null || json.isEmpty) {
      _activeDraftRoutineId = null;
      return;
    }
    try {
      final Map<String, dynamic> draft =
          dart_convert.jsonDecode(json) as Map<String, dynamic>;
      _activeDraftRoutineId = draft['routineId'] as String?;
    } catch (_) {
      _activeDraftRoutineId = null;
    }
  }

  Future<void> saveWorkout(WorkoutModel workout) async {
    await DatabaseHelper.instance.saveWorkout(workout);
    _workouts.insert(0, workout);
    _activeDraftRoutineId = null;
    notifyListeners();
  }

  Future<void> deleteWorkout(String workoutId) async {
    await DatabaseHelper.instance.deleteWorkout(workoutId);
    _workouts.removeWhere((w) => w.id == workoutId);
    notifyListeners();
  }

  Future<void> updateRoutine(RoutineModel routine) async {
    await DatabaseHelper.instance.updateRoutine(routine);
    final index = _routines.indexWhere((r) => r.id == routine.id);
    if (index != -1) {
      _routines[index] = routine;
      notifyListeners();
    }
  }
}

class NutritionProvider with ChangeNotifier {
  NutritionDayModel? _currentDayNutrition;
  List<FoodLogModel> _currentDayLogs = [];
  List<Map<String, dynamic>> _weightLogs = [];

  int targetCalories = 1850;
  int targetProtein = 116;
  int targetCarbs = 210;
  int targetFats = 60;

  NutritionDayModel? get currentDayNutrition => _currentDayNutrition;
  List<FoodLogModel> get currentDayLogs => _currentDayLogs;
  List<Map<String, dynamic>> get weightLogs => _weightLogs;

  String _getTodayStr() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  int _parseSetting(String? value, int fallback) {
    if (value == null) return fallback;
    return int.tryParse(value) ?? fallback;
  }

  int _subtractToZero(int current, int change) {
    final next = current - change;
    return next < 0 ? 0 : next;
  }

  NutritionProvider() {
    loadTodayData();
  }

  Future<void> updateTargets(int c, int p, int carbs, int f) async {
    targetCalories = c;
    targetProtein = p;
    targetCarbs = carbs;
    targetFats = f;
    await DatabaseHelper.instance.saveUserSetting(
      'targetCalories',
      c.toString(),
    );
    await DatabaseHelper.instance.saveUserSetting(
      'targetProtein',
      p.toString(),
    );
    await DatabaseHelper.instance.saveUserSetting(
      'targetCarbs',
      carbs.toString(),
    );
    await DatabaseHelper.instance.saveUserSetting('targetFats', f.toString());
    notifyListeners();
  }

  Future<void> loadTodayData() async {
    targetCalories = _parseSetting(
      await DatabaseHelper.instance.getUserSetting('targetCalories'),
      targetCalories,
    );
    targetProtein = _parseSetting(
      await DatabaseHelper.instance.getUserSetting('targetProtein'),
      targetProtein,
    );
    targetCarbs = _parseSetting(
      await DatabaseHelper.instance.getUserSetting('targetCarbs'),
      targetCarbs,
    );
    targetFats = _parseSetting(
      await DatabaseHelper.instance.getUserSetting('targetFats'),
      targetFats,
    );

    final dateStr = _getTodayStr();
    _currentDayNutrition = await DatabaseHelper.instance.getNutritionDay(
      dateStr,
    );
    _currentDayLogs = await DatabaseHelper.instance.getFoodLogs(dateStr);
    _weightLogs = await DatabaseHelper.instance.getWeightLogs();

    if (_currentDayNutrition == null) {
      _currentDayNutrition = NutritionDayModel(
        date: dateStr,
        calories: 0,
        protein: 0,
        carbs: 0,
        fats: 0,
      );
      await DatabaseHelper.instance.saveNutritionDay(_currentDayNutrition!);
    }
    notifyListeners();
  }

  Future<void> addFoodLog(String name, int cals, int p, int c, int f) async {
    final dateStr = _getTodayStr();
    final log = FoodLogModel(
      id: const Uuid().v4(),
      date: dateStr,
      name: name,
      calories: cals,
      protein: p,
      carbs: c,
      fats: f,
    );

    await DatabaseHelper.instance.insertFoodLog(log);
    _currentDayLogs.add(log);

    if (_currentDayNutrition != null) {
      _currentDayNutrition!.calories += cals;
      _currentDayNutrition!.protein += p;
      _currentDayNutrition!.carbs += c;
      _currentDayNutrition!.fats += f;
      await DatabaseHelper.instance.saveNutritionDay(_currentDayNutrition!);
    }

    notifyListeners();
  }

  Future<void> deleteFoodLog(FoodLogModel log) async {
    await DatabaseHelper.instance.deleteFoodLog(log.id);
    _currentDayLogs.removeWhere((l) => l.id == log.id);

    if (_currentDayNutrition != null) {
      _currentDayNutrition!.calories = _subtractToZero(
        _currentDayNutrition!.calories,
        log.calories,
      );
      _currentDayNutrition!.protein = _subtractToZero(
        _currentDayNutrition!.protein,
        log.protein,
      );
      _currentDayNutrition!.carbs = _subtractToZero(
        _currentDayNutrition!.carbs,
        log.carbs,
      );
      _currentDayNutrition!.fats = _subtractToZero(
        _currentDayNutrition!.fats,
        log.fats,
      );
      await DatabaseHelper.instance.saveNutritionDay(_currentDayNutrition!);
    }

    notifyListeners();
  }

  Future<void> addWeightLog(double weight) async {
    final dateStr = _getTodayStr();
    await DatabaseHelper.instance.saveWeightLog(dateStr, weight);
    _weightLogs = await DatabaseHelper.instance.getWeightLogs();
    notifyListeners();
  }
}
