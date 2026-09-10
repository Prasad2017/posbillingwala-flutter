const fs = require('fs');
const path = require('path');

const root = path.join(
  'd:/Webus Labs/POS BIllingwala/pos_billingwala_v2/lib/features',
);

function walk(dir, out = []) {
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) walk(p, out);
    else if (p.includes(`${path.sep}presentation${path.sep}`) && p.endsWith('.dart')) {
      out.push(p);
    }
  }
  return out;
}

function fixEncoding(s) {
  return s
    .replace(/Ã—/g, '×')
    .replace(/â‚¹/g, '₹')
    .replace(/â€¦/g, '…')
    .replace(/Savingâ€¦/g, 'Saving…');
}

function migrate(s) {
  let n = 0;
  // Card( → AppCard( when followed by child: ListTile or child: Column without Padding unwrap
  // Only plain Card( → AppCard( 
  const before = s;
  s = s.replace(/\bCard\(/g, () => {
    n++;
    return 'AppCard(';
  });

  // Simple FilledButton again
  s = s.replace(
    /(Filled|Elevated|Outlined)Button\(\s*onPressed:\s*([^,]+?),\s*child:\s*const Text\('([^']*)'\)\s*,?\s*\)/gs,
    (m, kind, onPressed, label) => {
      n++;
      const variant =
        kind === 'Outlined'
          ? ',\n            variant: AppButtonVariant.outlined'
          : '';
      return `AppButton(\n            label: '${label}',\n            onPressed: ${onPressed.trim()}${variant},\n            expanded: false,\n          )`;
    },
  );

  return { s: fixEncoding(s), n: n + (s !== before && n === 0 ? 0 : 0), changed: s !== before };
}

let totalFiles = 0;
for (const f of walk(root)) {
  const before = fs.readFileSync(f, 'utf8');
  if (!before.includes('core/widgtes/widgtes.dart')) continue;
  const { s, changed } = migrate(before);
  if (changed) {
    fs.writeFileSync(f, s);
    totalFiles++;
    console.log('updated', path.relative(root, f));
  }
}
console.log('files updated', totalFiles);
