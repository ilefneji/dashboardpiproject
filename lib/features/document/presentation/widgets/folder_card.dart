import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/item_action_menu.dart';
import '../../data/models/folder_model.dart';

class FolderCard extends StatelessWidget {
  final FolderModel folder;
  final VoidCallback? onOpen;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const FolderCard({
    super.key,
    required this.folder,
    this.onOpen,
    this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DashboardCard(
      onTap: onOpen,
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.softOrange,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
        ),
        child: const Icon(
          Icons.folder_rounded,
          color: AppColors.primaryColor,
          size: 24,
        ),
      ),
      title: folder.name ?? 'Dossier sans nom',
      subtitle: folder.projectId != null ? 'Projet #${folder.projectId}' : null,
      metadata: [
        InfoRow(
          icon: Icons.insert_drive_file_outlined,
          value: '${folder.totalFiles} fichier${folder.totalFiles == 1 ? '' : 's'}',
        ),
        InfoRow(
          icon: Icons.folder_outlined,
          value: '${folder.totalSubfolders} sous-dossier${folder.totalSubfolders == 1 ? '' : 's'}',
        ),
      ],
      trailing: ItemActionMenu(
        onView: onOpen,
        onEdit: onRename,
        onDelete: onDelete,
        deleteConfirmationTitle: 'Supprimer le dossier ?',
        deleteConfirmationMessage:
            'Êtes-vous sûr de vouloir supprimer "${folder.name ?? 'ce dossier'}" et tout son contenu ?',
      ),
    );
  }
}
