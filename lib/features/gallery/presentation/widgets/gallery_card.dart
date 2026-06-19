import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/item_action_menu.dart';
import '../../data/models/gallery_model.dart';

class GalleryCard extends StatelessWidget {
  final GalleryModel gallery;
  final VoidCallback? onView;

  const GalleryCard({
    super.key,
    required this.gallery,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final reserveName = gallery.reserve?.nom ?? 'Réserve non renseignée';

    return DashboardCard(
      onTap: onView,
      leading: _Thumbnail(path: gallery.path),
      title: gallery.name ?? 'Image sans nom',
      subtitle: reserveName,
      metadata: [
        if (gallery.createdAt != null)
          InfoRow(
            icon: Icons.calendar_today_rounded,
            value: _formatDate(gallery.createdAt!),
          ),
        if (gallery.reserve?.user != null)
          InfoRow(
            icon: Icons.person_outline_rounded,
            value: _formatAuthor(gallery.reserve!.user!),
          ),
      ],
      trailing: ItemActionMenu(
        onView: onView,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatAuthor(User user) {
    final first = user.firstname ?? '';
    final last = user.lastname ?? '';
    final full = '$first $last'.trim();
    return full.isEmpty ? 'Auteur inconnu' : full;
  }
}

class _Thumbnail extends StatelessWidget {
  final String? path;

  const _Thumbnail({this.path});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageUrl = path != null && path!.isNotEmpty
        ? 'http://localhost:3000/$path'
        : null;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackIcon(colors),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            )
          : _fallbackIcon(colors),
    );
  }

  Widget _fallbackIcon(ColorScheme colors) {
    return Center(
      child: Icon(
        Icons.image_outlined,
        color: AppColors.primaryColor.withOpacity(0.6),
        size: 28,
      ),
    );
  }
}
