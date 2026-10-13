import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/profile_provider.dart';

class CurrencyFormatter {
  const CurrencyFormatter({required this.symbol, required this.rate});
  final String symbol;
  final double rate;

  String format(num bdtValue, {bool withNight = false}) {
    final value = bdtValue / rate;
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: symbol == '৳' || symbol == '₹' ? 0 : 0,
      customPattern: symbol == '৳' || symbol == '₹' ? '\u00A4#,##0' : '\u00A4#,##0',
    );
    final str = formatter.format(value);
    return withNight ? '$str/night' : str;
  }
}

final currencyFormatterProvider = Provider<CurrencyFormatter>((ref) {
  final currencyStr = ref.watch(profileProvider).currency;

  if (currencyStr.contains('USD')) return const CurrencyFormatter(symbol: r'$', rate: 110.0);
  if (currencyStr.contains('EUR')) return const CurrencyFormatter(symbol: '€', rate: 120.0);
  if (currencyStr.contains('GBP')) return const CurrencyFormatter(symbol: '£', rate: 140.0);
  if (currencyStr.contains('INR')) return const CurrencyFormatter(symbol: '₹', rate: 1.32);

  return const CurrencyFormatter(symbol: '৳', rate: 1.0);
});

// Legacy backward-compatibility if needed
class CurrencyFormatters {
  const CurrencyFormatters._();

  static final NumberFormat bdt = NumberFormat.currency(
    locale: 'en_BD',
    symbol: '৳',
    decimalDigits: 0,
  );

  static String perNight(num value) => '${bdt.format(value)} / night';
}
