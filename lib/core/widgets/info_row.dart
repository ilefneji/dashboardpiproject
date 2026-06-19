import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Petite ligne d'information secondaire (icône + label + valeur).
///
/// Exemple : date, auteur, type de fichier, taille, statut...
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;
  final double iconSize;
  final double fontSize;

  const InfoRow({
    super.key,
    required this.icon,
    this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
    this.iconSize = 13,
    this.fontSize = 11.5,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: iconColor ?? colors.onSurfaceVariant.withOpacity(0.75),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label != null ? '${label!}: $value' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: valueColor ?? colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Chip compact pour afficher un statut ou une catégorie.
class StatusChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fg = foregroundColor ?? colors.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ??
            colors.surfaceVariant.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.5 : 0.7,
            ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
