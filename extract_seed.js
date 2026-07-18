const fs = require('fs');
const { program, formGuides } = require('./shared_data');

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
        let fg = formGuides[name] || null;
        if (!fg) {
            if (name.includes('Lateral Raise')) fg = formGuides['Dumbbell Lateral Raise'] || formGuides['Cable Lateral Raise'] || formGuides['Seated Lateral Raise'];
            if (name.includes('Face Pull')) fg = formGuides['Face Pull (Cable)'];
            if (name.includes('Pec') && name.includes('Fly')) fg = formGuides['Pec Deck / Pec Fly Machine'];
            if (name.includes('Curl') && name.includes('Machine')) fg = formGuides['Bicep Curl Machine'];
        }

        dartCode += `      RoutineExerciseModel(\n`;
        dartCode += `        name: '${name.replace(/'/g, "\\'")}',\n`;
        dartCode += `        sets: ${ex.sets},\n`;
        dartCode += `        reps: '${ex.reps.replace(/'/g, "\\'")}',\n`;
        dartCode += `        restSeconds: ${ex.rest},\n`;
        dartCode += `        tip: '${ex.tip.replace(/'/g, "\\'")}',\n`;
        dartCode += `        badge: '${ex.badge}',\n`;

        if (fg) {
            dartCode += `        setup: [${fg.setup.map(s => `'${s.replace(/'/g, "\\'")}'`).join(', ')}],\n`;
            dartCode += `        execution: [${fg.execution.map(s => `'${s.replace(/'/g, "\\'")}'`).join(', ')}],\n`;
            dartCode += `        mistakes: [${fg.mistakes.map(s => `'${s.replace(/'/g, "\\'")}'`).join(', ')}],\n`;
        } else {
            dartCode += `        setup: [],\n`;
            dartCode += `        execution: [],\n`;
            dartCode += `        mistakes: [],\n`;
        }
        dartCode += `      ),\n`;
    }

    dartCode += `    ],\n`;
    dartCode += `  ),\n`;
}

dartCode += `};\n`;

fs.writeFileSync('workout_tracker/lib/seed_data.dart', dartCode);
console.log('seed_data.dart generated.');
