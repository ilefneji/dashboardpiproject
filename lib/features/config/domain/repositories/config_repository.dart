// ─────────────────────────────────────────────
// domain/repositories/config_repository.dart
// ─────────────────────────────────────────────

import 'dart:typed_data';

import '../entities/config.dart';
import '../entities/subscription.dart';

abstract class ConfigRepository {
  // ════════════════════════════════════════════
  // ⚙️ Config
  // ════════════════════════════════════════════

  Future<Config?> getConfig();

  Future<bool> updateConfig(Config config);

  // ════════════════════════════════════════════
  // 💳 Subscriptions — READ
  // ════════════════════════════════════════════

  Future<List<SubscriptionModel>> getSubscriptions();

  Future<SubscriptionModel?> getSubscription(int id);

  Future<List<SubscriptionModel>> getSubscriptionsByCompany(int companyId);

  Future<List<SubscriptionModel>> getSubscriptionsByUser(int userId);

  Future<List<SubscriptionModel>> getSubscriptionHistory();

  // ════════════════════════════════════════════
  // ✏️ Subscriptions — WRITE
  // ════════════════════════════════════════════

  Future<SubscriptionModel?> createSubscription(Map<String, dynamic> data);

  Future<SubscriptionModel?> updateSubscription(
    int id,
    Map<String, dynamic> data,
  );

  Future<bool> deleteSubscription(int id);

  Future<bool> cancelSubscription(int id);

  // ✅ Creates a fresh Stripe Checkout URL for renewing an existing subscription
  Future<String?> createRenewalCheckoutSession({
    required int subscriptionId,
  });

  // ════════════════════════════════════════════
  // 🧾 Invoice
  // ════════════════════════════════════════════

  Future<Uint8List?> downloadInvoice(int id);
}