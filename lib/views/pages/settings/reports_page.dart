import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:trackedify/database/database_helper.dart';
import 'package:trackedify/services/currency_controller.dart';
import 'package:trackedify/services/report_service.dart';
import 'package:trackedify/shared/widgets/app_snackbar.dart';
import 'package:trackedify/shared/widgets/custom_dialog.dart';

enum DateRangePreset {
  allTime,
  thisMonth,
  lastMonth,
  last30Days,
  thisYear,
  custom,
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final CurrencyController _currencyCtrl = CurrencyController.instance;

  DateRangePreset _selectedPreset = DateRangePreset.thisMonth;
  DateTimeRange? _customDateRange;

  bool _isLoadingData = true;
  bool _isGeneratingPdf = false;
  bool _isExportingCsv = false;

  List<Map<String, dynamic>> _allExpenses = [];
  List<Map<String, dynamic>> _filteredExpenses = [];
  String _username = 'User';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      await _currencyCtrl.load();
      final db = await _dbHelper.database;
      final expenses = await db.query(
        'expenses_with_category',
        orderBy: 'date DESC, id DESC',
      );

      final users = await db.query('user_info', limit: 1);
      if (users.isNotEmpty && users.first['username'] != null) {
        _username = users.first['username'].toString();
      }

      if (mounted) {
        setState(() {
          _allExpenses = expenses;
          _isLoadingData = false;
        });
        _applyDateFilter();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        AppSnackBar.showError(context, 'Failed to load expenses: $e');
      }
    }
  }

  void _applyDateFilter() {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;

    switch (_selectedPreset) {
      case DateRangePreset.allTime:
        start = null;
        end = null;
        break;
      case DateRangePreset.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case DateRangePreset.lastMonth:
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case DateRangePreset.last30Days:
        start = now.subtract(const Duration(days: 30));
        end = now;
        break;
      case DateRangePreset.thisYear:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case DateRangePreset.custom:
        start = _customDateRange?.start;
        end = _customDateRange?.end;
        break;
    }

    final filtered = ReportService.filterExpensesByDateRange(
      _allExpenses,
      start,
      end,
    );

    setState(() {
      _filteredExpenses = filtered;
    });
  }

  String _getDateRangeLabel() {
    final DateFormat fmt = DateFormat('MMM dd, yyyy');
    final now = DateTime.now();

    switch (_selectedPreset) {
      case DateRangePreset.allTime:
        return 'All Time';
      case DateRangePreset.thisMonth:
        return DateFormat('MMMM yyyy').format(now);
      case DateRangePreset.lastMonth:
        final lastM = DateTime(now.year, now.month - 1, 1);
        return DateFormat('MMMM yyyy').format(lastM);
      case DateRangePreset.last30Days:
        final start = now.subtract(const Duration(days: 30));
        return '${fmt.format(start)} - ${fmt.format(now)}';
      case DateRangePreset.thisYear:
        return '${now.year} (Jan - Dec)';
      case DateRangePreset.custom:
        if (_customDateRange != null) {
          return '${fmt.format(_customDateRange!.start)} - ${fmt.format(_customDateRange!.end)}';
        }
        return 'Custom Date Range';
    }
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange:
          _customDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPreset = DateRangePreset.custom;
        _customDateRange = picked;
      });
      _applyDateFilter();
    }
  }

  double _calculateTotalAmount() {
    double total = 0;
    for (var e in _filteredExpenses) {
      final amt = e['amount'] is num
          ? (e['amount'] as num).toDouble()
          : (double.tryParse(e['amount'].toString()) ?? 0.0);
      total += amt;
    }
    return total;
  }

  Future<void> _savePdfToDevice() async {
    if (_isGeneratingPdf) return;
    if (_filteredExpenses.isEmpty) {
      AppSnackBar.showInfo(
        context,
        'No expenses available for the selected period.',
      );
      return;
    }

    setState(() => _isGeneratingPdf = true);

    try {
      final pdfBytes = await ReportService.generatePdfBytes(
        expenses: _filteredExpenses,
        currencySymbol: _currencyCtrl.symbol,
        currencyCode: _currencyCtrl.code,
        dateRangeLabel: _getDateRangeLabel(),
        username: _username,
      );

      final timeStampStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'Trackedify_Report_$timeStampStr.pdf';

      final tempFile = await ReportService.createTempCsvFile('', fileName);
      final pdfFile = File(tempFile.path);
      await pdfFile.writeAsBytes(pdfBytes, flush: true);

      final params = SaveFileDialogParams(
        sourceFilePath: pdfFile.path,
        fileName: fileName,
      );

      final savedPath = await FlutterFileDialog.saveFile(params: params);

      try {
        if (pdfFile.existsSync()) await pdfFile.delete();
      } catch (_) {}

      if (mounted && savedPath != null) {
        final isUri = savedPath.startsWith('content://');
        AppSnackBar.showSuccess(
          context,
          isUri
              ? 'PDF Report saved successfully.'
              : 'PDF saved to: ${p.basename(savedPath)}',
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to save PDF: $e');
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _generateAndSharePdf() async {
    if (_isGeneratingPdf) return;
    if (_filteredExpenses.isEmpty) {
      AppSnackBar.showInfo(
        context,
        'No expenses available for the selected period.',
      );
      return;
    }

    setState(() => _isGeneratingPdf = true);

    try {
      final pdfBytes = await ReportService.generatePdfBytes(
        expenses: _filteredExpenses,
        currencySymbol: _currencyCtrl.symbol,
        currencyCode: _currencyCtrl.code,
        dateRangeLabel: _getDateRangeLabel(),
        username: _username,
      );

      final timeStampStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'Trackedify_Report_$timeStampStr.pdf';

      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);

      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          'PDF Report generated!',
          icon: Icons.picture_as_pdf_outlined,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to generate PDF: $e');
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _exportFilteredCsv() async {
    if (_isExportingCsv) return;
    if (_filteredExpenses.isEmpty) {
      AppSnackBar.showInfo(
        context,
        'No expenses available for the selected period.',
      );
      return;
    }

    setState(() => _isExportingCsv = true);

    try {
      final csvContent = ReportService.generateCsv(
        expenses: _filteredExpenses,
        currencySymbol: _currencyCtrl.symbol,
        currencyCode: _currencyCtrl.code,
        dateRangeLabel: _getDateRangeLabel(),
      );

      final timeStampStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'Trackedify_Expenses_$timeStampStr.csv';

      final tmpFile = await ReportService.createTempCsvFile(
        csvContent,
        fileName,
      );

      final params = SaveFileDialogParams(
        sourceFilePath: tmpFile.path,
        fileName: fileName,
      );

      final savedPath = await FlutterFileDialog.saveFile(params: params);

      try {
        if (tmpFile.existsSync()) await tmpFile.delete();
      } catch (_) {}

      if (mounted) {
        if (savedPath != null) {
          final isUri = savedPath.startsWith('content://');
          AppSnackBar.showSuccess(
            context,
            isUri
                ? 'CSV exported successfully.'
                : 'CSV saved to: ${p.basename(savedPath)}',
            icon: Icons.table_chart_outlined,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to export CSV: $e');
      }
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
  }

  void _showTipsDialog() {
    InfoDialog.show(
      context: context,
      title: 'PDF & CSV Reports',
      message:
          'Generate official printable PDF summary reports complete with pie charts, category distribution, and itemized logs for tax and accounting. Or export filtered CSV files for spreadsheet software.',
      buttonLabel: 'Got it',
      icon: Icons.lightbulb_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final totalSpent = _calculateTotalAmount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Exports'),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Tips',
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _showTipsDialog,
          ),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CupertinoActivityIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.print_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Statement & Reports',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Printable PDF & CSV Spreadsheet Exports',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Filter Presets Section
                  Text(
                    'Select Time Period',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip('This Month', DateRangePreset.thisMonth),
                      _buildPresetChip('Last Month', DateRangePreset.lastMonth),
                      _buildPresetChip(
                        'Last 30 Days',
                        DateRangePreset.last30Days,
                      ),
                      _buildPresetChip('This Year', DateRangePreset.thisYear),
                      _buildPresetChip('All Time', DateRangePreset.allTime),
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.date_range_rounded, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _selectedPreset == DateRangePreset.custom &&
                                      _customDateRange != null
                                  ? '${DateFormat('MMM d').format(_customDateRange!.start)} - ${DateFormat('MMM d').format(_customDateRange!.end)}'
                                  : 'Custom Range...',
                            ),
                          ],
                        ),
                        selected: _selectedPreset == DateRangePreset.custom,
                        selectedColor: cs.primary,
                        labelStyle: TextStyle(
                          color: _selectedPreset == DateRangePreset.custom
                              ? cs.onPrimary
                              : cs.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            _selectCustomDateRange();
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Report Preview Card
                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Report Summary',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getDateRangeLabel(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  label: 'Total Expenses',
                                  value: _currencyCtrl.formatAmount(totalSpent),
                                  icon: Icons.account_balance_wallet_outlined,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatItem(
                                  label: 'Transactions',
                                  value: '${_filteredExpenses.length}',
                                  icon: Icons.receipt_long_outlined,
                                  color: cs.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Action Buttons
                  Text(
                    'PDF Report Options',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Save PDF Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_isGeneratingPdf || _isExportingCsv)
                              ? null
                              : _savePdfToDevice,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          icon: _isGeneratingPdf
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 20),
                          label: Text(
                            _isGeneratingPdf ? 'Saving...' : 'Save PDF',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Print / Share PDF Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (_isGeneratingPdf || _isExportingCsv)
                              ? null
                              : _generateAndSharePdf,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: cs.primary, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 20),
                          label: Text(
                            'Print / Share',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // CSV Section Header & Action Button
                  Text(
                    'Spreadsheet Export',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: (_isGeneratingPdf || _isExportingCsv)
                          ? null
                          : _exportFilteredCsv,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: cs.secondary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isExportingCsv
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.table_chart_outlined,
                              color: cs.secondary,
                            ),
                      label: Text(
                        _isExportingCsv
                            ? 'Exporting CSV...'
                            : 'Save Filtered CSV Spreadsheet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.secondary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildPresetChip(String label, DateRangePreset preset) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedPreset == preset;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: cs.primary,
      labelStyle: TextStyle(
        color: isSelected ? cs.onPrimary : cs.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPreset = preset;
          });
          _applyDateFilter();
        }
      },
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
