import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ', decimalDigits: 2);
final _plain = NumberFormat('#,##0', 'pt_BR');
final _monthKey = DateFormat('yyyy-MM');
final _monthLabel = DateFormat("MMMM 'de' yyyy", 'pt_BR');
final _dayLabel = DateFormat('dd MMM', 'pt_BR');

String money(double value) => _currency.format(value);
String plain(double value) => _plain.format(value);
String monthKey(DateTime date) => _monthKey.format(date);
String dayLabel(DateTime date) => _dayLabel.format(date);

String monthLabel(DateTime date) {
  final raw = _monthLabel.format(date);
  return raw[0].toUpperCase() + raw.substring(1);
}