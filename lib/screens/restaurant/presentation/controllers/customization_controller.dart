import 'package:flutter/foundation.dart';
import '../../domain/customization_entity.dart';

/// Controller that manages customization selections and computes pricing.
///
/// Keeps the UI code clean by encapsulating all selection logic here.
class CustomizationController extends ChangeNotifier {
  final double basePrice;
  final List<CustomizationGroup> groups;

  int _quantity = 1;

  /// Key = group index, Value = set of selected option indices.
  final Map<int, Set<int>> _selections = {};

  CustomizationController({required this.basePrice, required this.groups}) {
    // Pre-select the first option for required radio groups.
    for (int i = 0; i < groups.length; i++) {
      if (groups[i].type == SelectionType.radio && groups[i].required) {
        _selections[i] = {0};
      } else {
        _selections[i] = {};
      }
    }
  }

  // ── Getters ──────────────────────────────────────────────────────

  int get quantity => _quantity;

  /// Get the selected index for a radio group (or -1 if none).
  int getSelectedRadioIndex(int groupIndex) {
    final set = _selections[groupIndex];
    if (set != null && set.isNotEmpty) {
      return set.first;
    }
    return -1;
  }

  /// Whether an option is currently selected.
  bool isSelected(int groupIndex, int optionIndex) {
    return _selections[groupIndex]?.contains(optionIndex) ?? false;
  }

  /// Sum of all selected paid extras.
  double get totalExtrasPrice {
    double total = 0;
    _selections.forEach((groupIndex, optionIndices) {
      for (final optionIndex in optionIndices) {
        final price = groups[groupIndex].options[optionIndex].price;
        if (price != null && price > 0) {
          total += price;
        }
      }
    });
    return total;
  }

  /// Grand total = (base + extras) × quantity.
  double get grandTotal => (basePrice + totalExtrasPrice) * _quantity;

  /// Flat list of all selected customization option names.
  List<String> get selectedCustomizationNames {
    final names = <String>[];
    _selections.forEach((groupIndex, optionIndices) {
      for (final optionIndex in optionIndices) {
        names.add(groups[groupIndex].options[optionIndex].name);
      }
    });
    return names;
  }

  /// Flat extras-only surcharge for one unit (used when adding to cart).
  double get extrasUnitPrice => totalExtrasPrice;

  // ── Mutators ─────────────────────────────────────────────────────

  /// Toggle checkbox selection (multi-select).
  void toggleCheckbox(int groupIndex, int optionIndex) {
    final set = _selections.putIfAbsent(groupIndex, () => {});
    if (set.contains(optionIndex)) {
      set.remove(optionIndex);
    } else {
      set.add(optionIndex);
    }
    notifyListeners();
  }

  /// Set radio selection (single-select).
  void selectRadio(int groupIndex, int optionIndex) {
    _selections[groupIndex] = {optionIndex};
    notifyListeners();
  }

  void incrementQuantity() {
    _quantity++;
    notifyListeners();
  }

  void decrementQuantity() {
    if (_quantity > 1) {
      _quantity--;
      notifyListeners();
    }
  }
}
