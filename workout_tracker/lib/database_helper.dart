import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';
import 'seed_data.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static double _asDouble(dynamic value) => (value as num).toDouble();

  static int _asInt(dynamic value) => (value as num).toInt();

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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Migrate old schema (v1 → v2): drop date-keyed weight_logs, recreate with id key
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Preserve existing data by reading it first
      final existing = await db.query('weight_logs');
      await db.execute('DROP TABLE IF EXISTS weight_logs');
      await db.execute('''
CREATE TABLE weight_logs (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  weightKg REAL NOT NULL
)
''');
      // Re-insert old rows with auto-generated ids
      for (final row in existing) {
        await db.insert('weight_logs', {
          'id': '${row['date']}_migrated',
          'date': row['date'],
          'weightKg': row['weightKg'],
        });
      }
    }
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

    await db.execute('''
CREATE TABLE user_settings (
  key $idType,
  value TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE weight_logs (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  weightKg REAL NOT NULL
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
        'exercises': jsonEncode(
          routine.exercises.map((e) => e.toJson()).toList(),
        ),
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
        exercises: exercisesList
            .map((e) => RoutineExerciseModel.fromJson(e))
            .toList(),
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
        'exercises': jsonEncode(
          routine.exercises.map((e) => e.toJson()).toList(),
        ),
      },
      where: 'id = ?',
      whereArgs: [routine.id],
    );
  }

  // --- Workouts ---
  Future<void> saveWorkout(WorkoutModel workout) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('workouts', {
        'id': workout.id,
        'date': workout.date.toIso8601String(),
        'routineId': workout.routineId,
        'durationSeconds': workout.durationSeconds,
        'volume': workout.volume,
      });

      for (var set in workout.sets) {
        await txn.insert('sets', {
          'id': set.id,
          'workoutId': workout.id,
          'exerciseName': set.exerciseName,
          'reps': set.reps,
          'weight': set.weight,
          'isCompleted': set.isCompleted ? 1 : 0,
        });
      }
    });
  }

  Future<void> deleteWorkout(String workoutId) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('sets', where: 'workoutId = ?', whereArgs: [workoutId]);
      await txn.delete('workouts', where: 'id = ?', whereArgs: [workoutId]);
    });
  }

  Future<List<WorkoutModel>> getWorkouts() async {
    final db = await instance.database;
    final workoutMaps = await db.query('workouts', orderBy: 'date DESC');

    List<WorkoutModel> workouts = [];
    for (var map in workoutMaps) {
      final workoutId = map['id'] as String;
      final setMaps = await db.query(
        'sets',
        where: 'workoutId = ?',
        whereArgs: [workoutId],
      );

      workouts.add(
        WorkoutModel(
          id: workoutId,
          date: DateTime.parse(map['date'] as String),
          routineId: map['routineId'] as String,
          durationSeconds: _asInt(map['durationSeconds']),
          volume: _asDouble(map['volume']),
          sets: setMaps
              .map(
                (s) => SetModel(
                  id: s['id'] as String,
                  exerciseName: s['exerciseName'] as String,
                  reps: _asInt(s['reps']),
                  weight: _asDouble(s['weight']),
                  isCompleted: _asInt(s['isCompleted']) == 1,
                ),
              )
              .toList(),
        ),
      );
    }
    return workouts;
  }

  // --- Nutrition ---
  Future<NutritionDayModel?> getNutritionDay(String dateStr) async {
    final db = await instance.database;
    final maps = await db.query(
      'nutrition',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    if (maps.isNotEmpty) {
      return NutritionDayModel.fromJson(maps.first);
    }
    return null;
  }

  Future<void> saveNutritionDay(NutritionDayModel nutrition) async {
    final db = await instance.database;
    await db.insert(
      'nutrition',
      nutrition.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FoodLogModel>> getFoodLogs(String dateStr) async {
    final db = await instance.database;
    final maps = await db.query(
      'food_logs',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'rowid DESC',
    );
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

  // --- Weight Logs ---
  Future<void> saveWeightLog(String date, double weightKg) async {
    final db = await instance.database;
    // Use full ISO timestamp as the unique id so multiple entries per day work
    final id = DateTime.now().toIso8601String();
    await db.insert('weight_logs', {
      'id': id,
      'date': date,
      'weightKg': weightKg,
    });
  }

  Future<List<Map<String, dynamic>>> getWeightLogs() async {
    final db = await instance.database;
    return await db.query('weight_logs', orderBy: 'date ASC');
  }

  // --- User Settings ---
  Future<String?> getUserSetting(String key) async {
    final db = await instance.database;
    final maps = await db.query(
      'user_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  Future<void> saveUserSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert('user_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
