import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import '../theme/app_colors.dart';

class StripePaymentService {
  // ✅ Remplace par l'URL de ton backend
  static const String _backendUrl = 'https://TON_BACKEND.com';

  // ══════════════════════════════════════════════
  // 💳 Méthode principale — Lancer le paiement
  // ══════════════════════════════════════════════
  Future<void> makePayment({
    required int amount,      // montant en centimes (ex: 1000 = 10.00€)
    required String currency, // ex: 'eur', 'usd'
  }) async {
    try {
      // ÉTAPE A — Créer le PaymentIntent côté backend
      final paymentIntent = await _createPaymentIntent(
        amount: amount,
        currency: currency,
      );

      // ÉTAPE B — Initialiser la feuille de paiement Stripe
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'Construction Dashboard',
          style: ThemeMode.light,
        ),
      );

      // ÉTAPE C — Afficher la feuille de paiement
      await _presentPaymentSheet();

    } catch (e) {
      Get.snackbar(
        '❌ Erreur de paiement',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  // ══════════════════════════════════════════════
  // 🌐 Créer PaymentIntent via le backend
  // ══════════════════════════════════════════════
  Future<Map<String, dynamic>> _createPaymentIntent({
    required int amount,
    required String currency,
  }) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/create-payment-intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  }

  // ══════════════════════════════════════════════
  // 📋 Afficher la feuille de paiement
  // ══════════════════════════════════════════════
  Future<void> _presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();

      // ✅ Paiement réussi
      Get.snackbar(
        '✅ Paiement réussi !',
        'Votre paiement a été effectué avec succès.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // ✅ L'utilisateur a annulé
        Get.snackbar(
          '⚠️ Paiement annulé',
          'Vous avez annulé le paiement.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Erreur Stripe: ${e.error.message}');
      }
    }
  }
}
