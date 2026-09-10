const fs = require('fs');

const file =
  'd:/Webus Labs/POS BIllingwala/pos_billingwala_v2/lib/features/settings/presentation/settings_page.dart';
let s = fs.readFileSync(file, 'utf8');

// Pattern produced by bad migration:
//   AppTextField(
//   controller: ...
//   label: ...,
// ),
//   ),   <-- orphan
s = s.replace(
  /(AppTextField\(\s*\n(?:[ \t]*[a-zA-Z_][\w:]*[\s\S]*?)*?[ \t]*\),)\s*\n[ \t]+\),/g,
  '$1',
);

fs.writeFileSync(file, s);
console.log('settings_page paren fix done');
