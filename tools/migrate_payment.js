const fs = require('fs');
const path = 'd:/Webus Labs/POS BIllingwala/pos_billingwala_v2/lib/features/pos/presentation/payment_page.dart';
let s = fs.readFileSync(path, 'utf8');

// Customer TextFields → AppTextField (if still present)
s = s.replace(
  /TextField\(\s*controller: _customerNameController,\s*textCapitalization: TextCapitalization\.words,\s*decoration: const InputDecoration\(\s*labelText: 'Name',[\s\S]*?isDense: true,\s*\),\s*onChanged: \(_\) => _persistCustomer\(\),\s*\)/,
  `AppTextField(
                                  controller: _customerNameController,
                                  label: 'Name',
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: (_) => _persistCustomer(),
                                )`,
);

s = s.replace(
  /TextField\(\s*controller: _customerPhoneController,\s*keyboardType: TextInputType\.phone,\s*decoration: const InputDecoration\(\s*labelText: 'Mobile',[\s\S]*?isDense: true,\s*\),\s*onChanged: \(_\) => _persistCustomer\(\),\s*\)/,
  `AppTextField(
                                  controller: _customerPhoneController,
                                  label: 'Mobile',
                                  keyboardType: TextInputType.phone,
                                  onChanged: (_) => _persistCustomer(),
                                )`,
);

// Card with Padding all(16) → AppCard
s = s.replace(
  /Card\(\s*child:\s*Padding\(\s*padding:\s*const EdgeInsets\.all\(16\),\s*child:\s*/g,
  'AppCard(\n                          child: ',
);
// Remove one closing paren for each unwrapped Padding — fragile.
// Count AppCard openings we just made vs fix manually for remaining Dropdowns.

// Disc/Pack dropdowns
s = s.replace(
  /DropdownButtonFormField<String>\(\s*initialValue: checkout\.discountType,[\s\S]*?items: const \[[\s\S]*?\],\s*onChanged: checkout\.busy\s*\? null\s*: \(v\) \{([\s\S]*?)\},\s*\)/,
  `StringDropdownField(
                                      label: 'Disc type',
                                      value: checkout.discountType,
                                      options: const ['Amount', 'Percent'],
                                      onChanged: checkout.busy
                                          ? (_) {}
                                          : (v) {$1},
                                    )`,
);

s = s.replace(
  /DropdownButtonFormField<String>\(\s*initialValue: checkout\.packingChargeType,[\s\S]*?items: const \[[\s\S]*?\],\s*onChanged: checkout\.busy\s*\? null\s*: \(v\) \{([\s\S]*?)\},\s*\)/,
  `StringDropdownField(
                                      label: 'Pack type',
                                      value: checkout.packingChargeType,
                                      options: const ['Amount', 'Percent'],
                                      onChanged: checkout.busy
                                          ? (_) {}
                                          : (v) {$1},
                                    )`,
);

// Discount / packing / cash / upi TextFormField → AppTextField (label from decoration)
s = s.replace(
  /TextFormField\(\s*controller: _discountController,[\s\S]*?decoration: const InputDecoration\(\s*labelText: 'Discount',[\s\S]*?\),\s*onChanged:/,
  `AppTextField(
                                      controller: _discountController,
                                      label: 'Discount',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged:`,
);
s = s.replace(
  /TextFormField\(\s*controller: _packingController,[\s\S]*?decoration: const InputDecoration\(\s*labelText: 'Packing',[\s\S]*?\),\s*onChanged:/,
  `AppTextField(
                                      controller: _packingController,
                                      label: 'Packing',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged:`,
);
s = s.replace(
  /TextFormField\(\s*controller: _cashController,[\s\S]*?decoration: const InputDecoration\(\s*labelText: 'Cash amount',[\s\S]*?prefixIcon: Icon\(Icons\.payments_outlined\),[\s\S]*?\),\s*onChanged:/,
  `AppTextField(
                          controller: _cashController,
                          label: 'Cash amount',
                          prefixIcon: Icons.payments_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          onChanged:`,
);
s = s.replace(
  /TextFormField\(\s*controller: _upiController,[\s\S]*?decoration: const InputDecoration\(\s*labelText: 'UPI amount',[\s\S]*?prefixIcon: Icon\(Icons\.qr_code_2_rounded\),[\s\S]*?\),\s*onChanged:/,
  `AppTextField(
                          controller: _upiController,
                          label: 'UPI amount',
                          prefixIcon: Icons.qr_code_2_rounded,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          onChanged:`,
);

// PRINT BILL button
s = s.replace(
  /FilledButton\.icon\(\s*onPressed: checkout\.busy \|\| summary\.isEmpty\s*\? null\s*: _complete,\s*icon: checkout\.busy[\s\S]*?: const Icon\(Icons\.print_rounded\),\s*label: Text\(\s*checkout\.busy \? 'Saving…' : 'PRINT BILL',[\s\S]*?\),\s*\)/,
  `AppButton(
                          label: 'PRINT BILL',
                          icon: Icons.print_rounded,
                          isLoading: checkout.busy,
                          expanded: false,
                          onPressed: summary.isEmpty ? null : _complete,
                        )`,
);

fs.writeFileSync(path, s);
console.log('payment_page updated');
console.log('remaining TextFormField', (s.match(/TextFormField/g) || []).length);
console.log('remaining DropdownButtonFormField', (s.match(/DropdownButtonFormField/g) || []).length);
console.log('remaining FilledButton', (s.match(/FilledButton/g) || []).length);
console.log('AppTextField', (s.match(/AppTextField/g) || []).length);
console.log('AppButton', (s.match(/AppButton/g) || []).length);
console.log('StringDropdownField', (s.match(/StringDropdownField/g) || []).length);
