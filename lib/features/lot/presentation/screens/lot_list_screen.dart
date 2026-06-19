import 'package:constructiondashboard/core/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/lot_controller.dart';
import '../../domain/entities/lot.dart';
import '../widgets/lot_form_dialog.dart';
import '../widgets/lot_detail_dialog.dart';

// ═══════════════════════════════════════════════════════════
// 📦 LotListScreen
// ═══════════════════════════════════════════════════════════
class LotListScreen extends StatelessWidget {
  final bool embedded;

  const LotListScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LotController>();

    final content = SafeArea(
      // ✅ Outer Stack removed — Column gets proper bounded height
      child: Column(
        children: [
          _PageHeader(controller: controller),
          Expanded(
            child: Obx(
              () => AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildBody(context, controller),
              ),
            ),
          ),
        ],
      ),
    );

    return embedded ? content : AppShell(child: content);
  }

  Widget _buildBody(BuildContext context, LotController controller) {
    // ✅ Loading
    if (controller.isLoading.value) {
      return const _LoadingView(key: ValueKey('loading'));
    }

    // ✅ Error
    if (controller.hasError.value) {
      return _ErrorView(
        key: const ValueKey('error'),
        message: controller.error.value,
        onRetry: controller.fetchLots,
      );
    }

    // ✅ Empty
    if (controller.filteredLots.isEmpty) {
      return _EmptyView(
        key: const ValueKey('empty'),
        controller: controller,
      );
    }

    // ✅ List — FAB lives inside _LotList's own bounded Stack
    return _LotList(
      key: const ValueKey('list'),
      controller: controller,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 🔝 Page Header — StatefulWidget owns the TextEditingController
// ═══════════════════════════════════════════════════════════
class _PageHeader extends StatefulWidget {
  final LotController controller;

  const _PageHeader({required this.controller});

  @override
  State<_PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<_PageHeader> {
  // ✅ Owned here — Flutter manages its full lifecycle safely
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    // ✅ Disposed with the widget — never touched by GetX
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF94A3B8).withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF94A3B8).withOpacity(0.12),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title Row ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.dashboard_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // ── Title + Count ──────────────────────────
                Expanded(
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'lots'.tr,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.controller.filteredLots.length} ${'lots'.tr}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Search Field ────────────────────────────────
            TextField(
              // ✅ Uses local controller — never disposed by GetX
              controller: _searchController,
              onChanged: widget.controller.searchLots,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFCBD5E1),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 📋 Lot List
// ═══════════════════════════════════════════════════════════
class _LotList extends StatefulWidget {
  final LotController controller;

  const _LotList({super.key, required this.controller});

  @override
  State<_LotList> createState() => _LotListState();
}

class _LotListState extends State<_LotList> {
  static const int _pageSize = 7;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    ever(widget.controller.filteredLots, (_) {
      if (mounted) setState(() => _currentPage = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = widget.controller.filteredLots;
      final totalPages = (items.length / _pageSize).ceil();
      final start = _currentPage * _pageSize;
      final end = (start + _pageSize).clamp(0, items.length);
      final pageItems = items.sublist(start, end);

      return Stack(
        children: [
          // ── List ────────────────────────────────────────
          ListView.separated(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 100,
            ),
            itemCount: pageItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _LotCard(lot: pageItems[index]);
            },
          ),

          // ── Pagination ───────────────────────────────────
          if (totalPages > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 80, // ✅ space reserved for FAB
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(40),
                    border:
                        Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF94A3B8).withOpacity(0.15),
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

          // ✅ FAB — moved inside bounded Stack
          Positioned(
            bottom: 24,
            right: 24,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => LotFormDialog(
                    isEditing: false,
                    onSave: widget.controller.createLot,
                  ),
                );
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════
// 💳 Lot Card
// ═══════════════════════════════════════════════════════════
class _LotCard extends StatefulWidget {
  final Lot lot;

  const _LotCard({required this.lot});

  @override
  State<_LotCard> createState() => _LotCardState();
}

class _LotCardState extends State<_LotCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LotController>();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          await controller.selectLotAndRefresh(widget.lot);
          if (mounted) {
            showDialog(
              context: context,
              builder: (_) => LotDetailDialog(lot: widget.lot),
            );
          }
        },
        child: AnimatedContainer(
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
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.dashboard_rounded,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lot.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.lot.description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      controller.nameController.text = widget.lot.name;
                      controller.descriptionController.text =
                          widget.lot.description;
                      showDialog(
                        context: context,
                        builder: (_) => LotFormDialog(
                          isEditing: true,
                          onSave: () => controller.updateLot(widget.lot),
                        ),
                      );
                    } else if (value == 'delete') {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor:
                              Theme.of(dialogContext).colorScheme.surface,
                          surfaceTintColor: Colors.transparent,
                          title: const Text('Supprimer le lot'),
                          content: Text(
                              'Êtes-vous sûr de vouloir supprimer "${widget.lot.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final success = await controller
                                    .deleteLot(widget.lot.id ?? 0);
                                if (success && dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }
                              },
                              child: const Text('Supprimer',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded,
                              size: 16, color: AppColors.primaryColor),
                          const SizedBox(width: 10),
                          Text(
                            'Modifier',
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded,
                              size: 16, color: Color(0xFFEF4444)),
                          const SizedBox(width: 10),
                          Text(
                            'Supprimer',
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
                      borderRadius: BorderRadius.circular(12)),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 🔘 Pagination Button
// ═══════════════════════════════════════════════════════════
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
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF64748B) : Colors.grey[300],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 📭 Empty View
// ═══════════════════════════════════════════════════════════
class _EmptyView extends StatelessWidget {
  final LotController controller;

  const _EmptyView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard_customize_outlined,
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('no_lots_found'.tr,
              style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ⏳ Loading View
// ═══════════════════════════════════════════════════════════
class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

// ═══════════════════════════════════════════════════════════
// ❌ Error View
// ═══════════════════════════════════════════════════════════
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFFECACA),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 32,
                color: Color(0xFFEF4444),
              ),
            ),

            const SizedBox(height: 20),

            // ── Title ────────────────────────────────────────
            Text(
              'Une erreur est survenue',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // ── Message Box ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFECACA),
                  width: 1,
                ),
              ),
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFEF4444),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 24),

            // ── Retry Button ─────────────────────────────────
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.28),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Réessayer',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
