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

  factory CustomizationOption.fromJson(Map<String, dynamic> json) {
    return CustomizationOption(
      name: json['name'] as String,
      price: (json['price'] as num?)?.toDouble(),
    );
  }

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

  factory CustomizationGroup.fromJson(Map<String, dynamic> json) {
    final addons = (json['addons'] as List?) ?? [];
    return CustomizationGroup(
      title: json['name'] as String,
      type:
          (json['max_select'] as int? ?? 0) == 1
              ? SelectionType.radio
              : SelectionType.checkbox,
      required: json['required'] ?? false,
      options:
          addons
              .map(
                (a) => CustomizationOption.fromJson(a as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}
