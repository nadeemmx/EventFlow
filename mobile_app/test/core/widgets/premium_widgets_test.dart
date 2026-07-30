import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventflow_app/core/widgets/empty_state_widget.dart';
import 'package:eventflow_app/core/widgets/status_chip.dart';
import 'package:eventflow_app/core/widgets/error_widget.dart';
import 'package:eventflow_app/core/widgets/section_header.dart';

Widget wrapInApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('EmptyStateWidget', () {
    testWidgets('displays title and subtitle', (tester) async {
      await tester.pumpWidget(wrapInApp(
        const EmptyStateWidget(
          title: 'No Bookings',
          subtitle: 'You have no bookings yet',
        ),
      ));

      expect(find.text('No Bookings'), findsOneWidget);
      expect(find.text('You have no bookings yet'), findsOneWidget);
    });

    testWidgets('displays action button when provided', (tester) async {
      await tester.pumpWidget(wrapInApp(
        EmptyStateWidget(
          title: 'Empty',
          actionLabel: 'Add New',
          onAction: () {},
        ),
      ));

      expect(find.text('Add New'), findsOneWidget);
    });
  });

  group('StatusChip', () {
    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(wrapInApp(
        const StatusChip(
          label: 'Confirmed',
          color: Colors.green,
        ),
      ));

      expect(find.text('Confirmed'), findsOneWidget);
    });
  });

  group('AppErrorWidget', () {
    testWidgets('displays message and retry button', (tester) async {
      await tester.pumpWidget(wrapInApp(
        AppErrorWidget(
          message: 'Failed to load data',
          onRetry: () {},
        ),
      ));

      expect(find.text('Failed to load data'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('displays default Oops title', (tester) async {
      await tester.pumpWidget(wrapInApp(
        const AppErrorWidget(message: 'Some error'),
      ));

      expect(find.text('Oops!'), findsOneWidget);
    });
  });

  group('SectionHeader', () {
    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(wrapInApp(
        const SectionHeader(title: 'Recent Bookings'),
      ));

      expect(find.text('Recent Bookings'), findsOneWidget);
    });

    testWidgets('displays action button when provided', (tester) async {
      await tester.pumpWidget(wrapInApp(
        SectionHeader(
          title: 'Upcoming Events',
          actionLabel: 'View All',
          onAction: () {},
        ),
      ));

      expect(find.text('View All'), findsOneWidget);
    });
  });
}
