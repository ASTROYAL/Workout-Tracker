const fs = require('fs');
const { program, formGuides } = require('./shared_data');

// Generate missing guides
const allExercises = new Set();
for (const routine of Object.values(program)) {
    for (const ex of routine.exercises) {
        allExercises.add(ex.name);
    }
}

for (const name of allExercises) {
    if (!formGuides[name]) {
        let n = name.toLowerCase();
        let sg = {setup: [], execution: [], mistakes: []};
        if (n.includes('curl')) {
            sg = {
                setup: ['Stand or sit tall', 'Grip handles firmly', 'Elbows locked at sides'],
                execution: ['Curl weight up fully', 'Squeeze at the top', 'Lower under control'],
                mistakes: ['✓ Feel the bicep working', '✗ Don\'t swing', '✗ Don\'t use momentum']
            };
        } else if (n.includes('press')) {
            sg = {
                setup: ['Brace core', 'Grip firmly', 'Set shoulders down and back'],
                execution: ['Press weight smoothly', 'Lock out at the top', 'Lower with control'],
                mistakes: ['✓ Target muscle engaged', '✗ Don\'t flare elbows', '✗ Don\'t lose tension']
            };
        } else {
            sg = {
                setup: ['Set up in a stable position', 'Brace your core'],
                execution: ['Perform movement with control', 'Focus on the target muscle'],
                mistakes: ['✓ Full range of motion', '✗ Don\'t use momentum']
            };
        }
        formGuides[name] = sg;
    }
}

let dartCode = `// GENERATED CODE - DO NOT MODIFY BY HAND
import 'models.dart';

final Map<String, RoutineModel> seedRoutines = {\n`;

for (const [key, routine] of Object.entries(program)) {
    dartCode += `  '${key}': RoutineModel(\n`;
    dartCode += `    id: '${key}',\n`;
    dartCode += `    name: '${routine.name.replace(/'/g, "\\'")}',\n`;
    dartCode += `    type: '${routine.type}',\n`;
    dartCode += `    day: '${routine.day}',\n`;
    dartCode += `    subtitle: '${routine.subtitle.replace(/'/g, "\\'")}',\n`;
    dartCode += `    exercises: [\n`;

    for (const ex of routine.exercises) {
        let name = ex.name;
        let fg = formGuides[name];

        dartCode += `      RoutineExerciseModel(\n`;
        dartCode += `        name: '${name.replace(/'/g, "\\'")}',\n`;
        dartCode += `        sets: ${ex.sets},\n`;
        dartCode += `        reps: '${ex.reps.replace(/'/g, "\\'")}',\n`;
        dartCode += `        restSeconds: ${ex.rest},\n`;
        dartCode += `        tip: '${ex.tip.replace(/'/g, "\\'")}',\n`;
        dartCode += `        badge: '${ex.badge}',\n`;
        dartCode += `        setup: [${fg.setup.map(s => `'${s.replace(/'/g, "\\'")}'`).join(', ')}],\n`;
        dartCode += `        execution: [${fg.execution.map(s => `'${s.replace(/'/g, "\\'")}'`).join(', ')}],\n`;
        dartCode += `        mistakes: [${fg.mistakes.map(s => `'${s.replace(/'/g, "\\'")}'`).join(', ')}],\n`;
        dartCode += `      ),\n`;
    }

    dartCode += `    ],\n`;
    dartCode += `  ),\n`;
}

dartCode += `};\n`;

fs.writeFileSync('workout_tracker/lib/seed_data.dart', dartCode);
console.log('seed_data.dart generated.');
