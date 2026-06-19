import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/module_list_shell.dart';
import '../../../../core/widgets/responsive_card_grid.dart';
import '../../../../features/project/data/models/project_model.dart';
import '../../data/models/gallery_model.dart';
import '../controllers/gallery_controller.dart';
import '../widgets/gallery_card.dart';

class GalleryListPage extends GetView<GalleryController> {
  const GalleryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final project = controller.selectedProject.value;

      return ModuleListShell(
        title: 'Galeries',
        icon: Icons.photo_library_outlined,
        subtitle: project != null ? project.name : 'Sélectionnez un projet',
        itemCount: controller.filteredGalleries.length,
        searchController: controller.searchController,
        onSearchChanged: controller.searchGalleries,
        searchHint: 'Rechercher une image...',
        isLoading: controller.isLoading.value || controller.isLoadingProjects.value,
        onRefresh: controller.loadGalleries,
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
      return _buildLoadingView('Chargement des galeries...');
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _buildErrorView(controller.errorMessage.value);
    }

    final items = controller.filteredGalleries;

    if (items.isEmpty) {
      return _buildEmptyView(
        icon: Icons.photo_outlined,
        title: 'Aucune image',
        subtitle: controller.allGalleries.isEmpty
            ? 'Ce projet ne contient aucune image dans ses galeries.'
            : 'Aucune image ne correspond à votre recherche.',
      );
    }

    return ResponsiveCardGrid<GalleryModel>(
      items: items,
      itemBuilder: (context, gallery, index) {
        return GalleryCard(
          gallery: gallery,
          onView: () => controller.viewImage(gallery),
        );
      },
    );
  }

  Widget _buildLoadingView(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryColor),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
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
              onPressed: controller.loadGalleries,
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

class _ProjectPickerView extends StatelessWidget {
  final GalleryController controller;

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
            'Choisissez un projet pour afficher ses galeries.',
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
                      Icons.photo_library_outlined,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  title: project.name ?? 'Projet sans nom',
                  subtitle: project.localisation ?? '',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
