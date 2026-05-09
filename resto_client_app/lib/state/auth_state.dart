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

  String? _email;
  String? get email => _email;

  String? _phone;
  String? get phone => _phone;

  String? _adresse;
  String? get adresse => _adresse;

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

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        'auth/login',
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

      _userName = (data is Map && data['user'] is Map)
          ? (data['user']['name'] as String?)
          : null;
      _email = (data is Map && data['user'] is Map)
          ? (data['user']['email'] as String?)
          : null;
      _phone = (data is Map && data['user'] is Map)
          ? (data['user']['phone'] as String?)
          : null;
      _pointsFidelite = (data is Map && data['client'] is Map)
          ? ((data['client']['points_fidelite'] ?? 0) as num).toInt()
          : 0;
      _fidelityEnabled = (data is Map && data['fidelity_settings'] is Map)
          ? (data['fidelity_settings']['actif'] == true)
          : false;
      _valeurFcfa1Point = (data is Map && data['fidelity_settings'] is Map)
          ? ((data['fidelity_settings']['valeur_fcfa_1_point'] ?? 0) as num)
                .toDouble()
          : 0;
      _waveEnabled = (data is Map && data['payment_method_settings'] is Map)
          ? (data['payment_method_settings']['wave_enabled'] != false)
          : true;

      notifyListeners();
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message'] as String?)
          : null;
      throw Exception(message ?? 'Erreur de connexion');
    }
  }

  Future<void> register({
    required String nom,
    required String prenom,
    required String telephone,
    String? email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        'auth/register',
        data: {
          'nom': nom,
          'prenom': prenom,
          'telephone': telephone,
          'email': (email != null && email.trim().isNotEmpty)
              ? email.trim()
              : null,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
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

      _userName = (data is Map && data['user'] is Map)
          ? (data['user']['name'] as String?)
          : null;
      _email = (data is Map && data['user'] is Map)
          ? (data['user']['email'] as String?)
          : null;
      _phone = (data is Map && data['user'] is Map)
          ? (data['user']['phone'] as String?)
          : null;
      _pointsFidelite = (data is Map && data['client'] is Map)
          ? ((data['client']['points_fidelite'] ?? 0) as num).toInt()
          : 0;
      _fidelityEnabled = (data is Map && data['fidelity_settings'] is Map)
          ? (data['fidelity_settings']['actif'] == true)
          : false;
      _valeurFcfa1Point = (data is Map && data['fidelity_settings'] is Map)
          ? ((data['fidelity_settings']['valeur_fcfa_1_point'] ?? 0) as num)
                .toDouble()
          : 0;
      _waveEnabled = (data is Map && data['payment_method_settings'] is Map)
          ? (data['payment_method_settings']['wave_enabled'] != false)
          : true;

      notifyListeners();
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message'] as String?)
          : null;
      if (message != null && message.trim().isNotEmpty) {
        throw Exception(message);
      }
      throw Exception('Erreur d’inscription');
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? adresse,
  }) async {
    try {
      final res = await _apiClient.dio.put(
        'auth/update-profile',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'adresse': (adresse != null && adresse.trim().isNotEmpty)
              ? adresse.trim()
              : null,
        },
      );

      final data = res.data;
      if (data is Map && data['user'] is Map) {
        final user = data['user'] as Map;
        _userName = user['name']?.toString();
        _email = user['email']?.toString();
        _phone = user['phone']?.toString();
      } else {
        _userName = name;
        _email = email;
        _phone = phone;
      }
      _adresse = adresse;
      notifyListeners();
      await refreshMe();
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message'] as String?)
          : null;
      throw Exception(message ?? 'Erreur lors de la mise à jour du profil');
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      await _apiClient.dio.put(
        'auth/update-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message'] as String?)
          : null;
      throw Exception(
        message ?? 'Erreur lors de la mise à jour du mot de passe',
      );
    }
  }

  Future<void> refreshMe() async {
    if (_token == null) return;
    final res = await _apiClient.dio.get('auth/me');
    final data = res.data;

    if (data is Map) {
      final user = data['user'];
      if (user is Map) {
        _userName = user['name'] as String?;
        _email = user['email'] as String?;
        _phone = user['phone'] as String?;
      }

      final client = data['client'];
      if (client is Map) {
        _pointsFidelite = ((client['points_fidelite'] ?? 0) as num).toInt();
        _adresse = client['adresse']?.toString();
      }

      final fidelitySettings = data['fidelity_settings'];
      if (fidelitySettings is Map) {
        _fidelityEnabled = fidelitySettings['actif'] == true;
        _valeurFcfa1Point =
            ((fidelitySettings['valeur_fcfa_1_point'] ?? 0) as num).toDouble();
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
    _email = null;
    _phone = null;
    _adresse = null;
    _pointsFidelite = 0;
    notifyListeners();
  }

  Future<void> deleteAccount({required String code}) async {
    try {
      await _apiClient.dio.post('auth/delete-account', data: {'code': code});
      await logout();
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message'] as String?)
          : null;
      throw Exception(message ?? 'Impossible de supprimer le compte');
    }
  }
}
