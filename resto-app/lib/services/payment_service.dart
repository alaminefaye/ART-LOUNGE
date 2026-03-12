import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/payment.dart';
import 'api_service.dart';

class PaymentService {
  final ApiService _apiService = ApiService();

  // Lancer une commande (changer statut vers "preparation")
  Future<Map<String, dynamic>> launchOrder(int orderId) async {
    try {
      final response = await _apiService.post(
        ApiConfig.launchOrder(orderId),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Commande lancée avec succès',
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors du lancement de la commande',
        };
      }
    } on DioException catch (e) {
      String message = 'Erreur lors du lancement de la commande';
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'] as String;
        }
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }

  // Payer avec les points de fidélité (client)
  Future<Map<String, dynamic>> payWithPoints({
    required int commandeId,
    required int pointsUtilises,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.payments,
        data: {
          'commande_id': commandeId,
          'moyen_paiement': PaymentMethod.pointsFidelite.value,
          'points_utilises': pointsUtilises,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>?;
        final message = data?['message'] as String? ?? 'Paiement en points enregistré.';
        final dataContent = data?['data'];
        double? resteAPayer;
        if (data?['reste_a_payer'] != null) {
          final r = data!['reste_a_payer'];
          if (r is num) resteAPayer = r.toDouble();
        }
        if (dataContent is Map) {
          try {
            final payment = Payment.fromJson(dataContent as Map<String, dynamic>);
            return {
              'success': true,
              'message': message,
              'data': payment,
              if (resteAPayer != null) 'reste_a_payer': resteAPayer,
            };
          } catch (_) {}
        }
        return {
          'success': true,
          'message': message,
          if (resteAPayer != null) 'reste_a_payer': resteAPayer,
        };
      }
      return {
        'success': false,
        'message': (response.data is Map && response.data['message'] != null)
            ? response.data['message'] as String
            : 'Erreur lors du paiement en points',
      };
    } on DioException catch (e) {
      String message = 'Erreur lors du paiement en points';
      if (e.response != null) {
        final d = e.response?.data;
        if (d is Map && d['message'] != null) message = d['message'] as String;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Erreur: ${e.toString()}'};
    }
  }

  // Initier un paiement (Wave, Orange Money)
  Future<Map<String, dynamic>> initiatePayment({
    required int commandeId,
    required PaymentMethod moyenPaiement,
    String? transactionId,
    String? notes,
    int? pointsUtilises,
  }) async {
    try {
      final body = <String, dynamic>{
        'commande_id': commandeId,
        'moyen_paiement': moyenPaiement.value,
        if (transactionId != null && transactionId.isNotEmpty) 'transaction_id': transactionId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };
      if (pointsUtilises != null && pointsUtilises > 0) {
        body['points_utilises'] = pointsUtilises;
      }
      final response = await _apiService.post(ApiConfig.payments, data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        Map<String, dynamic> paymentData;
        if (data is Map) {
          if (data.containsKey('data')) {
            final dataContent = data['data'];
            // Si data est un Map avec 'paiement', utiliser celui-ci
            if (dataContent is Map && dataContent.containsKey('paiement')) {
              paymentData = dataContent['paiement'] as Map<String, dynamic>;
            } else if (dataContent is Map) {
              // Sinon, data est directement le paiement
              paymentData = dataContent as Map<String, dynamic>;
            } else {
              return {
                'success': false,
                'message': 'Format de réponse invalide',
              };
            }
          } else {
            paymentData = data as Map<String, dynamic>;
          }
        } else {
          return {
            'success': false,
            'message': 'Format de réponse invalide',
          };
        }

        try {
          return {
            'success': true,
            'message': data['message'] ?? 'Paiement initié avec succès',
            'data': Payment.fromJson(paymentData),
          };
        } catch (e) {
          debugPrint('Erreur parsing Payment: $e');
          debugPrint('PaymentData: $paymentData');
          return {
            'success': false,
            'message': 'Erreur lors du parsing du paiement: ${e.toString()}',
          };
        }
      } else {
        return {
          'success': false,
          'message': (response.data is Map && response.data['message'] != null)
              ? response.data['message'] as String
              : 'Erreur lors de l\'initiation du paiement',
        };
      }
    } on DioException catch (e) {
      String message = 'Erreur lors de l\'initiation du paiement';
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'] as String;
        }
        if (e.response?.statusCode == 403) {
          message = 'Non autorisé. Veuillez vous reconnecter.';
        }
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }

  // Confirmer un paiement mobile money (Wave, Orange Money) - Client
  Future<Map<String, dynamic>> confirmPayment({
    required int paymentId,
    required String transactionId,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.confirmPayment(paymentId),
        data: {
          'transaction_id': transactionId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        Map<String, dynamic> paymentData;
        if (data is Map) {
          if (data.containsKey('data')) {
            final dataContent = data['data'];
            if (dataContent is Map) {
              paymentData = dataContent as Map<String, dynamic>;
            } else {
              return {
                'success': false,
                'message': 'Format de réponse invalide',
              };
            }
          } else {
            paymentData = data as Map<String, dynamic>;
          }
        } else {
          return {
            'success': false,
            'message': 'Format de réponse invalide',
          };
        }

        try {
          return {
            'success': true,
            'message': (data['message']) ?? 'Paiement confirmé avec succès',
            'data': Payment.fromJson(paymentData),
          };
        } catch (e) {
          debugPrint('Erreur parsing Payment: $e');
          return {
            'success': false,
            'message': 'Erreur lors du parsing du paiement: ${e.toString()}',
          };
        }
      } else {
        return {
          'success': false,
          'message': (response.data is Map && response.data['message'] != null)
              ? response.data['message'] as String
              : 'Erreur lors de la confirmation du paiement',
        };
      }
    } on DioException catch (e) {
      String message = 'Erreur lors de la confirmation du paiement';
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'] as String;
        }
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }

  // Payer en espèces (Gérant uniquement)
  Future<Map<String, dynamic>> payCash({
    required int commandeId,
    required double montantRecu,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.payCash,
        data: {
          'commande_id': commandeId,
          'montant_recu': montantRecu,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        Map<String, dynamic> paymentData;
        double monnaieRendue = 0.0;

        if (data is Map && data.containsKey('data')) {
          final dataContent = data['data'];
          if (dataContent is Map) {
            // Si data contient 'paiement', utiliser celui-ci
            if (dataContent.containsKey('paiement')) {
              paymentData = dataContent['paiement'] as Map<String, dynamic>;
            } else {
              paymentData = dataContent as Map<String, dynamic>;
            }
            // Récupérer monnaie_rendue
            if (dataContent.containsKey('monnaie_rendue')) {
              final monnaie = dataContent['monnaie_rendue'];
              if (monnaie is num) {
                monnaieRendue = monnaie.toDouble();
              } else if (monnaie is String) {
                monnaieRendue = double.tryParse(monnaie) ?? 0.0;
              }
            }
          } else {
            return {
              'success': false,
              'message': 'Format de réponse invalide',
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Format de réponse invalide',
          };
        }

        try {
          return {
            'success': true,
            'message': (data['message']) ?? 'Paiement espèces effectué avec succès',
            'data': Payment.fromJson(paymentData),
            'monnaie_rendue': monnaieRendue,
          };
        } catch (e) {
          debugPrint('Erreur parsing Payment: $e');
          return {
            'success': false,
            'message': 'Erreur lors du parsing du paiement: ${e.toString()}',
          };
        }
      } else {
        return {
          'success': false,
          'message': (response.data is Map && response.data['message'] != null)
              ? response.data['message'] as String
              : 'Erreur lors du paiement en espèces',
        };
      }
    } on DioException catch (e) {
      String message = 'Erreur lors du paiement en espèces';
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'] as String;
        }
        if (e.response?.statusCode == 422 && data is Map && data.containsKey('data')) {
          // Erreur de montant insuffisant
          final errorData = data['data'] as Map<String, dynamic>;
          message = '$message\nMontant requis: ${errorData['montant_requis']} FCFA\nManquant: ${errorData['manquant']} FCFA';
        }
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }

  // Valider un paiement mobile money (Gérant uniquement)
  Future<Map<String, dynamic>> validatePayment(int paymentId) async {
    try {
      final response = await _apiService.patch(
        ApiConfig.validatePayment(paymentId),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        Map<String, dynamic> paymentData;
        if (data is Map && data.containsKey('data')) {
          final dataContent = data['data'];
          if (dataContent is Map) {
            // Si data contient 'paiement', utiliser celui-ci
            if (dataContent.containsKey('paiement')) {
              paymentData = dataContent['paiement'] as Map<String, dynamic>;
            } else {
              paymentData = dataContent as Map<String, dynamic>;
            }
          } else {
            return {
              'success': false,
              'message': 'Format de réponse invalide',
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Format de réponse invalide',
          };
        }

        try {
          return {
            'success': true,
            'message': (data['message']) ?? 'Paiement validé avec succès',
            'data': Payment.fromJson(paymentData),
          };
        } catch (e) {
          debugPrint('Erreur parsing Payment: $e');
          return {
            'success': false,
            'message': 'Erreur lors du parsing du paiement: ${e.toString()}',
          };
        }
      } else {
        return {
          'success': false,
          'message': (response.data is Map && response.data['message'] != null)
              ? response.data['message'] as String
              : 'Erreur lors de la validation du paiement',
        };
      }
    } on DioException catch (e) {
      String message = 'Erreur lors de la validation du paiement';
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'] as String;
        }
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }

  // Récupérer les paiements d'une commande
  Future<List<Payment>> getOrderPayments(int commandeId) async {
    try {
      final response = await _apiService.get(
        ApiConfig.payments,
        queryParameters: {'commande_id': commandeId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List paymentsData;
        if (data is List) {
          paymentsData = data;
        } else if (data is Map && data.containsKey('data')) {
          paymentsData = data['data'] as List;
        } else {
          return [];
        }

        return paymentsData.map((json) {
          try {
            if (json is Map<String, dynamic>) {
              return Payment.fromJson(json);
            }
            return null;
          } catch (e) {
            debugPrint('Erreur parsing Payment: $e');
            return null;
          }
        }).whereType<Payment>().toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des paiements: $e');
      return [];
    }
  }
}
