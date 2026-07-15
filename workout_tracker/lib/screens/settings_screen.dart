import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../theme.dart';
import 'routine_edit_screen.dart';

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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RoutineEditScreen(routine: routine)),
                );
              },
            ),
          )),
          const SizedBox(height: 32),
          Text('NUTRITION TARGETS', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          Consumer<NutritionProvider>(
            builder: (context, nutritionProvider, child) {
              return Card(
                child: ListTile(
                  title: const Text('Daily Targets'),
                  subtitle: Text('${nutritionProvider.targetCalories} kcal · ${nutritionProvider.targetProtein}g P · ${nutritionProvider.targetCarbs}g C · ${nutritionProvider.targetFats}g F'),
                  trailing: const Icon(Icons.edit, color: AppTheme.accent),
                  onTap: () {
                    _showEditTargetsDialog(context, nutritionProvider);
                  },
                ),
              );
            }
          ),
        ],
      ),
    );
  }

  void _showEditTargetsDialog(BuildContext context, NutritionProvider provider) {
    final calsController = TextEditingController(text: provider.targetCalories.toString());
    final protController = TextEditingController(text: provider.targetProtein.toString());
    final carbsController = TextEditingController(text: provider.targetCarbs.toString());
    final fatsController = TextEditingController(text: provider.targetFats.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Daily Targets'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: calsController,
                decoration: const InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: protController,
                decoration: const InputDecoration(labelText: 'Protein (g)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: carbsController,
                decoration: const InputDecoration(labelText: 'Carbs (g)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: fatsController,
                decoration: const InputDecoration(labelText: 'Fats (g)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final c = int.tryParse(calsController.text) ?? provider.targetCalories;
              final p = int.tryParse(protController.text) ?? provider.targetProtein;
              final cb = int.tryParse(carbsController.text) ?? provider.targetCarbs;
              final f = int.tryParse(fatsController.text) ?? provider.targetFats;
              provider.updateTargets(c, p, cb, f);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
