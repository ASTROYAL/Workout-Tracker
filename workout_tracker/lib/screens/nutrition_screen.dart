import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers.dart';
import '../theme.dart';
import 'wild_widgets.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final day = provider.currentDayNutrition;

    if (day == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final caloriesLeft = (provider.targetCalories - day.calories).clamp(
      0,
      provider.targetCalories,
    );
    final calorieProgress = provider.targetCalories <= 0
        ? 0.0
        : (day.calories / provider.targetCalories).clamp(0.0, 1.0);

    return Scaffold(
      appBar: const WildHeader(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFoodDialog(context, provider),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
        children: [
          // Date + Title below WildStrength header
          Text(
            DateFormat('EEEE, MMMM d').format(DateTime.now()).toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.orangeSoft,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Daily Fueling',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppTheme.snow,
            ),
          ),
          Text(
            'Nourish your inner strength with balanced, organic energy.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),

          // Macronutrient Split
          WildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MACRONUTRIENT SPLIT',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 14),

                // Total Calories – larger progress bar
                _CaloriesBar(
                  consumed: day.calories,
                  target: provider.targetCalories,
                  left: caloriesLeft,
                  progress: calorieProgress,
                ),
                const SizedBox(height: 6),

                _MacroBar(
                  label: 'Protein',
                  value: day.protein,
                  target: provider.targetProtein,
                  color: AppTheme.sage,
                ),
                _MacroBar(
                  label: 'Carbohydrates',
                  value: day.carbs,
                  target: provider.targetCarbs,
                  color: AppTheme.sage.withValues(alpha: 0.82),
                ),
                _MacroBar(
                  label: 'Healthy Fats',
                  value: day.fats,
                  target: provider.targetFats,
                  color: AppTheme.blush,
                ),
                const SizedBox(height: 10),
                WildCard(
                  radius: 18,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.orange.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.eco_outlined,
                          color: AppTheme.orangeSoft,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          day.carbs < provider.targetCarbs
                              ? 'Add slow carbs or greens to round out today.'
                              : 'Energy target is looking strong today.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.snow),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Meal Journals header with VIEW HISTORY
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meal Journals',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MealHistoryScreen(),
                    ),
                  );
                },
                child: const Text('VIEW HISTORY'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Meal rows – max 3, compact single-line
          if (provider.currentDayLogs.isEmpty)
            WildCard(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.restaurant_outlined,
                    color: AppTheme.blush,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No meals logged yet',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          'Tap + to add breakfast, lunch, dinner, or a custom entry.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ...provider.currentDayLogs.reversed.take(3).map(
              (log) => _MealRow(
                log: log,
                onDelete: () => provider.deleteFoodLog(log),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddFoodDialog(BuildContext context, NutritionProvider provider) {
    final nameController = TextEditingController();
    final calsController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatsController = TextEditingController();
    final quickAdd = [
      {'name': 'Paneer (100g)', 'cals': 265, 'p': 18, 'c': 1, 'f': 20},
      {'name': 'Dal (1 bowl)', 'cals': 150, 'p': 9, 'c': 20, 'f': 5},
      {'name': 'Whey Protein', 'cals': 120, 'p': 24, 'c': 3, 'f': 1},
      {'name': 'Soya Chunks', 'cals': 170, 'p': 26, 'c': 16, 'f': 0},
      {'name': 'Roti', 'cals': 100, 'p': 3, 'c': 20, 'f': 1},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.canopy,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Add',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickAdd.map((food) {
                  return ActionChip(
                    label: Text(food['name'] as String),
                    onPressed: () {
                      provider.addFoodLog(
                        food['name'] as String,
                        food['cals'] as int,
                        food['p'] as int,
                        food['c'] as int,
                        food['f'] as int,
                      );
                      Navigator.pop(sheetContext);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Text(
                'Custom Add',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Food Name'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: calsController,
                      decoration: const InputDecoration(labelText: 'Kcal'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: proteinController,
                      decoration: const InputDecoration(labelText: 'Protein'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: carbsController,
                      decoration: const InputDecoration(labelText: 'Carbs'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: fatsController,
                      decoration: const InputDecoration(labelText: 'Fats'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    provider.addFoodLog(
                      name,
                      int.tryParse(calsController.text) ?? 0,
                      int.tryParse(proteinController.text) ?? 0,
                      int.tryParse(carbsController.text) ?? 0,
                      int.tryParse(fatsController.text) ?? 0,
                    );
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Log Meal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Calories bar – larger to visually distinguish it as the primary macro
class _CaloriesBar extends StatelessWidget {
  final int consumed;
  final int target;
  final int left;
  final double progress;

  const _CaloriesBar({
    required this.consumed,
    required this.target,
    required this.left,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Calories',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '$consumed / ${target} kcal',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.orangeSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$left kcal remaining',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.blush,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 14, // Larger bar for total calories
              backgroundColor: AppTheme.snow.withValues(alpha: 0.08),
              color: AppTheme.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final int value;
  final int target;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${value}g / ${target}g',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.orangeSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 7,
              backgroundColor: AppTheme.snow.withValues(alpha: 0.08),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact single-line meal row
class _MealRow extends StatelessWidget {
  final FoodLogModel log;
  final VoidCallback onDelete;

  const _MealRow({required this.log, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: WildCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${log.calories} kcal',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.orangeSoft,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                log.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.snow,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${log.protein}P · ${log.carbs}C · ${log.fats}F',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.blush,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(
                Icons.close,
                color: AppTheme.blush,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MealHistoryScreen extends StatelessWidget {
  const MealHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    return Scaffold(
      appBar: const WildHeader(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
        children: [
          Text(
            'MEAL HISTORY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.orangeSoft,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'All Meals',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          if (provider.currentDayLogs.isEmpty)
            WildCard(
              child: Center(
                child: Text(
                  'No meals logged today.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            ...provider.currentDayLogs.reversed.map(
              (log) => _MealRow(
                log: log,
                onDelete: () => provider.deleteFoodLog(log),
              ),
            ),
        ],
      ),
    );
  }
}
