import 'package:flutter/material.dart';
import 'package:pos_billingwala_v2/core/widgtes/dropdown/app_dropdown_form_field.dart';
import 'package:pos_billingwala_v2/core/widgtes/dropdown/expandable_dropdown.dart';

class NullableTextDropdownFormField extends StatelessWidget {
  const NullableTextDropdownFormField({
    super.key,
    required this.label,
    this.hint,
    required this.options,
    required this.value,
    required this.onChanged,
    this.decoration,
    this.enableSearch = false,
    this.showLabel = true,
    this.validator,
  });

  final String label;
  final String? hint;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final InputDecoration? decoration;
  final bool enableSearch;
  final bool showLabel;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return AppDropdownFormField<String>(
      label: label,
      hint: hint ?? decoration?.hintText,
      items: options,
      itemLabel: (item) => item,
      value: value,
      onChanged: onChanged,
      enableSearch:
          enableSearch || options.length > kDropdownSearchMinOptionCount,
      showLabel: showLabel,
      validator: validator,
    );
  }
}
