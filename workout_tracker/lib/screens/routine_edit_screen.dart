import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers.dart';
import '../theme.dart';

class RoutineEditScreen extends StatefulWidget {
  final RoutineModel routine;

  const RoutineEditScreen({super.key, required this.routine});

  @override
  State<RoutineEditScreen> createState() => _RoutineEditScreenState();
}

class _RoutineEditScreenState extends State<RoutineEditScreen> {
  late List<RoutineExerciseModel> _exercises;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.routine.exercises);
    _nameController = TextEditingController(text: widget.routine.name);
  }

  void _saveRoutine() {
    final updatedRoutine = RoutineModel(
      id: widget.routine.id,
      name: _nameController.text.trim(),
      type: widget.routine.type,
      day: widget.routine.day,
      subtitle: widget.routine.subtitle,
      exercises: _exercises,
    );

    context.read<WorkoutProvider>().updateRoutine(updatedRoutine);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Routine Updated')),
    );
  }

  void _editExercise(int index) {
    final ex = _exercises[index];
    final nameCtrl = TextEditingController(text: ex.name);
    final setsCtrl = TextEditingController(text: ex.sets.toString());
    final repsCtrl = TextEditingController(text: ex.reps);
    final restCtrl = TextEditingController(text: ex.restSeconds.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Exercise'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: setsCtrl, decoration: const InputDecoration(labelText: 'Sets'), keyboardType: TextInputType.number),
              TextField(controller: repsCtrl, decoration: const InputDecoration(labelText: 'Reps (e.g., 8-10)')),
              TextField(controller: restCtrl, decoration: const InputDecoration(labelText: 'Rest (seconds)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _exercises[index] = RoutineExerciseModel(
                  name: nameCtrl.text.trim(),
                  sets: int.tryParse(setsCtrl.text) ?? ex.sets,
                  reps: repsCtrl.text.trim(),
                  restSeconds: int.tryParse(restCtrl.text) ?? ex.restSeconds,
                  tip: ex.tip,
                  badge: ex.badge,
                  setup: ex.setup,
                  execution: ex.execution,
                  mistakes: ex.mistakes,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Routine'),
        actions: [
          TextButton(
            onPressed: _saveRoutine,
            child: const Text('SAVE', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Routine Name'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _exercises.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _exercises.removeAt(oldIndex);
                    _exercises.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final ex = _exercises[index];
                  return Card(
                    key: ValueKey(ex.name + index.toString()),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(ex.name),
                      subtitle: Text('${ex.sets} sets x ${ex.reps} | Rest: ${ex.restSeconds}s'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppTheme.accent2),
                            onPressed: () => _editExercise(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppTheme.push),
                            onPressed: () {
                              setState(() {
                                _exercises.removeAt(index);
                              });
                            },
                          ),
                          const Icon(Icons.drag_handle, color: AppTheme.muted),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _exercises.add(RoutineExerciseModel(
              name: 'New Exercise',
              sets: 3,
              reps: '10',
              restSeconds: 90,
              tip: '',
              badge: 'Accessory',
              setup: [],
              execution: [],
              mistakes: [],
            ));
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
