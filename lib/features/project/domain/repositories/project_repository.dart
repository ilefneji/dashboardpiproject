import '../../data/models/project_model.dart';
import '../../data/models/subscription_code_model.dart';

abstract class ProjectRepository {
  Future<List<ProjectModel>> getAllProjects();
  Future<List<ProjectModel>> getAllProjectsNoFilter();
  Future<List<ProjectModel>> getSubProjects(int parentId);
  Future<ProjectModel?> getProject(int id);

  Future<SubscriptionCodeModel> generateSubscriptionCode({
    required int projectId,
    required int numberOfMembers,
  });

  Future<bool> createProject({
    required String name,
    required String description,
    required String startDate,
    required String endDate,
    required int budget,
    required String localisation,
    String? latitude,
    String? longitude,
    int? organizationId,
    List<int> lotIds, // ✅ no default in abstract — impl provides it
  });

  // ✅ NEW — update project
  Future<bool> updateProject(
    int projectId, {
    required String name,
    required String description,
    required String startDate,
    required String endDate,
    required int budget,
    required String localisation,
    String? latitude,
    String? longitude,
    List<int> lotIds,
  });
}
