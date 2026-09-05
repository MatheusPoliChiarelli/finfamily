import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ', decimalDigits: 2);
final _plain = NumberFormat('#,##0.00', 'pt_BR');
final _monthKey = DateFormat('yyyy-MM');
final _monthLabel = DateFormat("MMMM 'de' yyyy", 'pt_BR');
final _dayLabel = DateFormat('dd MMM', 'pt_BR');
final _fullDayLabel = DateFormat("d 'de' MMMM", 'pt_BR');
final _weekday = DateFormat('EEEE', 'pt_BR');
final _fullDate = DateFormat("d 'de' MMMM 'de' y", 'pt_BR');
final _shortMonth = DateFormat('MMM', 'pt_BR');

String fullDate(DateTime date) => _fullDate.format(date);

String money(double value) => _currency.format(value);
String plain(double value) => _plain.format(value);
String monthKey(DateTime date) => _monthKey.format(date);
String dayLabel(DateTime date) => _dayLabel.format(date);

String fullDayLabel(DateTime date) {
  final weekday = _weekday.format(date);
  return '${weekday[0].toUpperCase()}${weekday.substring(1)}, ${_fullDayLabel.format(date)}';
}

String monthLabel(DateTime date) {
  final raw = _monthLabel.format(date);
  return raw[0].toUpperCase() + raw.substring(1);
}



String shortMonth(int month) {
  final raw = _shortMonth.format(DateTime(2000, month));
  return raw[0].toUpperCase() + raw.substring(1).replaceAll('.', '');
}