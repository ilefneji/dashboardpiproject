import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'app_shell.dart';

/// Squelette commun pour les pages de liste de modules.
///
/// Fournit un header cohérent avec icône, titre, compteur, barre de recherche
/// et actions optionnelles, ainsi qu'un corps scrollable.
class ModuleListShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final int? itemCount;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;
  final List<Widget>? headerActions;
  final Widget body;
  final Widget? floatingActionButton;
  final bool embedded;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const ModuleListShell({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.itemCount,
    this.searchController,
    this.onSearchChanged,
    this.searchHint = 'Rechercher...',
    this.headerActions,
    required this.body,
    this.floatingActionButton,
    this.embedded = false,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final content = SafeArea(
      child: Column(
        children: [
          _ModuleHeader(
            title: title,
            icon: icon,
            subtitle: subtitle,
            itemCount: itemCount,
            searchController: searchController,
            onSearchChanged: onSearchChanged,
            searchHint: searchHint,
            headerActions: headerActions,
            onRefresh: onRefresh,
            isLoading: isLoading,
          ),
          Expanded(
            child: body,
          ),
        ],
      ),
    );

    return embedded
        ? content
        : AppShell(
            child: Scaffold(
              backgroundColor: colors.background,
              body: content,
              floatingActionButton: floatingActionButton,
            ),
          );
  }
}

class _ModuleHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final int? itemCount;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;
  final List<Widget>? headerActions;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const _ModuleHeader({
    required this.title,
    required this.icon,
    this.subtitle,
    this.itemCount,
    this.searchController,
    this.onSearchChanged,
    required this.searchHint,
    this.headerActions,
    this.onRefresh,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.06,
            ),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (itemCount != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$itemCount élément${itemCount == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: colors.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                if (headerActions != null) ...headerActions!,
              ],
            ),
            if (onSearchChanged != null || searchController != null) ...[
              const SizedBox(height: 14),
              TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: searchHint,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: colors.onSurfaceVariant.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: colors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.outlineVariant),
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
          ],
        ),
      ),
    );
  }
}
