const fs = require('fs');

const indexHtml = fs.readFileSync('index.html', 'utf8');
const personalHtml = fs.readFileSync('personal_plan.html', 'utf8');

const programMatch = indexHtml.match(/const PROGRAM = ({[\s\S]*?});/);
let program = {};
if (programMatch) {
    eval('program = ' + programMatch[1]);
}

// Scrape form guides from HTML
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
    'Seated Lateral Raise': { // Or Dumbbell Lateral Raise
        setup: ['Stand, dumbbells at sides, palms inward', 'Slight forward lean (10–15°) — hits side delt more', 'Soft bend in elbows', 'Go lighter than you think you need'],
        execution: ['Raise arms out to sides — like pouring water', 'Lead with elbows, not hands', 'Stop when arms are parallel to floor (90°)', 'Lower slowly over 3 seconds', 'Don\'t rest at the bottom'],
        mistakes: ['✓ Burning on outer/top of shoulder', '✗ Don\'t shrug traps up', '✗ Don\'t swing or use momentum', '✗ Don\'t raise above parallel']
    },
    'Cable Lateral Raise': {
        setup: ['Stand, dumbbells at sides, palms inward', 'Slight forward lean (10–15°) — hits side delt more', 'Soft bend in elbows', 'Go lighter than you think you need'],
        execution: ['Raise arms out to sides — like pouring water', 'Lead with elbows, not hands', 'Stop when arms are parallel to floor (90°)', 'Lower slowly over 3 seconds', 'Don\'t rest at the bottom'],
        mistakes: ['✓ Burning on outer/top of shoulder', '✗ Don\'t shrug traps up', '✗ Don\'t swing or use momentum', '✗ Don\'t raise above parallel']
    },
    'Pec Deck / Pec Fly Machine': {
        setup: ['Adjust seat so handles are at chest height', 'Sit tall, back firmly against the pad', 'Grip handles, elbows slightly bent', 'Chest up, shoulders pulled back before starting'],
        execution: ['Bring handles together in a hugging arc', 'Squeeze chest hard when handles meet', 'Hold the squeeze for 1 full second', 'Open back slowly (3s) — feel the stretch', 'Don\'t slam the weight stack at the back'],
        mistakes: ['✓ Chest squeeze at centre, stretch at widest', '✗ Don\'t let shoulders roll forward', '✗ Don\'t use momentum — controlled always', '✗ Don\'t go so wide it stresses the shoulder']
    },
    'Barbell Bench Press': {
        setup: ['Lie flat on bench, eyes under bar', 'Feet planted firmly on the floor', 'Grip slightly wider than shoulder-width', 'Squeeze shoulder blades together and down'],
        execution: ['Unrack and hold bar directly over shoulders', 'Lower bar to mid-chest with control', 'Elbows tucked at ~45 degree angle', 'Press bar back up to starting position'],
        mistakes: ['✓ Chest and triceps doing the work', '✗ Don\'t let elbows flare out to 90 degrees', '✗ Don\'t bounce bar off chest', '✗ Don\'t lift glutes off the bench']
    },
    'Overhead Press (Barbell)': {
        setup: ['Stand with feet shoulder-width apart', 'Grip bar just outside shoulders', 'Bar rests on upper chest/clavicle', 'Brace core and squeeze glutes'],
        execution: ['Press bar straight up over head', 'Tuck chin slightly to let bar pass', 'Lock out elbows at the top', 'Lower under control to upper chest'],
        mistakes: ['✓ Shoulders and triceps engaged', '✗ Don\'t lean back excessively', '✗ Don\'t press forward, press straight up', '✗ Don\'t use leg drive']
    },
    'Weighted Pull-Up': {
        setup: ['Overhand grip, hands slightly wider than shoulders', 'Start from a dead hang — arms fully extended', 'Pull shoulder blades down and back first', 'Slight forward lean at the bottom'],
        execution: ['Think "pull elbows to hips" not "pull hands up"', 'Drive chest up toward the bar', 'Chin clears the bar = one rep', 'Lower slowly (3s) to full dead hang'],
        mistakes: ['✓ Feel lats (sides of back) — not just arms', '✗ Don\'t kip or use momentum', '✗ Don\'t half-rep — full hang every time', '✗ Can\'t do one yet? Use lat pulldown first']
    },
    'Seated Cable Row': {
        setup: ['Sit tall, feet on the platform', 'Slight forward lean to grab handle', 'Chest up, back flat before you pull', 'Use a V-handle or wide bar'],
        execution: ['Pull handle to your belly button', 'Lead with elbows — drive them back', 'Squeeze shoulder blades hard at the end', 'Return slowly, feel the stretch', 'Don\'t rock forward and back'],
        mistakes: ['✓ Squeeze between shoulder blades at end', '✗ Don\'t use body momentum to row', '✗ Don\'t shrug traps up', '✗ Don\'t let lower back round']
    },
    'Barbell Back Squat': {
        setup: ['Bar on upper traps, grip to pull it in tight', 'Feet shoulder-width, toes out 15–30°', 'Big breath into belly, brace core hard', 'Unrack and take 2 steps back only'],
        execution: ['Push knees out toward toes', 'Descend like sitting back into a chair', 'Break parallel — hip crease below knee', 'Drive through the whole foot to stand', 'Keep chest up throughout'],
        mistakes: ['✓ Quads and glutes working equally', '✗ Don\'t let knees cave inward', '✗ Don\'t squat to just parallel — go below', '✗ Don\'t rise on your toes']
    },
    'Sumo Deadlift': {
        setup: ['Wide stance — feet near the plates', 'Toes pointed out ~45°', 'Grip the bar inside your legs, narrow grip', 'Hips lower than conventional — more squat-like', 'Chest up, shins nearly vertical'],
        execution: ['Push knees out hard as you pull', 'Drive through heels, not toes', 'Bar stays close to body — drags up inner thighs', 'Lock out by squeezing glutes — stand tall', 'Lower with control, reset each rep'],
        mistakes: ['✓ Glutes and inner thighs doing the work', '✗ Don\'t let knees cave in — push them out', '✗ Don\'t round lower back', '✗ Don\'t let hips shoot up at the start']
    }
};

// Generate missing guides
const allExercises = [];
for (const routine of Object.values(program)) {
    for (const ex of routine.exercises) {
        if (!allExercises.includes(ex.name)) allExercises.push(ex.name);
    }
}

for (const name of allExercises) {
    if (!formGuides[name]) {
        let n = name.toLowerCase();
        let sg = {setup: [], execution: [], mistakes: []};
        if (n.includes('curl')) {
            sg = {
                setup: ['Stand tall or sit securely', 'Grip firmly, elbows tucked at sides'],
                execution: ['Curl weight up smoothly', 'Squeeze at the top contraction', 'Lower weight under control'],
                mistakes: ['✓ Biceps working', '✗ Don\'t use momentum or swing', '✗ Don\'t move elbows forward']
            };
        } else if (n.includes('row')) {
            sg = {
                setup: ['Brace core, maintain straight back', 'Grip firmly'],
                execution: ['Pull weight toward torso', 'Squeeze shoulder blades together', 'Lower with control'],
                mistakes: ['✓ Back muscles engaged', '✗ Don\'t jerk the weight', '✗ Don\'t round lower back']
            };
        } else if (n.includes('press') || n.includes('dip')) {
            sg = {
                setup: ['Plant feet firmly', 'Brace core and stabilize shoulders'],
                execution: ['Press weight smoothly', 'Lock out or nearly lock out at the end', 'Lower under control'],
                mistakes: ['✓ Target muscles working', '✗ Don\'t flare elbows excessively', '✗ Don\'t lose tension at bottom']
            };
        } else if (n.includes('extension') || n.includes('pushdown')) {
            sg = {
                setup: ['Stand tall or sit securely', 'Elbows tucked and stationary'],
                execution: ['Extend arms fully', 'Squeeze at the contraction', 'Return to start with control'],
                mistakes: ['✓ Triceps/Quads working', '✗ Don\'t use momentum', '✗ Don\'t move elbows/knees']
            };
        } else if (n.includes('raise')) {
            sg = {
                setup: ['Stand or sit tall', 'Slight bend in knees/elbows'],
                execution: ['Raise weight smoothly', 'Pause at the top', 'Lower under control'],
                mistakes: ['✓ Target muscles engaged', '✗ Don\'t swing the weight', '✗ Don\'t raise too high']
            };
        } else if (n.includes('leg') || n.includes('squat')) {
            sg = {
                setup: ['Plant feet securely', 'Brace core'],
                execution: ['Move through full range of motion', 'Keep knees tracking over toes', 'Return to start'],
                mistakes: ['✓ Leg muscles working', '✗ Don\'t let knees cave in', '✗ Don\'t lift heels']
            };
        } else if (n.includes('wheel') || n.includes('plank')) {
            sg = {
                setup: ['Engage core, straight back', 'Hands/elbows under shoulders'],
                execution: ['Hold position or roll out smoothly', 'Maintain core tension', 'Return to start without sagging'],
                mistakes: ['✓ Core working', '✗ Don\'t let lower back sag', '✗ Don\'t hold breath']
            };
        } else if (n.includes('pulldown')) {
            sg = {
                setup: ['Sit securely, feet flat', 'Grip firmly'],
                execution: ['Pull bar down to upper chest', 'Squeeze back muscles', 'Return to start slowly'],
                mistakes: ['✓ Lats engaged', '✗ Don\'t lean back excessively', '✗ Don\'t use momentum']
            };
        } else {
            sg = {
                setup: ['Set up securely and brace core', 'Use an appropriate weight'],
                execution: ['Perform movement smoothly', 'Focus on muscle contraction', 'Control the negative'],
                mistakes: ['✓ Target muscle engaged', '✗ Don\'t use momentum', '✗ Don\'t rush the reps']
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
console.log("seed_data.dart generated.");
