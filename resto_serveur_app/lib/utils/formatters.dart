import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount)} FCFA';
  }

  static String formatCurrencyThermal(double amount) {
    final n = amount.round();
    if (n == 0) return '0 FCFA';
    final neg = n < 0;
    final digits = n.abs().toString();
    final rev = digits.split('').reversed.join();
    final parts = <String>[];
    for (var i = 0; i < rev.length; i += 3) {
      final end = i + 3 <= rev.length ? i + 3 : rev.length;
      parts.add(rev.substring(i, end));
    }
    final spaced = parts.join(' ');
    final forward = spaced.split('').reversed.join();
    final numStr = neg ? '-$forward' : forward;
    return '$numStr FCFA';
  }

  static String sanitizeThermalText(String text) {
    var t = text
        .replaceAll('\u202f', ' ')
        .replaceAll('\u00a0', ' ')
        .replaceAll('\u2007', ' ')
        .replaceAll('\u2009', ' ');
    const replacements = <String, String>{
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'À': 'A',
      'Â': 'A',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'É': 'E',
      'È': 'E',
      'î': 'i',
      'ï': 'i',
      'Î': 'I',
      'ô': 'o',
      'ö': 'o',
      'Ô': 'O',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'Ù': 'U',
      'ç': 'c',
      'Ç': 'C',
      'œ': 'oe',
      'Œ': 'Oe',
    };
    for (final e in replacements.entries) {
      t = t.replaceAll(e.key, e.value);
    }
    return t;
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm', 'fr_FR').format(date);
  }
}
