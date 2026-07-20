import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'models.dart';

class ExportHelper {
  static Future<void> exportPdf(WorkoutModel workout) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(workout.date);
          return [
            pw.Header(level: 0, child: pw.Text('Workout Log Summary')),
            pw.SizedBox(height: 20),
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Workout: ${workout.routineId} - $dateStr',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  pw.Text(
                    'Duration: ${workout.durationSeconds ~/ 60} min | Total Volume: ${workout.volume} kg',
                    style: const pw.TextStyle(color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 8),
                  pw.TableHelper.fromTextArray(
                    context: context,
                    headers: ['Exercise', 'Sets x Reps', 'Weight (kg)'],
                    data: workout.sets
                        .map(
                          (s) => [
                            s.exerciseName,
                            '1 x ${s.reps}',
                            s.weight.toString(),
                          ],
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/workout_log.pdf');
    await file.writeAsBytes(await pdf.save());

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)], text: 'My Workout Log');
  }

  static Future<void> exportAllWorkoutsPdf(List<WorkoutModel> workouts) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Header(level: 0, child: pw.Text('Complete Workout History')),
            pw.SizedBox(height: 20),
            ...workouts.map((workout) {
              final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(workout.date);
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Workout: ${workout.routineId} - $dateStr',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Text(
                      'Duration: ${workout.durationSeconds ~/ 60} min | Total Volume: ${workout.volume} kg',
                      style: const pw.TextStyle(color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 8),
                    pw.TableHelper.fromTextArray(
                      context: context,
                      headers: ['Exercise', 'Sets x Reps', 'Weight (kg)'],
                      data: workout.sets
                          .map(
                            (s) => [
                              s.exerciseName,
                              '1 x ${s.reps}',
                              s.weight.toString(),
                            ],
                          )
                          .toList(),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(),
                  ],
                ),
              );
            }).toList(),
          ];
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/all_workout_logs.pdf');
    await file.writeAsBytes(await pdf.save());

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)], text: 'My Complete Workout History PDF');
  }

  static Future<void> shareAllWorkoutsTxt(List<WorkoutModel> workouts) async {
    String summary = 'COMPLETE WORKOUT HISTORY\n';
    summary += 'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\n\n';
    summary += '=================================\n\n';

    for (var workout in workouts) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(workout.date);
      summary += 'Workout: ${workout.routineId} - $dateStr\n';
      summary += 'Duration: ${workout.durationSeconds ~/ 60} mins\n';
      summary += 'Volume: ${workout.volume} kg\n';
      summary += '---------------------------------\n';
      for (var set in workout.sets) {
        summary += '- ${set.exerciseName}: ${set.reps} reps @ ${set.weight}kg\n';
      }
      summary += '\n=================================\n\n';
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/workout_history.txt');
    await file.writeAsBytes(summary.codeUnits);

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)], text: 'My Complete Workout History TXT');
  }

  static void shareTextSummary(WorkoutModel workout) {
    final dateStr = DateFormat('yyyy-MM-dd').format(workout.date);

    String summary =
        'Just smashed a ${workout.routineId} workout on $dateStr!\n';
    summary += 'Duration: ${workout.durationSeconds ~/ 60} mins\n';
    summary += 'Volume: ${workout.volume} kg\n\n';

    for (var set in workout.sets) {
      summary += '- ${set.exerciseName}: ${set.reps} reps @ ${set.weight}kg\n';
    }

    // ignore: deprecated_member_use
    Share.share(summary);
  }
}
