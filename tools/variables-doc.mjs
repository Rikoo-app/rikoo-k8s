/**
 * Writes `charts/rikoo/VARIABLES.md` from the contract shipped with the chart.
 *
 * An operator needs one place that answers "what may I set, and in which shape". The contract is
 * exact but it is JSON; this is the same facts as a table, sorted so the ones a deployment must
 * provide come first. Generated on purpose: a hand-written list of two hundred names drifts the week
 * after it is written.
 *
 * What it deliberately does NOT carry is what each variable DOES. That prose lives in the product's
 * variable manifest, in a language this repository does not use, and translating two hundred
 * descriptions is a piece of work of its own. Until then this file answers "may I set this, and how",
 * and the product documentation answers "should I".
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const CHART = join(ROOT, 'charts/rikoo');
export const OUTPUT = 'charts/rikoo/VARIABLES.md';

/** Names the chart sets itself, which an operator must not repeat in a settings map. */
function managedNames() {
  const helpers = readFileSync(join(CHART, 'templates/_helpers.tpl'), 'utf8');
  const block = helpers.split('define "rikoo.managedEnvNames"')[1]?.split('{{- end -}}')[0] ?? '';
  return new Set(block.split(/\s+/).filter((w) => /^[A-Z][A-Z0-9_]*$/.test(w)));
}

/** Where an operator sets a variable, from the services that read it. */
function surfaceOf(services, name, managed) {
  if (managed.has(name)) return 'a chart value';
  if (name.startsWith('RIKOO_FEATURE_')) return '`rikoo.features`';
  const both = services.some((s) => s === 'shared' || s === 'ee');
  const api = both || services.includes('api');
  const worker = both || services.includes('worker');
  if (api && worker) return '`rikoo.settings`';
  if (api) return '`rikoo.api.settings`';
  if (worker) return '`rikoo.worker.settings`';
  return '—';
}

export function render(contract) {
  const managed = managedNames();
  const rows = Object.entries(contract.variables).map(([name, spec]) => ({
    name,
    spec,
    surface: surfaceOf(spec.services, name, managed),
  }));
  const cell = (v) => (v === undefined || v === '' ? '' : `\`${v}\``);
  const table = (list) =>
    [
      '| Variable | Set through | Format | Default |',
      '| --- | --- | --- | --- |',
      ...list.map(
        ({ name, spec, surface }) =>
          `| \`${name}\` | ${surface} | ${cell(spec.values ? spec.values.join(' \\| ') : spec.format)} | ${cell(spec.default)} |`,
      ),
    ].join('\n');

  const required = rows.filter((r) => r.spec.required.includes('self-hosted') && !r.spec.secret);
  const secrets = rows.filter((r) => r.spec.secret);
  const optional = rows.filter(
    (r) => !r.spec.secret && !r.spec.required.includes('self-hosted'),
  );

  return `<!-- GENERATED from env-contract.json by tools/variables-doc.mjs. Do not edit by hand.
     Regenerate: make variables-doc. Verify: make contract-check. -->

# Environment variables

Every variable this version of Rikoo reads in a cluster, from \`env-contract.json\`, which the product
generates from its own manifest and ships inside this chart. ${rows.length} in total.

**Set through** says where it belongs. A variable the chart already models has a typed value of its
own, and setting it in a \`settings\` map is refused at render time: two sources for one name would
leave the winner to render order. The \`settings\` maps are checked against this same contract, so a
mistyped name is refused instead of silently doing nothing.

What each variable *does* is not described here. See the product's own documentation for that; this
file answers whether you may set something and in which shape.

## Required by a self-hosted deployment

${table(required)}

## Secrets

Never set these in a \`settings\` map or as a literal in \`additionalEnv\`: both are written in clear,
one into a ConfigMap and the other into a Deployment. Use the chart's own setting where there is one,
or \`additionalEnvFrom\` with a Secret.

${table(secrets)}

## Optional

${table(optional)}
`;
}

const contract = JSON.parse(readFileSync(join(CHART, 'env-contract.json'), 'utf8'));
const body = render(contract);
if (process.argv.includes('--check')) {
  const current = readFileSync(join(ROOT, OUTPUT), 'utf8');
  if (current !== body) {
    console.error(`✗ ${OUTPUT} is out of date — run: make variables-doc`);
    process.exit(1);
  }
  console.log(`✓ ${OUTPUT} matches the contract.`);
} else {
  writeFileSync(join(ROOT, OUTPUT), body);
  console.log(`✓ ${OUTPUT}`);
}
