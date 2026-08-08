import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportService {
  /// Filter expenses by a given date range [startDate, endDate].
  static List<Map<String, dynamic>> filterExpensesByDateRange(
    List<Map<String, dynamic>> expenses,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null && endDate == null) return expenses;

    return expenses.where((item) {
      final rawDate = item['date']?.toString();
      if (rawDate == null || rawDate.isEmpty) return false;
      final parsedDate = DateTime.tryParse(rawDate);
      if (parsedDate == null) return false;

      if (startDate != null && parsedDate.isBefore(startDate)) {
        return false;
      }
      if (endDate != null) {
        final inclusiveEnd = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
          999,
        );
        if (parsedDate.isAfter(inclusiveEnd)) return false;
      }
      return true;
    }).toList();
  }

  /// Convert a currency symbol/code into a 100% reliable PDF-safe string
  static String formatPdfCurrency(String symbol, String code) {
    final s = symbol.trim();
    final c = code.trim().toLowerCase();

    // Standard Latin-1 symbols that render natively across all PDF viewers
    if (s == '\$' ||
        s == '€' ||
        s == '£' ||
        s == '¥' ||
        s == 'kr' ||
        s == 'R' ||
        s == 'RM' ||
        s == 'lei') {
      return s;
    }

    // Mapping complex non-Latin script symbols to clean, unbreakable ISO 4217 representations
    const map = <String, String>{
      'bdt': 'BDT',
      'inr': 'INR',
      'aed': 'AED',
      'sar': 'SAR',
      'rub': 'RUB',
      'try': 'TRY',
      'thb': 'THB',
      'idr': 'IDR',
      'huf': 'HUF',
      'czk': 'CZK',
      'ils': 'ILS',
      'php': 'PHP',
      'clp': 'CLP\$',
      'cop': 'COP\$',
      'brl': 'R\$',
      'twd': 'NT\$',
      'nzd': 'NZ\$',
      'aud': 'A\$',
      'cad': 'C\$',
      'chf': 'CHF',
      'cny': 'CNY',
      'sek': 'SEK',
      'dkk': 'DKK',
      'pln': 'PLN',
    };

    if (map.containsKey(c)) {
      return map[c]!;
    }

    // Check if the symbol contains ONLY basic Latin/ASCII chars (runes <= 255)
    final isBasicAscii = s.isNotEmpty && s.runes.every((r) => r <= 255);
    if (isBasicAscii) {
      return s;
    }

    return code.isNotEmpty ? code.toUpperCase() : '\$';
  }

  static String _fmtAmount(double amt, String formattedSymbol) {
    if (formattedSymbol.length == 1 &&
        (formattedSymbol == '\$' ||
            formattedSymbol == '€' ||
            formattedSymbol == '£' ||
            formattedSymbol == '¥')) {
      return '$formattedSymbol${amt.toStringAsFixed(2)}';
    }
    return '$formattedSymbol ${amt.toStringAsFixed(2)}';
  }

  /// Generate CSV content for expenses
  static String generateCsv({
    required List<Map<String, dynamic>> expenses,
    required String currencySymbol,
    String currencyCode = 'usd',
    required String dateRangeLabel,
  }) {
    final sb = StringBuffer();
    final pdfCurrency = formatPdfCurrency(currencySymbol, currencyCode);

    // CSV Metadata Header
    sb.writeln('# Trackedify Expense Report');
    sb.writeln('# Period: ${_escapeCsv(dateRangeLabel)}');
    sb.writeln(
      '# Exported At: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
    );
    sb.writeln('# Currency: ${_escapeCsv(pdfCurrency)}');
    sb.writeln();

    // Column Headers
    sb.writeln('ID,Date,Category,Amount,Currency,Note');

    double totalAmount = 0.0;
    for (var row in expenses) {
      final id = row['id'];
      final date = row['date'];
      final category = row['category'] ?? 'Uncategorized';
      final amountNum = row['amount'] is num
          ? (row['amount'] as num).toDouble()
          : (double.tryParse(row['amount'].toString()) ?? 0.0);
      final note = row['note'] ?? '';

      totalAmount += amountNum;

      sb.writeln(
        [
          _escapeCsv(id?.toString() ?? ''),
          _escapeCsv(date?.toString() ?? ''),
          _escapeCsv(category.toString()),
          amountNum.toStringAsFixed(2),
          _escapeCsv(pdfCurrency),
          _escapeCsv(note.toString()),
        ].join(','),
      );
    }

    sb.writeln();
    sb.writeln('# Total Expenses: ${expenses.length} item(s)');
    sb.writeln(
      '# Total Amount: ${_fmtAmount(totalAmount, pdfCurrency)}',
    );

    return sb.toString();
  }

  /// Helper to safely escape CSV values
  static String _escapeCsv(String val) {
    if (val.contains(',') ||
        val.contains('"') ||
        val.contains('\n') ||
        val.contains('\r')) {
      final escaped = val.replaceAll('"', '""');
      return '"$escaped"';
    }
    return val;
  }

  /// Generate PDF Document Bytes
  static Future<Uint8List> generatePdfBytes({
    required List<Map<String, dynamic>> expenses,
    required String currencySymbol,
    String currencyCode = 'usd',
    required String dateRangeLabel,
    String username = 'User',
  }) async {
    final pdfCurrency = formatPdfCurrency(currencySymbol, currencyCode);

    // Load full UTF-8 Unicode fonts so all international currency symbols render cleanly
    pw.Font? mainFont;
    pw.Font? fallbackFont;

    try {
      mainFont = await PdfGoogleFonts.interRegular();
      fallbackFont = await PdfGoogleFonts.notoSansRegular();
    } catch (_) {
      try {
        final fontData = await rootBundle.load('assets/fonts/Inter.ttf');
        mainFont = pw.Font.ttf(fontData);
      } catch (_) {}
    }

    final pdfTheme = pw.ThemeData.withFont(
      base: mainFont,
      bold: mainFont,
      fontFallback: fallbackFont != null ? [fallbackFont] : [],
    );

    final pdf = pw.Document(theme: pdfTheme);

    // Compute category aggregations
    final Map<String, double> categoryTotals = {};
    double grandTotal = 0.0;

    for (var e in expenses) {
      final cat = (e['category'] ?? 'Uncategorized').toString();
      final amt = e['amount'] is num
          ? (e['amount'] as num).toDouble()
          : (double.tryParse(e['amount'].toString()) ?? 0.0);
      categoryTotals[cat] = (categoryTotals[cat] ?? 0.0) + amt;
      grandTotal += amt;
    }

    // Sorted categories by highest total
    final sortedCategoryEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Preset vibrant PDF palette for categories
    final List<PdfColor> colorPalette = [
      PdfColors.indigo600,
      PdfColors.orange600,
      PdfColors.teal600,
      PdfColors.pink600,
      PdfColors.amber600,
      PdfColors.purple600,
      PdfColors.blue600,
      PdfColors.green600,
      PdfColors.red600,
      PdfColors.cyan600,
      PdfColors.brown600,
      PdfColors.grey600,
    ];

    final DateFormat dateFmt = DateFormat('yyyy-MM-dd');
    final String generatedDate = DateFormat(
      'MMM dd, yyyy - HH:mm',
    ).format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 24,
                        height: 24,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.indigo700,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'T',
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'Trackedify Financial Report',
                        style: const pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Period: $dateRangeLabel',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(color: PdfColors.indigo200, thickness: 1),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated for $username on $generatedDate',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Executive Summary Cards
            pw.Row(
              children: [
                _buildPdfSummaryCard(
                  title: 'TOTAL SPENT',
                  value: _fmtAmount(grandTotal, pdfCurrency),
                  color: PdfColors.indigo700,
                  bgColor: PdfColors.indigo50,
                ),
                pw.SizedBox(width: 12),
                _buildPdfSummaryCard(
                  title: 'TRANSACTIONS',
                  value: '${expenses.length}',
                  color: PdfColors.teal700,
                  bgColor: PdfColors.teal50,
                ),
                pw.SizedBox(width: 12),
                _buildPdfSummaryCard(
                  title: 'CATEGORIES',
                  value: '${categoryTotals.length}',
                  color: PdfColors.orange700,
                  bgColor: PdfColors.orange50,
                ),
                pw.SizedBox(width: 12),
                _buildPdfSummaryCard(
                  title: 'AVG / TXN',
                  value: expenses.isEmpty
                      ? _fmtAmount(0, pdfCurrency)
                      : _fmtAmount(grandTotal / expenses.length, pdfCurrency),
                  color: PdfColors.purple700,
                  bgColor: PdfColors.purple50,
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Pie Chart & Category Table Section
            if (sortedCategoryEntries.isNotEmpty) ...[
              pw.Text(
                'Expense Breakdown by Category',
                style: const pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Custom Pie Chart
                  pw.Container(
                    width: 160,
                    height: 160,
                    alignment: pw.Alignment.center,
                    child: pw.CustomPaint(
                      size: const PdfPoint(150, 150),
                      painter: (PdfGraphics canvas, PdfPoint size) {
                        final double cx = size.x / 2;
                        final double cy = size.y / 2;
                        final double radius = min(cx, cy) - 5;

                        if (grandTotal <= 0) {
                          canvas.setFillColor(PdfColors.grey300);
                          canvas.drawEllipse(cx, cy, radius, radius);
                          canvas.fillPath();
                          return;
                        }

                        double startAngle = -pi / 2;
                        for (int i = 0; i < sortedCategoryEntries.length; i++) {
                          final entry = sortedCategoryEntries[i];
                          final sweep = (entry.value / grandTotal) * 2 * pi;
                          if (sweep <= 0) continue;

                          final color = colorPalette[i % colorPalette.length];
                          canvas.setFillColor(color);
                          canvas.moveTo(cx, cy);

                          const int steps = 40;
                          for (int s = 0; s <= steps; s++) {
                            final angle = startAngle + (sweep * s / steps);
                            final x = cx + radius * cos(angle);
                            final y = cy + radius * sin(angle);
                            canvas.lineTo(x, y);
                          }
                          canvas.lineTo(cx, cy);
                          canvas.fillPath();

                          startAngle += sweep;
                        }

                        // Inner white circle for Donut style
                        canvas.setFillColor(PdfColors.white);
                        canvas.drawEllipse(
                          cx,
                          cy,
                          radius * 0.45,
                          radius * 0.45,
                        );
                        canvas.fillPath();
                      },
                    ),
                  ),
                  pw.SizedBox(width: 20),

                  // Category Breakdown Table
                  pw.Expanded(
                    child: pw.Table(
                      border: pw.TableBorder.all(
                        color: PdfColors.grey300,
                        width: 0.5,
                      ),
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey100,
                          ),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                'Category',
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                'Amount',
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                'Share',
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        ...sortedCategoryEntries.asMap().entries.map((item) {
                          final idx = item.key;
                          final entry = item.value;
                          final color = colorPalette[idx % colorPalette.length];
                          final percent = grandTotal > 0
                              ? (entry.value / grandTotal) * 100
                              : 0.0;

                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Row(
                                  children: [
                                    pw.Container(
                                      width: 8,
                                      height: 8,
                                      decoration: pw.BoxDecoration(
                                        color: color,
                                        shape: pw.BoxShape.circle,
                                      ),
                                    ),
                                    pw.SizedBox(width: 5),
                                    pw.Expanded(
                                      child: pw.Text(
                                        entry.key,
                                        style: const pw.TextStyle(
                                          fontSize: 8.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(
                                  _fmtAmount(entry.value, pdfCurrency),
                                  style: const pw.TextStyle(fontSize: 8.5),
                                  textAlign: pw.TextAlign.right,
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(
                                  '${percent.toStringAsFixed(1)}%',
                                  style: const pw.TextStyle(fontSize: 8.5),
                                  textAlign: pw.TextAlign.right,
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
            ],

            // Itemized Expenses Table
            pw.Text(
              'Itemized Transactions (${expenses.length})',
              style: const pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 8),

            if (expenses.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'No transactions found for the selected period.',
                  style: const pw.TextStyle(
                    color: PdfColors.grey600,
                    fontSize: 10,
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.indigo50,
                ),
                headerStyle: const pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                cellStyle: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey900,
                ),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 5,
                ),
                headers: ['Date', 'Category', 'Note', 'Amount'],
                columnWidths: {
                  0: const pw.FixedColumnWidth(80),
                  1: const pw.FixedColumnWidth(100),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FixedColumnWidth(80),
                },
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                },
                data: expenses.map((item) {
                  final rawDate = item['date']?.toString() ?? '';
                  String displayDate = rawDate;
                  final dt = DateTime.tryParse(rawDate);
                  if (dt != null) {
                    displayDate = dateFmt.format(dt);
                  }

                  final cat = item['category']?.toString() ?? 'Uncategorized';
                  final note = item['note']?.toString() ?? '';
                  final amt = item['amount'] is num
                      ? (item['amount'] as num).toDouble()
                      : (double.tryParse(item['amount'].toString()) ?? 0.0);

                  return [
                    displayDate,
                    cat,
                    note,
                    _fmtAmount(amt, pdfCurrency),
                  ];
                }).toList(),
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfSummaryCard({
    required String title,
    required String value,
    required PdfColor color,
    required PdfColor bgColor,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: color, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Write CSV string to a temporary file
  static Future<File> createTempCsvFile(
    String csvContent,
    String filename,
  ) async {
    final tmpDir = await getTemporaryDirectory();
    final file = File(p.join(tmpDir.path, filename));
    await file.writeAsString(csvContent, flush: true);
    return file;
  }
}
