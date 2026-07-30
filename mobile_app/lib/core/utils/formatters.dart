import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _timeFormat = DateFormat('hh:mm a');

  static String currency(double amount) => _currencyFormat.format(amount);
  static String date(DateTime? date) => date != null ? _dateFormat.format(date) : '-';
  static String dateTime(DateTime? dateTime) => dateTime != null ? _dateTimeFormat.format(dateTime) : '-';
  static String time(DateTime? dateTime) => dateTime != null ? _timeFormat.format(dateTime) : '-';

  static String phone(String? mobile) => mobile ?? '-';
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String statusLabel(String status) {
    return status.split('_').map((word) => capitalize(word)).join(' ');
  }
}
