import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._apiClient);

  final ApiClient _apiClient;

  bool _isReady = false;
  bool get isReady => _isReady;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  String? _token;
  String? get token => _token;

  String? _userName;
  String? get userName => _userName;

  int _pointsFidelite = 0;
  int get pointsFidelite => _pointsFidelite;

  bool _fidelityEnabled = false;
  bool get fidelityEnabled => _fidelityEnabled;

  double _valeurFcfa1Point = 0;
  double get valeurFcfa1Point => _valeurFcfa1Point;

  bool _waveEnabled = true;
  bool get waveEnabled => _waveEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      _token = savedToken;
      _apiClient.setAuthToken(_token);
      _isAuthenticated = true;
      try {
        await refreshMe();
      } catch (_) {}
    }
    _isReady = true;
    notifyListeners();
  }

  Future<void> login({required String identifier, required String password}) async {
    try {
      final res = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': identifier, 'password': password},
      );
      final data = res.data;
      final token = (data is Map) ? data['token'] as String? : null;
      if (token == null || token.isEmpty) {
        throw Exception('Token manquant');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      _token = token;
      _apiClient.setAuthToken(_token);
      _isAuthenticated = true;

      _userName = (data is Map && data['user'] is Map) ? (data['user']['name'] as String?) : null;
      _pointsFidelite = (data is Map && data['client'] is Map) ? ((data['client']['points_fidelite'] ?? 0) as num).toInt() : 0;
      _fidelityEnabled = (data is Map && data['fidelity_settings'] is Map) ? (data['fidelity_settings']['actif'] == true) : false;
      _valeurFcfa1Point = (data is Map && data['fidelity_settings'] is Map)
          ? ((data['fidelity_settings']['valeur_fcfa_1_point'] ?? 0) as num).toDouble()
          : 0;
      _waveEnabled = (data is Map && data['payment_method_settings'] is Map) ? (data['payment_method_settings']['wave_enabled'] != false) : true;

      notifyListeners();
    } on DioException catch (e) {
      final message = e.response?.data is Map ? (e.response?.data['message'] as String?) : null;
      throw Exception(message ?? 'Erreur de connexion');
    }
  }

  Future<void> refreshMe() async {
    if (_token == null) return;
    final res = await _apiClient.dio.get('/auth/me');
    final data = res.data;

    if (data is Map) {
      final user = data['user'];
      if (user is Map) {
        _userName = user['name'] as String?;
      }

      final client = data['client'];
      if (client is Map) {
        _pointsFidelite = ((client['points_fidelite'] ?? 0) as num).toInt();
      }

      final fidelitySettings = data['fidelity_settings'];
      if (fidelitySettings is Map) {
        _fidelityEnabled = fidelitySettings['actif'] == true;
        _valeurFcfa1Point = ((fidelitySettings['valeur_fcfa_1_point'] ?? 0) as num).toDouble();
      }

      final paymentMethodSettings = data['payment_method_settings'];
      if (paymentMethodSettings is Map) {
        _waveEnabled = paymentMethodSettings['wave_enabled'] != false;
      }
    }
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    _apiClient.setAuthToken(null);
    _isAuthenticated = false;
    _userName = null;
    _pointsFidelite = 0;
    notifyListeners();
  }
}

