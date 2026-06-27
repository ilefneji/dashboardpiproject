import 'package:constructiondashboard/core/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/subscription.dart';
import '../controllers/subscription_controller.dart';

class SubscriptionListPage extends StatelessWidget {
  final bool embedded;

  const SubscriptionListPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    debugPrint('[SubscriptionListPage] build');

    final authController = Get.find<AuthController>();
    final subscriptionController = Get.find<SubscriptionController>();

    final content = LayoutBuilder(
      builder: (context, viewportConstraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Abonnements page OK',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _AnimatedFadeIn(
                    delay: Duration(milliseconds: 0),
                    child: _PageHeader(),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    if (subscriptionController.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final currentUser = authController.currentUser.value;

                    final allSubscriptions =
                        subscriptionController.subscriptions.isNotEmpty
                            ? subscriptionController.subscriptions.toList()
                            : subscriptionController.userSubscriptions.toList();
                    final currentSubscription =
                        _CurrentSubscriptionCard._findCurrentSubscription(
                      allSubscriptions,
                      currentUser?.id,
                    );
                    final bool isCurrentSubscriptionLoading =
                        currentUser == null ||
                            (subscriptionController.isLoading.value &&
                                currentSubscription == null);
                    final currentSubscriptionCard = _CurrentSubscriptionCard(
                      subscription: currentSubscription,
                    );

                    final String currentPlan = _resolvePlan(
                      currentSubscription,
                    );
                    final bool isPro = currentPlan == 'pro';
                    final bool isOnPremise = currentPlan == 'onpremise' ||
                        currentPlan == 'on_premise' ||
                        currentPlan == '500';

                    final planCards = isPro
                        ? [_PlanCard.onPremise(isCurrentPlan: false)]
                        : isOnPremise
                            ? [_PlanCard.entreprise(isCurrentPlan: false)]
                            : [
                                _PlanCard.entreprise(isCurrentPlan: false),
                                _PlanCard.onPremise(isCurrentPlan: false),
                              ];

                    final offersPanel = _PremiumPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const _GradientOrb(
                                size: 34,
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Offres disponibles',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _textPrimary(),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Plans adaptes aux equipes chantier et enterprise.',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _textSecondary(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const _PillBadge(
                                label: 'Pricing',
                                icon: Icons.payments_rounded,
                                color: AppColors.primaryColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (planCards.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 24,
                              ),
                              child: Center(
                                child: Text(
                                  'Aucune offre disponible',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _textSecondary(),
                                  ),
                                ),
                              ),
                            )
                          else
                            _ResponsivePlanGrid(children: planCards),
                        ],
                      ),
                    );

                    return _AnimatedFadeIn(
                      delay: const Duration(milliseconds: 80),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (isCurrentSubscriptionLoading) {
                            return offersPanel;
                          }
                          if (constraints.maxWidth >= 1100) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: currentSubscriptionCard,
                                ),
                                const SizedBox(width: 16),
                                Expanded(flex: 7, child: offersPanel),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              currentSubscriptionCard,
                              const SizedBox(height: 16),
                              offersPanel,
                            ],
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );

    return embedded ? content : AppShell(child: content);
  }

  String _resolvePlan(SubscriptionModel? subscription) {
    final directPlan = subscription?.plan?.trim().toLowerCase();
    if (directPlan != null && directPlan.isNotEmpty) {
      debugPrint('[Plan] resolved from subscription.plan: $directPlan');
      return directPlan;
    }

    final companyPlan = subscription?.company?.plan?.trim().toLowerCase();
    if (companyPlan != null && companyPlan.isNotEmpty) {
      debugPrint(
        '[Plan] resolved from subscription.company.plan: $companyPlan',
      );
      return companyPlan;
    }

    final projectPlan =
        subscription?.project?.company?.plan?.trim().toLowerCase();
    if (projectPlan != null && projectPlan.isNotEmpty) {
      debugPrint('[Plan] resolved from project.company.plan: $projectPlan');
      return projectPlan;
    }

    debugPrint('[Plan] no plan found — defaulting to free');
    return 'free';
  }
}

class _AnimatedFadeIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  const _AnimatedFadeIn({required this.child, required this.delay});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _GradientOrb extends StatelessWidget {
  final double size;
  final Widget child;
  const _GradientOrb({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _PillBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(Get.isDarkMode ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF141E2E), const Color(0xFF111827)]
              : [Colors.white, const Color(0xFFFFF7ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2A3D) : const Color(0xFFE8E0D9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(isDark ? 0.04 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _GradientOrb(
            size: 38,
            child: Icon(
              Icons.subscriptions_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Abonnements',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary(),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gérer et consulter les plans disponibles',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary(),
                  ),
                ),
              ],
            ),
          ),
          const _PillBadge(
            label: 'SaaS Billing',
            icon: Icons.workspace_premium_rounded,
            color: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }
}

class _CurrentSubscriptionCard extends StatelessWidget {
  final SubscriptionModel? subscription;
  const _CurrentSubscriptionCard({this.subscription});

  @override
  Widget build(BuildContext context) {
    final DateTime? endDate =
        subscription?.currentPeriodEnd ?? subscription?.project?.endDate;

    final int? daysLeft = endDate?.difference(DateTime.now()).inDays;

    final bool showWarning = daysLeft != null && daysLeft <= 7 && daysLeft >= 0;
    final bool isExpired = daysLeft != null && daysLeft < 0;

    final String currentPlan = (() {
      final directPlan = subscription?.plan?.trim().toLowerCase() ??
          subscription?.company?.plan?.trim().toLowerCase();
      if (directPlan != null && directPlan.isNotEmpty) return directPlan;
      final projectPlan =
          subscription?.project?.company?.plan?.trim().toLowerCase();
      if (projectPlan != null && projectPlan.isNotEmpty) return projectPlan;
      return 'free';
    })();

    final bool isFree = currentPlan == 'free';
    final subscriptionLabel = _resolveSubscriptionLabel(subscription, null);
    final statusLabel = _formatStatus(subscription?.status ?? 'active');
    final seats =
        (subscription?.seats ?? subscription?.userIds.length ?? 1).toString();
    final billingInterval = _formatInterval(
      subscription?.billingInterval ?? 'month',
    );
    final paymentStatus = _formatPaymentStatus(
      subscription?.paymentStatus ?? '',
    );
    final endDateText = _resolveEndDate(endDate);
    final String amountDisplay = isFree
        ? 'Gratuit'
        : '${(subscription?.amountPaid ?? subscription?.priceTotal ?? subscription?.price ?? 0).toString()} ${subscription?.currency ?? 'TND'}';
    final isDark = Get.isDarkMode;

    final cardGradient = isExpired
        ? [
            isDark ? const Color(0xFF2A1518) : const Color(0xFFFFF5F5),
            isDark ? const Color(0xFF1E1014) : const Color(0xFFFFF0F0),
          ]
        : showWarning
            ? [
                isDark ? const Color(0xFF2A2112) : const Color(0xFFFFFBF0),
                isDark ? const Color(0xFF1E1A0E) : const Color(0xFFFFF8E6),
              ]
            : [
                isDark ? const Color(0xFF161E2C) : const Color(0xFFFFFBF5),
                isDark ? const Color(0xFF111827) : const Color(0xFFFFF7F0),
              ];

    const daysTotal = 30;
    final daysProgress = daysLeft != null && daysLeft > 0
        ? (daysTotal - daysLeft) / daysTotal
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showWarning || isExpired) ...[
          _buildWarningBanner(daysLeft, isExpired),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: cardGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isExpired
                  ? const Color(0xFFDC2626).withOpacity(isDark ? 0.25 : 0.18)
                  : showWarning
                      ? const Color(0xFFF59E0B)
                          .withOpacity(isDark ? 0.25 : 0.18)
                      : const Color(0xFF2A3443).withOpacity(0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isExpired
                        ? const Color(0xFFDC2626)
                        : AppColors.primaryColor)
                    .withOpacity(isDark ? 0.08 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.20 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: subscription == null
              ? _buildNoSubscription()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header : badges + nom + icône ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _StatusBadge(
                                    label: statusLabel,
                                    color: _statusColor(statusLabel),
                                  ),
                                  _PlanBadge(plan: currentPlan),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                subscriptionLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary(),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Votre abonnement actuel',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: _textSecondary(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryColor.withOpacity(0.20),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFree
                                ? Icons.lock_open_rounded
                                : Icons.workspace_premium_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // ── Bloc prix & progression ──
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0B1117).withOpacity(0.5)
                            : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      amountDisplay,
                                      style: GoogleFonts.inter(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: isFree
                                            ? const Color(0xFF22C55E)
                                            : _textPrimary(),
                                        letterSpacing: -0.8,
                                        height: 1,
                                      ),
                                    ),
                                    if (!isFree)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'par mois / utilisateur',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: _textSecondary(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (daysLeft != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: _CountdownPill(
                                    daysLeft: daysLeft,
                                    isExpired: isExpired,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: _textSecondary(),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Fin : $endDateText',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _ProgressBar(
                            value: daysProgress.clamp(0.0, 1.0),
                            isWarning: showWarning,
                            isExpired: isExpired,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            daysLeft != null && !isExpired
                                ? '$daysLeft jour${daysLeft > 1 ? 's' : ''} restant${daysLeft > 1 ? 's' : ''}'
                                : isExpired
                                    ? 'Periode expiree — renouvellement requis'
                                    : 'Periode illimitee',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _textSecondary(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // ── Tags ──
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SubscriptionChip(
                          icon: Icons.sync_rounded,
                          label: billingInterval,
                        ),
                        _SubscriptionChip(
                          icon: Icons.people_alt_outlined,
                          label: '$seats utilisateur${seats == '1' ? '' : 's'}',
                        ),
                        if (paymentStatus.isNotEmpty)
                          _SubscriptionChip(
                            icon: Icons.credit_card_rounded,
                            label: paymentStatus,
                          ),
                        _SubscriptionChip(
                          icon: Icons.business_center_rounded,
                          label: currentPlan == 'pro' ? 'Pro' : 'Gratuit',
                          highlighted: currentPlan == 'pro',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // ── Usage stats ──
                    _UsageStats(
                      projectsCount: subscription?.projectsCount ??
                          (subscription?.project != null ? 1 : 0),
                      usersCount:
                          subscription?.usersCount ?? int.tryParse(seats) ?? 1,
                      storageText:
                          currentPlan == 'pro' ? 'Cloud securise' : 'Standard',
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildNoSubscription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _softCardColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 22,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aucun abonnement actif',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary(),
                    ),
                  ),
                  Text(
                    'Aucune donnée disponible pour le moment.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _textSecondary(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _UsageStats(projectsCount: 0, usersCount: 0, storageText: '-'),
      ],
    );
  }

  Widget _buildWarningBanner(int daysLeft, bool isExpired) {
    final subscriptionController = Get.find<SubscriptionController>();

    final Color bg =
        isExpired ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final Color border =
        isExpired ? const Color(0xFFFCA5A5) : const Color(0xFFFCD34D);
    final Color iconColor =
        isExpired ? const Color(0xFFDC2626) : const Color(0xFFF59E0B);
    final Color textColor =
        isExpired ? const Color(0xFF991B1B) : const Color(0xFF92400E);

    final String title = isExpired
        ? '⛔ Abonnement expiré'
        : '⚠️ Expiration imminente — J-$daysLeft';

    final String body = isExpired
        ? 'Votre abonnement a expiré. Payez pour le renouveler.'
        : 'Votre abonnement expire dans $daysLeft jour${daysLeft > 1 ? 's' : ''}. Contactez l\'administrateur pour prolonger votre accès.';

    Future<void> handleRenewalPayment() async {
      final checkoutUrl =
          await subscriptionController.createRenewalCheckoutUrl();

      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        Get.snackbar(
          'Erreur',
          subscriptionController.errorMessage.value.isNotEmpty
              ? subscriptionController.errorMessage.value
              : 'Impossible de créer la session de paiement.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return;
      }

      final uri = Uri.parse(checkoutUrl);

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_self',
      );

      if (!launched) {
        Get.snackbar(
          'Erreur',
          'Impossible d’ouvrir la page de paiement.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isExpired ? Icons.cancel_rounded : Icons.warning_amber_rounded,
            color: iconColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: handleRenewalPayment,
            child: Container(
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Payer',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static SubscriptionModel? _findCurrentSubscription(
    List<SubscriptionModel> subscriptions,
    int? userId,
  ) {
    if (userId == null) return null;

    final now = DateTime.now();

    final matches = subscriptions.where((sub) {
      final belongsToUser = sub.userIds.contains(userId) ||
          sub.subscriptionUsers.any((su) => su.userId == userId) ||
          (sub.project?.userProjects.any((up) => up.userId == userId) ??
              false) ||
          (sub.company?.userCompanies.any((uc) => uc.userId == userId) ??
              false) ||
          (sub.project?.company?.userCompanies.any(
                (uc) => uc.userId == userId,
              ) ??
              false);

      return belongsToUser;
    }).toList();

    if (matches.isEmpty) return null;

    int score(SubscriptionModel s) {
      int value = 0;

      final paymentStatus = (s.paymentStatus ?? '').toLowerCase();
      final status = (s.status ?? '').toLowerCase();
      final endDate = s.currentPeriodEnd ?? s.project?.endDate;
      final currentPlan = s.plan?.trim().toLowerCase() ??
          s.company?.plan?.trim().toLowerCase() ??
          s.project?.company?.plan?.trim().toLowerCase() ??
          'free';

      if (paymentStatus == 'paid') value += 100;
      if (status == 'active') value += 60;
      if (status == 'trialing') value += 40;
      if (endDate != null && endDate.isAfter(now)) value += 20;
      if (currentPlan == 'pro') value += 10;

      return value;
    }

    matches.sort((a, b) {
      final scoreCompare = score(b).compareTo(score(a));
      if (scoreCompare != 0) return scoreCompare;

      final aEnd = a.currentPeriodEnd ?? a.project?.endDate;
      final bEnd = b.currentPeriodEnd ?? b.project?.endDate;

      if (aEnd == null && bEnd == null) return 0;
      if (aEnd == null) return 1;
      if (bEnd == null) return -1;

      return bEnd.compareTo(aEnd);
    });

    return matches.first;
  }

  static String _resolveSubscriptionLabel(
    SubscriptionModel? sub,
    dynamic user,
  ) {
    if (sub?.company?.name?.trim().isNotEmpty == true) {
      return sub!.company!.name!;
    }
    if (sub?.project?.company?.name?.trim().isNotEmpty == true) {
      return sub!.project!.company!.name!;
    }
    if (sub?.project?.name?.trim().isNotEmpty == true) {
      return sub!.project!.name!;
    }
    if (user?.isAdmin == true) {
      return 'Abonnement administrateur';
    }
    return 'Abonnement utilisateur';
  }

  static String _resolveEndDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatStatus(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return 'Actif';
      case 'paid':
        return 'Payé';
      case 'trialing':
        return 'Essai';
      case 'past_due':
        return 'En retard';
      case 'canceled':
      case 'cancelled':
        return 'Annulé';
      case 'pending':
        return 'En attente';
      default:
        return value.isEmpty ? '--' : value;
    }
  }

  static String _formatPaymentStatus(String value) {
    switch (value.toLowerCase()) {
      case 'paid':
        return 'Payé';
      case 'unpaid':
        return 'Impayé';
      case 'no_payment_required':
        return 'Gratuit';
      default:
        return '';
    }
  }

  static String _formatInterval(String value) {
    switch (value.toLowerCase()) {
      case 'month':
        return 'Mensuel';
      case 'year':
        return 'Annuel';
      default:
        return value.isEmpty ? '--' : value;
    }
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'actif':
        return const Color(0xFF16A34A);
      case 'payé':
        return const Color(0xFF2563EB);
      case 'annulé':
        return const Color(0xFFDC2626);
      case 'en retard':
        return const Color(0xFFEA580C);
      case 'essai':
        return const Color(0xFF7C3AED);
      case 'en attente':
        return const Color(0xFF64748B);
      default:
        return AppColors.primaryColor;
    }
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final bool isWarning;
  final bool isExpired;

  const _ProgressBar({
    required this.value,
    this.isWarning = false,
    this.isExpired = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color trackColor =
        Get.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    final Color fillColor = isExpired
        ? const Color(0xFFDC2626)
        : isWarning
            ? const Color(0xFFF59E0B)
            : AppColors.primaryColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [fillColor.withOpacity(0.9), fillColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: fillColor.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UsageStats extends StatelessWidget {
  final int projectsCount;
  final int usersCount;
  final String storageText;

  const _UsageStats({
    required this.projectsCount,
    required this.usersCount,
    required this.storageText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool veryNarrow = constraints.maxWidth < 280;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F1720).withOpacity(0.5)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment:
                veryNarrow ? WrapAlignment.start : WrapAlignment.spaceEvenly,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _statItem(
                icon: Icons.apartment_rounded,
                label: 'Projets',
                value: '$projectsCount',
                color: const Color(0xFF3B82F6),
              ),
              if (!veryNarrow)
                Container(
                  width: 1,
                  height: 28,
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
              _statItem(
                icon: Icons.groups_rounded,
                label: 'Utilisateurs',
                value: '$usersCount',
                color: const Color(0xFF10B981),
              ),
              if (!veryNarrow)
                Container(
                  width: 1,
                  height: 28,
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
              _statItem(
                icon: Icons.cloud_done_rounded,
                label: 'Stockage',
                value: storageText,
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(Get.isDarkMode ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _textPrimary(),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _textSecondary(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CountdownPill extends StatelessWidget {
  final int daysLeft;
  final bool isExpired;

  const _CountdownPill({required this.daysLeft, required this.isExpired});

  @override
  Widget build(BuildContext context) {
    final Color bg = isExpired
        ? const Color(0xFFDC2626)
        : daysLeft <= 3
            ? const Color(0xFFEA580C)
            : const Color(0xFFF59E0B);

    final String label = isExpired ? 'Expiré' : 'J-$daysLeft';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.block_rounded : Icons.hourglass_bottom_rounded,
            size: 16,
            color: bg,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: bg,
            ),
          ),
          if (!isExpired)
            Text(
              'rest.',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: bg.withOpacity(0.70),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String plan;
  const _PlanBadge({required this.plan});

  @override
  Widget build(BuildContext context) {
    final bool isPro = plan == 'pro';
    final Color color =
        isPro ? const Color(0xFF7C3AED) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPro ? Icons.bolt_rounded : Icons.lock_open_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isPro ? 'PRO' : 'FREE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;

  const _SubscriptionChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent =
        highlighted ? const Color(0xFF7C3AED) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFF7C3AED).withOpacity(0.06)
            : _softCardColor(),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF7C3AED).withOpacity(0.20)
              : _borderColor(),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: highlighted ? const Color(0xFF7C3AED) : _textPrimary(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsivePlanGrid extends StatelessWidget {
  const _ResponsivePlanGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 840
            ? children.length.clamp(1, 3)
            : constraints.maxWidth >= 560
                ? children.length.clamp(1, 2)
                : 1;

        if (columns > 1) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i < children.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _PremiumPanel extends StatelessWidget {
  const _PremiumPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF141E2E), const Color(0xFF111827)]
              : [Colors.white, const Color(0xFFFAFAFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2A3D) : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(isDark ? 0.03 : 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PlanCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String price;
  final String? priceSuffix;
  final List<String> features;
  final String buttonLabel;
  final bool isPopular;
  final bool isCurrentPlan;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _PlanCard({
    required this.title,
    this.subtitle,
    required this.price,
    this.priceSuffix,
    required this.features,
    required this.buttonLabel,
    this.isPopular = false,
    this.isCurrentPlan = false,
    required this.accentColor,
    this.onPressed,
  });

  factory _PlanCard.gratuit({bool isCurrentPlan = false}) => _PlanCard(
        title: 'Projet Gratuit BTP',
        subtitle: 'Pour découvrir notre solution',
        price: 'Gratuit',
        features: const [
          'Un seul utilisateur',
          'Fonctionnalités de base',
          'Support par email',
          '1 projet actif',
        ],
        buttonLabel: 'Commencer gratuitement',
        isPopular: false,
        isCurrentPlan: isCurrentPlan,
        accentColor: const Color(0xFF1A1A2E),
        onPressed: () {},
      );

  factory _PlanCard.entreprise({bool isCurrentPlan = false}) => _PlanCard(
        title: 'Entreprise Cloud BTP',
        subtitle: 'Pour les équipes en croissance',
        price: '30 TND',
        priceSuffix: 'par mois / utilisateur',
        features: const [
          'Projets illimités',
          'Jusqu\'à 5 utilisateurs',
          'Support prioritaire',
          'Rapports avancés et analytics',
          'Intégrations API',
        ],
        buttonLabel: 'Choisir cette offre',
        isPopular: false,
        isCurrentPlan: isCurrentPlan,
        accentColor: const Color(0xFF1A1A2E),
        onPressed: () {},
      );

  factory _PlanCard.onPremise({bool isCurrentPlan = false}) => _PlanCard(
        title: 'On Premise BTP',
        subtitle: 'Pour les grandes entreprises',
        price: '500 TND',
        priceSuffix: 'par an',
        features: const [
          'Projets illimités',
          'Utilisateurs illimités',
          'Installation sur vos serveurs',
          'Support dédié 24/7',
          'Personnalisation complète',
        ],
        buttonLabel: 'Contacter l equipe',
        isPopular: false,
        isCurrentPlan: isCurrentPlan,
        accentColor: const Color(0xFF1A1A2E),
        onPressed: () {},
      );

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnterprise = widget.title.toLowerCase().contains('premise');
    final isQuarter = widget.title.toLowerCase().contains('3 mois');
    final badgeLabel = isEnterprise
        ? 'Enterprise'
        : isQuarter
            ? 'Recommande'
            : 'PRO';
    final badgeColor = isEnterprise
        ? const Color(0xFF7C3AED)
        : isQuarter
            ? AppColors.primaryColor
            : const Color(0xFF2563EB);
    final isDark = Get.isDarkMode;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isEnterprise
              ? LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1A1625), const Color(0xFF111827)]
                      : [const Color(0xFFFAFAFA), const Color(0xFFFFF7ED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isEnterprise ? null : _cardColor(),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isEnterprise
                ? badgeColor.withOpacity(isDark ? 0.25 : 0.18)
                : isQuarter
                    ? AppColors.primaryColor.withOpacity(isDark ? 0.25 : 0.18)
                    : _borderColor(),
            width: isEnterprise || isQuarter ? 1.2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
              blurRadius: _hovered ? 24 : 16,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            if (isEnterprise)
              BoxShadow(
                color: badgeColor.withOpacity(isDark ? 0.08 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEnterprise
                        ? Icons.domain_rounded
                        : Icons.workspace_premium_rounded,
                    color: badgeColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary(),
                          height: 1.25,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _PillBadge(
                  label: badgeLabel,
                  icon:
                      isEnterprise ? Icons.shield_rounded : Icons.bolt_rounded,
                  color: badgeColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.price,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary(),
                    letterSpacing: -0.6,
                  ),
                ),
                if (widget.priceSuffix != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        widget.priceSuffix!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (isEnterprise) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _softCardColor().withOpacity(isDark ? 0.6 : 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor()),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.primaryColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Solution dédiée pour grandes entreprises BTP.',
                        style: GoogleFonts.inter(
                          color: _textPrimary(),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _PlanStat(icon: Icons.groups_rounded, label: _usersStat()),
                _PlanStat(
                  icon: Icons.apartment_rounded,
                  label: _projectsStat(),
                ),
                _PlanStat(
                  icon: Icons.cloud_done_rounded,
                  label: _storageStat(),
                ),
                _PlanStat(icon: Icons.schedule_rounded, label: _durationStat()),
              ],
            ),
            const SizedBox(height: 12),
            ...widget.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF22C55E),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 12,
                          color: _textPrimary(),
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _PremiumButton(
                label: widget.buttonLabel,
                icon: isEnterprise
                    ? Icons.support_agent_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: widget.onPressed,
                isEnterprise: isEnterprise,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _usersStat() {
    final text = widget.features.join(' ').toLowerCase();
    if (text.contains('illimit')) return 'Utilisateurs illimités';
    if (text.contains('5 utilisateur')) return '5 utilisateurs';
    return '1 utilisateur';
  }

  String _projectsStat() {
    final text = widget.features.join(' ').toLowerCase();
    if (text.contains('projets illimit')) return 'Projets illimités';
    return '1 projet actif';
  }

  String _storageStat() {
    return widget.title.toLowerCase().contains('premise')
        ? 'Sur vos serveurs'
        : 'Cloud sécurisé';
  }

  String _durationStat() {
    if ((widget.priceSuffix ?? '').toLowerCase().contains('3 mois')) {
      return '3 mois';
    }
    if ((widget.priceSuffix ?? '').toLowerCase().contains('an')) {
      return 'Annuel';
    }
    return 'Mensuel';
  }
}

class _PremiumButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isEnterprise;

  const _PremiumButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.isEnterprise = false,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isEnterprise
                ? [const Color(0xFF7C3AED), const Color(0xFF6D28D9)]
                : [AppColors.primaryColor, const Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (widget.isEnterprise
                      ? const Color(0xFF7C3AED)
                      : AppColors.primaryColor)
                  .withOpacity(isDark ? 0.25 : 0.18),
              blurRadius: _pressed ? 8 : 14,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanStat extends StatelessWidget {
  const _PlanStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _softCardColor(),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderColor()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _textSecondary(),
            ),
          ),
        ],
      ),
    );
  }
}

Color _cardColor() {
  return Get.isDarkMode ? const Color(0xFF131B2C) : Colors.white;
}

Color _softCardColor() {
  return Get.isDarkMode ? const Color(0xFF0F1720) : const Color(0xFFF8FAFC);
}

Color _borderColor() {
  return Get.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
}

Color _textPrimary() {
  return Get.isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
}

Color _textSecondary() {
  return Get.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
}

List<BoxShadow> _softShadow() {
  final isDark = Get.isDarkMode;
  return [
    BoxShadow(
      color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
      blurRadius: 24,
      offset: const Offset(0, 10),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: AppColors.primaryColor.withOpacity(isDark ? 0.03 : 0.02),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
