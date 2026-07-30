import 'package:flutter_test/flutter_test.dart';
import 'package:eventflow_app/core/utils/formatters.dart';

void main() {
  group('Formatters', () {
    test('currency formats correctly', () {
      expect(Formatters.currency(1234.56), '₹1,234.56');
    });

    test('capitalize works', () {
      expect(Formatters.capitalize('hello'), 'Hello');
    });

    test('statusLabel formats snake_case', () {
      expect(Formatters.statusLabel('IN_PROGRESS'), 'In Progress');
    });

    test('date formats correctly', () {
      final date = DateTime(2026, 3, 15);
      expect(Formatters.date(date), '15 Mar 2026');
    });

    test('phone returns dash for null', () {
      expect(Formatters.phone(null), '-');
    });

    test('date returns dash for null', () {
      expect(Formatters.date(null), '-');
    });

    test('dateTime formats correctly', () {
      final dateTime = DateTime(2026, 3, 15, 10, 30);
      expect(Formatters.dateTime(dateTime), '15 Mar 2026, 10:30 AM');
    });

    test('time formats correctly', () {
      final dateTime = DateTime(2026, 3, 15, 14, 45);
      expect(Formatters.time(dateTime), '02:45 PM');
    });

    test('phone returns mobile when provided', () {
      expect(Formatters.phone('9876543210'), '9876543210');
    });

    test('capitalize returns empty for empty string', () {
      expect(Formatters.capitalize(''), '');
    });
  });
}
