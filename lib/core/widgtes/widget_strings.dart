/// Small string helpers for reusable widgets (no ARB dependency).
class WidgetStrings {
  WidgetStrings._();

  static const cancel = 'Cancel';
  static const searchOptions = 'Search…';
  static const noResultsFound = 'No results found';

  static String enterFieldHint(String label) => 'Enter $label';
  static String selectFieldHint(String label) => 'Select $label';
  static String selectedCount(int count) => '$count selected';
}
