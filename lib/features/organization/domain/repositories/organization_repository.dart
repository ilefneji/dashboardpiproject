import '../entities/organization.dart';

abstract class OrganizationRepository {
  Future<List<Organization>> getOrganizations();
  Future<Organization>       getOrganization(int id);    
  Future<Organization>       createOrganization(Organization organization);
  Future<Organization>       updateOrganization(Organization organization);
  Future<void>               deleteOrganization(int id);
}