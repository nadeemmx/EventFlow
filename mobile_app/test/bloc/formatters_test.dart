import 'package:flutter_test/flutter_test.dart';
import 'package:eventflow_app/core/utils/formatters.dart';

void main() {
  group('Formatters', () {
    test('currency formats correctly', () {
      expect(Formatters.currency(1000), '₹1,000.00');
      expect(Formatters.currency(0), '₹0.00');
      expect(Formatters.currency(1000.5), '₹1,000.50');
    });

    test('date formats correctly', () {
      final date = DateTime(2024, 1, 15);
      expect(Formatters.date(date), '15 Jan 2024');
      expect(Formatters.date(null), '-');
    });

    test('phone formats correctly', () {
      expect(Formatters.phone('9876543210'), '9876543210');
      expect(Formatters.phone(null), '-');
    });

    test('capitalize formats correctly', () {
      expect(Formatters.capitalize('hello'), 'Hello');
      expect(Formatters.capitalize(''), '');
      expect(Formatters.capitalize('HELLO'), 'Hello');
    });

    test('statusLabel formats correctly', () {
      expect(Formatters.statusLabel('CONFIRMED'), 'Confirmed');
      expect(Formatters.statusLabel('IN_PROGRESS'), 'In Progress');
      expect(Formatters.statusLabel('SITE_VISIT'), 'Site Visit');
    });
  });
}
