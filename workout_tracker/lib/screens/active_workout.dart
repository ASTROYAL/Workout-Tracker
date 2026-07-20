import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../models.dart';
import '../providers.dart';
import '../theme.dart';
import 'hiit_screen.dart';
import 'wild_widgets.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

/// Key used to store the active workout draft in user_settings table
const _kDraftKey = 'active_workout_draft';

class ActiveWorkoutScreen extends StatefulWidget {
  final RoutineModel routine;

  const ActiveWorkoutScreen({super.key, required this.routine});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late final DateTime _startTime;
  late final List<RoutineExerciseModel> _activeExercises;

  // Maps setId -> SetModel
  final Map<String, List<SetModel>> _exerciseSets = {};

  // Maps setId -> controller (weight / reps)
  final Map<String, TextEditingController> _weightControllers = {};
  final Map<String, TextEditingController> _repsControllers = {};

  int _restSecondsRemaining = 0;
  bool _loadedDraft = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _activeExercises = List.from(widget.routine.exercises);
    for (final exercise in _activeExercises) {
      _addSetGroup(exercise);
    }
    _loadDraft();
  }

  @override
  void dispose() {
    for (final controller in _weightControllers.values) {
      controller.dispose();
    }
    for (final controller in _repsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ──────────────────────────────── Draft persistence ──────────────────────

  /// Restore a saved draft so weight/reps/completed survives app close
  Future<void> _loadDraft() async {
    try {
      final json = await DatabaseHelper.instance.getUserSetting(_kDraftKey);
      if (json == null || json.isEmpty) return;

      final Map<String, dynamic> draft = jsonDecode(json);
      final String routineId = draft['routineId'] ?? '';
      if (routineId != widget.routine.id) return; // different routine, ignore

      final Map<String, dynamic> setsData = draft['sets'] ?? {};

      setState(() {
        for (final exerciseName in setsData.keys) {
          final List<dynamic> setList = setsData[exerciseName];
          if (!_exerciseSets.containsKey(exerciseName)) continue;

          final existingSets = _exerciseSets[exerciseName]!;
          for (int i = 0; i < setList.length && i < existingSets.length; i++) {
            final savedSet = setList[i];
            final set = existingSets[i];
            set.weight = (savedSet['weight'] as num?)?.toDouble() ?? 0;
            set.reps = (savedSet['reps'] as num?)?.toInt() ?? 0;
            set.isCompleted = savedSet['isCompleted'] as bool? ?? false;

            _weightControllers[set.id]?.text =
                set.weight > 0 ? set.weight.toString() : '';
            _repsControllers[set.id]?.text =
                set.reps > 0 ? set.reps.toString() : '';
          }
        }
        _loadedDraft = true;
      });
    } catch (_) {
      // Draft corrupted — silently ignore
    }
  }

  /// Save current session state as a draft (called when tick is tapped)
  Future<void> _saveDraft() async {
    final Map<String, dynamic> setsData = {};
    for (final entry in _exerciseSets.entries) {
      setsData[entry.key] = entry.value
          .map((s) => {
                'weight': s.weight,
                'reps': s.reps,
                'isCompleted': s.isCompleted,
              })
          .toList();
    }

    final draft = jsonEncode({
      'routineId': widget.routine.id,
      'sets': setsData,
      'savedAt': DateTime.now().toIso8601String(),
    });

    await DatabaseHelper.instance.saveUserSetting(_kDraftKey, draft);
  }

  /// Clear the draft when the workout is finished
  Future<void> _clearDraft() async {
    await DatabaseHelper.instance.saveUserSetting(_kDraftKey, '');
  }

  // ──────────────────────────────── Core actions ───────────────────────────

  void _addSetGroup(RoutineExerciseModel exercise) {
    _exerciseSets[exercise.name] = List.generate(exercise.sets, (_) {
      final set = SetModel(
        id: const Uuid().v4(),
        exerciseName: exercise.name,
        reps: 0,
        weight: 0,
        isCompleted: false,
      );
      _weightControllers[set.id] = TextEditingController();
      _repsControllers[set.id] = TextEditingController();
      return set;
    });
  }

  void _addHIIT() {
    if (_activeExercises.any((e) => e.name == 'HIIT (Post-Workout)')) return;
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
    setState(() {
      _activeExercises.add(hiitExercise);
      final set = SetModel(
        id: const Uuid().v4(),
        exerciseName: hiitExercise.name,
        reps: 1,
        weight: 0,
        isCompleted: true,
      );
      _exerciseSets[hiitExercise.name] = [set];
      _weightControllers[set.id] = TextEditingController(text: '0');
      _repsControllers[set.id] = TextEditingController(text: '1');
    });
  }

  Future<void> _finishWorkout() async {
    var duration = DateTime.now().difference(_startTime).inSeconds;
    var volume = 0.0;
    final allSets = <SetModel>[];
    var includeHIIT = false;

    for (final exerciseSets in _exerciseSets.values) {
      for (final set in exerciseSets) {
        if (!set.isCompleted) continue;
        includeHIIT = includeHIIT || set.exerciseName == 'HIIT (Post-Workout)';
        volume += set.weight * set.reps;
        allSets.add(set);
      }
    }

    if (allSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete at least one set before saving.'),
        ),
      );
      return;
    }

    if (includeHIIT) {
      final completedHiit = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              HIITScreen(onFinish: () => Navigator.pop(context, true)),
        ),
      );
      if (completedHiit != true || !mounted) return;
      duration = DateTime.now().difference(_startTime).inSeconds;
    }

    final workout = WorkoutModel(
      id: const Uuid().v4(),
      date: DateTime.now(),
      routineId: widget.routine.id,
      durationSeconds: duration,
      volume: volume,
      sets: allSets,
    );

    await context.read<WorkoutProvider>().saveWorkout(workout);
    await _clearDraft(); // ← clear the draft after saving
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(includeHIIT ? 'Workout + HIIT saved ✓' : 'Workout saved ✓'),
      ),
    );
  }

  void _showFormGuide(RoutineExerciseModel exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.canopy,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Text(exercise.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              exercise.tip,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.blush),
            ),
            const SizedBox(height: 24),
            _GuideSection(title: 'SETUP', items: exercise.setup),
            _GuideSection(title: 'EXECUTION', items: exercise.execution),
            _GuideSection(
              title: 'FEEL & MISTAKES',
              items: exercise.mistakes,
              highlight: true,
            ),
          ],
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
            child: const Text('FINISH'),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          Text(
            'ACTIVE PROGRAM',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppTheme.orangeSoft),
          ),
          const SizedBox(height: 8),
          Text(
            widget.routine.subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.blush),
          ),
          if (_loadedDraft) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.pine.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.pine.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.restore, color: AppTheme.pine, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Previous session restored',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.pine,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          ..._activeExercises.map(
            (exercise) => _ExerciseCard(
              exercise: exercise,
              sets: _exerciseSets[exercise.name]!,
              weightControllers: _weightControllers,
              repsControllers: _repsControllers,
              onInfo: () => _showFormGuide(exercise),
              onToggle: (set) async {
                if (set.isCompleted && exercise.restSeconds > 0) {
                  setState(() {
                    _restSecondsRemaining = exercise.restSeconds;
                  });
                }
                // Persist draft to DB immediately
                await _saveDraft();
              },
            ),
          ),
          if (!_activeExercises.any(
            (e) => e.name == 'HIIT (Post-Workout)',
          )) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addHIIT,
              icon: const Icon(Icons.bolt),
              label: const Text('Add HIIT Finisher'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.violet,
                foregroundColor: AppTheme.snow,
              ),
            ),
          ],
        ],
      ),
      bottomSheet: _restSecondsRemaining > 0
          ? _RestTimerSheet(
              key: ValueKey(_restSecondsRemaining),
              initialSeconds: _restSecondsRemaining,
              onFinished: () => setState(() => _restSecondsRemaining = 0),
              onSkip: () => setState(() => _restSecondsRemaining = 0),
            )
          : null,
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final RoutineExerciseModel exercise;
  final List<SetModel> sets;
  final Map<String, TextEditingController> weightControllers;
  final Map<String, TextEditingController> repsControllers;
  final VoidCallback onInfo;
  final Future<void> Function(SetModel) onToggle;

  const _ExerciseCard({
    required this.exercise,
    required this.sets,
    required this.weightControllers,
    required this.repsControllers,
    required this.onInfo,
    required this.onToggle,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final sets = widget.sets;
    final hasGuide = exercise.setup.isNotEmpty ||
        exercise.execution.isNotEmpty ||
        exercise.mistakes.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: WildCard(
        accent: exercise.name == 'HIIT (Post-Workout)'
            ? AppTheme.violet
            : AppTheme.orange,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (hasGuide)
                  IconButton(
                    onPressed: widget.onInfo,
                    icon: const Icon(
                      Icons.info_outline,
                      color: AppTheme.orangeSoft,
                    ),
                  ),
              ],
            ),
            Text(
              '${exercise.sets} sets × ${exercise.reps} · ${exercise.restSeconds}s rest',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 16),
            ...sets.asMap().entries.map((entry) {
              final set = entry.value;
              return _SetRow(
                key: ValueKey(set.id),
                setNumber: entry.key + 1,
                set: set,
                weightController: widget.weightControllers[set.id]!,
                repsController: widget.repsControllers[set.id]!,
                onToggle: () async {
                  // Read latest field values into model
                  set.weight = double.tryParse(
                        widget.weightControllers[set.id]?.text ?? '',
                      ) ??
                      set.weight;
                  set.reps = int.tryParse(
                        widget.repsControllers[set.id]?.text ?? '',
                      ) ??
                      set.reps;
                  // Update only this row's visual state
                  setState(() {
                    set.isCompleted = !set.isCompleted;
                  });
                  await widget.onToggle(set);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Individual set row — isolated StatefulWidget so focus/keyboard never
/// causes the parent list to rebuild.
class _SetRow extends StatefulWidget {
  final int setNumber;
  final SetModel set;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final Future<void> Function() onToggle;

  const _SetRow({
    super.key,
    required this.setNumber,
    required this.set,
    required this.weightController,
    required this.repsController,
    required this.onToggle,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final completed = widget.set.isCompleted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${widget.setNumber}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'kg',
                isDense: true,
              ),
              onChanged: (val) =>
                  widget.set.weight = double.tryParse(val) ?? widget.set.weight,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'reps',
                isDense: true,
              ),
              onChanged: (val) =>
                  widget.set.reps = int.tryParse(val) ?? widget.set.reps,
            ),
          ),
          // Tick — saves draft and toggles completion locally
          _saving
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.pine,
                    ),
                  ),
                )
              : IconButton(
                  tooltip: completed ? 'Unmark set' : 'Save & complete set',
                  onPressed: () async {
                    setState(() => _saving = true);
                    await widget.onToggle();
                    if (mounted) setState(() => _saving = false);
                  },
                  icon: Icon(
                    completed ? Icons.check_circle : Icons.check_circle_outline,
                    color: completed ? AppTheme.pine : AppTheme.blush,
                  ),
                ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final bool highlight;

  const _GuideSection({
    required this.title,
    required this.items,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: highlight ? AppTheme.orangeSoft : AppTheme.blush,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '- $item',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestTimerSheet extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback onFinished;
  final VoidCallback onSkip;

  const _RestTimerSheet({
    super.key,
    required this.initialSeconds,
    required this.onFinished,
    required this.onSkip,
  });

  @override
  State<_RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<_RestTimerSheet> {
  late int _secondsRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.initialSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: const BoxDecoration(
        color: AppTheme.canopyHigh,
        border: Border(top: BorderSide(color: AppTheme.glassBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rest ${_secondsRemaining ~/ 60}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.snow),
            ),
            TextButton(
              onPressed: () {
                _timer?.cancel();
                widget.onSkip();
              },
              child: const Text('SKIP REST'),
            ),
          ],
        ),
      ),
    );
  }
}
