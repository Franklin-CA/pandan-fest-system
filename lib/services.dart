import 'package:flutter/services.dart';

class MaxValueFormatter extends TextInputFormatter {
  final double maxValue;
  MaxValueFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final parsed = double.tryParse(newValue.text);
    if (parsed == null) return oldValue;
    if (parsed > maxValue) return oldValue; // block if over max
    return newValue;
  }
}