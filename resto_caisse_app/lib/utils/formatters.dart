import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(double amount) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    return formatCurrency.format(amount);
  }
}
