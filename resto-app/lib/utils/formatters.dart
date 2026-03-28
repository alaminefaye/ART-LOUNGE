import 'package:intl/intl.dart';

class Formatters {
  // Formater un montant en FCFA
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount)} FCFA';
  }

  /// Montants pour imprimante thermique ESC/POS : uniquement caractères ASCII
  /// (évite l'espace insécable U+202F / U+00A0 du `fr_FR` qui provoque
  /// "Invalid argument (string): Contains invalid characters" dans esc_pos_utils_plus).
  static String formatCurrencyThermal(double amount) {
    final n = amount.round();
    if (n == 0) {
      return '0 FCFA';
    }
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

  /// Texte libre pour ESC/POS : espaces insécables + accents FR → ASCII (imprimantes 8 bits).
  static String sanitizeThermalText(String text) {
    var t = text
        .replaceAll('\u202f', ' ')
        .replaceAll('\u00a0', ' ')
        .replaceAll('\u2007', ' ')
        .replaceAll('\u2009', ' ');
    const replacements = <String, String>{
      'à': 'a', 'â': 'a', 'ä': 'a', 'À': 'A', 'Â': 'A',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'É': 'E', 'È': 'E',
      'î': 'i', 'ï': 'i', 'Î': 'I',
      'ô': 'o', 'ö': 'o', 'Ô': 'O',
      'ù': 'u', 'û': 'u', 'ü': 'u', 'Ù': 'U',
      'ç': 'c', 'Ç': 'C',
      'œ': 'oe', 'Œ': 'Oe',
    };
    for (final e in replacements.entries) {
      t = t.replaceAll(e.key, e.value);
    }
    return t;
  }

  // Formater une date
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  // Formater une date avec heure
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(date);
  }

  // Formater une date relative (il y a...)
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return formatDate(date);
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}

