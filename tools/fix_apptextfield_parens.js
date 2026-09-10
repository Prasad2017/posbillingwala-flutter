const fs = require('fs');
const path = require('path');

function fixExtraClosings(s) {
  // AppTextField( ... ),\n                  ),  → remove the orphan ),
  return s.replace(
    /(AppTextField\([\s\S]*?\),\s*)\n(\s*)\),/g,
    (m, field, indent) => {
      // Only strip if the next token after orphan is SizedBox/AppTextField/AppButton/const/Row/etc
      return `${field}`;
    },
  );
}

const files = [
  'd:/Webus Labs/POS BIllingwala/pos_billingwala_v2/lib/features/settings/presentation/settings_page.dart',
];

// Also scan presentation for the bad pattern
function walk(dir, out = []) {
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) walk(p, out);
    else if (p.includes(`${path.sep}presentation${path.sep}`) && p.endsWith('.dart')) out.push(p);
  }
  return out;
}

const root = 'd:/Webus Labs/POS BIllingwala/pos_billingwala_v2/lib/features';
for (const f of walk(root)) {
  const before = fs.readFileSync(f, 'utf8');
  if (!before.includes('AppTextField(')) continue;
  // Fix: after AppTextField closing `),` an immediate orphan `),` on its own line
  let s = before.replace(
    /(AppTextField\((?:[^()]|\([^()]*\))*\),\s*)\r?\n(\s+)\),/g,
    '$1\n',
  );
  // Broader multiline AppTextField with nested () limited - use iterative brace match
  s = before;
  const lines = s.split(/\r?\n/);
  const out = [];
  for (let i = 0; i < lines.length; i++) {
    out.push(lines[i]);
    // If previous pushed line ends AppTextField closing and next is only `),` with indent
    if (
      i + 1 < lines.length &&
      /^\s+\),?\s*$/.test(lines[i + 1]) &&
      /AppTextField\(/.test(lines.slice(Math.max(0, i - 12), i + 1).join('\n')) &&
      lines[i].trim() === '),'
    ) {
      // Check that between last AppTextField( and this ), we have a complete call
      const window = lines.slice(Math.max(0, i - 20), i + 1).join('\n');
      const opens = (window.match(/AppTextField\(/g) || []).length;
      if (opens > 0) {
        // skip the orphan next line
        i++;
      }
    }
  }
  const after = out.join('\n');
  if (after !== before) {
    fs.writeFileSync(f, after);
    console.log('fixed', path.relative(root, f));
  }
}
