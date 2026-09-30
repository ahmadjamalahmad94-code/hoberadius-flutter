import 'package:flutter/material.dart';

import '../../core/format/number_input.dart';

/// A number field that NEVER rewrites what was typed and shows why a value
/// is refused, live, under the field (the shared rule of
/// core/format/number_input.dart: Arabic-Indic digits and «٫» accepted,
/// «-», «e», «,» and letters refused with an Arabic message).
///
/// [extraError] adds a rule on the parsed value (caps, minimums); it is only
/// asked when the text is a valid number.
class NumberTextField extends StatelessWidget {
  const NumberTextField({
    super.key,
    required this.controller,
    this.decimal = true,
    this.allowNegative = false,
    this.decoration = const InputDecoration(),
    this.extraError,
    this.onChanged,
    this.autofocus = false,
    this.enabled,
  });

  final TextEditingController controller;
  final bool decimal;
  final bool allowNegative;
  final InputDecoration decoration;
  final String? Function(num value)? extraError;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final bool? enabled;

  /// The message shown under the field for [text] (null = fine or empty).
  static String? errorFor(
    String text, {
    bool decimal = true,
    bool allowNegative = false,
    String? Function(num value)? extraError,
  }) {
    final r = readNumberInput(
      text,
      decimal: decimal,
      allowNegative: allowNegative,
    );
    if (r.isEmpty) return null;
    if (r.error != null) return r.error;
    return extraError?.call(r.value!);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        autofocus: autofocus,
        enabled: enabled,
        keyboardType: decimal ? decimalKeyboard : integerKeyboard,
        inputFormatters: numberFieldFormatters,
        decoration: decoration.copyWith(
          errorText: errorFor(
            value.text,
            decimal: decimal,
            allowNegative: allowNegative,
            extraError: extraError,
          ),
          errorMaxLines: 4,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
