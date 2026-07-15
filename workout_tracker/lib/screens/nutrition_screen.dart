import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../theme.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionProvider>();
    final day = provider.currentDayNutrition;

    if (day == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Log')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.ink,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DAILY TARGET', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white54)),
                const SizedBox(height: 8),
                Text(
                  '${provider.targetCalories - day.calories}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.paper),
                ),
                Text('kcal remaining', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54)),
                const SizedBox(height: 24),
                _buildMacroBar(context, 'Protein', day.protein, provider.targetProtein, AppTheme.pull),
                const SizedBox(height: 12),
                _buildMacroBar(context, 'Carbs', day.carbs, provider.targetCarbs, AppTheme.legs),
                const SizedBox(height: 12),
                _buildMacroBar(context, 'Fats', day.fats, provider.targetFats, AppTheme.push),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Today\'s Log', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppTheme.accent),
                onPressed: () => _showAddFoodDialog(context, provider),
              )
            ],
          ),
          ...provider.currentDayLogs.map((log) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(log.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text('${log.calories} kcal · ${log.protein}g P · ${log.carbs}g C · ${log.fats}g F'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.muted),
                onPressed: () => provider.deleteFoodLog(log),
              ),
            ),
          ))
        ],
      ),
    );
  }

  Widget _buildMacroBar(BuildContext context, String label, int current, int target, Color color) {
    double percent = (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white54)),
            Text('${current}g / ${target}g', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.paper, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: Colors.white12,
          color: color,
          minHeight: 6,
        ),
      ],
    );
  }

  void _showAddFoodDialog(BuildContext context, NutritionProvider provider) {
    final nameController = TextEditingController();
    final calsController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatsController = TextEditingController();

    // Defaults optimized for Indian veg recomp
    final List<Map<String, dynamic>> quickAdd = [
      {'name': 'Paneer (100g)', 'cals': 265, 'p': 18, 'c': 1, 'f': 20},
      {'name': 'Dal (1 bowl)', 'cals': 150, 'p': 9, 'c': 20, 'f': 5},
      {'name': 'Whey Protein (1 scoop)', 'cals': 120, 'p': 24, 'c': 3, 'f': 1},
      {'name': 'Soya Chunks (50g dry)', 'cals': 170, 'p': 26, 'c': 16, 'f': 0},
      {'name': 'Roti (1 medium)', 'cals': 100, 'p': 3, 'c': 20, 'f': 1},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Add', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: quickAdd.map((food) => ActionChip(
                label: Text(food['name'] as String),
                onPressed: () {
                  provider.addFoodLog(food['name'] as String, food['cals'] as int, food['p'] as int, food['c'] as int, food['f'] as int);
                  Navigator.pop(context);
                },
              )).toList(),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text('Custom Add', style: Theme.of(context).textTheme.labelSmall),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Food Name')),
            Row(
              children: [
                Expanded(child: TextField(controller: calsController, decoration: const InputDecoration(labelText: 'Kcal'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: proteinController, decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: TextInputType.number)),
              ],
            ),
            Row(
              children: [
                Expanded(child: TextField(controller: carbsController, decoration: const InputDecoration(labelText: 'Carbs (g)'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: fatsController, decoration: const InputDecoration(labelText: 'Fats (g)'), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final cals = int.tryParse(calsController.text) ?? 0;
                  final p = int.tryParse(proteinController.text) ?? 0;
                  final c = int.tryParse(carbsController.text) ?? 0;
                  final f = int.tryParse(fatsController.text) ?? 0;
                  provider.addFoodLog(name, cals, p, c, f);
                  Navigator.pop(context);
                },
                child: const Text('Add Food'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
