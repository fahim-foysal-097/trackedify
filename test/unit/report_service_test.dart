import 'package:flutter_test/flutter_test.dart';
import 'package:trackedify/services/report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReportService', () {
    final sampleExpenses = [
      {
        'id': 1,
        'date': '2026-05-01',
        'category': 'Groceries',
        'amount': 45.50,
        'note': 'Weekly food shop',
      },
      {
        'id': 2,
        'date': '2026-05-15',
        'category': 'Utilities',
        'amount': 120.00,
        'note': 'Electric bill',
      },
      {
        'id': 3,
        'date': '2026-06-10',
        'category': 'Entertainment',
        'amount': 30.00,
        'note': 'Movie, popcorn & snacks',
      },
    ];

    group('filterExpensesByDateRange', () {
      test('returns all expenses when date range is null', () {
        final filtered = ReportService.filterExpensesByDateRange(
          sampleExpenses,
          null,
          null,
        );
        expect(filtered.length, equals(3));
      });

      test('filters expenses after startDate correctly', () {
        final start = DateTime(2026, 5, 10);
        final filtered = ReportService.filterExpensesByDateRange(
          sampleExpenses,
          start,
          null,
        );
        expect(filtered.length, equals(2));
        expect(
          filtered.every(
            (e) => DateTime.parse(e['date'] as String).isAfter(start),
          ),
          isTrue,
        );
      });

      test('filters expenses within date range inclusive', () {
        final start = DateTime(2026, 5, 1);
        final end = DateTime(2026, 5, 31);
        final filtered = ReportService.filterExpensesByDateRange(
          sampleExpenses,
          start,
          end,
        );
        expect(filtered.length, equals(2));
      });
    });

    group('formatPdfCurrency', () {
      test('keeps Latin-1 currency symbols', () {
        expect(ReportService.formatPdfCurrency('\$', 'usd'), equals('\$'));
        expect(ReportService.formatPdfCurrency('€', 'eur'), equals('€'));
        expect(ReportService.formatPdfCurrency('£', 'gbp'), equals('£'));
        expect(ReportService.formatPdfCurrency('¥', 'jpy'), equals('¥'));
      });

      test('converts non-Latin script symbols to ISO 4217 representations', () {
        expect(ReportService.formatPdfCurrency('৳', 'bdt'), equals('BDT'));
        expect(ReportService.formatPdfCurrency('₹', 'inr'), equals('INR'));
        expect(ReportService.formatPdfCurrency('د.إ', 'aed'), equals('AED'));
        expect(ReportService.formatPdfCurrency('₹₹₹', 'xyz'), equals('XYZ'));
      });
    });

    group('generateCsv', () {
      test('generates valid CSV header and rows', () {
        final csv = ReportService.generateCsv(
          expenses: sampleExpenses,
          currencySymbol: '\$',
          currencyCode: 'usd',
          dateRangeLabel: 'May 2026',
        );

        expect(csv, contains('# Trackedify Expense Report'));
        expect(csv, contains('# Period: May 2026'));
        expect(csv, contains('ID,Date,Category,Amount,Currency,Note'));
        expect(
          csv,
          contains('1,2026-05-01,Groceries,45.50,\$,Weekly food shop'),
        );
        expect(
          csv,
          contains('"Movie, popcorn & snacks"'),
        ); // CSV escaped due to comma
        expect(csv, contains('# Total Expenses: 3 item(s)'));
        expect(csv, contains('# Total Amount: \$195.50'));
      });
    });

    group('generatePdfBytes', () {
      test('generates non-empty PDF Uint8List without throwing', () async {
        final pdfBytes = await ReportService.generatePdfBytes(
          expenses: sampleExpenses,
          currencySymbol: '\$',
          currencyCode: 'usd',
          dateRangeLabel: 'May 2026',
          username: 'Test User',
        );

        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(0));
        // PDF header magic bytes "%PDF-"
        expect(String.fromCharCodes(pdfBytes.take(5)), equals('%PDF-'));
      });
    });
  });
}
