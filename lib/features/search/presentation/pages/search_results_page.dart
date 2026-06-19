import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/search_controller.dart';
import '../widgets/search_bar_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/search_result.dart';

class SearchResultsPage extends StatelessWidget {
  final GlobalSearchController searchController;

  const SearchResultsPage({
    super.key,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('search_results'.tr),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.backgroundColor,
            child: SearchBarWidget(
              searchController: searchController,
              showInAppBar: false,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (searchController.isSearching.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (searchController.searchResults.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_results_found'.tr,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: searchController.searchResults.length,
                itemBuilder: (context, index) {
                  final result = searchController.searchResults[index];
                  return _buildSearchResultItem(result);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(SearchResult result) {
    IconData iconData;
    Color iconColor;
    
    switch (result.type) {
      case 'organization':
        iconData = Icons.business;
        iconColor = AppColors.primaryColor;
        break;
      case 'project':
        iconData = Icons.folder;
        iconColor = AppColors.secondaryColor;
        break;
      case 'task':
        iconData = Icons.assignment;
        iconColor = Colors.orange;
        break;
      case 'user':
        iconData = Icons.person;
        iconColor = Colors.blue;
        break;
      case 'lot':
        iconData = Icons.category;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.info;
        iconColor = Colors.grey;
    }
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(iconData, color: iconColor),
      ),
      title: Text(
        result.title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        result.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Get.back(); // Close search results page
        Get.toNamed(result.route); // Navigate to the result
      },
    );
  }
}
