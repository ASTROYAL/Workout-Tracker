const fs = require('fs');

const indexHtml = fs.readFileSync('index.html', 'utf8');
const personalHtml = fs.readFileSync('personal_plan.html', 'utf8');

const programMatch = indexHtml.match(/const PROGRAM = ({[\s\S]*?});/);
let program = {};
if (programMatch) {
    eval('program = ' + programMatch[1]);
}

// Map of exercise names to form guides
const formGuides = {
    'Conventional Deadlift': {
        setup: ['Feet hip-width, bar over mid-foot', 'Hinge down, grip just outside legs', 'Shins vertical, hips above knees', 'Chest up, back flat — "proud chest"', 'Big breath, brace core maximally'],
        execution: ['"Push the floor away" — not "pull up"', 'Bar drags up your shins and thighs', 'Hips and shoulders rise at the same rate', 'Lock out: stand tall, squeeze glutes hard', 'Hinge back down — don\'t drop the bar'],
        mistakes: ['✓ Hamstrings and glutes loading, back tight', '✗ Don\'t round your lower back — ever', '✗ Don\'t let bar drift away from body', '✗ Don\'t jerk — build tension first, then pull']
    },
    'Romanian Deadlift': {
        setup: ['Start standing, bar at hip level', 'Feet hip-width, soft bend in knees', 'Shoulder blades back and down', 'This is a hinge — move hips back'],
        execution: ['Push hips back — bar drags down thighs', 'Lower until you feel a deep hamstring stretch', 'Stop at your flexibility — don\'t force it', 'Drive hips forward to stand, squeeze glutes'],
        mistakes: ['✓ Deep stretch in back of thighs', '✗ Don\'t bend knees too much — becomes a squat', '✗ Don\'t round lower back to reach lower', '✗ Don\'t let bar drift away from legs']
    },
    'Bulgarian Split Squat': {
        setup: ['Rear foot elevated on bench, laces down', 'Front foot far enough that shin stays vertical', 'Start with hands on hips — learn balance first', 'Stand tall, core braced'],
        execution: ['Lower straight down — don\'t lunge forward', 'Front knee tracks over toes, not caving in', 'Rear knee drops toward floor', 'Drive through front heel to return', 'All reps one side, then switch'],
        mistakes: ['✓ Front quad and glute doing the work', '✗ Don\'t lean too far forward', '✗ Don\'t add weight until balance is solid', '✗ Bodyweight only for the first 2 weeks']
    },
    'Face Pull (Cable)': {
        setup: ['Cable at face height or above', 'Rope attachment, thumbs pointing toward you', 'Step back so cable is taut with arms extended', 'Light weight — this is a health exercise'],
        execution: ['Pull rope toward forehead, splitting it apart', 'Elbows flare out to sides at shoulder height', 'At the end: externally rotate — hands by ears', 'Hold 1 second, squeeze rear delts', 'Return slowly, repeat'],
        mistakes: ['✓ Back of shoulder (rear delt) squeezing', '✗ Don\'t pull to your chin — aim for forehead', '✗ Don\'t use heavy weight or momentum', '✗ Don\'t skip — protects shoulder health']
    },
    'Bicep Curl Machine': {
        setup: ['Adjust seat so upper arms rest flat on pad', 'Elbows aligned with the machine\'s pivot point', 'Grip the handles — palms facing up', 'Sit tall, no slouching'],
        execution: ['Curl all the way up — full contraction', 'Squeeze hard for 1 second at the top', 'Lower slowly over 3 full seconds', 'Arms fully extended at the bottom — full stretch', 'No momentum — the pad locks you in'],
        mistakes: ['✓ Bicep burning — full squeeze at top', '✗ Don\'t let elbows lift off the pad', '✗ Don\'t rush the negative — 3s down always', '✗ Don\'t use a weight you can\'t fully control']
    },
    'Dumbbell Lateral Raise': {
        setup: ['Stand, dumbbells at sides, palms inward', 'Slight forward lean (10–15°) — hits side delt more', 'Soft bend in elbows', 'Go lighter than you think you need'],
        execution: ['Raise arms out to sides — like pouring water', 'Lead with elbows, not hands', 'Stop when arms are parallel to floor (90°)', 'Lower slowly over 3 seconds', 'Don\'t rest at the bottom'],
        mistakes: ['✓ Burning on outer/top of shoulder', '✗ Don\'t shrug traps up', '✗ Don\'t swing or use momentum', '✗ Don\'t raise above parallel']
    },
    'Pec Deck / Pec Fly Machine': {
        setup: ['Adjust seat so handles are at chest height', 'Sit tall, back firmly against the pad', 'Grip handles, elbows slightly bent', 'Chest up, shoulders pulled back before starting'],
        execution: ['Bring handles together in a hugging arc', 'Squeeze chest hard when handles meet', 'Hold the squeeze for 1 full second', 'Open back slowly (3s) — feel the stretch', 'Don\'t slam the weight stack at the back'],
        mistakes: ['✓ Chest squeeze at centre, stretch at widest', '✗ Don\'t let shoulders roll forward', '✗ Don\'t use momentum — controlled always', '✗ Don\'t go so wide it stresses the shoulder']
    }
};

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
            if (name.includes('Lateral Raise')) fg = formGuides['Dumbbell Lateral Raise'];
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
