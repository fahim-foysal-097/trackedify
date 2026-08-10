import 'package:flutter_test/flutter_test.dart';
import 'package:trackedify/services/currency_controller.dart';

void main() {
  group('CurrencyController', () {
    late CurrencyController controller;

    setUp(() {
      controller = CurrencyController.instance;
    });

    test('initial default values are usd and \$', () {
      expect(controller.code, equals('usd'));
      expect(controller.symbol, equals('\$'));
    });

    test('formatAmount formats numbers correctly', () {
      expect(controller.formatAmount(100), equals('\$100.00'));
      expect(controller.formatAmount(49.99), equals('\$49.99'));
      expect(controller.formatAmount(0), equals('\$0.00'));
    });

    test('formatAmount handles string inputs', () {
      expect(controller.formatAmount('123.45'), equals('\$123.45'));
      expect(controller.formatAmount('invalid'), equals('\$0.00'));
    });

    test('formatAmount handles null input', () {
      expect(controller.formatAmount(null), equals('\$0.00'));
    });

    test('kCurrencySymbols map contains essential currency symbols', () {
      expect(kCurrencySymbols['usd'], equals('\$'));
      expect(kCurrencySymbols['eur'], equals('€'));
      expect(kCurrencySymbols['gbp'], equals('£'));
      expect(kCurrencySymbols['jpy'], equals('¥'));
      expect(kCurrencySymbols['bdt'], equals('৳'));
      expect(kCurrencySymbols['inr'], equals('₹'));
    });
  });
}
