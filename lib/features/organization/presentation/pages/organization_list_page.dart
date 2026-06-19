import 'package:constructiondashboard/core/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../config/presentation/controllers/subscription_controller.dart';
import '../../domain/entities/organization.dart';
import '../controllers/organization_controller.dart';
import '../widgets/organization_detail_dialog.dart';
import '../widgets/organization_form_dialog.dart';

class OrganizationListPage extends StatefulWidget {
  final bool embedded;

  const OrganizationListPage({super.key, this.embedded = false});

  @override
  State<OrganizationListPage> createState() => _OrganizationListPageState();
}

class _OrganizationListPageState extends State<OrganizationListPage> {
  late final OrganizationController _controller;

  late final Worker _listWorker;
  late final Worker _loadingWorker;
  late final Worker _errorWorker;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<OrganizationController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.organizations.isEmpty && !_controller.isLoading.value) {
        _controller.fetchOrganizations();
      }
    });

    _listWorker = ever(_controller.filteredOrganizations, (_) => _refresh());
    _loadingWorker = ever(_controller.isLoading, (_) => _refresh());
    _errorWorker = ever(_controller.hasError, (_) => _refresh());
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _listWorker.dispose();
    _loadingWorker.dispose();
    _errorWorker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _buildBody(context, _controller),
      ),
    );

    return widget.embedded ? content : AppShell(child: content);
  }

  Widget _buildBody(BuildContext context, OrganizationController controller) {
    if (controller.isLoading.value && controller.organizations.isEmpty) {
      return const _LoadingView(key: ValueKey('loading'));
    }

    if (controller.hasError.value && controller.error.value.isNotEmpty) {
      return _ErrorView(
        key: const ValueKey('error'),
        message: controller.error.value,
        onRetry: controller.fetchOrganizations,
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _PageHeader(controller: controller),
        if (controller.filteredOrganizations.isEmpty)
          const SizedBox(height: 180)
        else
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: _OrganizationList(
              key: const ValueKey('list'),
              controller: controller,
              onChanged: _controller.fetchOrganizations,
            ),
          ),
      ],
    );
  }
}

class _PageHeader extends StatefulWidget {
  final OrganizationController controller;

  const _PageHeader({required this.controller});

  @override
  State<_PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<_PageHeader> {
  bool _requestedCompanySubscriptions = false;

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final subscriptionController = Get.find<SubscriptionController>();
    return Obx(() {
      final currentUser = authController.currentUser.value;
      final fullName =
          '${currentUser?.firstname ?? ''} ${currentUser?.lastname ?? ''}'
              .trim();
      final _ = subscriptionController.userSubscriptions.length +
          subscriptionController.companySubscriptions.length +
          widget.controller.organizations.length;

      int? resolveCompanyId() {
        final currentSub =
            subscriptionController.findCurrentSubscriptionForUser(
          currentUser?.id,
        );

        final fromSub = currentSub?.companyId ??
            currentSub?.company?.id ??
            currentSub?.project?.company?.id;

        if (fromSub != null) return fromSub;

        final userOrgId = currentUser?.organizationId;
        if (userOrgId == null) return null;

        for (final org in widget.controller.organizations) {
          if (org.id == userOrgId) return org.companyId;
        }

        return null;
      }

      final companyId = resolveCompanyId();

      if (!_requestedCompanySubscriptions && companyId != null) {
        _requestedCompanySubscriptions = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          subscriptionController.fetchSubscriptionsByCompany(companyId);
        });
      }

      final currentSub = subscriptionController
          .findCurrentSubscriptionForUser(currentUser?.id);

      final dynamic company =
          currentSub?.company ?? currentSub?.project?.company;

      String companyName = '—';

      for (final sub in subscriptionController.companySubscriptions) {
        final name = sub.company?.name?.trim();
        if (name != null && name.isNotEmpty) {
          companyName = name;
          break;
        }

        final projectName = sub.project?.company?.name?.trim();
        if (projectName != null && projectName.isNotEmpty) {
          companyName = projectName;
          break;
        }
      }

      if (companyName == '—') {
        final direct = currentSub?.company?.name?.trim();
        if (direct != null && direct.isNotEmpty) companyName = direct;
      }

      if (companyName == '—') {
        final projectDirect = currentSub?.project?.company?.name?.trim();
        if (projectDirect != null && projectDirect.isNotEmpty) {
          companyName = projectDirect;
        }
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;

          return Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(
              isSmall ? 10 : 18,
              12,
              isSmall ? 10 : 24,
              20,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF374151)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmall ? 16 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isSmall)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Mon organisme',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Informations entreprise et compte utilisateur',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mon organisme',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Informations entreprise et compte utilisateur',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 22),
                  _AccountInfoCard(
                    fullName: fullName.isNotEmpty ? fullName : '—',
                    email: currentUser?.email ?? '—',
                    companyName: companyName,
                    phone: currentUser?.phone ?? '—',
                  ),
                  const SizedBox(height: 18),
                  _CompanyDetailsCard(
                    company: company,
                    organizationCount: widget.controller.organizations.length,
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

class _CompanyDetailsCard extends StatelessWidget {
  final dynamic company;
  final int organizationCount;

  const _CompanyDetailsCard({
    required this.company,
    required this.organizationCount,
  });

  String _text(dynamic value) {
    if (value == null) return '—';
    final v = value.toString().trim();
    return v.isEmpty ? '—' : v;
  }

  @override
  Widget build(BuildContext context) {
    final companyName = _text(company?.name);
    final plan = _text(company?.plan);
    final status = _text(company?.subscriptionStatus);
    final billingEmail = _text(company?.billingEmail);
    final billingCountry = _text(company?.billingCountry);

    String createdAt = '—';

    if (company?.createdAt != null) {
      try {
        final date = DateTime.parse(company.createdAt.toString());

        createdAt =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } catch (_) {
        createdAt = _text(company?.createdAt);
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [
                  Color(0xFF111827),
                  Color(0xFF1F2937),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [
                  Color(0xFFF1F3F5),
                  Color(0xFFE5E7EB),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: Color.fromARGB(255, 255, 255, 255),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entreprise',
                      style: GoogleFonts.inter(
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      companyName,
                      style: GoogleFonts.inter(
                        color: isDark
                            ? const Color(0xFFF9FAFB)
                            : const Color(0xFF1F2937),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              final cards = [
                _CompanyMiniCard(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Plan',
                  value: plan,
                ),
                _CompanyMiniCard(
                  icon: Icons.verified_outlined,
                  title: 'Statut abonnement',
                  value: status,
                ),
                _CompanyMiniCard(
                  icon: Icons.business_center_outlined,
                  title: 'Organisations liées',
                  value: organizationCount.toString(),
                ),
                _CompanyMiniCard(
                  icon: Icons.email_outlined,
                  title: 'Email facturation',
                  value: billingEmail,
                ),
                _CompanyMiniCard(
                  icon: Icons.flag_outlined,
                  title: 'Pays facturation',
                  value: billingCountry,
                ),
                _CompanyMiniCard(
                  icon: Icons.calendar_month_outlined,
                  title: 'Créée le',
                  value: createdAt,
                ),
              ];

              if (isWide) {
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: cards
                      .map(
                        (card) => SizedBox(
                          width: (constraints.maxWidth - 14) / 2,
                          child: card,
                        ),
                      )
                      .toList(),
                );
              }

              return Column(
                children: cards
                    .map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: card,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CompanyMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _CompanyMiniCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
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
                  title,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizationList extends StatefulWidget {
  final OrganizationController controller;
  final VoidCallback onChanged;

  const _OrganizationList({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<_OrganizationList> createState() => _OrganizationListState();
}

class _OrganizationListState extends State<_OrganizationList> {
  static const int _pageSize = 7;
  int _currentPage = 0;

  late final Worker _worker;

  @override
  void initState() {
    super.initState();
    _worker = ever(widget.controller.filteredOrganizations, (_) {
      if (mounted) setState(() => _currentPage = 0);
    });
  }

  @override
  void dispose() {
    _worker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.controller.filteredOrganizations;
    final totalPages = (items.length / _pageSize).ceil().clamp(1, 999);
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, items.length);
    final pageItems = items.sublist(start, end);
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 10 : 18,
              vertical: 16,
            ),
            itemCount: pageItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _AnimatedEntry(
              index: index,
              child: _OrganizationCard(
                organization: pageItems[index],
                onChanged: widget.onChanged,
              ),
            ),
          ),
        ),
        if (totalPages > 1)
          Padding(
            padding: EdgeInsets.only(
              bottom: isSmall ? 24 : 80,
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.3)
                          : const Color(0xFF94A3B8).withOpacity(0.15),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PaginationButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: _currentPage > 0,
                      onTap: () => setState(() => _currentPage--),
                    ),
                    const SizedBox(width: 8),
                    ...List.generate(totalPages, (i) {
                      final isActive = i == _currentPage;

                      return GestureDetector(
                        onTap: () => setState(() => _currentPage = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primaryColor
                                : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    _PaginationButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: _currentPage < totalPages - 1,
                      onTap: () => setState(() => _currentPage++),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PaginationButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primaryColor.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? AppColors.primaryColor.withOpacity(0.3)
                : isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? AppColors.primaryColor
              : isDark
                  ? const Color(0xFF6B7280)
                  : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}

class _OrganizationCard extends StatefulWidget {
  final Organization organization;
  final VoidCallback onChanged;

  const _OrganizationCard({
    required this.organization,
    required this.onChanged,
  });

  @override
  State<_OrganizationCard> createState() => _OrganizationCardState();
}

class _OrganizationCardState extends State<_OrganizationCard> {
  bool _isHovered = false;

  Future<void> _handleEdit(Organization org) async {
    await showDialog(
      context: Get.context!,
      builder: (_) => OrganizationFormDialog(organization: org),
    );
    widget.onChanged();
  }

  Future<void> _handleDelete(
    OrganizationController controller,
    Organization org,
  ) async {
    await controller.deleteOrganization(org.id);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrganizationController>();
    final org = widget.organization;
    final hasDesc =
        org.description != null && org.description!.trim().isNotEmpty;

    Widget popupMenu() {
      return PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            _handleEdit(org);
          } else if (value == 'delete') {
            _handleDelete(controller, org);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 10),
                Text(
                  'edit'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 10),
                Text(
                  'delete'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        color: Theme.of(context).colorScheme.surface,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.more_vert_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    Widget avatar() {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.business_rounded,
          size: 22,
          color: Colors.white,
        ),
      );
    }

    Widget textContent({required bool small}) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              org.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasDesc ? org.description!.trim() : '—',
              maxLines: small ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    Widget cardContent(bool small) {
      if (small) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                avatar(),
                const SizedBox(width: 12),
                textContent(small: true),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: popupMenu(),
            ),
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          avatar(),
          const SizedBox(width: 12),
          textContent(small: false),
          const SizedBox(width: 10),
          popupMenu(),
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (_) => OrganizationDetailDialog(organization: org),
        ),
        child: AnimatedContainer(
          width: double.infinity,
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? AppColors.primaryColor.withOpacity(0.35)
                  : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppColors.primaryColor.withOpacity(0.10)
                    : const Color(0xFFE8EBF2).withOpacity(0.06),
                blurRadius: _isHovered ? 16 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final small = constraints.maxWidth < 420;
                return cardContent(small);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedEntry extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedEntry({
    required this.index,
    required this.child,
  });

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 260 + (widget.index * 30).clamp(0, 180),
      ),
    );

    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  final String fullName;
  final String email;
  final String companyName;
  final String phone;

  const _AccountInfoCard({
    required this.fullName,
    required this.email,
    required this.companyName,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        final rows = [
          _AccountInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Nom complet',
            value: fullName,
          ),
          _AccountInfoRow(
            icon: Icons.email_outlined,
            label: 'Email pro',
            value: email,
          ),
          _AccountInfoRow(
            icon: Icons.business_outlined,
            label: 'Entreprise',
            value: companyName,
          ),
          _AccountInfoRow(
            icon: Icons.phone_outlined,
            label: 'Telephone',
            value: phone,
          ),
        ];

        final Widget content = isWide
            ? Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: rows[0]),
                      const SizedBox(width: 18),
                      Expanded(child: rows[1]),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: rows[2]),
                      const SizedBox(width: 18),
                      Expanded(child: rows[3]),
                    ],
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  rows[0],
                  const SizedBox(height: 12),
                  rows[1],
                  const SizedBox(height: 12),
                  rows[2],
                  const SizedBox(height: 12),
                  rows[3],
                ],
              );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF374151)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Informations du compte',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              content,
            ],
          ),
        );
      },
    );
  }
}

class _AccountInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AccountInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF374151)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isNotEmpty ? value : '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: AppColors.primaryColor,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 14),
            Text(
              'Une erreur est survenue',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
