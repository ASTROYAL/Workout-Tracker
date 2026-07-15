const fs = require('fs');

const indexHtml = fs.readFileSync('index.html', 'utf8');
const personalHtml = fs.readFileSync('personal_plan.html', 'utf8');

// I can extract the PROGRAM data from index.html using regex or simple parsing
const programMatch = indexHtml.match(/const PROGRAM = ({[\s\S]*?});/);
let program = {};
if (programMatch) {
    // evaluate the object
    eval('program = ' + programMatch[1]);
    console.log("Program extracted:", Object.keys(program));
}

// I can also extract the form guides from personal_plan.html
const formGuides = [];
// This is just to check if we can parse it
