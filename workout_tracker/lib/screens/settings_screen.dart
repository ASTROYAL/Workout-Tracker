import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../theme.dart';
import '../export_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('ROUTINES', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          ...workoutProvider.routines.map((routine) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(routine.name, style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text(routine.subtitle),
              trailing: const Icon(Icons.edit, color: AppTheme.accent2),
              onTap: () {
                // Future enhancement: Edit routine exercises
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Routine editing opens here.')),
                );
              },
            ),
          )),
          const SizedBox(height: 32),
          Text('EXPORT & SHARE', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppTheme.push),
              title: const Text('Export Workout Log (PDF)'),
              onTap: () async {
                 final workouts = workoutProvider.workouts;
                 if (workouts.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No workouts to export.')));
                   return;
                 }
                 await ExportHelper.exportPdf(workouts);
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.share, color: AppTheme.legs),
              title: const Text('Share Summary Text'),
              onTap: () {
                 final workouts = workoutProvider.workouts;
                 if (workouts.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No workouts to share.')));
                   return;
                 }
                 ExportHelper.shareTextSummary(workouts);
              },
            ),
          ),
        ],
      ),
    );
  }
}
