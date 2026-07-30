import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventflow_app/core/widgets/loading_widget.dart';
import 'package:eventflow_app/core/widgets/error_widget.dart';
import 'package:eventflow_app/core/widgets/empty_state_widget.dart';
import 'package:eventflow_app/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:eventflow_app/features/dashboard/presentation/widgets/recent_booking_card.dart';
import 'package:eventflow_app/features/dashboard/data/models/dashboard_model.dart';

void main() {
  group('LoadingWidget', () {
    testWidgets('displays loading indicator', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: LoadingWidget()),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays shimmer list', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ShimmerList()),
      ));
      expect(find.byType(ShimmerList), findsOneWidget);
    });
  });

  group('AppErrorWidget', () {
    testWidgets('displays error message and retry button', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AppErrorWidget(
          message: 'Test error',
          onRetry: () {},
        )),
      ));
      expect(find.text('Test error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });

  group('EmptyStateWidget', () {
    testWidgets('displays empty state with title', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmptyStateWidget(
          icon: Icons.info,
          title: 'No Data',
          subtitle: 'Nothing to show',
        )),
      ));
      expect(find.text('No Data'), findsOneWidget);
      expect(find.text('Nothing to show'), findsOneWidget);
    });
  });

  group('StatCard', () {
    testWidgets('displays stat values correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatCard(
          title: 'Revenue',
          value: '₹50,000',
          icon: Icons.account_balance_wallet,
          color: Colors.green,
        )),
      ));
      expect(find.text('Revenue'), findsOneWidget);
      expect(find.text('₹50,000'), findsOneWidget);
    });

    testWidgets('triggers onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatCard(
          title: 'Test',
          value: '100',
          icon: Icons.info,
          color: Colors.blue,
          onTap: () => tapped = true,
        )),
      ));
      await tester.tap(find.text('Test'));
      expect(tapped, true);
    });
  });

  group('RecentBookingCard', () {
    testWidgets('displays booking info correctly', (tester) async {
      final booking = RecentBooking(
        id: 1, bookingNumber: 'BK-001', customerName: 'John',
        eventDate: '2024-01-15', status: 'CONFIRMED', totalAmount: 50000,
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: RecentBookingCard(booking: booking)),
      ));
      expect(find.text('John'), findsOneWidget);
      expect(find.textContaining('BK-001'), findsOneWidget);
    });
  });
}
