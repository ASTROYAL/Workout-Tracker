import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'database_helper.dart';

class WorkoutProvider with ChangeNotifier {
  List<RoutineModel> _routines = [];
  List<WorkoutModel> _workouts = [];

  List<RoutineModel> get routines => _routines;
  List<WorkoutModel> get workouts => _workouts;

  WorkoutProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _routines = await DatabaseHelper.instance.getRoutines();
    _workouts = await DatabaseHelper.instance.getWorkouts();
    notifyListeners();
  }

  Future<void> saveWorkout(WorkoutModel workout) async {
    await DatabaseHelper.instance.saveWorkout(workout);
    _workouts.insert(0, workout);
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

  final int targetCalories = 1850;
  final int targetProtein = 116;
  final int targetCarbs = 210;
  final int targetFats = 60;

  NutritionDayModel? get currentDayNutrition => _currentDayNutrition;
  List<FoodLogModel> get currentDayLogs => _currentDayLogs;

  String _getTodayStr() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  NutritionProvider() {
    loadTodayData();
  }

  Future<void> loadTodayData() async {
    final dateStr = _getTodayStr();
    _currentDayNutrition = await DatabaseHelper.instance.getNutritionDay(dateStr);
    _currentDayLogs = await DatabaseHelper.instance.getFoodLogs(dateStr);

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
      _currentDayNutrition!.calories -= log.calories;
      _currentDayNutrition!.protein -= log.protein;
      _currentDayNutrition!.carbs -= log.carbs;
      _currentDayNutrition!.fats -= log.fats;
      await DatabaseHelper.instance.saveNutritionDay(_currentDayNutrition!);
    }

    notifyListeners();
  }
}
