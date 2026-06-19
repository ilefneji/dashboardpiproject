import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/module_list_shell.dart';
import '../../../../core/widgets/responsive_card_grid.dart';
import '../../../../features/project/data/models/project_model.dart';
import '../../data/models/file_model.dart';
import '../../data/models/folder_model.dart';
import '../controllers/document_controller.dart';
import '../widgets/file_card.dart';
import '../widgets/folder_card.dart';

class DocumentListPage extends GetView<DocumentController> {
  const DocumentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final project = controller.selectedProject.value;

      return ModuleListShell(
        title: 'Documents',
        icon: Icons.folder_outlined,
        subtitle: project != null ? project.name : 'Sélectionnez un projet',
        itemCount:
            controller.flatFiles.length + controller.currentFolders.length,
        searchController: controller.searchController,
        onSearchChanged: controller.searchDocuments,
        searchHint: 'Rechercher un document...',
        isLoading:
            controller.isLoading.value || controller.isLoadingProjects.value,
        onRefresh: controller.loadDocuments,
        headerActions: [
          if (project != null && controller.allProjects.length > 1)
            TextButton.icon(
              onPressed: controller.clearSelectedProject,
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Changer'),
            ),
        ],
        body: _buildBody(context),
      );
    });
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isLoadingProjects.value) {
      return _buildLoadingView('Chargement des projets...');
    }

    if (controller.allProjects.isEmpty) {
      return _buildEmptyView(
        icon: Icons.folder_off_outlined,
        title: 'Aucun projet disponible',
        subtitle: 'Aucun projet ne vous est assigné pour le moment.',
      );
    }

    if (controller.selectedProject.value == null) {
      return _ProjectPickerView(controller: controller);
    }

    if (controller.isLoading.value) {
      return _buildLoadingView('Chargement des documents...');
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _buildErrorView(controller.errorMessage.value);
    }

    return Column(
      children: [
        _Breadcrumbs(controller: controller),
        Expanded(
          child: _buildItemsGrid(context),
        ),
      ],
    );
  }

  Widget _buildItemsGrid(BuildContext context) {
    final folders = controller.currentFolders;
    final files = controller.flatFiles;

    if (folders.isEmpty && files.isEmpty) {
      return _buildEmptyView(
        icon: Icons.folder_open_outlined,
        title: 'Aucun document',
        subtitle: 'Ce projet ne contient aucun fichier ou dossier.',
      );
    }

    // Combine folders and files into a single typed list for the grid.
    final items = <_DocumentItem>[
      ...folders.map((f) => _DocumentItem.folder(f)),
      ...files.map((f) => _DocumentItem.file(f)),
    ];

    return ResponsiveCardGrid<_DocumentItem>(
      items: items,
      itemBuilder: (context, item, index) {
        return item.map(
          folder: (f) => FolderCard(
            folder: f,
            onOpen: () => controller.openFolder(f),
            onRename: () => _showRenameDialog(
              context: context,
              title: 'Renommer le dossier',
              initialValue: f.name ?? '',
              onConfirm: (newName) => controller.renameFolder(f, newName),
            ),
            onDelete: () => controller.deleteFolder(f),
          ),
          file: (f) => FileCard(
            file: f,
            onView: () => _openFile(f),
            onDownload: () => _downloadFile(f),
            onRename: () => _showRenameDialog(
              context: context,
              title: 'Renommer le fichier',
              initialValue: f.displayName,
              onConfirm: (newName) => controller.renameFile(f, newName),
            ),
            onDelete: () => controller.deleteFile(f),
          ),
        );
      },
    );
  }

  void _openFile(FileModel file) {
    final path = file.path;
    if (path == null || path.isEmpty) return;

    // Sur web, ouvrir dans un nouvel onglet.
    final url = 'https://pipropmsapi.onrender.com//$path';
    // Utilisation de html.window.open serait idéale ici, mais on garde
    // l'action abstraite pour ne pas casser la compilation mobile.
    // Pour le dashboard web, on peut utiliser url_launcher si disponible.
  }

  void _downloadFile(FileModel file) {
    final path = file.path;
    if (path == null || path.isEmpty) return;
    // Logique de téléchargement web à brancher (url_launcher / html).
  }

  void _showRenameDialog({
    required BuildContext context,
    required String title,
    required String initialValue,
    required ValueChanged<String> onConfirm,
  }) {
    final controller = TextEditingController(text: initialValue);
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nouveau nom',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop();
                onConfirm(name);
              }
            },
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryColor),
          const SizedBox(height: 16),
          Text(message,
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildEmptyView({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.red[200]),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: controller.loadDocuments,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Réessayer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                side: const BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Union type simple pour mélanger dossiers et fichiers dans la grille.
class _DocumentItem {
  final FolderModel? folder;
  final FileModel? file;

  const _DocumentItem.folder(this.folder) : file = null;
  const _DocumentItem.file(this.file) : folder = null;

  T map<T>({
    required T Function(FolderModel) folder,
    required T Function(FileModel) file,
  }) {
    if (this.folder != null) return folder(this.folder!);
    if (this.file != null) return file(this.file!);
    throw StateError('Invalid _DocumentItem');
  }
}

class _Breadcrumbs extends StatelessWidget {
  final DocumentController controller;

  const _Breadcrumbs({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Obx(() {
      final crumbs = controller.breadcrumbs;
      if (crumbs.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Crumb(
              label: 'Racine',
              onTap: controller.goToRoot,
              isActive: false,
            ),
            ...crumbs.asMap().entries.expand((entry) {
              final index = entry.key;
              final folder = entry.value;
              final isLast = index == crumbs.length - 1;
              return [
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                _Crumb(
                  label: folder.name ?? 'Dossier',
                  onTap: isLast ? null : () => _goUpTo(index),
                  isActive: isLast,
                ),
              ];
            }),
          ],
        ),
      );
    });
  }

  void _goUpTo(int index) {
    controller.navigateToBreadcrumb(index);
  }
}

class _Crumb extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const _Crumb({
    required this.label,
    this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? colors.onSurface : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ProjectPickerView extends StatelessWidget {
  final DocumentController controller;

  const _ProjectPickerView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélectionner un projet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choisissez un projet pour afficher ses documents.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ResponsiveCardGrid<ProjectModel>(
              items: controller.allProjects,
              itemBuilder: (context, project, index) {
                return DashboardCard(
                  onTap: () => controller.selectProject(project),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.folder_outlined,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  title: project.name ?? 'Projet sans nom',
                  subtitle: project.localisation,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
