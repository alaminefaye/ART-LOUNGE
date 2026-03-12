import 'dart:async';

class FCMEvents {
  // Stream pour notifier l'UI des mises à jour
  static final StreamController<bool> _orderUpdateController =
      StreamController<bool>.broadcast();
  static Stream<bool> get orderUpdateStream => _orderUpdateController.stream;

  static void triggerOrderUpdate() {
    _orderUpdateController.add(true);
  }

  // Stream pour "paiement validé" (orderId pour afficher popup reçu + note satisfaction)
  static final StreamController<int> _paymentValidatedController =
      StreamController<int>.broadcast();
  static Stream<int> get paymentValidatedStream =>
      _paymentValidatedController.stream;

  static void triggerPaymentValidated(int orderId) {
    _paymentValidatedController.add(orderId);
  }
}
