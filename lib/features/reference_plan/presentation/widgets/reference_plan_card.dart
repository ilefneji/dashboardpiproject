import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/item_action_menu.dart';
import '../../data/models/reference_plan_model.dart';

class ReferencePlanCard extends StatelessWidget {
  final ReferencePlanModel plan;
  final VoidCallback? onView;

  const ReferencePlanCard({
    super.key,
    required this.plan,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      onTap: onView,
      leading: _PdfIcon(),
      title: plan.name ?? 'Plan sans nom',
      subtitle: plan.description?.isNotEmpty == true ? plan.description : null,
      metadata: [
        if (plan.taskId != null)
          InfoRow(
            icon: Icons.task_alt_outlined,
            label: 'Tâche',
            value: plan.taskId.toString(),
          ),
        if (plan.id != null)
          InfoRow(
            icon: Icons.tag_outlined,
            label: 'ID',
            value: plan.id.toString(),
          ),
      ],
      chips: [
        StatusChip(
          label: 'Plan de référence',
          icon: Icons.picture_as_pdf_outlined,
          foregroundColor: AppColors.primaryColor,
        ),
      ],
      trailing: ItemActionMenu(
        onView: onView,
      ),
    );
  }
}

class _PdfIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.2)),
      ),
      child: Center(
        child: Text(
          'PDF',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFDC2626),
          ),
        ),
      ),
    );
  }
}
