// lib/features/project/presentation/widgets/year_filter_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/project_controller.dart';

class YearFilterWidget extends StatelessWidget {
  const YearFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProjectController>();

    return Obx(() {
      final selectedYear = controller.selectedYear.value;
      final availableYears = controller.availableYears;
      final isFiltered = selectedYear != 0;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFiltered ? const Color(0xFF4F8EF7) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFiltered ? const Color(0xFF4F8EF7) : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedYear,
            isDense: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isFiltered ? Colors.white : const Color(0xFF4F8EF7),
              size: 20,
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isFiltered ? Colors.white : const Color(0xFF1A1A2E),
            ),
            // ── Option "Toutes les années" ──────────────────
            items: [
              DropdownMenuItem<int>(
                value: 0,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color:
                          isFiltered ? Colors.white : const Color(0xFF4F8EF7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Toutes les années',
                      style: TextStyle(
                        color:
                            isFiltered ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Années disponibles ──────────────────────
              ...availableYears.map(
                (year) => DropdownMenuItem<int>(
                  value: year,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_rounded,
                        size: 15,
                        color: Color(0xFF4F8EF7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        year.toString(),
                        style: const TextStyle(
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                if (value == 0) {
                  controller.clearYearFilter();
                } else {
                  controller.filterByYear(value);
                }
              }
            },
          ),
        ),
      );
    });
  }
}
