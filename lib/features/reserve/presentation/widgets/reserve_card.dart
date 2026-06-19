import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/item_action_menu.dart';
import '../../data/models/reserve_model.dart';

class ReserveCard extends StatelessWidget {
  final ReserveModel reserve;
  final VoidCallback? onView;
  final ValueChanged<String>? onStatusChanged;
  final List<String> statusOptions;

  const ReserveCard({
    super.key,
    required this.reserve,
    this.onView,
    this.onStatusChanged,
    this.statusOptions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      onTap: onView,
      leading: _ImageThumbnail(images: reserve.imagesPath ?? []),
      title: reserve.nom?.isNotEmpty == true ? reserve.nom! : 'Sans nom',
      subtitle: _subtitle,
      description:
          reserve.declaration?.isNotEmpty == true ? reserve.declaration : null,
      metadata: [
        if (reserve.localisation?.isNotEmpty == true)
          InfoRow(
            icon: Icons.location_on_outlined,
            value: reserve.localisation!,
          ),
        if (reserve.filePlan?.name?.isNotEmpty == true)
          InfoRow(
            icon: Icons.folder_copy_outlined,
            value: reserve.filePlan!.name!,
          ),
        if (reserve.createdAt != null)
          InfoRow(
            icon: Icons.calendar_today_outlined,
            value: _formatDate(reserve.createdAt!),
          ),
        if (reserve.aiDefectLabel?.isNotEmpty == true)
          InfoRow(
            icon: Icons.auto_awesome_outlined,
            value: 'IA : ${reserve.aiDefectLabel} '
                '(${(reserve.aiConfidence ?? 0).toStringAsFixed(0)}%)',
          ),
      ],
      chips: [
        _PriorityChip(priority: reserve.priority),
        _StatusChip(
          status: reserve.status,
          onStatusChanged: onStatusChanged,
          statusOptions: statusOptions,
        ),
      ],
      trailing: ItemActionMenu(
        onView: onView,
      ),
    );
  }

  String? get _subtitle {
    final parts = <String>[
      if (reserve.status?.isNotEmpty == true) reserve.status!,
      if (reserve.priority?.isNotEmpty == true) reserve.priority!,
    ];
    return parts.isEmpty ? null : parts.join(' • ');
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _ImageThumbnail extends StatefulWidget {
  final List<String> images;

  const _ImageThumbnail({required this.images});

  @override
  State<_ImageThumbnail> createState() => _ImageThumbnailState();
}

class _ImageThumbnailState extends State<_ImageThumbnail> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (widget.images.isEmpty) {
      return _Placeholder(colors: colors);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 76,
        height: 76,
        color: colors.surfaceVariant,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return Image.network(
                  _imageUrl(widget.images[index]),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
            if (widget.images.length > 1)
              Positioned(
                bottom: 6,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.images.length, (index) {
                    return Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? AppColors.primaryColor
                            : colors.onSurface.withOpacity(0.4),
                      ),
                    );
                  }),
                ),
              ),
            if (widget.images.length > 1)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.images.length}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _imageUrl(String path) {
    if (path.startsWith('http')) return path;
    const base = ApiClient.baseUrl;
    if (path.startsWith('/')) return '$base$path';
    return '$base/$path';
  }
}

class _Placeholder extends StatelessWidget {
  final ColorScheme colors;

  const _Placeholder({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: colors.onSurfaceVariant,
        size: 28,
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String? priority;

  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final label = _priorityLabel(priority);
    final color = _priorityColor(priority);

    return StatusChip(
      label: label,
      backgroundColor: color.withOpacity(0.12),
      foregroundColor: color,
      icon: _priorityIcon(priority),
    );
  }

  String _priorityLabel(String? priority) {
    switch (priority?.toLowerCase().trim()) {
      case 'urgent':
      case 'urgente':
      case 'élevée':
      case 'elevee':
      case 'eleve':
      case 'high':
        return 'Urgent';
      case 'moyenne':
      case 'medium':
        return 'Moyenne';
      case 'faible':
      case 'low':
        return 'Faible';
      default:
        return priority?.isNotEmpty == true ? priority! : 'Normal';
    }
  }

  Color _priorityColor(String? priority) {
    switch (priority?.toLowerCase().trim()) {
      case 'urgent':
      case 'urgente':
      case 'élevée':
      case 'elevee':
      case 'eleve':
      case 'high':
        return AppColors.error;
      case 'moyenne':
      case 'medium':
        return AppColors.warning;
      case 'faible':
      case 'low':
        return AppColors.success;
      default:
        return AppColors.primaryColor;
    }
  }

  IconData _priorityIcon(String? priority) {
    switch (priority?.toLowerCase().trim()) {
      case 'urgent':
      case 'urgente':
      case 'élevée':
      case 'elevee':
      case 'eleve':
      case 'high':
        return Icons.error_outline_rounded;
      case 'moyenne':
      case 'medium':
        return Icons.warning_amber_rounded;
      case 'faible':
      case 'low':
        return Icons.keyboard_arrow_down_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String? status;
  final ValueChanged<String>? onStatusChanged;
  final List<String> statusOptions;

  const _StatusChip({
    required this.status,
    this.onStatusChanged,
    required this.statusOptions,
  });

  @override
  Widget build(BuildContext context) {
    final current = status?.isNotEmpty == true ? status! : 'En cours';
    final color = _statusColor(current);
    final icon = _statusIcon(current);

    final chip = StatusChip(
      label: current,
      backgroundColor: color.withOpacity(0.12),
      foregroundColor: color,
      icon: icon,
    );

    if (onStatusChanged == null || statusOptions.isEmpty) return chip;

    return PopupMenuButton<String>(
      tooltip: 'Changer le statut',
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (newStatus) {
        if (newStatus != current) {
          onStatusChanged?.call(newStatus);
        }
      },
      itemBuilder: (context) => statusOptions.map((option) {
        final optionColor = _statusColor(option);
        return PopupMenuItem<String>(
          value: option,
          height: 40,
          child: Row(
            children: [
              Icon(_statusIcon(option), size: 16, color: optionColor),
              const SizedBox(width: 8),
              Text(
                option,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: optionColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: chip,
    );
  }

  Color _statusColor(String? status) {
    final s = status?.toLowerCase().trim() ?? '';
    if (s == 'corrigée' || s == 'corrigee' || s == 'fixed' || s == 'done') {
      return AppColors.success;
    }
    if (s == 'à corriger' ||
        s == 'a corriger' ||
        s == 'to fix' ||
        s == 'a_corrigier') {
      return AppColors.error;
    }
    if (s == 'rejetée' || s == 'rejetee' || s == 'rejected') {
      return Colors.grey.shade600;
    }
    if (s == 'suspendue' || s == 'suspended') {
      return AppColors.primaryColor;
    }
    return AppColors.warning;
  }

  IconData _statusIcon(String? status) {
    final s = status?.toLowerCase().trim() ?? '';
    if (s == 'corrigée' || s == 'corrigee' || s == 'fixed' || s == 'done') {
      return Icons.check_circle_outline_rounded;
    }
    if (s == 'à corriger' || s == 'a corriger' || s == 'to fix') {
      return Icons.error_outline_rounded;
    }
    if (s == 'rejetée' || s == 'rejetee' || s == 'rejected') {
      return Icons.block_rounded;
    }
    if (s == 'suspendue' || s == 'suspended') {
      return Icons.pause_circle_outline_rounded;
    }
    return Icons.hourglass_bottom_rounded;
  }
}
