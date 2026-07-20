import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../theme.dart';
import 'routine_edit_screen.dart';
import 'wild_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();

    return Scaffold(
      appBar: const WildHeader(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
        children: [
          Text(
            'CONTROL ROOM',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.orangeSoft),
          ),
          Text(
            'Logs',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.snow,
            ),
          ),
          const SizedBox(height: 20),
          Text('ROUTINES', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 10),
          ...workoutProvider.routines.map(
            (routine) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: WildCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoutineEditScreen(routine: routine),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.orange.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: AppTheme.orangeSoft,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routine.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            routine.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_outlined, color: AppTheme.blush),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'NUTRITION TARGETS',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 10),
          Consumer<NutritionProvider>(
            builder: (context, nutritionProvider, child) {
              return WildCard(
                onTap: () => _showEditTargetsDialog(context, nutritionProvider),
                child: Row(
                  children: [
                    const Icon(Icons.tune, color: AppTheme.orangeSoft),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '${nutritionProvider.targetCalories} kcal - ${nutritionProvider.targetProtein}g P - ${nutritionProvider.targetCarbs}g C - ${nutritionProvider.targetFats}g F',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.blush),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditTargetsDialog(
    BuildContext context,
    NutritionProvider provider,
  ) {
    final calsController = TextEditingController(
      text: provider.targetCalories.toString(),
    );
    final protController = TextEditingController(
      text: provider.targetProtein.toString(),
    );
    final carbsController = TextEditingController(
      text: provider.targetCarbs.toString(),
    );
    final fatsController = TextEditingController(
      text: provider.targetFats.toString(),
    );

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
              const SizedBox(height: 10),
              TextField(
                controller: protController,
                decoration: const InputDecoration(labelText: 'Protein (g)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: carbsController,
                decoration: const InputDecoration(labelText: 'Carbs (g)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
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
              final calories =
                  int.tryParse(calsController.text) ?? provider.targetCalories;
              final protein =
                  int.tryParse(protController.text) ?? provider.targetProtein;
              final carbs =
                  int.tryParse(carbsController.text) ?? provider.targetCarbs;
              final fats =
                  int.tryParse(fatsController.text) ?? provider.targetFats;
              provider.updateTargets(calories, protein, carbs, fats);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
