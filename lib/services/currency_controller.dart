import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';

const Map<String, String> kCurrencySymbols = {
  'usd': '\$',
  'eur': '€',
  'gbp': '£',
  'jpy': '¥',
  'aud': 'A\$',
  'cad': 'C\$',
  'chf': 'CHF',
  'cny': '¥',
  'sek': 'kr',
  'nzd': 'NZ\$',
  'inr': '₹',
  'rub': '₽',
  'bdt': '৳',
  'zar': 'R',
  'try': '₺',
  'brl': 'R\$',
  'twd': 'NT\$',
  'dkk': 'kr',
  'pln': 'zł',
  'thb': '฿',
  'idr': 'Rp',
  'huf': 'Ft',
  'czk': 'Kč',
  'ils': '₪',
  'clp': 'CLP\$',
  'php': '₱',
  'aed': 'د.إ',
  'cop': 'COL\$',
  'sar': '﷼',
  'myr': 'RM',
  'ron': 'lei',
};

class CurrencyController extends ChangeNotifier {
  static final CurrencyController instance = CurrencyController._();

  CurrencyController._();

  String _selectedCurrencyCode = 'usd';
  String _selectedCurrencyName = 'US Dollar';
  String _selectedCurrencySymbol = '\$';

  String get code => _selectedCurrencyCode;
  String get name => _selectedCurrencyName;
  String get symbol => _selectedCurrencySymbol;
  String get currencySymbol => _selectedCurrencySymbol;

  Future<void> load() async {
    // 1. Try loading from Database first (primary source of truth for user data)
    try {
      final cur = await DatabaseHelper().getCurrency();
      if (cur != null && cur['code'] != null && cur['code']!.isNotEmpty) {
        final code = cur['code']!;
        final name = cur['name'] ?? code.toUpperCase();
        final sym =
            cur['symbol'] ??
            kCurrencySymbols[code.toLowerCase()] ??
            code.toUpperCase();

        _selectedCurrencyCode = code;
        _selectedCurrencyName = name;
        _selectedCurrencySymbol = sym;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('currency_code', code);
        await prefs.setString('currency_name', name);
        await prefs.setString('currency_symbol', sym);

        notifyListeners();
        return;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('CurrencyController.load from DB failed: $e');
    }

    // 2. Fallback to SharedPreferences if DB has no currency info
    final prefs = await SharedPreferences.getInstance();
    _selectedCurrencyCode = prefs.getString('currency_code') ?? 'usd';
    _selectedCurrencyName = prefs.getString('currency_name') ?? 'US Dollar';
    _selectedCurrencySymbol =
        prefs.getString('currency_symbol') ??
        kCurrencySymbols[_selectedCurrencyCode.toLowerCase()] ??
        '\$';
    notifyListeners();
  }

  /// Force reload and sync currency settings directly from the current database
  Future<void> syncFromDatabase() async {
    try {
      final cur = await DatabaseHelper().getCurrency();
      if (cur != null && cur['code'] != null && cur['code']!.isNotEmpty) {
        await setCurrency(
          cur['code']!,
          cur['name'] ?? cur['code']!,
          cur['symbol'],
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to sync currency from DB: $e');
    }
  }

  Future<void> setCurrency(String code, String name, [String? symbol]) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanCode = code.trim().toLowerCase();
    final cleanName = name.trim().isNotEmpty && name != 'null'
        ? name.trim()
        : cleanCode.toUpperCase();
    final sym = (symbol != null && symbol.trim().isNotEmpty && symbol != 'null')
        ? symbol.trim()
        : (kCurrencySymbols[cleanCode] ?? cleanCode.toUpperCase());

    await prefs.setString('currency_code', cleanCode);
    await prefs.setString('currency_name', cleanName);
    await prefs.setString('currency_symbol', sym);

    await DatabaseHelper().updateCurrency(cleanCode, cleanName, sym);

    _selectedCurrencyCode = cleanCode;
    _selectedCurrencyName = cleanName;
    _selectedCurrencySymbol = sym;
    notifyListeners();
  }

  /// Formats the given amount with the currently selected currency symbol.
  String formatAmount(dynamic amount) {
    if (amount == null) return '${_selectedCurrencySymbol}0.00';

    double val;
    if (amount is num) {
      val = amount.toDouble();
    } else {
      val = double.tryParse(amount.toString()) ?? 0.0;
    }

    return '$_selectedCurrencySymbol${val.toStringAsFixed(2)}';
  }

  /// Fetches all available currencies
  Future<Map<String, String>> fetchAllCurrencies() async {
    final primaryUrl = Uri.parse(
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies.json',
    );
    final fallbackUrl = Uri.parse(
      'https://currency-api.pages.dev/v1/currencies.json',
    );

    try {
      final res = await http
          .get(primaryUrl)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Primary currency API failed: $e');
    }

    // Try fallback
    try {
      final res = await http
          .get(fallbackUrl)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Fallback currency API failed: $e');
    }

    throw Exception('Failed to fetch currencies list');
  }

  /// Fetches conversion rate via Fawazahmed0 Currency API
  Future<double> fetchConversionRate(String fromCode, String toCode) async {
    final from = fromCode.toLowerCase();
    final to = toCode.toLowerCase();
    if (from == to) return 1.0;

    final primaryUrl = Uri.parse(
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/$from.json',
    );
    final fallbackUrl = Uri.parse(
      'https://currency-api.pages.dev/v1/currencies/$from.json',
    );

    try {
      final res = await http
          .get(primaryUrl)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rate = data[from][to];
        if (rate != null) return (rate as num).toDouble();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Primary currency API failed: $e');
    }

    // Try fallback
    try {
      final res = await http
          .get(fallbackUrl)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rate = data[from][to];
        if (rate != null) return (rate as num).toDouble();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Fallback currency API failed: $e');
    }

    throw Exception('Failed to fetch conversion rate from $from to $to');
  }
}
