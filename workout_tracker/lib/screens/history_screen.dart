import 'dart:io';
import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../export_helper.dart';
import '../models.dart';
import '../providers.dart';
import '../theme.dart';
import 'wild_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Period enum
// ─────────────────────────────────────────────────────────────────────────────
enum ChartPeriod { week, month, threeMonths, year, all }

extension ChartPeriodLabel on ChartPeriod {
  String get label {
    switch (this) {
      case ChartPeriod.week:        return '1W';
      case ChartPeriod.month:       return '1M';
      case ChartPeriod.threeMonths: return '3M';
      case ChartPeriod.year:        return '1Y';
      case ChartPeriod.all:         return 'All';
    }
  }

  Duration? get duration {
    switch (this) {
      case ChartPeriod.week:        return const Duration(days: 7);
      case ChartPeriod.month:       return const Duration(days: 30);
      case ChartPeriod.threeMonths: return const Duration(days: 90);
      case ChartPeriod.year:        return const Duration(days: 365);
      case ChartPeriod.all:         return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HistoryScreen
// ─────────────────────────────────────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Map<String, GlobalKey> _cardKeys = {};
  ChartPeriod _weightPeriod = ChartPeriod.month;
  ChartPeriod _volumePeriod = ChartPeriod.month;

  // ── Chart data helpers ────────────────────────────────────────────────────

  List<FlSpot> _weightSpots(List<Map<String, dynamic>> logs, ChartPeriod period) {
    if (logs.isEmpty) return [];
    final now = DateTime.now();
    final cutoff = period.duration == null
        ? null
        : DateTime(now.year, now.month, now.day)
            .subtract(period.duration!)
            .subtract(const Duration(days: 1));

    final filtered = logs.where((e) {
      if (cutoff == null) return true;
      final date = DateTime.tryParse(e['date'] as String);
      return date != null && date.isAfter(cutoff);
    }).toList();

    if (filtered.length < 2) return [];

    final firstDate = DateTime.parse(filtered.first['date'] as String);
    return filtered.map((e) {
      final date = DateTime.parse(e['date'] as String);
      final x = date.difference(firstDate).inDays.toDouble();
      final y = (e['weightKg'] as num).toDouble();
      return FlSpot(x, y);
    }).toList();
  }

  List<FlSpot> _volumeSpots(List<WorkoutModel> workouts, ChartPeriod period) {
    if (workouts.isEmpty) return [];
    final cutoff = period.duration == null
        ? null
        : DateTime.now().subtract(period.duration!);
    final filtered = workouts.reversed.where((w) {
      if (cutoff == null) return true;
      return w.date.isAfter(cutoff);
    }).toList();
    if (filtered.isEmpty) return [];
    return filtered.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.volume))
        .toList();
  }

  // ── Stat helpers ──────────────────────────────────────────────────────────

  String _bestVolume(List<WorkoutModel> workouts) {
    if (workouts.isEmpty) return 'Complete a session';
    final best = workouts.map((w) => w.volume).reduce((a, b) => a > b ? a : b);
    return '${best.toStringAsFixed(0)} kg moved';
  }

  int _maxStreak(List<WorkoutModel> workouts) {
    if (workouts.isEmpty) return 0;
    final dates = workouts
        .map((w) => DateTime(w.date.year, w.date.month, w.date.day))
        .toSet().toList()..sort((a, b) => a.compareTo(b));
    int maxStreak = 0, cur = 0;
    DateTime? prev;
    for (final d in dates) {
      if (prev == null) {
        cur = 1;
      } else {
        final diff = d.difference(prev).inDays;
        if (diff == 1) { cur++; }
        else if (diff > 1) { if (cur > maxStreak) maxStreak = cur; cur = 1; }
      }
      prev = d;
    }
    if (cur > maxStreak) maxStreak = cur;
    return maxStreak;
  }

  // ── Share helpers ─────────────────────────────────────────────────────────

  Future<void> _shareAsImage(String workoutId) async {
    try {
      final boundary = _cardKeys[workoutId]?.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/workout_summary.png');
      await file.writeAsBytes(pngBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Check out my workout');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error sharing image: $e')));
      }
    }
  }

  void _showShareAllSheet(BuildContext context, List<WorkoutModel> workouts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.canopy,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Export All Workout Data',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppTheme.orange),
              title: const Text('Download as PDF'),
              subtitle: const Text('Full workout history as a PDF file'),
              onTap: () async { Navigator.pop(ctx); await ExportHelper.exportAllWorkoutsPdf(workouts); },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined, color: AppTheme.sage),
              title: const Text('Share as .txt file'),
              subtitle: const Text('Plain text summary of all sessions'),
              onTap: () { Navigator.pop(ctx); ExportHelper.shareAllWorkoutsTxt(workouts); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context, WorkoutModel workout) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.canopy,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppTheme.orange),
              title: const Text('Download PDF'),
              onTap: () async { Navigator.pop(ctx); await ExportHelper.exportPdf(workout); },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: AppTheme.sage),
              title: const Text('Share as Text'),
              onTap: () { Navigator.pop(ctx); ExportHelper.shareTextSummary(workout); },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: AppTheme.water),
              title: const Text('Share as Image'),
              onTap: () async { Navigator.pop(ctx); await _shareAsImage(workout.id); },
            ),
          ],
        ),
      ),
    );
  }

  void _showWeightDialog(BuildContext context, NutritionProvider provider) {
    final ctrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dlg) => AlertDialog(
        title: const Text('Log Body Weight'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Weight in kg'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlg), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final w = double.tryParse(ctrl.text);
              Navigator.pop(dlg);
              if (w != null && w > 0) {
                await provider.addWeightLog(w);
                messenger.showSnackBar(const SnackBar(content: Text('Weight logged ✓')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWorkoutDetails(BuildContext context, WorkoutModel workout, String routineName) {
    showWorkoutDetailsDialogHelper(context, workout, routineName, () {
      _showShareSheet(context, workout);
    });
  }

  Future<void> _deleteWorkout(BuildContext context, WorkoutModel workout, String routineName) async {
    final confirmed = await showDeleteWorkoutConfirmation(context, workout, routineName);
    if (confirmed && context.mounted) {
      context.read<WorkoutProvider>().deleteWorkout(workout.id);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();
    final nutritionProvider = context.watch<NutritionProvider>();
    final workouts = workoutProvider.workouts;
    final weightLogs = nutritionProvider.weightLogs;

    final weightSpots = _weightSpots(weightLogs, _weightPeriod);
    final volumeSpots = _volumeSpots(workouts, _volumePeriod);

    return Scaffold(
      appBar: const WildHeader(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
        children: [
          Text('EVOLUTION TRACKER',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.orangeSoft, letterSpacing: 2.0)),
          const SizedBox(height: 4),
          Text('Your Growth',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900, color: AppTheme.snow)),
          const SizedBox(height: 12),

          // Share All button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: workouts.isEmpty ? null : () => _showShareAllSheet(context, workouts),
              icon: const Icon(Icons.ios_share_outlined, color: AppTheme.orangeSoft),
              label: const Text('Share All Workout Data', style: TextStyle(color: AppTheme.snow)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.glassBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Weight Trend
          RepaintBoundary(
            child: _TrendCard(
              title: 'Weight Trend',
              subtitle: 'Body weight over time',
              spots: weightSpots,
              emptyText: 'Log two weight entries to draw the curve.',
              currentLabel: weightLogs.isEmpty
                  ? null
                  : '${(weightLogs.last['weightKg'] as num).toStringAsFixed(1)} kg',
              selectedPeriod: _weightPeriod,
              onPeriodChanged: (p) => setState(() => _weightPeriod = p),
              action: ElevatedButton.icon(
                onPressed: () => _showWeightDialog(context, nutritionProvider),
                icon: const Icon(Icons.monitor_weight_outlined, size: 16),
                label: const Text('Log Weight'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  foregroundColor: AppTheme.forest,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recent Wins
          Text('RECENT WINS', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: WildCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    const Icon(Icons.workspace_premium_outlined, color: AppTheme.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('BEST VOLUME',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppTheme.orange, fontSize: 8)),
                        Text(_bestVolume(workouts),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    )),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: WildCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    const Icon(Icons.local_fire_department, color: AppTheme.orangeSoft, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('MAX STREAK',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppTheme.orangeSoft, fontSize: 8)),
                        Text('${_maxStreak(workouts)} Days',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    )),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Workout Progression
          RepaintBoundary(
            child: _TrendCard(
              title: 'Workout Progression',
              subtitle: 'Total volume by session',
              spots: volumeSpots,
              emptyText: 'Finish a workout to start progression tracking.',
              currentLabel: workouts.isEmpty
                  ? null
                  : '${workouts.first.volume.toStringAsFixed(0)} kg',
              selectedPeriod: _volumePeriod,
              onPeriodChanged: (p) => setState(() => _volumePeriod = p),
            ),
          ),
          const SizedBox(height: 24),

          // History Logs (latest 2 + VIEW ALL)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('History Logs', style: Theme.of(context).textTheme.labelMedium),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WorkoutHistoryLogsScreen())),
                child: const Text('VIEW ALL'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (workouts.isEmpty)
            WildCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No workouts logged yet.',
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
            )
          else
            ...workouts.take(2).map((workout) {
              final r = workoutProvider.routines.where((r) => r.id == workout.routineId);
              final routineName = r.isNotEmpty ? r.first.name : workout.routineId;
              _cardKeys[workout.id] ??= GlobalKey();
              return RepaintBoundary(
                key: _cardKeys[workout.id],
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _WorkoutLogCard(
                    workout: workout,
                    routineName: routineName,
                    onTap: () => _showWorkoutDetails(context, workout, routineName),
                    onDelete: () => _deleteWorkout(context, workout, routineName),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete confirmation dialog
// ─────────────────────────────────────────────────────────────────────────────
Future<bool> showDeleteWorkoutConfirmation(
  BuildContext context,
  WorkoutModel workout,
  String routineName,
) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.75),
    transitionDuration: const Duration(milliseconds: 280),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: curved,
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (ctx, _, __) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C1A14), Color(0xFF1A100C)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.orange.withValues(alpha: 0.38),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 48,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: AppTheme.orange.withValues(alpha: 0.07),
                  blurRadius: 28,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing icon ring
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.orange.withValues(alpha: 0.10),
                    border: Border.all(
                      color: AppTheme.orange.withValues(alpha: 0.32),
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.orange.withValues(alpha: 0.18),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.orange,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 22),

                // Title
                Text(
                  'Delete Session?',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.snow,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle — routine + date
                Text(
                  '$routineName  ·  ${DateFormat('MMM d, yyyy').format(workout.date)}',
                  style: GoogleFonts.dmMono(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: AppTheme.orangeSoft,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Warning body
                Text(
                  'This permanently removes this workout log and all its set data. It cannot be undone.',
                  style: GoogleFonts.caveat(
                    fontSize: 16,
                    color: AppTheme.blush,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),

                // Mini stats bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppTheme.snow.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.snow.withValues(alpha: 0.09),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _DeleteStat(icon: Icons.fitness_center_outlined,
                          label: '${workout.volume.toStringAsFixed(0)} kg'),
                      _DeleteStat(icon: Icons.timer_outlined,
                          label: '${workout.durationSeconds ~/ 60} min'),
                      _DeleteStat(icon: Icons.check_circle_outline_rounded,
                          label: '${workout.sets.length} sets'),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.blush,
                          side: BorderSide(
                              color: AppTheme.blush.withValues(alpha: 0.28)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(99)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Keep It'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: const Icon(Icons.delete_rounded, size: 16),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.orange,
                          foregroundColor: AppTheme.forest,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(99)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return result == true;
}

class _DeleteStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DeleteStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.blush),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.snow, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared workout detail dialog
// ─────────────────────────────────────────────────────────────────────────────
void showWorkoutDetailsDialogHelper(
  BuildContext context,
  WorkoutModel workout,
  String routineName,
  VoidCallback onShare,
) {
  final Map<String, List<SetModel>> groupedSets = {};
  for (final set in workout.sets) {
    groupedSets.putIfAbsent(set.exerciseName, () => []).add(set);
  }

  showDialog(
    context: context,
    builder: (dlg) => AlertDialog(
      backgroundColor: AppTheme.canopy,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(DateFormat('EEEE, MMMM d, yyyy').format(workout.date),
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppTheme.orangeSoft)),
          Text('$routineName Session',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(children: [
            _DialogMetric(label: 'VOLUME',
                value: '${workout.volume.toStringAsFixed(0)} kg'),
            const SizedBox(width: 20),
            _DialogMetric(label: 'TIME',
                value: '${workout.durationSeconds ~/ 60} min'),
            const SizedBox(width: 20),
            _DialogMetric(label: 'SETS', value: '${workout.sets.length}'),
          ]),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          children: [
            const Divider(),
            ...groupedSets.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold, color: AppTheme.sage)),
                  const SizedBox(height: 6),
                  ...entry.value.asMap().entries.map((se) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      Text('Set ${se.key + 1}:',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 8),
                      Text('${se.value.weight} kg × ${se.value.reps} reps',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.snow)),
                      if (se.value.isCompleted) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_outline,
                            color: AppTheme.pine, size: 14),
                      ],
                    ]),
                  )),
                ],
              ),
            )),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dlg),
            child: const Text('Close')),
        ElevatedButton.icon(
          onPressed: () { Navigator.pop(dlg); onShare(); },
          icon: const Icon(Icons.ios_share_outlined, size: 16),
          label: const Text('Share'),
        ),
      ],
    ),
  );
}

class _DialogMetric extends StatelessWidget {
  final String label;
  final String value;
  const _DialogMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
        Text(value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold, color: AppTheme.orangeSoft)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared workout log card (used in preview + full history)
// ─────────────────────────────────────────────────────────────────────────────
class _WorkoutLogCard extends StatelessWidget {
  final WorkoutModel workout;
  final String routineName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WorkoutLogCard({
    required this.workout,
    required this.routineName,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return WildCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(workout.date).toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppTheme.orangeSoft),
                ),
                Text('$routineName Session',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 20,
                  runSpacing: 6,
                  children: [
                    _LogMetric(label: 'VOLUME',
                        value: '${workout.volume.toStringAsFixed(0)} kg'),
                    _LogMetric(label: 'TIME',
                        value: '${workout.durationSeconds ~/ 60} min'),
                    _LogMetric(label: 'SETS',
                        value: '${workout.sets.length}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              const Icon(Icons.chevron_right, color: AppTheme.blush),
              const SizedBox(height: 10),
              // Delete button
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.orange.withValues(alpha: 0.24),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.orange,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogMetric extends StatelessWidget {
  final String label;
  final String value;
  const _LogMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.snow, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrendCard
// ─────────────────────────────────────────────────────────────────────────────
class _TrendCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<FlSpot> spots;
  final String emptyText;
  final String? currentLabel;
  final Widget? action;
  final ChartPeriod selectedPeriod;
  final ValueChanged<ChartPeriod> onPeriodChanged;

  const _TrendCard({
    required this.title,
    required this.subtitle,
    required this.spots,
    required this.emptyText,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.currentLabel,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return WildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              )),
              if (action != null) ...[action!, const SizedBox(width: 4)],
            ],
          ),
          const SizedBox(height: 12),

          // Period pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ChartPeriod.values.map((p) {
                final sel = p == selectedPeriod;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onPeriodChanged(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.orange
                            : AppTheme.forestDeep.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(p.label,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: sel ? AppTheme.forest : AppTheme.blush,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 200,
            child: spots.length < 2
                ? Center(
                    child: Text(
                      spots.isEmpty
                          ? emptyText
                          : 'Log one more entry to draw the chart.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.blush),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppTheme.snow.withValues(alpha: 0.05),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppTheme.orangeSoft,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: spots.length <= 30),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.orange.withValues(alpha: 0.07),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 250),
                  ),
          ),
          if (currentLabel != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text('CURRENT  $currentLabel',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppTheme.orangeSoft)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full workout history screen
// ─────────────────────────────────────────────────────────────────────────────
class WorkoutHistoryLogsScreen extends StatelessWidget {
  const WorkoutHistoryLogsScreen({super.key});

  void _showLogDetail(BuildContext context, WorkoutModel workout, String routineName) {
    showWorkoutDetailsDialogHelper(context, workout, routineName, () {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.canopy,
        builder: (sheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: AppTheme.orange),
                title: const Text('Download PDF'),
                onTap: () async {
                  Navigator.pop(sheet);
                  await ExportHelper.exportPdf(workout);
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet, color: AppTheme.sage),
                title: const Text('Share as Text'),
                onTap: () {
                  Navigator.pop(sheet);
                  ExportHelper.shareTextSummary(workout);
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _deleteWorkout(BuildContext context, WorkoutModel workout, String routineName) async {
    final confirmed = await showDeleteWorkoutConfirmation(context, workout, routineName);
    if (confirmed && context.mounted) {
      context.read<WorkoutProvider>().deleteWorkout(workout.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();
    final workouts = workoutProvider.workouts;

    return Scaffold(
      appBar: const WildHeader(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
        children: [
          Text('ALL SESSIONS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.orangeSoft, letterSpacing: 2.0)),
          const SizedBox(height: 4),
          Text('Workout History',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          if (workouts.isEmpty)
            WildCard(
              child: Center(
                child: Text('No workouts logged yet.',
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
            )
          else
            ...workouts.map((workout) {
              final r = workoutProvider.routines
                  .where((r) => r.id == workout.routineId);
              final routineName = r.isNotEmpty ? r.first.name : workout.routineId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WorkoutLogCard(
                  workout: workout,
                  routineName: routineName,
                  onTap: () => _showLogDetail(context, workout, routineName),
                  onDelete: () => _deleteWorkout(context, workout, routineName),
                ),
              );
            }),
        ],
      ),
    );
  }
}
