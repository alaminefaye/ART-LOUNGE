import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
    final hasNetwork = await _hasConnectivity();
    if (!hasNetwork) {
      return {
        'success': false,
        'message':
            'Pas de connexion internet. Vérifiez que le Wi-Fi ou les données mobiles sont activés et que l\'accès réseau est autorisé pour l\'application.',
      };
    }
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
        return {
          'success': false,
          'message': 'Erreur d\'inscription (${response.statusCode})'
        };
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
          message = message.isNotEmpty
              ? message
              : 'Les données fournies sont invalides.';
        } else if (e.response?.statusCode == 409) {
          message = 'Un compte existe déjà avec cet email ou ce téléphone.';
        } else if (e.response?.statusCode == 500) {
          message = 'Erreur serveur. Veuillez réessayer plus tard.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        message =
            'Délai d\'attente dépassé. Vérifiez votre connexion internet et que l\'accès réseau est autorisé.';
      } else if (e.type == DioExceptionType.connectionError) {
        message =
            'Impossible de joindre le serveur. Vérifiez votre connexion internet et que l\'accès réseau est autorisé pour l\'application.';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}'
      };
    }
  }

  /// Vérifie si une connexion réseau est disponible (Wi-Fi, données mobiles, etc.).
  Future<bool> _hasConnectivity() async {
    // Sur Windows/Desktop, le plugin connectivity_plus est parfois instable.
    // On autorise la tentative d'appel API par défaut sur ces plateformes.
    if (defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.macOS || 
        defaultTargetPlatform == TargetPlatform.linux) {
      return true;
    }

    try {
      final result = await Connectivity().checkConnectivity();
      if (result.isEmpty) {
        return false;
      }
      if (result.contains(ConnectivityResult.none) && result.length == 1) {
        return false;
      }
      if (result.every((r) => r == ConnectivityResult.none)) {
        return false;
      }
      return true;
    } catch (_) {
      return true; // En cas de doute, laisser tenter l'appel API
    }
  }

  // Login (accepte email ou téléphone)
  Future<Map<String, dynamic>> login(
      String emailOrPhone, String password) async {
    final hasNetwork = await _hasConnectivity();
    if (!hasNetwork) {
      return {
        'success': false,
        'message':
            'Pas de connexion internet. Vérifiez que le Wi-Fi ou les données mobiles sont activés et que l\'accès réseau est autorisé pour l\'application.',
      };
    }
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
        return {
          'success': false,
          'message': 'Erreur de connexion (${response.statusCode})'
        };
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
          message = message.isNotEmpty
              ? message
              : 'Les identifiants fournis sont incorrects.';
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
        message =
            'Délai d\'attente dépassé. Vérifiez votre connexion internet et que l\'accès réseau est autorisé.';
      } else if (e.type == DioExceptionType.connectionError) {
        message =
            'Impossible de joindre le serveur. Vérifiez votre connexion internet, que l\'accès réseau est autorisé pour l\'application, et que l\'adresse du serveur est correcte.';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}'
      };
    }
  }

  // Login uniquement par PIN
  Future<Map<String, dynamic>> loginWithPinOnly(String pin) async {
    final hasNetwork = await _hasConnectivity();
    if (!hasNetwork) {
      return {
        'success': false,
        'message':
            'Pas de connexion internet. Vérifiez que le Wi-Fi ou les données mobiles sont activés et que l\'accès réseau est autorisé pour l\'application.',
      };
    }
    try {
      final response = await _apiService.post(
        '/auth/login-pin-only',
        data: {
          'pin': pin,
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
        return {
          'success': false,
          'message': 'Erreur de connexion (${response.statusCode})'
        };
      }
    } on DioException catch (e) {
      String message = 'Erreur de connexion';

      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map) {
          if (data['message'] != null) {
            message = data['message'] as String;
          } else if (data['errors'] != null) {
            final errors = data['errors'] as Map;
            if (errors['pin'] != null) {
              message = (errors['pin'] as List).first as String;
            }
          }
        }

        if (e.response?.statusCode == 422) {
          message = message.isNotEmpty
              ? message
              : 'Code PIN incorrect.';
        } else if (e.response?.statusCode == 403) {
          message = 'Accès refusé';
        } else if (e.response?.statusCode == 500) {
          message = 'Erreur serveur. Veuillez réessayer plus tard.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        message = 'Délai d\'attente dépassé.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Impossible de joindre le serveur.';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}'
      };
    }
  }


  // Changer de mot de passe
  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    try {
      final response = await _apiService.put(
        '/auth/update-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        },
      );
      return {'success': response.statusCode == 200, 'message': response.data['message'] ?? 'Mot de passe mis à jour'};
    } on DioException catch (e) {
      String message = 'Erreur lors de la modification';
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'];
        }
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Suppression définitive du compte client (mot de passe requis côté API).
  Future<Map<String, dynamic>> deleteAccount(String password) async {
    final hasNetwork = await _hasConnectivity();
    if (!hasNetwork) {
      return {
        'success': false,
        'message':
            'Pas de connexion internet. Vérifiez votre connexion et réessayez.',
      };
    }
    try {
      final response = await _apiService.post(
        ApiConfig.deleteAccount,
        data: {'password': password},
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final msg = data is Map && data['message'] != null
            ? data['message'] as String
            : 'Compte supprimé.';
        _token = null;
        _currentUser = null;
        await _clearToken();
        _apiService.setToken(null);
        notifyListeners();
        return {'success': true, 'message': msg};
      }
      return {
        'success': false,
        'message': 'La suppression a échoué (${response.statusCode}).',
      };
    } on DioException catch (e) {
      String message = 'Erreur lors de la suppression du compte';
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map) {
          if (data['message'] != null) {
            message = data['message'] as String;
          } else if (data['errors'] is Map) {
            final errors = data['errors'] as Map;
            final pwd = errors['password'];
            if (pwd is List && pwd.isNotEmpty) {
              message = pwd.first as String;
            }
          }
        }
        if (e.response?.statusCode == 422) {
          message = message.isNotEmpty ? message : 'Mot de passe incorrect.';
        } else if (e.response?.statusCode == 403) {
          message = message.isNotEmpty
              ? message
              : 'Cette action n\'est pas autorisée pour votre compte.';
        }
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
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

  // Mettre à jour le profil
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final response = await _apiService.put(
        ApiConfig.updateProfile,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['user'] != null) {
          // Mettre à jour l'utilisateur localement
          final userData = data['user'] as Map<String, dynamic>;
          
          if (_currentUser != null) {
            // On garde les infos de rôle/client et on met à jour le reste
            _currentUser = User(
              id: _currentUser!.id,
              name: userData['name'] ?? name,
              email: userData['email'] ?? email,
              phone: userData['phone'] ?? phone,
              roles: _currentUser!.roles,
              pointsFidelite: _currentUser!.pointsFidelite,
              valeurFcfa1Point: _currentUser!.valeurFcfa1Point,
              waveEnabled: _currentUser!.waveEnabled,
              orangeMoneyEnabled: _currentUser!.orangeMoneyEnabled,
            );
            notifyListeners();
          }
          return {'success': true, 'message': data['message']};
        }
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Erreur lors de la mise à jour'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau: ${e.toString()}'
      };
    }
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
