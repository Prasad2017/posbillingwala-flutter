import 'package:flutter/material.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/widgtes/widget_strings.dart';
import 'package:pos_billingwala_v2/core/widgtes/widget_theme.dart';

const int kDropdownSearchMinOptionCount = 6;

enum ExpandableDropdownMode { single, multi }

class ExpandableDropdownField<T> extends StatefulWidget {
  const ExpandableDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.itemLabel,
    this.itemComparer,
    this.enableSearch = true,
    this.searchHint,
    this.maxListHeight = 220,
    this.mode = ExpandableDropdownMode.single,
    this.value,
    this.onChanged,
    this.selectedValues,
    this.onSelectionChanged,
    this.actionLabel,
    this.onActionTap,
    this.emptyText,
    this.showLabel = true,
    this.multiSelectLabelBuilder,
    this.hasError = false,
    this.fitContent = false,
  }) : assert(
          mode == ExpandableDropdownMode.single
              ? onChanged != null
              : onSelectionChanged != null && selectedValues != null,
          'Provide onChanged for single select or selectedValues/onSelectionChanged for multi select.',
        );

  final String label;
  final String hint;
  final List<T> items;
  final String Function(T item) itemLabel;
  final bool Function(T a, T b)? itemComparer;
  final bool enableSearch;
  final String? searchHint;
  final double maxListHeight;
  final ExpandableDropdownMode mode;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final Set<T>? selectedValues;
  final ValueChanged<Set<T>>? onSelectionChanged;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final String? emptyText;
  final bool showLabel;
  final String Function(int count, T? singleValue)? multiSelectLabelBuilder;
  final bool hasError;
  /// When true, the field sizes to its content instead of stretching full width.
  final bool fitContent;

  @override
  State<ExpandableDropdownField<T>> createState() =>
      _ExpandableDropdownFieldState<T>();
}

class _ExpandableDropdownFieldState<T>
    extends State<ExpandableDropdownField<T>> {
  var _expanded = false;
  final _searchController = TextEditingController();

  bool _itemsEqual(T a, T b) => widget.itemComparer?.call(a, b) ?? a == b;

  bool _isSelected(T item) {
    if (widget.mode == ExpandableDropdownMode.multi) {
      return widget.selectedValues!.any((value) => _itemsEqual(value, item));
    }
    final selected = widget.value;
    return selected != null && _itemsEqual(selected, item);
  }

  List<T> _filteredItems() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.items;
    return widget.items
        .where((item) => widget.itemLabel(item).toLowerCase().contains(query))
        .toList();
  }

  String _triggerLabel() {
    if (widget.mode == ExpandableDropdownMode.multi) {
      final selected = widget.selectedValues!;
      if (selected.isEmpty) return widget.hint;
      if (widget.multiSelectLabelBuilder != null) {
        return widget.multiSelectLabelBuilder!(
          selected.length,
          selected.length == 1 ? selected.first : null,
        );
      }
      if (selected.length == 1) {
        return widget.itemLabel(selected.first);
      }
      return WidgetStrings.selectedCount(selected.length);
    }

    final selected = widget.value;
    if (selected == null) return widget.hint;
    return widget.itemLabel(selected);
  }

  bool get _hasSelection {
    if (widget.mode == ExpandableDropdownMode.multi) {
      return widget.selectedValues!.isNotEmpty;
    }
    return widget.value != null;
  }

  void _closeDropdown() {
    if (!_expanded) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _expanded = false;
      _searchController.clear();
    });
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
      if (!_expanded) {
        _searchController.clear();
      }
    });
  }

  void _handleItemTap(T item) {
    if (widget.mode == ExpandableDropdownMode.multi) {
      final next = {...widget.selectedValues!};
      if (_isSelected(item)) {
        next.removeWhere((value) => _itemsEqual(value, item));
      } else {
        next.add(item);
      }
      widget.onSelectionChanged!(next);
      _closeDropdown();
      return;
    }

    widget.onChanged!(item);
    _closeDropdown();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final bodySm =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final items = _filteredItems();

    final triggerLabel = Text(
      _triggerLabel(),
      style: bodyStyle.copyWith(
        color: _hasSelection ? context.textPrimary : context.textSecondary,
        fontSize: 14,
      ),
    );

    final dropdown = TapRegion(
      onTapOutside: (_) => _closeDropdown(),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.hasError ? AppColors.danger : context.borderColor,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: widget.fitContent
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _toggleExpanded,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.fitContent ? 12 : 14,
                  vertical: widget.fitContent ? 10 : 14,
                ),
                child: Row(
                  mainAxisSize:
                      widget.fitContent ? MainAxisSize.min : MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.fitContent)
                      triggerLabel
                    else
                      Expanded(child: triggerLabel),
                    const SizedBox(width: 8),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: context.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              Divider(height: 1, color: context.borderColor),
              if (widget.enableSearch && !widget.fitContent)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    cursorColor: context.textPrimary,
                    style: bodyStyle.copyWith(
                      color: context.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: widget.searchHint ?? WidgetStrings.searchOptions,
                      hintStyle: bodyStyle.copyWith(
                        color: context.textSecondary,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: context.textSecondary,
                      ),
                      filled: true,
                      fillColor: context.subtleBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: widget.maxListHeight),
                child: items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        child: Text(
                          widget.emptyText ?? WidgetStrings.noResultsFound,
                          style: bodySm.copyWith(
                            color: context.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    // fitContent must not use ListView/viewport â€” parents may
                    // measure intrinsics, and ShrinkWrappingViewport forbids that.
                    : widget.fitContent
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var index = 0;
                                  index < items.length;
                                  index++)
                                _buildOption(
                                  context: context,
                                  bodyStyle: bodyStyle,
                                  item: items[index],
                                  isFirst: index == 0,
                                ),
                              if (widget.actionLabel != null)
                                _buildAction(bodyStyle),
                            ],
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const ClampingScrollPhysics(),
                            itemCount: items.length +
                                (widget.actionLabel != null ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (widget.actionLabel != null &&
                                  index == items.length) {
                                return _buildAction(bodyStyle);
                              }
                              return _buildOption(
                                context: context,
                                bodyStyle: bodyStyle,
                                item: items[index],
                                isFirst: index == 0,
                              );
                            },
                          ),
              ),
            ],
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: widget.fitContent
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel) ...[
          Text(
            widget.label,
            style: bodySm.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Sized from content via MainAxisSize.min â€” never IntrinsicWidth.
        dropdown,
      ],
    );
  }

  Widget _buildAction(TextStyle bodyStyle) {
    return InkWell(
      onTap: () {
        widget.onActionTap?.call();
        _closeDropdown();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: Text(
          widget.actionLabel!,
          style: bodyStyle.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required TextStyle bodyStyle,
    required T item,
    required bool isFirst,
  }) {
    final selected = _isSelected(item);
    return Material(
      color: selected && widget.mode == ExpandableDropdownMode.multi
          ? context.subtleBackground
          : Colors.transparent,
      child: InkWell(
        onTap: () => _handleItemTap(item),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            widget.fitContent ? 12 : 14,
            isFirst ? 6 : 8,
            widget.fitContent ? 12 : 14,
            8,
          ),
          child: Text(
            widget.itemLabel(item),
            style: bodyStyle.copyWith(
              color: selected ? AppColors.primary : context.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

