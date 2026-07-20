import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers.dart';
import '../theme.dart';
import 'active_workout.dart';
import 'wild_widgets.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with RouteAware, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshDraft());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshDraft();
  }

  Future<void> _refreshDraft() async {
    if (!mounted) return;
    await context.read<WorkoutProvider>().refreshDraft();
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'push':
        return AppTheme.push;
      case 'pull':
        return AppTheme.pull;
      case 'legs':
        return AppTheme.legs;
      default:
        return AppTheme.orange;
    }
  }

  RoutineModel? _todayRoutine(List<RoutineModel> routines) {
    if (routines.isEmpty) return null;
    final weekday = DateTime.now().weekday;
    final byDay = routines.where((routine) {
      final day = routine.day.toLowerCase();
      return day.contains(
            DateFormat('EEEE').format(DateTime.now()).toLowerCase(),
          ) ||
          day.contains('day $weekday') ||
          day == weekday.toString();
    });
    return byDay.isNotEmpty
        ? byDay.first
        : routines[(weekday - 1) % routines.length];
  }

  int _streak(List<WorkoutModel> workouts) {
    if (workouts.isEmpty) return 0;
    final days = workouts
        .map((w) => DateTime(w.date.year, w.date.month, w.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    var cursor = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    var count = 0;
    for (final day in days) {
      if (day == cursor) {
        count++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (day.isBefore(cursor)) {
        break;
      }
    }
    return count;
  }

  void _openRoutine(RoutineModel routine) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutScreen(routine: routine),
      ),
    );
    // Refresh draft state when returning from active session
    if (mounted) _refreshDraft();
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();
    final routines = workoutProvider.routines;
    final todayRoutine = _todayRoutine(routines);
    final activeDraftId = workoutProvider.activeDraftRoutineId;

    return Scaffold(
      appBar: const WildHeader(),
      body: routines.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
              children: [
                // Date + Welcome
                Text(
                  DateFormat('EEEE, MMMM d')
                      .format(DateTime.now())
                      .toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.orangeSoft,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.snow,
                  ),
                ),
                const SizedBox(height: 20),

                // Streak Panel – compact forest background
                RepaintBoundary(
                  child: ForestPanel(
                    imageUrl:
                        'https://images.unsplash.com/photo-1448375240586-882707db888b?w=800&q=80',
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_streak(workoutProvider.workouts)}',
                          style: Theme.of(
                            context,
                          ).textTheme.displayLarge?.copyWith(
                            color: AppTheme.orangeSoft,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DAY STREAK',
                                style: Theme.of(
                                  context,
                                ).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.orangeSoft,
                                ),
                              ),
                              Text(
                                'Strength in consistency.',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.snow,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Today's Session
                Text(
                  "Today's Session",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                if (todayRoutine != null)
                  WildCard(
                    accent: _typeColor(todayRoutine.type),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    todayRoutine.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(color: AppTheme.orangeSoft),
                                  ),
                                  Text(
                                    todayRoutine.subtitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppTheme.blush),
                                  ),
                                ],
                              ),
                            ),
                            _SessionButton(
                              hasDraft: activeDraftId == todayRoutine.id,
                              onTap: () => _openRoutine(todayRoutine),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ...todayRoutine.exercises
                            .take(3)
                            .map(
                              (exercise) =>
                                  _ExercisePreview(exercise: exercise),
                            ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // All Routines
                Text(
                  'All Routines',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                ...routines.map(
                  (routine) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: WildCard(
                      accent: _typeColor(routine.type),
                      onTap: () => _openRoutine(routine),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: _typeColor(
                                routine.type,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.fitness_center,
                              color: _typeColor(routine.type),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  routine.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  routine.day,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.blush,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (activeDraftId == routine.id)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.pine.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: AppTheme.pine.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                'CONTINUE',
                                style: Theme.of(
                                  context,
                                ).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.pine,
                                  fontSize: 9,
                                ),
                              ),
                            )
                          else
                            const Icon(
                              Icons.play_arrow_rounded,
                              color: AppTheme.orangeSoft,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Start / Continue button for today's session card
class _SessionButton extends StatelessWidget {
  final bool hasDraft;
  final VoidCallback onTap;

  const _SessionButton({required this.hasDraft, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (hasDraft) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.play_circle_outline, size: 16),
        label: const Text('Continue'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.pine,
          foregroundColor: AppTheme.forest,
        ),
      );
    }
    return ElevatedButton(
      onPressed: onTap,
      child: const Text('Start'),
    );
  }
}

class _ExercisePreview extends StatelessWidget {
  final RoutineExerciseModel exercise;

  const _ExercisePreview({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.canopyHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.fitness_center, color: AppTheme.sage),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${exercise.sets} SETS · ${exercise.reps} REPS',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.blush),
        ],
      ),
    );
  }
}
