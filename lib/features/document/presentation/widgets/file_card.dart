import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/item_action_menu.dart';
import '../../data/models/file_model.dart';

class FileCard extends StatelessWidget {
  final FileModel file;
  final VoidCallback? onView;
  final VoidCallback? onDownload;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const FileCard({
    super.key,
    required this.file,
    this.onView,
    this.onDownload,
    this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      onTap: onView,
      leading: _FileIcon(extension: file.extension),
      title: file.displayName,
      subtitle: file.size?.isNotEmpty == true ? 'Taille : ${file.size}' : null,
      metadata: [
        if (file.createdAt != null)
          InfoRow(
            icon: Icons.calendar_today_rounded,
            value: _formatDate(file.createdAt!),
          ),
        InfoRow(
          icon: Icons.insert_drive_file_outlined,
          value: file.extension.isEmpty ? 'Fichier' : file.extension.toUpperCase(),
        ),
      ],
      trailing: ItemActionMenu(
        onView: onView,
        onDownload: onDownload,
        onEdit: onRename,
        onDelete: onDelete,
        deleteConfirmationTitle: 'Supprimer le fichier ?',
        deleteConfirmationMessage:
            'Êtes-vous sûr de vouloir supprimer "${file.displayName}" ?',
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _FileIcon extends StatelessWidget {
  final String extension;

  const _FileIcon({required this.extension});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final config = _configForExtension(extension, colors);

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.foreground.withOpacity(0.2)),
      ),
      child: Center(
        child: Text(
          config.label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: config.foreground,
          ),
        ),
      ),
    );
  }

  _FileIconConfig _configForExtension(String ext, ColorScheme colors) {
    switch (ext) {
      case 'pdf':
        return _FileIconConfig(
          label: 'PDF',
          background: const Color(0xFFFEE2E2),
          foreground: const Color(0xFFDC2626),
        );
      case 'doc':
      case 'docx':
        return _FileIconConfig(
          label: 'DOC',
          background: const Color(0xFFDBEAFE),
          foreground: const Color(0xFF2563EB),
        );
      case 'xls':
      case 'xlsx':
        return _FileIconConfig(
          label: 'XLS',
          background: const Color(0xFFD1FAE5),
          foreground: const Color(0xFF059669),
        );
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return _FileIconConfig(
          label: 'IMG',
          background: const Color(0xFFFEF3C7),
          foreground: const Color(0xFFD97706),
        );
      default:
        return _FileIconConfig(
          label: ext.isEmpty
              ? '?'
              : ext.toUpperCase().substring(0, ext.length.clamp(1, 3)),
          background: colors.surfaceVariant,
          foreground: colors.onSurfaceVariant,
        );
    }
  }
}

class _FileIconConfig {
  final String label;
  final Color background;
  final Color foreground;

  _FileIconConfig({
    required this.label,
    required this.background,
    required this.foreground,
  });
}
