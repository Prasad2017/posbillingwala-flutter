/**
 * Mechanical migration helper: common Material → App* widgets.
 * Conservative — skips complex multi-child button trees.
 */
const fs = require('fs');
const path = require('path');

const root = path.join(
  'd:',
  'Webus Labs',
  'POS BIllingwala',
  'pos_billingwala_v2',
  'lib',
  'features',
);

function walk(dir, out = []) {
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) walk(p, out);
    else if (ent.name.endsWith('.dart') && p.includes(`${path.sep}presentation${path.sep}`)) {
      out.push(p);
    }
  }
  return out;
}

function migrate(text) {
  let s = text;
  let n = 0;

  // Card( → AppCard( only when next non-ws is child: or margin:/color:/clipBehavior:
  // Too risky globally — convert Card(child: Padding(padding: const EdgeInsets.all(16), child: X))
  s = s.replace(
    /Card\(\s*child:\s*Padding\(\s*padding:\s*const EdgeInsets\.all\((\d+)\)\s*,\s*child:\s*/g,
    (m, pad) => {
      n++;
      return `AppCard(\n                          padding: const EdgeInsets.all(${pad}),\n                          child: `;
    },
  );
  // Close extra paren from removed Padding — hard; skip if unbalanced risk.
  // Revert Card→AppCard with Padding unwrap if we can't close — do simpler Card→AppCard only.
  // Actually the above leaves an extra `)` from Padding. Fix by removing one `)` before matching sibling commas is hard.
  // Safer: just Card( → AppCard( and accept default padding (may double-pad). Prefer:
  s = text; // reset — use safer transforms only
  n = 0;

  // Simple FilledButton / OutlinedButton with const Text child
  const btnRe =
    /(Filled|Elevated|Outlined)Button\(\s*onPressed:\s*([^,]+?),\s*child:\s*const Text\('([^']*)'\)\s*,?\s*\)/gs;
  s = s.replace(btnRe, (m, kind, onPressed, label) => {
    n++;
    const variant =
      kind === 'Outlined'
        ? ',\n            variant: AppButtonVariant.outlined'
        : '';
    return `AppButton(\n            label: '${label}',\n            onPressed: ${onPressed.trim()}${variant},\n            expanded: false,\n          )`;
  });

  // FilledButton.icon with const Icon + Text (no loading)
  const iconBtnRe =
    /FilledButton\.icon\(\s*onPressed:\s*([^,]+?),\s*icon:\s*const Icon\(([^)]+)\),\s*label:\s*(?:const )?Text\(\s*'([^']*)'\s*\),?\s*\)/gs;
  s = s.replace(iconBtnRe, (m, onPressed, icon, label) => {
    n++;
    return `AppButton(\n            label: '${label}',\n            icon: ${icon.trim()},\n            onPressed: ${onPressed.trim()},\n            expanded: false,\n          )`;
  });

  return { s, n };
}

const files = walk(root);
let total = 0;
const touched = [];
for (const f of files) {
  const before = fs.readFileSync(f, 'utf8');
  if (!before.includes('core/widgtes/widgtes.dart')) continue;
  const { s, n } = migrate(before);
  if (n > 0 && s !== before) {
    fs.writeFileSync(f, s);
    total += n;
    touched.push(`${path.relative(root, f)} (+${n})`);
  }
}
console.log(`Replacements: ${total}`);
touched.forEach((t) => console.log(t));
