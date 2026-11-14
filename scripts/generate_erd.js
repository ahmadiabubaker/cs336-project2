// Generate an initial editable Draw.io layout from a checked description of
// the final SQL schema. The submitted .drawio was manually refined after this
// initial layout; do not overwrite it by running this script.
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const tables = [
  { n: 'agency', x: 3940, y: 120, w: 280, pk: ['agency_code'], f: ['agency_code', 'agency_name', 'agency_abbr'] },
  { n: 'respondent', x: 3300, y: 120, w: 310, pk: ['agency_code', 'respondent_id'], fk: ['agency_code'], f: ['agency_code', 'respondent_id'], weak: true },
  { n: 'loan_type', x: 120, y: 180, w: 310, pk: ['loan_type'], f: ['loan_type', 'loan_type_name'] },
  { n: 'property_type', x: 120, y: 325, w: 310, pk: ['property_type'], f: ['property_type', 'property_type_name'] },
  { n: 'loan_purpose', x: 120, y: 470, w: 310, pk: ['loan_purpose'], f: ['loan_purpose', 'loan_purpose_name'] },
  { n: 'owner_occupancy', x: 120, y: 615, w: 310, pk: ['owner_occupancy'], f: ['owner_occupancy', 'owner_occupancy_name'] },
  { n: 'preapproval', x: 120, y: 760, w: 310, pk: ['preapproval'], f: ['preapproval', 'preapproval_name'] },
  { n: 'action_taken', x: 120, y: 905, w: 310, pk: ['action_taken'], f: ['action_taken', 'action_taken_name'] },
  { n: 'purchaser_type', x: 120, y: 1050, w: 310, pk: ['purchaser_type'], f: ['purchaser_type', 'purchaser_type_name'] },
  { n: 'hoepa_status', x: 120, y: 1195, w: 310, pk: ['hoepa_status'], f: ['hoepa_status', 'hoepa_status_name'] },
  { n: 'lien_status', x: 120, y: 1340, w: 310, pk: ['lien_status'], f: ['lien_status', 'lien_status_name'] },
  { n: 'edit_status', x: 120, y: 1485, w: 310, pk: ['edit_status'], f: ['edit_status', 'edit_status_name'] },
  { n: 'application', x: 2190, y: 590, w: 385, pk: ['application_id'], fk: ['agency_code', 'respondent_id', 'loan_type', 'property_type', 'loan_purpose', 'owner_occupancy', 'preapproval', 'action_taken', 'location_id', 'applicant_ethnicity', 'co_applicant_ethnicity', 'applicant_sex', 'co_applicant_sex', 'purchaser_type', 'hoepa_status', 'lien_status', 'edit_status'], f: ['application_id', 'as_of_year', 'agency_code', 'respondent_id', 'loan_type', 'property_type', 'loan_purpose', 'owner_occupancy', 'loan_amount_000s', 'preapproval', 'action_taken', 'location_id', 'applicant_ethnicity', 'co_applicant_ethnicity', 'applicant_sex', 'co_applicant_sex', 'applicant_income_000s', 'purchaser_type', 'rate_spread', 'hoepa_status', 'lien_status', 'edit_status', 'application_date_indicator'] },
  { n: 'ethnicity', x: 3330, y: 430, w: 310, pk: ['ethnicity_code'], f: ['ethnicity_code', 'ethnicity_name'] },
  { n: 'sex', x: 4090, y: 430, w: 280, pk: ['sex_code'], f: ['sex_code', 'sex_name'] },
  { n: 'location', x: 3260, y: 930, w: 380, pk: ['location_id'], fk: ['county_code', 'msamd', 'state_code'], f: ['location_id', 'county_code', 'msamd', 'state_code', 'census_tract_number', 'population', 'minority_population', 'hud_median_family_income', 'tract_to_msamd_income', 'number_of_owner_occupied_units', 'number_of_1_to_4_family_units'] },
  { n: 'county', x: 4160, y: 920, w: 305, pk: ['state_code', 'county_code'], fk: ['state_code'], f: ['state_code', 'county_code', 'county_name'], weak: true },
  { n: 'state', x: 5010, y: 870, w: 300, pk: ['state_code'], f: ['state_code', 'state_name', 'state_abbr'] },
  { n: 'msamd', x: 4590, y: 1390, w: 300, pk: ['msamd'], f: ['msamd', 'msamd_name'] },
  { n: 'applicant_race', x: 1950, y: 2020, w: 325, pk: ['application_id', 'race_number'], fk: ['application_id', 'race_code'], f: ['application_id', 'race_number', 'race_code'], weak: true },
  { n: 'co_applicant_race', x: 2590, y: 2020, w: 345, pk: ['application_id', 'race_number'], fk: ['application_id', 'race_code'], f: ['application_id', 'race_number', 'race_code'], weak: true },
  { n: 'application_denial_reason', x: 3390, y: 2020, w: 395, pk: ['application_id', 'reason_number'], fk: ['application_id', 'denial_reason_code'], f: ['application_id', 'reason_number', 'denial_reason_code'], weak: true },
  { n: 'race', x: 2410, y: 2580, w: 285, pk: ['race_code'], f: ['race_code', 'race_name'] },
  { n: 'denial_reason', x: 3860, y: 2580, w: 330, pk: ['denial_reason_code'], f: ['denial_reason_code', 'denial_reason_name'] },
];

// Check every pictured persistent relation and attribute against the SQL before
// emitting a diagram. Intermediate Step 2 tables are intentionally excluded.
const sql = ['02_normalize_names.sql', '03_normalize_full.sql']
  .map(file => fs.readFileSync(path.join(root, file), 'utf8')).join('\n');
const declared = new Map();
for (const match of sql.matchAll(/CREATE TABLE ([a-z_]+) \(([\s\S]*?)\n\);/g)) {
  const fields = [...match[2].matchAll(/^    ([a-z][a-z0-9_]*) (?:integer|smallint|text|numeric)\b/gm)]
    .map(m => m[1]);
  declared.set(match[1], fields);
}
const finals = [...declared.keys()].filter(n => !n.endsWith('_step2'));
const pictured = tables.map(t => t.n);
if (new Set(pictured).size !== pictured.length ||
    finals.length !== pictured.length ||
    finals.some(n => !pictured.includes(n))) {
  throw new Error(`Table mismatch: SQL=${finals.join(', ')}; ERD=${pictured.join(', ')}`);
}
for (const t of tables) {
  if (JSON.stringify(t.f) !== JSON.stringify(declared.get(t.n))) {
    throw new Error(`Column mismatch in ${t.n}: SQL=${declared.get(t.n)}; ERD=${t.f}`);
  }
  for (const key of [...(t.pk || []), ...(t.fk || [])]) {
    if (!t.f.includes(key)) throw new Error(`Missing key field ${t.n}.${key}`);
  }
}

// Relationship positions follow the class's table + diamond notation. Each
// parent end is "one", each referencing/child end is "many". Optional foreign
// keys are called out in the legend rather than hidden in the cardinality marks.
const rels = [
  ['loan_type', 'application', 'loan type', 1440, 195],
  ['property_type', 'application', 'property type', 1440, 340],
  ['loan_purpose', 'application', 'loan purpose', 1440, 485],
  ['owner_occupancy', 'application', 'occupancy', 1440, 630],
  ['preapproval', 'application', 'preapproval', 1440, 775],
  ['action_taken', 'application', 'action taken', 1440, 920],
  ['purchaser_type', 'application', 'purchaser type', 1440, 1065],
  ['hoepa_status', 'application', 'HOEPA status', 1440, 1210],
  ['lien_status', 'application', 'lien status', 1440, 1355],
  ['edit_status', 'application', 'edit status', 1440, 1500],
  ['agency', 'respondent', 'reports to', 3770, 140],
  ['respondent', 'application', 'files', 2840, 175],
  ['ethnicity', 'application', 'applicant ethnicity', 2940, 465],
  ['ethnicity', 'application', 'co-applicant ethnicity', 2940, 585],
  ['sex', 'application', 'applicant sex', 3800, 595],
  ['sex', 'application', 'co-applicant sex', 3800, 725],
  ['location', 'application', 'located at', 2880, 1110],
  ['state', 'county', 'has county', 4740, 920],
  ['state', 'location', 'in state', 4760, 1160],
  ['county', 'location', 'in county', 3860, 990],
  ['msamd', 'location', 'in MSA/MD', 4260, 1380],
  ['application', 'applicant_race', 'applicant races', 2090, 1650],
  ['application', 'co_applicant_race', 'co-applicant races', 2650, 1650],
  ['application', 'application_denial_reason', 'denial reasons', 3100, 1650],
  ['race', 'applicant_race', 'race code', 2120, 2350],
  ['race', 'co_applicant_race', 'race code', 2690, 2350],
  ['denial_reason', 'application_denial_reason', 'reason code', 3900, 2350],
];
for (const [parent, child] of rels) {
  if (!pictured.includes(parent) || !pictured.includes(child)) throw new Error(`Bad relationship ${parent} -> ${child}`);
}

const esc = value => String(value).replace(/&/g, '&amp;').replace(/</g, '&lt;')
  .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const cell = (id, attrs, geo) => `        <mxCell id="${id}" ${attrs}><mxGeometry ${geo} as="geometry" /></mxCell>`;
const out = [];
out.push('<?xml version="1.0" encoding="UTF-8"?>');
out.push('<mxfile host="app.diagrams.net" version="24.7.17">');
out.push('  <diagram id="cs336-p2" name="Project 2 Final ERD">');
out.push('    <mxGraphModel dx="5600" dy="2930" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="5500" pageHeight="2920" background="#ffffff" math="0" shadow="0">');
out.push('      <root>');
out.push('        <mxCell id="0" />');
out.push('        <mxCell id="1" parent="0" />');
out.push(cell('title', 'parent="1" style="text;html=1;align=left;verticalAlign=middle;strokeColor=none;fillColor=none;fontSize=30;fontStyle=1;" value="CS336 Project 2 — Final normalized ER diagram" vertex="1"', 'x="120" y="45" width="1100" height="55"'));
out.push(cell('legend', 'parent="1" style="text;html=1;align=left;verticalAlign=middle;strokeColor=none;fillColor=none;fontSize=15;" value="Underlined = primary key; (FK) = foreign key; dashed box = identifying/composite-key entity; crow’s foot = many. Optional FK: application.edit_status, location.county_code, location.msamd." vertex="1"', 'x="120" y="105" width="2600" height="35"'));
for (const t of tables) {
  const h = 32 + t.f.length * 26;
  const style = 'swimlane;fontStyle=1;childLayout=stackLayout;horizontal=1;startSize=32;horizontalStack=0;resizeParent=1;resizeParentMax=0;resizeLast=0;collapsible=0;marginBottom=0;html=1;fillColor=#ffffff;strokeColor=#000000;strokeWidth=1.5;fontSize=14;swimlaneFillColor=#ffffff;' + (t.weak ? 'dashed=1;dashPattern=8 4;' : '');
  out.push(cell(t.n, `parent="1" style="${style}" value="${t.n.toUpperCase()}" vertex="1"`, `x="${t.x}" y="${t.y}" width="${t.w}" height="${h}"`));
  t.f.forEach((field, i) => {
    const pk = t.pk.includes(field);
    const fk = (t.fk || []).includes(field);
    const label = `${pk ? '<u>' : ''}${field}${pk ? '</u>' : ''}${fk ? ' (FK)' : ''}`;
    out.push(cell(`${t.n}_${i}`, `parent="${t.n}" style="text;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;spacingLeft=10;html=1;fontSize=13;" value="${esc(label)}" vertex="1"`, `y="${32 + 26 * i}" width="${t.w}" height="26"`));
  });
}
rels.forEach(([parent, child, label, x, y], i) => {
  const id = `rel_${i + 1}`;
  const dash = ['respondent', 'county', 'applicant_race', 'co_applicant_race', 'application_denial_reason'].includes(child);
  const style = 'rhombus;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#000000;strokeWidth=1.5;fontSize=12;' + (dash ? 'dashed=1;dashPattern=8 4;' : '');
  out.push(cell(id, `parent="1" style="${style}" value="${esc(label)}" vertex="1"`, `x="${x}" y="${y}" width="145" height="64"`));
  const base = 'edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;startFill=0;endFill=0;startSize=14;endSize=14;strokeColor=#000000;strokeWidth=1.2;';
  let parentAnchor, childAnchor;
  if (i <= 9) {
    parentAnchor = 'exitX=1;exitY=0.5;entryX=0;entryY=0.5;';
    childAnchor = `exitX=1;exitY=0.5;entryX=0;entryY=${(0.06 + i * 0.095).toFixed(3)};`;
  } else if (i === 10) {
    parentAnchor = 'exitX=0;exitY=0.5;entryX=1;entryY=0.5;';
    childAnchor = 'exitX=0;exitY=0.5;entryX=1;entryY=0.5;';
  } else if (i === 11) {
    parentAnchor = 'exitX=0.5;exitY=1;entryX=0.5;entryY=0;';
    childAnchor = 'exitX=0.5;exitY=1;entryX=0.8;entryY=0;';
  } else if (i >= 12 && i <= 15) {
    parentAnchor = 'exitX=0;exitY=0.5;entryX=1;entryY=0.5;';
    const entryY = [0.13, 0.2, 0.28, 0.35][i - 12];
    childAnchor = `exitX=0;exitY=0.5;entryX=1;entryY=${entryY};`;
  } else if (i === 16) {
    parentAnchor = 'exitX=0;exitY=0.5;entryX=1;entryY=0.5;';
    childAnchor = 'exitX=0;exitY=0.5;entryX=1;entryY=0.79;';
  } else if (i === 17 || i === 19 || i === 20) {
    parentAnchor = 'exitX=0;exitY=0.5;entryX=1;entryY=0.5;';
    childAnchor = `exitX=0;exitY=0.5;entryX=1;entryY=${i === 19 ? 0.35 : i === 20 ? 0.85 : 0.5};`;
  } else if (i === 18) {
    parentAnchor = 'exitX=0.5;exitY=1;entryX=0.5;entryY=0;';
    childAnchor = 'exitX=0;exitY=0.5;entryX=1;entryY=0.5;';
  } else if (i >= 21 && i <= 23) {
    parentAnchor = `exitX=${[0.2, 0.5, 0.8][i - 21]};exitY=1;entryX=0.5;entryY=0;`;
    childAnchor = 'exitX=0.5;exitY=1;entryX=0.5;entryY=0;';
  } else {
    parentAnchor = 'exitX=0.5;exitY=0;entryX=0.5;entryY=1;';
    childAnchor = 'exitX=0.5;exitY=0;entryX=0.5;entryY=1;';
  }
  out.push(cell(`${id}_parent`, `edge="1" parent="1" source="${parent}" target="${id}" style="${base}startArrow=ERone;endArrow=none;${parentAnchor}"`, 'relative="1"'));
  out.push(cell(`${id}_child`, `edge="1" parent="1" source="${id}" target="${child}" style="${base}startArrow=none;endArrow=ERmany;${childAnchor}"`, 'relative="1"'));
});
out.push('      </root>');
out.push('    </mxGraphModel>');
out.push('  </diagram>');
out.push('</mxfile>');
const target = path.join(root, 'CS336_Project2_Generated_Draft_ERD.drawio');
fs.writeFileSync(target, out.join('\n') + '\n', 'utf8');
console.log(`Wrote ${target}: ${tables.length} tables, ${rels.length} relationships.`);
