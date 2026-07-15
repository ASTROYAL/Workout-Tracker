import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';
import 'seed_data.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('workout_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const numType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE routines (
  id $idType,
  name $textType,
  type $textType,
  day $textType,
  subtitle $textType,
  exercises TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE workouts (
  id $idType,
  date $textType,
  routineId TEXT NOT NULL,
  durationSeconds $intType,
  volume $numType
)
''');

    await db.execute('''
CREATE TABLE sets (
  id $idType,
  workoutId TEXT NOT NULL,
  exerciseName $textType,
  reps $intType,
  weight $numType,
  isCompleted INTEGER NOT NULL
)
''');

    await db.execute('''
CREATE TABLE nutrition (
  date $idType,
  calories $intType,
  protein $intType,
  carbs $intType,
  fats $intType
)
''');

    await db.execute('''
CREATE TABLE food_logs (
  id $idType,
  date TEXT NOT NULL,
  name $textType,
  calories $intType,
  protein $intType,
  carbs $intType,
  fats $intType
)
''');

    // Seed initial routines
    for (var routine in seedRoutines.values) {
      await db.insert('routines', {
        'id': routine.id,
        'name': routine.name,
        'type': routine.type,
        'day': routine.day,
        'subtitle': routine.subtitle,
        'exercises': jsonEncode(routine.exercises.map((e) => e.toJson()).toList()),
      });
    }
  }

  // --- Routines ---
  Future<List<RoutineModel>> getRoutines() async {
    final db = await instance.database;
    final maps = await db.query('routines');

    return maps.map((json) {
      final exercisesList = jsonDecode(json['exercises'] as String) as List;
      return RoutineModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        day: json['day'] as String,
        subtitle: json['subtitle'] as String,
        exercises: exercisesList.map((e) => RoutineExerciseModel.fromJson(e)).toList(),
      );
    }).toList();
  }

  Future<int> updateRoutine(RoutineModel routine) async {
    final db = await instance.database;
    return db.update(
      'routines',
      {
        'name': routine.name,
        'type': routine.type,
        'day': routine.day,
        'subtitle': routine.subtitle,
        'exercises': jsonEncode(routine.exercises.map((e) => e.toJson()).toList()),
      },
      where: 'id = ?',
      whereArgs: [routine.id],
    );
  }

  // --- Workouts ---
  Future<void> saveWorkout(WorkoutModel workout) async {
    final db = await instance.database;
    await db.insert('workouts', {
      'id': workout.id,
      'date': workout.date.toIso8601String(),
      'routineId': workout.routineId,
      'durationSeconds': workout.durationSeconds,
      'volume': workout.volume,
    });

    for (var set in workout.sets) {
      await db.insert('sets', {
        'id': set.id,
        'workoutId': workout.id,
        'exerciseName': set.exerciseName,
        'reps': set.reps,
        'weight': set.weight,
        'isCompleted': set.isCompleted ? 1 : 0,
      });
    }
  }

  Future<List<WorkoutModel>> getWorkouts() async {
    final db = await instance.database;
    final workoutMaps = await db.query('workouts', orderBy: 'date DESC');

    List<WorkoutModel> workouts = [];
    for (var map in workoutMaps) {
      final workoutId = map['id'] as String;
      final setMaps = await db.query('sets', where: 'workoutId = ?', whereArgs: [workoutId]);

      workouts.add(WorkoutModel(
        id: workoutId,
        date: DateTime.parse(map['date'] as String),
        routineId: map['routineId'] as String,
        durationSeconds: map['durationSeconds'] as int,
        volume: map['volume'] as double,
        sets: setMaps.map((s) => SetModel(
          id: s['id'] as String,
          exerciseName: s['exerciseName'] as String,
          reps: s['reps'] as int,
          weight: s['weight'] as double,
          isCompleted: (s['isCompleted'] as int) == 1,
        )).toList(),
      ));
    }
    return workouts;
  }

  // --- Nutrition ---
  Future<NutritionDayModel?> getNutritionDay(String dateStr) async {
    final db = await instance.database;
    final maps = await db.query('nutrition', where: 'date = ?', whereArgs: [dateStr]);
    if (maps.isNotEmpty) {
      return NutritionDayModel.fromJson(maps.first);
    }
    return null;
  }

  Future<void> saveNutritionDay(NutritionDayModel nutrition) async {
    final db = await instance.database;
    await db.insert('nutrition', nutrition.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<FoodLogModel>> getFoodLogs(String dateStr) async {
    final db = await instance.database;
    final maps = await db.query('food_logs', where: 'date = ?', whereArgs: [dateStr]);
    return maps.map((json) => FoodLogModel.fromJson(json)).toList();
  }

  Future<void> insertFoodLog(FoodLogModel log) async {
    final db = await instance.database;
    await db.insert('food_logs', log.toJson());
  }

  Future<void> deleteFoodLog(String id) async {
    final db = await instance.database;
    await db.delete('food_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
