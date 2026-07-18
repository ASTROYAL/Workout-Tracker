const fs = require('fs');
const { program } = require('./shared_data');

let indexHtml = fs.readFileSync('index.html', 'utf8');

const programJson = JSON.stringify(program, null, 2);
indexHtml = indexHtml.replace(/const PROGRAM = \{[\s\S]*?\};/, `const PROGRAM = ${programJson};`);

fs.writeFileSync('index.html', indexHtml);
console.log('index.html updated with PROGRAM from personal_plan.html');
