import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';

class ProjectAdminDetailController extends GetxController {
  ProjectAdminDetailController({ApiClient? apiClient})
      : _apiClient = apiClient ?? Get.find<ApiClient>();

  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxMap<String, dynamic> project = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> sections = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> counts = <String, dynamic>{}.obs;
  final RxMap<String, bool> sectionLoading = <String, bool>{}.obs;
  final RxString activeSection = 'events'.obs;
  final RxList<Map<String, dynamic>> companyUsers =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingCompanyUsers = false.obs;

  Future<void> loadCompanyUsers() async {
    final id = projectId;
    if (id == null) return;

    isLoadingCompanyUsers.value = true;

    try {
      final response = await _apiClient.get(
        '/projects/$id/available-company-members',
      );

      final data = response.data is Map<String, dynamic>
          ? response.data['data']
          : response.data;

      final list = data is List ? data : <dynamic>[];

      companyUsers.assignAll(list.whereType<Map<String, dynamic>>().toList());
    } finally {
      isLoadingCompanyUsers.value = false;
    }
  }

  Future<void> inviteStakeholderUser(
    Map<String, dynamic> user, {
    String role = 'member',
  }) async {
    final id = projectId;
    if (id == null) return;

    await _apiClient.patch(
      '/projects/$id',
      data: {
        'userProjects': [
          {
            'userId': int.parse(user['id'].toString()),
            'role': role,
            'status': 'pending',
          },
        ],
      },
    );

    await refreshSection('stakeholders');
  }

  int? projectId;

  Future<void> load(int id) async {
    projectId = id;
    isLoading.value = true;
    error.value = '';

    try {
      final data = await _loadAdminDetail(id);
      _applyAdminDetail(data);
    } catch (e) {
      error.value = 'Impossible de charger le detail du projet: $e';
      debugPrint(error.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshSection(String key) async {
    final id = projectId;
    if (id == null) return;

    sectionLoading[key] = true;
    try {
      final data = await _loadAdminDetail(id);
      project.assignAll(_asMap(data['project']));
      final freshSections = _asMap(data['sections']);
      final freshCounts = _asMap(data['counts']);
      sections[key] = freshSections[key];
      counts[key] = freshCounts[key];
      if (key == 'referencePlans') {
        sections['folders'] = freshSections['folders'];
      }
    } finally {
      sectionLoading[key] = false;
    }
  }

  Future<void> archiveProject() async {
    final id = projectId;
    if (id == null) return;

    try {
      await _apiClient.patch('/projects/archiveProject/$id');
      await refreshSection('archive');
      Get.snackbar(
        'Succes',
        'Projet archive avec succes',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d archiver le projet',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> createItem(String key, Map<String, dynamic> values) async {
    final id = projectId;
    if (id == null) return;

    final payload = await _payloadFor(key, values, creating: true);

    if (key == 'stakeholders') {
      await _apiClient.patch('/projects/$id', data: payload);
      await refreshSection(key);
      return;
    }

    final path = _createPathFor(key, id);
    if (path == null) return;

    await _apiClient.post(path, data: payload);
    await refreshSection(key);
  }

  Future<void> updateItem(
    String key,
    Map<String, dynamic> item,
    Map<String, dynamic> values,
  ) async {
    final itemId = _itemId(item);
    if (itemId == null) return;

    final payload = await _payloadFor(key, values, creating: false);
    final path = _updatePathFor(key, item, itemId);
    if (path == null) return;

    await _apiClient.patch(path, data: payload);
    await refreshSection(key);
  }

  Future<void> deleteItem(String key, Map<String, dynamic> item) async {
    final itemId = _itemId(item);
    if (itemId == null) return;

    final path = _deletePathFor(key, item, itemId);
    if (path == null) return;

    await _apiClient.delete(path);
    await refreshSection(key);
  }

  Future<void> uploadDocument(String key) async {
    final id = projectId;
    if (id == null) return;

    final result = await FilePicker.platform.pickFiles(withData: true);
    final picked = result?.files.single;
    if (picked == null) return;

    final folderId = await _ensureFolder(_folderNameFor(key));
    final upload = picked.bytes != null
        ? await _apiClient.uploadFileBytes(
            '/files/upload',
            bytes: picked.bytes!,
            fileName: picked.name,
          )
        : !kIsWeb && picked.path != null
            ? await _apiClient.uploadFile('/files/upload',
                filePath: picked.path!)
            : throw Exception('Fichier invalide pour upload');
    final uploaded = _asMap(upload.data);
    final fileId = uploaded['fileId'] ?? uploaded['id'];

    if (fileId == null) {
      throw Exception('Upload echoue: identifiant fichier absent');
    }

    await _apiClient.patch(
      '/files/$fileId',
      data: {'name': uploaded['name'] ?? picked.name, 'folderId': folderId},
    );

    if (key == 'referencePlans') {
      await _apiClient.post(
        '/plannings',
        data: {
          'name': picked.name,
          'description': '',
          'isActive': true,
          'fileId': fileId,
          'projectId': id,
        },
      );
    }

    await refreshSection(key);
  }

  Future<void> openDocument(Map<String, dynamic> item) async {
    final file = _fileFrom(item);
    final path = _text(file['path']);
    if (path.isEmpty) return;

    final uri = Uri.parse('${ApiClient.baseUrl}/$path');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<dynamic> listFor(String key) {
    final value = sections[key];
    return value is List ? value : <dynamic>[];
  }

  int countFor(String key) {
    final value = counts[key];
    if (value != null) return int.parse(value.toString());
    return listFor(key).length;
  }

  bool isDocumentSection(String key) {
    return const {
      'referencePlans',
      'contractualDocuments',
      'referenceDocuments',
      'galleries',
      'documents',
    }.contains(key);
  }

  bool canUpload(String key) => isDocumentSection(key) && key != 'documents';

  bool canDelete(String key) {
    return const {
      'events',
      'reserves',
      'referencePlans',
      'contractualDocuments',
      'referenceDocuments',
      'galleries',
      'journal',
      'stakeholders',
    }.contains(key);
  }

  bool canDownload(String key) => isDocumentSection(key);

  bool canEdit(String key) {
    return const {
      'events',
      'reserves',
      'referencePlans',
      'contractualDocuments',
      'referenceDocuments',
      'galleries',
      'journal',
      'stakeholders',
    }.contains(key);
  }

  bool canCreate(String key) {
    return const {
      'events',
      'reserves',
      'referencePlans',
      'contractualDocuments',
      'referenceDocuments',
      'galleries',
      'journal',
      'stakeholders',
    }.contains(key);
  }

  void openSection(String key) {
    activeSection.value = key;
  }

  List<ProjectAdminField> fieldsFor(String key, {Map<String, dynamic>? item}) {
    final now = DateTime.now();
    switch (key) {
      case 'events':
        return [
          ProjectAdminField(
            'name',
            'Nom',
            value: _fieldValue(item, ['name', 'title']),
          ),
          ProjectAdminField(
            'description',
            'Description',
            value: _fieldValue(item, ['description']),
            maxLines: 3,
          ),
          ProjectAdminField('zone', 'Zone', value: _fieldValue(item, ['zone'])),
          ProjectAdminField(
            'date',
            'Date',
            value: _dateValue(item?['date']) ?? _dateOnly(now),
          ),
          ProjectAdminField(
            'startHour',
            'Debut',
            value: _fieldValue(item, ['startHour']) ?? '08:00',
          ),
          ProjectAdminField(
            'endHour',
            'Fin',
            value: _fieldValue(item, ['endHour']) ?? '17:00',
          ),
        ];
      case 'reserves':
        return [
          ProjectAdminField(
            'nom',
            'Nom',
            value: _fieldValue(item, ['nom', 'name']),
          ),
          ProjectAdminField(
            'declaration',
            'Declaration',
            value: _fieldValue(item, ['declaration', 'description']),
            maxLines: 3,
          ),
          ProjectAdminField(
            'localisation',
            'Localisation',
            value: _fieldValue(item, ['localisation', 'zone']),
          ),
          ProjectAdminField(
            'priority',
            'Priorite',
            value: _fieldValue(item, ['priority']) ?? 'Moyenne',
          ),
          ProjectAdminField(
            'status',
            'Statut',
            value: _fieldValue(item, ['status']) ?? 'En cours',
          ),
        ];
      case 'eventReports':
        return [
          ProjectAdminField(
            'nom',
            'Nom',
            value: _fieldValue(item, ['nom', 'name']),
          ),
          ProjectAdminField('zone', 'Zone', value: _fieldValue(item, ['zone'])),
          ProjectAdminField(
            'eventId',
            'ID evenement',
            value: _fieldValue(item, ['eventId']) ?? _firstEventId(),
          ),
          ProjectAdminField(
            'comment',
            'Commentaire',
            value: _fieldValue(item, ['comment']),
            maxLines: 4,
          ),
        ];
      case 'journal':
        return [
          ProjectAdminField(
            'jour',
            'Jour',
            value: _fieldValue(item, ['jour']) ?? '${now.day}',
          ),
          ProjectAdminField(
            'mois',
            'Mois',
            value: _fieldValue(item, ['mois']) ?? '${now.month}',
          ),
          ProjectAdminField(
            'annee',
            'Annee',
            value: _fieldValue(item, ['annee']) ?? '${now.year}',
          ),
          ProjectAdminField(
            'travaux',
            'Travaux',
            value: _fieldValue(item, ['travaux']),
            maxLines: 3,
          ),
          ProjectAdminField(
            'observations',
            'Observations',
            value: _fieldValue(item, ['observations']),
            maxLines: 3,
          ),
          ProjectAdminField(
            'ressources',
            'Ressources',
            value: _fieldValue(item, ['ressources']),
            maxLines: 2,
          ),
          ProjectAdminField(
            'materiaux',
            'Materiaux',
            value: _fieldValue(item, ['materiaux']),
            maxLines: 2,
          ),
          ProjectAdminField(
            'accidents',
            'Accidents',
            value: _fieldValue(item, ['accidents']),
            maxLines: 2,
          ),
        ];
      case 'stakeholders':
        return [
          ProjectAdminField(
            'userId',
            'ID utilisateur',
            value: _fieldValue(item, ['userId']),
          ),
          ProjectAdminField(
            'role',
            'Role',
            value: _fieldValue(item, ['role']) ?? 'member',
          ),
          ProjectAdminField(
            'status',
            'Statut',
            value: _fieldValue(item, ['status']) ?? 'accepted',
          ),
        ];
      case 'referencePlans':
      case 'contractualDocuments':
      case 'referenceDocuments':
      case 'galleries':
        return [
          ProjectAdminField(
            'name',
            'Nom',
            value: _fieldValue(item, ['name']) ?? _titleFrom(item ?? {}),
          ),
        ];
      default:
        return [
          ProjectAdminField('name', 'Nom', value: _titleFrom(item ?? {})),
          ProjectAdminField(
            'description',
            'Description',
            value: _fieldValue(item, ['description']),
            maxLines: 3,
          ),
        ];
    }
  }

  Future<Map<String, dynamic>> _loadAdminDetail(int id) async {
    final response = await _apiClient.get('/projects/$id/admin-detail');
    return _unwrap(response.data);
  }

  void _applyAdminDetail(Map<String, dynamic> data) {
    project.assignAll(_asMap(data['project']));
    sections.assignAll(_asMap(data['sections']));
    counts.assignAll(_asMap(data['counts']));
  }

  Future<Map<String, dynamic>> _payloadFor(
    String key,
    Map<String, dynamic> values, {
    required bool creating,
  }) async {
    final id = projectId;
    final userId = await _currentUserId();
    final payload = Map<String, dynamic>.from(values)
      ..removeWhere(
        (_, value) => value == null || value.toString().trim().isEmpty,
      );

    int? asInt(dynamic value) =>
        value == null ? null : int.parse(value.toString());

    switch (key) {
      case 'events':
        return {
          ...payload,
          'projectId': id,
          if (userId != null) 'userId': userId,
          'eventUsers': [],
          'eventActivities': [],
          'eventSections': [],
        };
      case 'reserves':
        return {
          ...payload,
          'projectId': id,
          if (userId != null) 'userId': userId,
          'images': [],
        };
      case 'eventReports':
        return {
          ...payload,
          'projectId': id,
          if (userId != null) 'userId': userId,
          'eventId': asInt(payload['eventId']),
        };
      case 'journal':
        return {
          ...payload,
          'jour': asInt(payload['jour']),
          'mois': asInt(payload['mois']),
          'annee': asInt(payload['annee']),
          if (userId != null) 'userId': userId,
        };
      case 'stakeholders':
        return {
          'userProjects': [
            {
              'userId': asInt(payload['userId']),
              'role': payload['role'] ?? 'member',
              'status': payload['status'] ?? 'pending',
            },
          ],
        };
      default:
        return payload;
    }
  }

  String? _createPathFor(String key, int projectId) {
    switch (key) {
      case 'events':
        return '/events';
      case 'reserves':
        return '/reserve';
      case 'eventReports':
        return '/pvs';
      case 'journal':
        return '/journal-chantier/admin/project/$projectId';
      case 'stakeholders':
        return '/user-project-s';
      default:
        return null;
    }
  }

  String? _updatePathFor(String key, Map<String, dynamic> item, String itemId) {
    switch (key) {
      case 'events':
        return '/events/$itemId';
      case 'reserves':
        return '/reserve/$itemId';
      case 'eventReports':
        return item['dateCreated'] != null
            ? '/pv-comment/$itemId'
            : '/pvs/$itemId';
      case 'journal':
        return '/journal-chantier/admin/$itemId';
      case 'stakeholders':
        return '/user-project-s/$itemId';
      case 'referencePlans':
        if (item['folderId'] != null || item['path'] != null) {
          return '/files/$itemId';
        }
        if (item['isActive'] != null || item['parentId'] != null) {
          return '/plannings/$itemId';
        }
        if (item['fileId'] != null) return '/zones/$itemId';
        return '/plannings/$itemId';
      case 'contractualDocuments':
      case 'referenceDocuments':
      case 'galleries':
        return '/files/$itemId';
      default:
        return null;
    }
  }

  String? _deletePathFor(String key, Map<String, dynamic> item, String itemId) {
    switch (key) {
      case 'events':
        return '/events/$itemId';
      case 'reserves':
        return '/reserve/$itemId';
      case 'eventReports':
        return item['dateCreated'] != null
            ? '/pv-comment/$itemId'
            : '/pvs/$itemId';
      case 'journal':
        return '/journal-chantier/admin/$itemId';
      case 'stakeholders':
        return '/user-project-s/$itemId';
      case 'referencePlans':
        if (item['folderId'] != null || item['path'] != null) {
          return '/files/$itemId';
        }
        if (item['isActive'] != null || item['parentId'] != null) {
          return '/plannings/$itemId';
        }
        if (item['fileId'] != null) return '/zones/$itemId';
        return '/plannings/$itemId';
      case 'contractualDocuments':
      case 'referenceDocuments':
      case 'galleries':
        return '/files/${_fileFrom(item)['id'] ?? itemId}';
      default:
        return null;
    }
  }

  Future<int> _ensureFolder(String name) async {
    final id = projectId;
    if (id == null) throw Exception('Projet introuvable');

    final folders = listFor('folders').whereType<Map<String, dynamic>>();
    Map<String, dynamic>? existing;
    for (final folder in folders) {
      if (_text(folder['name']).toLowerCase() == name.toLowerCase()) {
        existing = folder;
        break;
      }
    }
    if (existing != null && existing['id'] != null) {
      return int.parse(existing['id'].toString());
    }

    final response = await _apiClient.post(
      '/folders',
      data: {'name': name, 'projectId': id},
    );
    final data = _unwrap(response.data);
    final rawResponse = response.data;
    final folderId = data['id'] ??
        (rawResponse is Map<String, dynamic> ? rawResponse['id'] : null);
    if (folderId != null) return int.parse(folderId.toString());
    throw Exception('Dossier non cree');
  }

  Future<int?> _currentUserId() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null || token.split('.').length < 2) return null;

    try {
      final payload = token.split('.')[1];
      final normalized = base64Url.normalize(payload);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      final value = decoded['id'] ?? decoded['userId'] ?? decoded['sub'];
      if (value != null) return int.parse(value.toString());
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _unwrap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) return data;
      return responseData;
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  String? _itemId(Map<String, dynamic> item) {
    final file = _fileFrom(item);
    final value = item['id'] ?? file['id'];
    return value?.toString();
  }

  Map<String, dynamic> _fileFrom(Map<String, dynamic> item) {
    final file = item['file'];
    if (file is Map<String, dynamic>) return file;
    return item;
  }

  String _folderNameFor(String key) {
    switch (key) {
      case 'contractualDocuments':
        return 'Marches, Avenants';
      case 'referenceDocuments':
        return 'Documents de reference';
      case 'galleries':
        return 'Galeries';
      default:
        return 'Plans approuves';
    }
  }

  String? _firstEventId() {
    final events = listFor('events');
    final event = events.isEmpty ? null : events.first;
    if (event is Map<String, dynamic>) return event['id']?.toString();
    return null;
  }
}

class ProjectAdminField {
  const ProjectAdminField(
    this.key,
    this.label, {
    this.value,
    this.maxLines = 1,
  });

  final String key;
  final String label;
  final String? value;
  final int maxLines;
}

String _text(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String _titleFrom(Map<String, dynamic> map) {
  final direct = _text(
    map['title'] ??
        map['name'] ??
        map['nom'] ??
        map['path'] ??
        map['status'] ??
        map['id'],
  );
  if (direct.isNotEmpty) return direct;

  final file = map['file'];
  if (file is Map<String, dynamic>) {
    return _text(file['name'], fallback: 'Document');
  }

  final user = map['user'];
  if (user is Map<String, dynamic>) {
    return '${_text(user['firstname'])} ${_text(user['lastname'])}'.trim();
  }

  return 'Element';
}

String? _fieldValue(Map<String, dynamic>? item, List<String> keys) {
  if (item == null) return null;
  for (final key in keys) {
    final value = _text(item[key]);
    if (value.isNotEmpty) return value;
  }
  return null;
}

String? _dateValue(dynamic value) {
  if (value == null) return null;
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();
  return _dateOnly(parsed);
}

String _dateOnly(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
