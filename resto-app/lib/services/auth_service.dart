import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;

  // Register
  Future<Map<String, dynamic>> register({
    required String nom,
    required String prenom,
    required String telephone,
    String? email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.register,
        data: {
          'nom': nom,
          'prenom': prenom,
          'telephone': telephone,
          if (email != null && email.isNotEmpty) 'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

        if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        _token = data['token'] as String?;
        if (data['user'] != null) {
          final hasFullResponse = data['client'] != null ||
              data['fidelity_settings'] != null ||
              data['payment_method_settings'] != null;
          _currentUser = hasFullResponse
              ? User.fromAuthResponse(data)
              : User.fromJson(data['user'] as Map<String, dynamic>);
        }
        
        // Sauvegarder le token
        if (_token != null) {
          await _saveToken(_token!);
          _apiService.setToken(_token);
          notifyListeners();
          return {'success': true, 'user': _currentUser};
        } else {
          return {'success': false, 'message': 'Token non reçu du serveur'};
        }
      } else {
        return {'success': false, 'message': 'Erreur d\'inscription (${response.statusCode})'};
      }
    } on DioException catch (e) {
      // Gérer les erreurs HTTP spécifiques
      String message = 'Erreur d\'inscription';
      
      if (e.response != null) {
        // Erreur avec réponse du serveur
        final data = e.response?.data;
        if (data is Map) {
          // Erreur de validation Laravel
          if (data['message'] != null) {
            message = data['message'] as String;
          } else if (data['errors'] != null) {
            final errors = data['errors'] as Map;
            // Prendre le premier message d'erreur
            if (errors.isNotEmpty) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                message = firstError.first as String;
              }
            }
          }
        }
        
        if (e.response?.statusCode == 422) {
          message = message.isNotEmpty ? message : 'Les données fournies sont invalides.';
        } else if (e.response?.statusCode == 409) {
          message = 'Un compte existe déjà avec cet email ou ce téléphone.';
        } else if (e.response?.statusCode == 500) {
          message = 'Erreur serveur. Veuillez réessayer plus tard.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        message = 'Délai d\'attente dépassé. Vérifiez votre connexion internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      }
      
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Erreur inattendue: ${e.toString()}'};
    }
  }

  // Login (accepte email ou téléphone)
  Future<Map<String, dynamic>> login(String emailOrPhone, String password) async {
    try {
      final response = await _apiService.post(
        ApiConfig.login,
        data: {
          'email': emailOrPhone, // Peut être email ou téléphone
          'password': password,
        },
      );

        if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        _token = data['token'] as String?;
        if (data['user'] != null) {
          final hasFullResponse = data['client'] != null ||
              data['fidelity_settings'] != null ||
              data['payment_method_settings'] != null;
          _currentUser = hasFullResponse
              ? User.fromAuthResponse(data)
              : User.fromJson(data['user'] as Map<String, dynamic>);
        }
        
        // Sauvegarder le token
        if (_token != null) {
          await _saveToken(_token!);
          _apiService.setToken(_token);
          notifyListeners();
          return {'success': true, 'user': _currentUser};
        } else {
          return {'success': false, 'message': 'Token non reçu du serveur'};
        }
      } else {
        return {'success': false, 'message': 'Erreur de connexion (${response.statusCode})'};
      }
    } on DioException catch (e) {
      // Gérer les erreurs HTTP spécifiques
      String message = 'Erreur de connexion';
      
      if (e.response != null) {
        // Erreur avec réponse du serveur
        final data = e.response?.data;
        if (data is Map) {
          // Erreur de validation Laravel
          if (data['message'] != null) {
            message = data['message'] as String;
          } else if (data['errors'] != null) {
            final errors = data['errors'] as Map;
            if (errors['email'] != null) {
              message = (errors['email'] as List).first as String;
            } else if (errors['password'] != null) {
              message = (errors['password'] as List).first as String;
            }
          }
        }
        
        if (e.response?.statusCode == 422) {
          message = message.isNotEmpty ? message : 'Les identifiants fournis sont incorrects.';
        } else if (e.response?.statusCode == 401) {
          message = 'Email ou mot de passe incorrect';
        } else if (e.response?.statusCode == 403) {
          message = 'Accès refusé';
        } else if (e.response?.statusCode == 404) {
          message = 'Service non trouvé';
        } else if (e.response?.statusCode == 500) {
          message = 'Erreur serveur. Veuillez réessayer plus tard.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        message = 'Délai d\'attente dépassé. Vérifiez votre connexion internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      }
      
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Erreur inattendue: ${e.toString()}'};
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      if (_token != null) {
        await _apiService.post(ApiConfig.logout);
      }
    } catch (e) {
      // Ignorer les erreurs de logout
    } finally {
      _token = null;
      _currentUser = null;
      await _clearToken();
      _apiService.setToken(null);
      notifyListeners();
    }
  }

  // Vérifier si l'utilisateur est connecté
  Future<bool> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null && token.isNotEmpty) {
      _token = token;
      _apiService.setToken(token);
      
      // Récupérer les infos utilisateur
      try {
        final response = await _apiService.get(ApiConfig.me);
        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>?;
          if (data != null && data['user'] != null) {
            final hasFullResponse = data['client'] != null ||
                data['fidelity_settings'] != null ||
                data['payment_method_settings'] != null;
            _currentUser = hasFullResponse
                ? User.fromAuthResponse(data)
                : User.fromJson(data['user'] as Map<String, dynamic>);
            notifyListeners();
            return true;
          }
        }
        // Si la réponse n'est pas valide, supprimer le token
        await _clearToken();
        _token = null;
        _currentUser = null;
        _apiService.setToken(null);
        return false;
      } catch (e) {
        // Token invalide ou expiré, supprimer
        await _clearToken();
        _token = null;
        _currentUser = null;
        _apiService.setToken(null);
        return false;
      }
    }
    
    _token = null;
    _currentUser = null;
    _apiService.setToken(null);
    return false;
  }

  // Sauvegarder le token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Supprimer le token
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}

