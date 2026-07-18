const fs = require('fs');
const cheerio = require('cheerio');

const html = fs.readFileSync('personal_plan.html', 'utf8');
const $ = cheerio.load(html);

const program = {};
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
    'Seated Lateral Raise': {
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
    },
    'Leg Extension Machine': {
        setup: ['Adjust backrest so knees align with pivot point', 'Ankle pad resting just above shoelaces', 'Hold side handles firmly, pull yourself down', 'Toes pointed slightly up'],
        execution: ['Kick legs up until fully straight', 'Squeeze quads maximally for 1 second at top', 'Lower slowly over 3 seconds', 'Stop just before weight stack touches', 'Don\'t use momentum to kick up'],
        mistakes: ['✓ Quads burning deeply', '✗ Don\'t let hips lift off the seat', '✗ Don\'t drop the weight on the way down', '✗ Don\'t do half reps — fully straighten knees']
    },
    'Lying Leg Curl': {
        setup: ['Lie flat, knees just off the edge of pad', 'Ankle pad resting on back of calves/Achilles', 'Hold handles and pull body tight to bench', 'Toes neutral'],
        execution: ['Curl heels toward glutes as far as possible', 'Squeeze hamstrings hard for 1 second', 'Lower slowly over 3 seconds', 'Fully extend legs at the bottom for a deep stretch', 'Keep hips pressed into the pad'],
        mistakes: ['✓ Hamstrings doing all the work', '✗ Don\'t let hips pop up in the air', '✗ Don\'t swing the weight up', '✗ Don\'t skip the stretch at the bottom']
    },
    'Seated Calf Raise': {
        setup: ['Sit, balls of feet on platform, heels hanging off', 'Knee pads resting firmly on lower thighs', 'Release safety catch', 'Lower heels until deep stretch is felt'],
        execution: ['Drive through balls of feet to raise heels as high as possible', 'Squeeze calves hard at the top for 1 second', 'Lower slowly over 3 seconds into a deep stretch', 'Hold stretch for 1 second before next rep', 'Focus on full range of motion'],
        mistakes: ['✓ Calves burning, deep stretch at bottom', '✗ Don\'t bounce out of the bottom', '✗ Don\'t do fast, short reps', '✗ Don\'t use momentum']
    },
    'Hip Abductor Machine': {
        setup: ['Sit tall, back against pad', 'Outer knees pressed against pads', 'Select a moderate weight', 'Hold handles lightly'],
        execution: ['Push knees outward as wide as possible', 'Squeeze outer glutes at the widest point', 'Return slowly to start position', 'Keep tension, don\'t let weights rest'],
        mistakes: ['✓ Glutes and outer hips doing the work', '✗ Don\'t lean too far forward or back', '✗ Don\'t use momentum to swing weight', '✗ Don\'t let knees snap back together']
    },
    'Hip Adductor Machine': {
        setup: ['Sit tall, inner knees against pads', 'Start with pads wide enough for a good stretch', 'Hold handles for stability', 'Brace core'],
        execution: ['Squeeze knees together until pads touch', 'Hold the squeeze for 1 second', 'Open slowly to starting stretch', 'Control the eccentric phase'],
        mistakes: ['✓ Glutes and inner thighs doing the work', '✗ Don\'t let knees cave in — push them out', '✗ Don\'t round lower back', '✗ Don\'t let hips shoot up at the start']
    }
};

// Parse Program blocks
$('.workout-block').each((i, el) => {
    const $el = $(el);
    const wbTitle = $el.find('.wb-title').text().trim();
    const match = wbTitle.match(/([a-zA-Z]+)\s*—\s*(.*)/);
    if (!match) return;
    const day = match[1].trim();
    const name = match[2].trim();
    const typeTag = $el.find('.type-tag').text().trim();

    const key = name.toLowerCase().replace(/\s+/g, '-');
    const type = key.split('-')[0];

    const exercises = [];
    $el.find('.ex-table tbody tr').each((j, tr) => {
        const $tr = $(tr);
        const tds = $tr.find('td');
        if (tds.length < 5) return;

        const exName = $(tds[1]).find('strong').text().trim();
        const badge = $(tds[1]).find('.ex-badge').text().trim();
        const tip = $(tds[1]).find('.ex-note').text().trim();

        const setsReps = $(tds[2]).text().trim();
        const [setsStr, reps] = setsReps.split('×').map(s => s.trim());
        const sets = parseInt(setsStr);

        const restStr = $(tds[3]).text().trim();
        let rest = 0;
        if (restStr.includes('min')) {
            const num = parseInt(restStr.split('–')[0]) || parseInt(restStr);
            if (restStr.includes('3–4')) rest = 210;
            else if (restStr.includes('2–3')) rest = 150;
            else rest = num * 60;
        } else if (restStr.includes('sec')) {
            rest = parseInt(restStr);
        }

        exercises.push({ name: exName, sets, reps, rest, tip, badge });
    });

    program[key] = { name, type, day, subtitle: typeTag, exercises };
});

// Parse Form Guides
$('.meal-day').each((i, el) => {
    const $el = $(el);
    const title = $el.find('.meal-day-title').text().trim();
    if (!title || title.includes('Training Day') || title.includes('Rest Day')) return;

    let normalizedTitle = title;
    if (title === 'Pull-Up') normalizedTitle = 'Weighted Pull-Up';
    if (title === 'Cable Face Pull') normalizedTitle = 'Face Pull (Cable)';
    if (title === 'Romanian Deadlift (RDL)') normalizedTitle = 'Romanian Deadlift';

    const fg = { setup: [], execution: [], mistakes: [] };
    const cols = $el.find('.form-grid > div');
    if (cols.length === 3) {
        $(cols[0]).find('li').each((j, li) => fg.setup.push($(li).text().trim()));
        $(cols[1]).find('li').each((j, li) => fg.execution.push($(li).text().trim()));
        $(cols[2]).find('li').each((j, li) => fg.mistakes.push($(li).text().trim()));
        formGuides[normalizedTitle] = fg;
    }
});

module.exports = { program, formGuides };
