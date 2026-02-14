/// Selection type for a customization group.
enum SelectionType {
  /// Multiple options can be selected (checkboxes).
  checkbox,

  /// Only one option can be selected (radio buttons).
  radio,
}

/// A single customization option (e.g., "Extra Cheese").
class CustomizationOption {
  final String name;

  /// Price surcharge. If null or 0, the option is free.
  final double? price;

  const CustomizationOption({required this.name, this.price});

  /// Display-friendly price string.
  String get displayPrice {
    if (price == null || price == 0) return 'Free';
    return '+\$${price!.toStringAsFixed(2)}';
  }

  bool get isFree => price == null || price == 0;
}

/// A group of related customization options.
class CustomizationGroup {
  final String title;
  final SelectionType type;
  final List<CustomizationOption> options;

  /// Whether the user must make a selection in this group.
  final bool required;

  const CustomizationGroup({
    required this.title,
    required this.type,
    required this.options,
    this.required = false,
  });
}
