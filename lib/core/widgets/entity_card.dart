import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EntityCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final String? avatarText;
  final Color? avatarColor;
  final List<Widget>? chips;
  final Widget? actions;
  final VoidCallback? onTap;

  const EntityCard({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.avatarText,
    this.avatarColor,
    this.chips,
    this.actions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outlineVariant),
          boxShadow: [
            BoxShadow(
                color: colors.shadow.withOpacity(
                    theme.brightness == Brightness.dark ? 0.16 : 0.035),
                blurRadius: 10,
                offset: const Offset(0, 3),
                spreadRadius: -1),
            BoxShadow(
                color: colors.shadow.withOpacity(
                    theme.brightness == Brightness.dark ? 0.08 : 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: avatarColor ?? const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                avatarText ?? '?',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: colors.onSurfaceVariant)),
                  ],
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: colors.onSurfaceVariant)),
                  ],
                  if (chips != null && chips!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 4, children: chips!),
                  ],
                ],
              ),
            ),
            if (actions != null) ...[
              const SizedBox(width: 10),
              actions!,
            ],
          ],
        ),
      ),
    );
  }
}
