import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../providers.dart';
import '../theme.dart';
import 'hiit_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final RoutineModel routine;

  const ActiveWorkoutScreen({super.key, required this.routine});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late DateTime _startTime;
  final Map<String, List<SetModel>> _exerciseSets = {};
  late List<RoutineExerciseModel> _activeExercises;
  Timer? _restTimer;
  int _restSecondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _activeExercises = List.from(widget.routine.exercises);
    for (var exercise in _activeExercises) {
      _exerciseSets[exercise.name] = List.generate(
        exercise.sets,
        (index) => SetModel(
          id: const Uuid().v4(),
          exerciseName: exercise.name,
          reps: 0,
          weight: 0.0,
          isCompleted: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restSecondsRemaining = seconds;
    });
    if (seconds > 0) {
      _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_restSecondsRemaining > 0) {
            _restSecondsRemaining--;
          } else {
            _restTimer?.cancel();
          }
        });
      });
    }
  }

  void _addHIIT() {
    setState(() {
      final hiitExercise = RoutineExerciseModel(
        name: 'HIIT (Post-Workout)',
        sets: 1,
        reps: '1',
        restSeconds: 0,
        tip: '15 minutes of high intensity interval training.',
        badge: 'Cardio',
        setup: [],
        execution: [],
        mistakes: [],
      );
      if (!_activeExercises.any((e) => e.name == 'HIIT (Post-Workout)')) {
        _activeExercises.add(hiitExercise);
        _exerciseSets[hiitExercise.name] = [
          SetModel(
            id: const Uuid().v4(),
            exerciseName: hiitExercise.name,
            reps: 1,
            weight: 0.0,
            isCompleted: false,
          )
        ];
      }
    });
  }

  void _finishWorkout() {
    int duration = DateTime.now().difference(_startTime).inSeconds;
    double volume = 0;
    List<SetModel> allSets = [];
    bool includeHIIT = false;

    for (var exerciseSets in _exerciseSets.values) {
      for (var set in exerciseSets) {
        if (set.isCompleted) {
          if (set.exerciseName == 'HIIT (Post-Workout)') {
            includeHIIT = true;
          }
          volume += set.weight * set.reps;
          allSets.add(set);
        }
      }
    }

    final workout = WorkoutModel(
      id: const Uuid().v4(),
      date: DateTime.now(),
      routineId: widget.routine.id,
      durationSeconds: duration,
      volume: volume,
      sets: allSets,
    );

    context.read<WorkoutProvider>().saveWorkout(workout);

    if (includeHIIT) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HIITScreen(
          onFinish: () {
            Navigator.pop(context); // Pop HIIT screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Workout + HIIT Saved!')),
            );
          }
        )),
      );
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout Saved!')),
      );
    }
  }

  void _showFormGuide(RoutineExerciseModel exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            controller: controller,
            children: [
              Text(exercise.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(exercise.tip, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
              const SizedBox(height: 24),
              if (exercise.setup.isNotEmpty) ...[
                Text('SETUP', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 8),
                ...exercise.setup.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $s', style: Theme.of(context).textTheme.bodyMedium),
                )),
                const SizedBox(height: 16),
              ],
              if (exercise.execution.isNotEmpty) ...[
                Text('EXECUTION', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 8),
                ...exercise.execution.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $s', style: Theme.of(context).textTheme.bodyMedium),
                )),
                const SizedBox(height: 16),
              ],
              if (exercise.mistakes.isNotEmpty) ...[
                Text('FEEL & MISTAKES', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.accent)),
                const SizedBox(height: 8),
                ...exercise.mistakes.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(s, style: Theme.of(context).textTheme.bodyMedium),
                )),
              ]
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine.name),
        actions: [
          TextButton(
            onPressed: _finishWorkout,
            child: const Text('FINISH', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._activeExercises.map((exercise) {
            final sets = _exerciseSets[exercise.name]!;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(exercise.name, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        if (exercise.setup.isNotEmpty || exercise.execution.isNotEmpty || exercise.mistakes.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.info_outline, color: AppTheme.accent2),
                            onPressed: () => _showFormGuide(exercise),
                          ),
                      ],
                    ),
                    Text('Target: ${exercise.sets} sets x ${exercise.reps} | Rest: ${exercise.restSeconds}s',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted)),
                    const SizedBox(height: 16),
                    ...sets.asMap().entries.map((entry) {
                      int index = entry.key;
                      SetModel set = entry.value;
                      return Row(
                        children: [
                          SizedBox(width: 30, child: Text('${index + 1}', style: Theme.of(context).textTheme.labelSmall)),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(hintText: 'kg', isDense: true),
                                onChanged: (val) => set.weight = double.tryParse(val) ?? 0,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(hintText: 'reps', isDense: true),
                                onChanged: (val) => set.reps = int.tryParse(val) ?? 0,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              set.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                              color: set.isCompleted ? AppTheme.accent3 : AppTheme.border,
                            ),
                            onPressed: () {
                              setState(() {
                                set.isCompleted = !set.isCompleted;
                                if (set.isCompleted) {
                                  _startRestTimer(exercise.restSeconds);
                                }
                              });
                            },
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          if (!_activeExercises.any((e) => e.name == 'HIIT (Post-Workout)'))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                onPressed: _addHIIT,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.hiit,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('ADD HIIT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          const SizedBox(height: 80), // extra padding for bottom sheet
        ],
      ),
      bottomSheet: _restSecondsRemaining > 0 ? Container(
        color: AppTheme.card,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rest: ${_restSecondsRemaining ~/ 60}:${(_restSecondsRemaining % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.paper)),
            TextButton(
              onPressed: () {
                _restTimer?.cancel();
                setState(() {
                  _restSecondsRemaining = 0;
                });
              },
              child: const Text('SKIP REST', style: TextStyle(color: AppTheme.accent)),
            )
          ],
        ),
      ) : null,
    );
  }
}
