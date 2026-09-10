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
    .replace(/Savingâ€¦/g, 'Saving…')
    .replace(/â€™/g, "'");
}

let n = 0;
for (const f of walk(root)) {
  const before = fs.readFileSync(f, 'utf8');
  const after = fixEncoding(before);
  if (after !== before) {
    fs.writeFileSync(f, after);
    n++;
    console.log(path.relative(root, f));
  }
}
console.log('encoding fixed in', n, 'files');
