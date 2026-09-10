const fs = require('fs');
const path = require('path');

const root = 'd:/Webus Labs/POS BIllingwala/pos_billingwala_v2/lib/features';

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

let n = 0;
for (const f of walk(root)) {
  const before = fs.readFileSync(f, 'utf8');
  const after = before
    .replace(
      /(AppTextField\(\s*\n(?:[ \t]*[a-zA-Z_][\w:]*[\s\S]*?)*?[ \t]*\),)\s*\n[ \t]+\),/g,
      '$1',
    )
    .replace(/Ã—/g, '×')
    .replace(/â‚¹/g, '₹')
    .replace(/â€¦/g, '…');
  if (after !== before) {
    fs.writeFileSync(f, after);
    n++;
    console.log('fixed', path.relative(root, f));
  }
}
console.log('files fixed', n);
