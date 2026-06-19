import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Menu d'actions standardisé pour les cartes de module.
///
/// Actions supportées : voir, télécharger, modifier, supprimer.
class ItemActionMenu extends StatelessWidget {
  final VoidCallback? onView;
  final VoidCallback? onDownload;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? deleteConfirmationTitle;
  final String? deleteConfirmationMessage;

  const ItemActionMenu({
    super.key,
    this.onView,
    this.onDownload,
    this.onEdit,
    this.onDelete,
    this.deleteConfirmationTitle,
    this.deleteConfirmationMessage,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: colors.onSurfaceVariant,
      ),
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      itemBuilder: (context) => [
        if (onView != null)
          _buildItem(
            value: 'view',
            icon: Icons.visibility_outlined,
            label: 'Voir',
            color: colors.onSurface,
          ),
        if (onDownload != null)
          _buildItem(
            value: 'download',
            icon: Icons.download_outlined,
            label: 'Télécharger',
            color: colors.onSurface,
          ),
        if (onEdit != null)
          _buildItem(
            value: 'edit',
            icon: Icons.edit_outlined,
            label: 'Modifier',
            color: colors.onSurface,
          ),
        if (onDelete != null)
          _buildItem(
            value: 'delete',
            icon: Icons.delete_outline_rounded,
            label: 'Supprimer',
            color: colors.error,
          ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'view':
            onView?.call();
            break;
          case 'download':
            onDownload?.call();
            break;
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            _confirmDelete(context);
            break;
        }
      },
    );
  }

  PopupMenuItem<String> _buildItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          deleteConfirmationTitle ?? 'Confirmer la suppression',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          deleteConfirmationMessage ??
              'Êtes-vous sûr de vouloir supprimer cet élément ? Cette action est irréversible.',
          style: GoogleFonts.inter(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            child: Text(
              'Supprimer',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
