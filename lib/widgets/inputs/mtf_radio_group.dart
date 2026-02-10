import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A custom radio group that provides value and callback to its children.
class MtfRadioGroup<T> extends InheritedWidget {
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const MtfRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required super.child,
  });

  static MtfRadioGroup<T>? of<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MtfRadioGroup<T>>();
  }

  @override
  bool updateShouldNotify(MtfRadioGroup<T> oldWidget) {
    return oldWidget.groupValue != groupValue;
  }
}

/// A custom radio that works with [MtfRadioGroup].
class MtfRadio<T> extends StatelessWidget {
  final T value;
  final Color? activeColor;

  const MtfRadio({super.key, required this.value, this.activeColor});

  @override
  Widget build(BuildContext context) {
    final group = MtfRadioGroup.of<T>(context);

    return Radio<T>(
      value: value,
      // ignore: deprecated_member_use
      groupValue: group?.groupValue,
      // ignore: deprecated_member_use
      onChanged: group?.onChanged,
      activeColor: activeColor ?? AppColors.primary,
    );
  }
}
