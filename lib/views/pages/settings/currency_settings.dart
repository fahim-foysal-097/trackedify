import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trackedify/database/database_helper.dart';
import 'package:trackedify/services/currency_controller.dart';
import 'package:trackedify/shared/widgets/app_snackbar.dart';

class CurrencySettingsPage extends StatefulWidget {
  const CurrencySettingsPage({super.key});

  @override
  State<CurrencySettingsPage> createState() => _CurrencySettingsPageState();
}

class _CurrencySettingsPageState extends State<CurrencySettingsPage>
    with SingleTickerProviderStateMixin {
  final _ctrl = CurrencyController.instance;

  // Currency list
  Map<String, String> _allCurrencies = {};
  List<MapEntry<String, String>> _filtered = [];
  bool _loadingList = true;
  String? _loadError;

  // Search
  final _searchCtrl = TextEditingController();

  // Tab controller for currency list vs converter test
  late TabController _tabCtrl;

  // Converter test state
  static const _testChain = ['usd', 'bdt', 'eur', 'jpy'];
  static const _testAmount = 200.0;
  List<_ConversionStep> _conversionSteps = [];
  bool _loadingTest = false;
  String? _testError;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadCurrencies();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    setState(() {
      _loadingList = true;
      _loadError = null;
    });
    try {
      final data = await _ctrl.fetchAllCurrencies();
      if (!mounted) return;
      setState(() {
        _allCurrencies = data;
        _applyFilter('');
        _loadingList = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loadingList = false;
      });
    }
  }

  void _applyFilter(String query) {
    final q = query.toLowerCase();
    final entries = _allCurrencies.entries.toList();
    if (q.isEmpty) {
      _filtered = entries;
    } else {
      _filtered = entries
          .where((e) => e.key.contains(q) || e.value.toLowerCase().contains(q))
          .toList();
    }
  }

  Future<void> _selectCurrency(String code, String name) async {
    final cs = Theme.of(context).colorScheme;
    final currentCode = _ctrl.code;
    if (code == currentCode) return;

    // Prompt for conversion
    final shouldConvert = await _showConversionDialog(
      context,
      fromCode: currentCode,
      fromName: _ctrl.name,
      toCode: code,
      toName: name,
      cs: cs,
    );

    if (!mounted) return;
    if (shouldConvert == null) return; // cancelled

    if (shouldConvert) {
      // Fetch rate and bulk-convert
      await _convertExpenses(currentCode, code);
      if (!mounted) return;
    }

    await _ctrl.setCurrency(code, name);
    if (!mounted) return;
    AppSnackBar.showSuccess(
      context,
      'Currency changed to ${name.isNotEmpty ? name : code.toUpperCase()}',
      icon: Icons.currency_exchange,
    );
  }

  /// Returns true=convert, false=don't convert, null=cancelled.
  Future<bool?> _showConversionDialog(
    BuildContext context, {
    required String fromCode,
    required String fromName,
    required String toCode,
    required String toName,
    required ColorScheme cs,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.currency_exchange, color: cs.primary),
            const SizedBox(width: 10),
            const Text('Convert Amounts?'),
          ],
        ),
        content: Text(
          'Do you want to convert your existing expense amounts from '
          '${fromName.isNotEmpty ? fromName : fromCode.toUpperCase()} '
          'to ${toName.isNotEmpty ? toName : toCode.toUpperCase()} '
          'using the current exchange rate?\n\n'
          'This will permanently update all amounts in the database. '
          'Selecting "No" only changes the currency symbol.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, just symbol'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Convert'),
          ),
        ],
      ),
    );
  }

  Future<void> _convertExpenses(String fromCode, String toCode) async {
    // Show loading dialog
    bool dialogOpen = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CupertinoActivityIndicator()),
      );
      dialogOpen = true;

      final rate = await _ctrl.fetchConversionRate(fromCode, toCode);

      if (!mounted) return;
      if (dialogOpen && Navigator.canPop(context)) {
        Navigator.pop(context);
        dialogOpen = false;
      }

      // Bulk update all expenses
      final db = await DatabaseHelper().database;
      await db.execute('UPDATE expenses SET amount = ROUND(amount * ?, 4)', [
        rate,
      ]);

      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        'All amounts converted (rate: ${rate.toStringAsFixed(6)})',
        icon: Icons.check_circle_outline,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      if (mounted && dialogOpen && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (!mounted) return;
      AppSnackBar.showError(context, 'Conversion failed: $e');
    }
  }

  // -- Converter Test -----------------------------------------------------------

  Future<void> _runConverterTest() async {
    setState(() {
      _loadingTest = true;
      _testError = null;
      _conversionSteps = [];
    });

    try {
      final steps = <_ConversionStep>[];
      double current = _testAmount;

      for (int i = 0; i < _testChain.length - 1; i++) {
        final from = _testChain[i];
        final to = _testChain[i + 1];
        final rate = await _ctrl.fetchConversionRate(from, to);
        final converted = current * rate;
        steps.add(
          _ConversionStep(
            fromCode: from,
            toCode: to,
            fromAmount: current,
            toAmount: converted,
            rate: rate,
          ),
        );
        current = converted;
      }

      if (!mounted) return;
      setState(() {
        _conversionSteps = steps;
        _loadingTest = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testError = e.toString();
        _loadingTest = false;
      });
    }
  }

  // -- Build --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency'),
        centerTitle: false,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 25),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.list_rounded), text: 'Select'),
            Tab(icon: Icon(Icons.science_outlined), text: 'Test Converter'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildCurrencyList(theme, cs),
          _buildConverterTest(theme, cs),
        ],
      ),
    );
  }

  // -- Currency List Tab --------------------------------------------------------

  Widget _buildCurrencyList(ThemeData theme, ColorScheme cs) {
    if (_loadingList) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(
              'Failed to load currencies',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              _loadError!,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadCurrencies,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search box
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search currencies…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _applyFilter(''));
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _applyFilter(v)),
          ),
        ),

        // Currently selected
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: cs.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Current: ${_ctrl.symbol} ${_ctrl.name} (${_ctrl.code.toUpperCase()})',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.primary),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // List
        Expanded(
          child: ListView.builder(
            itemCount: _filtered.length,
            itemBuilder: (context, i) {
              final entry = _filtered[i];
              final code = entry.key;
              final name = entry.value;
              final symbol = kCurrencySymbols[code] ?? code.toUpperCase();
              final isSelected = code == _ctrl.code;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? cs.primary
                      : cs.primary.withValues(alpha: 0.1),
                  child: Text(
                    symbol.length <= 2 ? symbol : code.toUpperCase()[0],
                    style: TextStyle(
                      color: isSelected ? cs.onPrimary : cs.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(
                  name.isNotEmpty
                      ? '${name[0].toUpperCase()}${name.substring(1)}'
                      : code.toUpperCase(),
                ),
                subtitle: Text(code.toUpperCase()),
                trailing: isSelected
                    ? Icon(Icons.check_rounded, color: cs.primary)
                    : null,
                tileColor: isSelected
                    ? cs.primary.withValues(alpha: 0.06)
                    : null,
                onTap: () => _selectCurrency(code, name),
              );
            },
          ),
        ),
      ],
    );
  }

  // -- Converter Test Tab -------------------------------------------------------

  Widget _buildConverterTest(ThemeData theme, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: cs.primary.withValues(alpha: 0.07),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.science_outlined, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Live Conversion Test',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Converts \$200 USD → BDT → EUR → JPY '
                    'using live exchange rates.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loadingTest ? null : _runConverterTest,
                      icon: _loadingTest
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        _loadingTest ? 'Fetching rates…' : 'Run Test',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_testError != null) ...[
            const SizedBox(height: 16),
            Card(
              color: cs.errorContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: cs.onErrorContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _testError!,
                        style: TextStyle(color: cs.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (_conversionSteps.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Results',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ..._conversionSteps.asMap().entries.map(
              (e) => _buildStepCard(e.value, theme, cs, e.key),
            ),
            const SizedBox(height: 12),
            // Final result summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Final result',
                    style: TextStyle(
                      color: cs.onPrimary.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${_testAmount.toStringAsFixed(2)} USD'
                    '  →  '
                    '¥${_conversionSteps.last.toAmount.toStringAsFixed(2)} JPY',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCard(
    _ConversionStep step,
    ThemeData theme,
    ColorScheme cs,
    int index,
  ) {
    final fromSymbol =
        kCurrencySymbols[step.fromCode] ?? step.fromCode.toUpperCase();
    final toSymbol = kCurrencySymbols[step.toCode] ?? step.toCode.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.primary.withValues(alpha: 0.15),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$fromSymbol${step.fromAmount.toStringAsFixed(2)} '
                        '${step.fromCode.toUpperCase()}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward, size: 14),
                      ),
                      Flexible(
                        child: Text(
                          '$toSymbol${step.toAmount.toStringAsFixed(2)} '
                          '${step.toCode.toUpperCase()}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rate: 1 ${step.fromCode.toUpperCase()} = '
                    '${step.rate.toStringAsFixed(6)} ${step.toCode.toUpperCase()}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversionStep {
  final String fromCode;
  final String toCode;
  final double fromAmount;
  final double toAmount;
  final double rate;

  const _ConversionStep({
    required this.fromCode,
    required this.toCode,
    required this.fromAmount,
    required this.toAmount,
    required this.rate,
  });
}
