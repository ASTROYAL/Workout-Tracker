class RoutineExerciseModel {
  String name;
  int sets;
  String reps;
  int restSeconds;
  String tip;
  String badge;
  List<String> setup;
  List<String> execution;
  List<String> mistakes;

  RoutineExerciseModel({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.tip,
    required this.badge,
    required this.setup,
    required this.execution,
    required this.mistakes,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'sets': sets,
    'reps': reps,
    'restSeconds': restSeconds,
    'tip': tip,
    'badge': badge,
    'setup': setup,
    'execution': execution,
    'mistakes': mistakes,
  };

  factory RoutineExerciseModel.fromJson(Map<String, dynamic> json) {
    return RoutineExerciseModel(
      name: json['name'] as String,
      sets: json['sets'] is int
          ? json['sets'] as int
          : (json['sets'] as num).toInt(),
      reps: json['reps'] as String,
      restSeconds: json['restSeconds'] is int
          ? json['restSeconds'] as int
          : (json['restSeconds'] as num).toInt(),
      tip: json['tip'] as String,
      badge: json['badge'] as String,
      setup: (json['setup'] as List?)?.map((e) => e as String).toList() ?? [],
      execution:
          (json['execution'] as List?)?.map((e) => e as String).toList() ?? [],
      mistakes:
          (json['mistakes'] as List?)?.map((e) => e as String).toList() ?? [],
    );
  }
}

class RoutineModel {
  String id;
  String name;
  String type;
  String day;
  String subtitle;
  List<RoutineExerciseModel> exercises;

  RoutineModel({
    required this.id,
    required this.name,
    required this.type,
    required this.day,
    required this.subtitle,
    required this.exercises,
  });
}

class SetModel {
  String id;
  String exerciseName;
  int reps;
  double weight;
  bool isCompleted;

  SetModel({
    required this.id,
    required this.exerciseName,
    required this.reps,
    required this.weight,
    required this.isCompleted,
  });
}

class WorkoutModel {
  String id;
  DateTime date;
  String routineId;
  int durationSeconds;
  double volume;
  List<SetModel> sets;

  WorkoutModel({
    required this.id,
    required this.date,
    required this.routineId,
    required this.durationSeconds,
    required this.volume,
    required this.sets,
  });
}

class NutritionDayModel {
  String date; // YYYY-MM-DD
  int calories;
  int protein;
  int carbs;
  int fats;

  NutritionDayModel({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fats': fats,
  };

  factory NutritionDayModel.fromJson(Map<String, dynamic> json) =>
      NutritionDayModel(
        date: json['date'] as String,
        calories: (json['calories'] as num).toInt(),
        protein: (json['protein'] as num).toInt(),
        carbs: (json['carbs'] as num).toInt(),
        fats: (json['fats'] as num).toInt(),
      );
}

class FoodLogModel {
  String id;
  String date; // YYYY-MM-DD
  String name;
  int calories;
  int protein;
  int carbs;
  int fats;

  FoodLogModel({
    required this.id,
    required this.date,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'name': name,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fats': fats,
  };

  factory FoodLogModel.fromJson(Map<String, dynamic> json) => FoodLogModel(
    id: json['id'] as String,
    date: json['date'] as String,
    name: json['name'] as String,
    calories: (json['calories'] as num).toInt(),
    protein: (json['protein'] as num).toInt(),
    carbs: (json['carbs'] as num).toInt(),
    fats: (json['fats'] as num).toInt(),
  );
}
