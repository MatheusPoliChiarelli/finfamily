import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _maskFormat = NumberFormat('#,##0.00', 'pt_BR');

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    if (digits.length > 12) return oldValue;

    final value = int.parse(digits) / 100;
    final text = _maskFormat.format(value);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

double parseCurrency(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.parse(digits) / 100;
}

String currencyMask(double value) => _maskFormat.format(value);