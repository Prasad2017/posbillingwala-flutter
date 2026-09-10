import 'package:flutter/material.dart';
import 'package:pos_billingwala_v2/core/widgtes/dropdown/expandable_dropdown.dart';
import 'package:pos_billingwala_v2/core/widgtes/widget_strings.dart';

class AppDropdownFormField<T> extends StatelessWidget {
  const AppDropdownFormField({
    super.key,
    required this.label,
    this.hint,
    required this.items,
    required this.itemLabel,
    required this.value,
    required this.onChanged,
    this.itemComparer,
    this.enableSearch = false,
    this.showLabel = true,
    this.validator,
  });

  final String label;
  final String? hint;
  final List<T> items;
  final String Function(T item) itemLabel;
  final T? value;
  final ValueChanged<T?> onChanged;
  final bool Function(T a, T b)? itemComparer;
  final bool enableSearch;
  final bool showLabel;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<T?>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExpandableDropdownField<T>(
              label: label,
              hint: hint ?? WidgetStrings.selectFieldHint(label),
              items: items,
              itemLabel: itemLabel,
              itemComparer: itemComparer,
              enableSearch:
                  enableSearch || items.length > kDropdownSearchMinOptionCount,
              value: value,
              showLabel: showLabel,
              hasError: state.hasError,
              onChanged: (selected) {
                onChanged(selected);
                state.didChange(selected);
                if (state.hasError) {
                  state.validate();
                }
              },
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  state.errorText ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
          ],
        );
      },
    );
  }
}
