import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Carte générique et moderne pour les éléments de module du dashboard.
///
/// Usage : Documents, Plans de référence, Événements, Réserves, Rapports, Journaux...
class DashboardCard extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? description;
  final int descriptionMaxLines;
  final List<Widget>? metadata;
  final List<Widget>? chips;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const DashboardCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.description,
    this.descriptionMaxLines = 2,
    this.metadata,
    this.chips,
    this.trailing,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: backgroundColor ?? colors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? colors.outlineVariant,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(
                  theme.brightness == Brightness.dark ? 0.18 : 0.045,
                ),
                blurRadius: 10,
                offset: const Offset(0, 3),
                spreadRadius: -1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                            height: 1.25,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 3),
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
                        if (description != null &&
                            description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            description!,
                            maxLines: descriptionMaxLines,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                        if (metadata != null && metadata!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            children: metadata!,
                          ),
                        ],
                        if (chips != null && chips!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: chips!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
