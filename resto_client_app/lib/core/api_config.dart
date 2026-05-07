import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    final fromEnv = const String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return _normalize(fromEnv);
    }

    if (kIsWeb) {
      return '${Uri.base.origin}/api';
    }

    return 'https://artlounge.universaltechnologiesafrica.com/api';
  }

  static String _normalize(String url) {
    var u = url.trim();
    if (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (!u.endsWith('/api')) {
      u = '$u/api';
    }
    return u;
  }
}
