import 'package:flutter/material.dart';
import 'package:pos_billingwala_v2/core/widgtes/dropdown/dropdown_theme.dart';
import 'package:pos_billingwala_v2/core/widgtes/dropdown/text_dropdown.dart';

class StringDropdownField extends StatelessWidget {
  const StringDropdownField({
    super.key,
    required this.label,
    this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enableSearch = false,
    this.showLabel = true,
    this.validator,
  });

  final String label;
  final String? hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool enableSearch;
  final bool showLabel;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return NullableTextDropdownFormField(
      label: label,
      hint: hint,
      value: value,
      options: options,
      decoration: appDropdownDecoration(
        context,
        label: label,
        hint: hint,
      ),
      enableSearch: enableSearch || options.length > 6,
      showLabel: showLabel,
      validator: validator,
      onChanged: onChanged,
    );
  }
}
