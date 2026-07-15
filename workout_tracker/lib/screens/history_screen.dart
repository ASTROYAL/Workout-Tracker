import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../theme.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../export_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Map<String, GlobalKey> _cardKeys = {};

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();
    final workouts = workoutProvider.workouts;

    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      body: workouts.isEmpty
          ? const Center(child: Text('No workouts logged yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final workout = workouts[index];
                final dateStr = DateFormat('MMM d, yyyy - h:mm a').format(workout.date);

                _cardKeys[workout.id] ??= GlobalKey();

                return RepaintBoundary(
                  key: _cardKeys[workout.id],
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                    title: Text('${workout.routineId} Workout', style: Theme.of(context).textTheme.titleMedium),
                    subtitle: Text(
                      '$dateStr\nDuration: ${workout.durationSeconds ~/ 60}m | Volume: ${workout.volume} kg',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...workout.sets.map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(s.exerciseName),
                                      Text('${s.reps} reps @ ${s.weight} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                _showShareSheet(context, workoutProvider, workout.id);
                              },
                              icon: const Icon(Icons.share),
                              label: const Text('SHARE / EXPORT'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.ink),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                );
              },
            ),
    );
  }

  Future<void> _shareAsImage(String workoutId) async {
    try {
      final boundary = _cardKeys[workoutId]?.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/workout_summary.png');
      await file.writeAsBytes(pngBytes);

      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'Check out my workout!');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing image: $e')));
      }
    }
  }

  void _showShareSheet(BuildContext context, WorkoutProvider provider, String workoutId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppTheme.push),
              title: const Text('Download PDF'),
              onTap: () async {
                Navigator.pop(context);
                final workouts = provider.workouts;
                if (workouts.isNotEmpty) {
                  await ExportHelper.exportPdf(workouts);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Generated!')));
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: AppTheme.legs),
              title: const Text('Share as Text'),
              onTap: () {
                Navigator.pop(context);
                final workouts = provider.workouts;
                if (workouts.isNotEmpty) {
                  ExportHelper.shareTextSummary(workouts);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: AppTheme.pull),
              title: const Text('Share as Image'),
              onTap: () async {
                Navigator.pop(context);
                await _shareAsImage(workoutId);
              },
            ),
          ],
        ),
      ),
    );
  }
}
