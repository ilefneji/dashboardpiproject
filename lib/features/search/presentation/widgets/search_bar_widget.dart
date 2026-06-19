import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart';
import '../../../../core/theme/app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final GlobalSearchController searchController;
  final bool showInAppBar;

  const SearchBarWidget({
    super.key,
    required this.searchController,
    this.showInAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: showInAppBar ? 320 : double.infinity,
      height: 46,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryOrange.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // ===== 🔍 Prefix Icon =====
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.primaryOrange,
              size: 22,
            ),
          ),

          // ===== ✏️ TextField =====
          Expanded(
            child: TextField(
              controller: searchController.textController,
              onChanged: searchController.onSearchQueryChanged,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'search_hint'.tr,
                hintStyle: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // ===== ❌ Clear Button =====
          Obx(() {
            final hasText = searchController.searchQuery.value.isNotEmpty;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: hasText
                  ? GestureDetector(
                      key: const ValueKey('clear'),
                      onTap: searchController.clearSearch,
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.primaryOrange,
                          size: 16,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            );
          }),
        ],
      ),
    );
  }
}
