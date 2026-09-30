import 'package:flutter/material.dart';

import '../../../../core/format/money_limits.dart';
import '../../../../core/format/number_input.dart';

/// A number field of the card screens, read strictly by the shared reader:
/// «٣» is 3, while «-1», «1e3», «7.5» in a whole-number field and text are
/// refused with the Arabic reason (they used to become «مطلوب», the default
/// value, or were silently dropped).
class CardNumberField extends StatelessWidget {
  const CardNumberField({
    super.key,
    required this.controller,
    this.decimal = false,
    this.required = false,
    this.min,
    this.max,
    this.emptyMessage,
    this.check,
    this.decoration,
    this.onChanged,
    this.serverError,
  }) : _moneyCap = false;

  /// A money field: decimals allowed, at most the configured generic cap
  /// ([kMaxMoneyAmount], read when the field builds).
  const CardNumberField.money({
    super.key,
    required this.controller,
    this.required = false,
    this.emptyMessage,
    this.decoration,
    this.onChanged,
    this.serverError,
  })  : decimal = true,
        min = null,
        max = null,
        _moneyCap = true,
        check = null;

  final TextEditingController controller;
  final bool decimal;
  final bool required;
  final num? min;
  final num? max;
  final String? emptyMessage;

  /// [max] is the configured generic money cap.
  final bool _moneyCap;

  /// Extra rule on a valid value (null = the field is empty).
  final String? Function(num? value)? check;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;

  /// The server's Arabic message about this field (4xx), shown under it.
  final String? serverError;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: decimal ? decimalKeyboard : integerKeyboard,
      inputFormatters: numberFieldFormatters,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: (decoration ?? const InputDecoration())
          .copyWith(errorText: serverError),
      onChanged: onChanged,
      validator: (v) => validateCardNumber(
        v,
        decimal: decimal,
        required: required,
        min: min,
        max: _moneyCap ? kMaxMoneyAmount : max,
        emptyMessage: emptyMessage,
        check: check,
      ),
    );
  }
}

/// The validator of [CardNumberField] (also for tests).
String? validateCardNumber(
  String? raw, {
  bool decimal = false,
  bool required = false,
  num? min,
  bool minExclusive = false,
  num? max,
  String? emptyMessage,
  String? Function(num? value)? check,
}) {
  final error = validateNumberInput(
    raw,
    required: required,
    decimal: decimal,
    min: min,
    minExclusive: minExclusive,
    max: max,
    emptyMessage: emptyMessage,
  );
  if (error != null) return error;
  return check?.call(parseNumberInput(raw, decimal: decimal));
}
