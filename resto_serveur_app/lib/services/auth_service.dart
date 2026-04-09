import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/serveur.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Serveur? _currentUser;
  String? _token;

  // The waiter who has entered their PIN and is active on this device
  Serveur? _activeServeur;

  Serveur? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;
  Serveur? get activeServeur => _activeServeur;

  // -------------------------------------------------------------------
  // LOGIN (email/password — global device login)
  // -------------------------------------------------------------------
  Future<Map<String, dynamic>> login(
    String emailOrPhone,
    String password,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConfig.login,
        data: {'email': emailOrPhone, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        _token = data['token'] as String?;

        if (data['user'] != null) {
          _currentUser = Serveur.fromJson(data['user'] as Map<String, dynamic>);
        }

        if (_token != null) {
          await _saveToken(_token!);
          _apiService.setToken(_token);
          notifyListeners();
          return {'success': true, 'user': _currentUser};
        }
        return {'success': false, 'message': 'Token non reçu du serveur'};
      }
      return {
        'success': false,
        'message': 'Erreur de connexion (${response.statusCode})',
      };
    } on DioException catch (e) {
      String message = 'Erreur de connexion';
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'] as String;
        }
        if (e.response?.statusCode == 401) {
          message = 'Email ou mot de passe incorrect';
        } else if (e.response?.statusCode == 403) {
          message = 'Accès refusé';
        } else if (e.response?.statusCode == 500) {
          message = 'Erreur serveur. Veuillez réessayer plus tard.';
        }
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Impossible de joindre le serveur. Vérifiez votre connexion.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Délai dépassé. Vérifiez votre connexion internet.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Erreur inattendue: $e'};
    }
  }

  // -------------------------------------------------------------------
  // LOGOUT
  // -------------------------------------------------------------------
  Future<void> logout() async {
    try {
      if (_token != null) {
        await _apiService.post(ApiConfig.logout);
      }
    } catch (_) {}
    _token = null;
    _currentUser = null;
    _activeServeur = null;
    await _clearToken();
    _apiService.setToken(null);
    notifyListeners();
  }

  // -------------------------------------------------------------------
  // CHECK AUTH (restores session on app start)
  // -------------------------------------------------------------------
  Future<bool> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      _token = token;
      _apiService.setToken(token);

      try {
        final response = await _apiService.get(ApiConfig.me);
        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>?;
          if (data != null) {
            final userMap = data['user'] ?? data;
            if (userMap != null) {
              _currentUser = Serveur.fromJson(userMap as Map<String, dynamic>);
              notifyListeners();
              return true;
            }
          }
        }
      } catch (_) {}

      await _clearToken();
      _token = null;
      _currentUser = null;
      _apiService.setToken(null);
    }

    return false;
  }

  // -------------------------------------------------------------------
  // PIN — set (first-time or change)
  // Calls POST /auth/set-pin on the backend.
  // Returns { success: bool, message: String }
  // -------------------------------------------------------------------
  Future<Map<String, dynamic>> setPin(String pin) async {
    try {
      final response = await _apiService.post(
        ApiConfig.setPin,
        data: {'pin': pin, 'pin_confirmation': pin},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && _currentUser != null) {
          // Update local model so UI knows PIN is now configured
          _currentUser = _currentUser!.copyWith(hasPin: true);
          notifyListeners();
        }
        return {'success': true};
      }
      return {'success': false, 'message': 'Erreur lors de la création du PIN'};
    } on DioException catch (e) {
      final msg = _extractErrorMessage(
        e,
        fallback: 'Impossible de créer le PIN',
      );
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Erreur inattendue: $e'};
    }
  }

  // -------------------------------------------------------------------
  // PIN — verify + unlock (PinScreen)
  // Calls POST /auth/verify-pin.
  // On success sets _activeServeur.
  // -------------------------------------------------------------------
  Future<bool> verifyPin(String pin) async {
    final ok = await checkPinOnly(pin);
    if (ok) {
      _activeServeur = _currentUser;
      notifyListeners();
    }
    return ok;
  }

  // -------------------------------------------------------------------
  // PIN — verify only (in-app confirmation dialogs, no state change)
  // Calls POST /auth/verify-pin.
  // If userId is provided, verifies that specific user's PIN (shared-tablet flow).
  // -------------------------------------------------------------------
  Future<bool> checkPinOnly(String pin, {int? userId}) async {
    if (_token == null) return false;
    try {
      final data = <String, dynamic>{'pin': pin};
      if (userId != null) data['user_id'] = userId;
      final response = await _apiService.post(ApiConfig.verifyPin, data: data);
      if (response.statusCode == 200) {
        final resp = response.data as Map<String, dynamic>;
        return resp['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------------
  // WAITERS — fetch list of staff for PIN confirmation selector
  // Returns list of { id, name, has_pin }
  // -------------------------------------------------------------------
  Future<List<Serveur>> getWaiters() async {
    try {
      final response = await _apiService.get(ApiConfig.waiters);
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final list = data['data'] as List? ?? [];
        return list.map((e) => Serveur.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // -------------------------------------------------------------------
  // Lock — returns to PIN screen without full logout
  // -------------------------------------------------------------------
  void lockServeur() {
    _activeServeur = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------
  // PRIVATE HELPERS
  // -------------------------------------------------------------------
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  String _extractErrorMessage(DioException e, {required String fallback}) {
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'] as String;
      }
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Impossible de joindre le serveur.';
    }
    return fallback;
  }
}
