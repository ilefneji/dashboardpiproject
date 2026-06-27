 import 'dart:io';
import 'package:dio/dio.dart' as dioConnect;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

import '../network/api_client.dart';

class Helper {
  Helper._();

  static Future<Map<String, dynamic>> uploadFile(PlatformFile file) async {
  final dioConnect.Dio dio = dioConnect.Dio();

  try {
    final formData = dioConnect.FormData.fromMap({});

    if (file.bytes != null) {
      formData.files.add(MapEntry(
        'file',
        dioConnect.MultipartFile.fromBytes(file.bytes!, filename: file.name),
      ));
    } else if (!kIsWeb && file.path != null) {
      formData.files.add(MapEntry(
        'file',
        await dioConnect.MultipartFile.fromFile(file.path!, filename: file.name),
      ));
    } else {
      throw Exception('No valid file data available');
    }

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');

    final response = await dio.post(
      '${ApiClient.baseUrl}/files/upload',
      data: formData,
      options: dioConnect.Options(
        headers: {
          if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
        },
        validateStatus: (_) => true,
      ),
    );

    print('UPLOAD STATUS: ${response.statusCode}');
    print('UPLOAD RESPONSE: ${response.data}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic body = response.data;

      final dynamic data = body is Map && body['data'] != null
          ? body['data']
          : body;

      final dynamic fileObj = data is Map && data['file'] != null
          ? data['file']
          : data;

      final int fileId = int.tryParse(
            '${fileObj['fileId'] ?? fileObj['id'] ?? 0}',
          ) ??
          0;

      final String filePath =
          '${fileObj['filePath'] ?? fileObj['path'] ?? fileObj['url'] ?? ''}';

      final String fileName =
          '${fileObj['fileName'] ?? fileObj['name'] ?? file.name}';

      return {
        'fileId': fileId,
        'filePath': filePath,
        'fileName': fileName,
      };
    }

    return {'fileId': 0, 'filePath': '', 'fileName': ''};
  } catch (e) {
    print('Error uploading file: $e');
    return {'fileId': 0, 'filePath': '', 'fileName': ''};
  }
}
  /// Opens a file for viewing based on its path
  /// Returns a map with success status and error message if applicable
  
  static Future<Map<String, dynamic>> viewFile(String filePath) async {
    try {
      if (filePath.isEmpty) {
        return {'success': false, 'error': 'File path is empty'};
      }
      
      // Construct the full URL to the file
      String fileUrl;
      if (filePath.startsWith('http')) {
        // If it's already a full URL, use it directly
        fileUrl = filePath;
      } else if (filePath.startsWith('/')) {
        // If it starts with a slash, append it to the base URL
        fileUrl = '${ApiClient.baseUrl}/$filePath';
      } else {
        // Otherwise, add a path separator and append
        fileUrl = '${ApiClient.baseUrl}/$filePath';
      }
      
      // Launch the URL to view the file
      final Uri uri = Uri.parse(fileUrl);
      final bool canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return {'success': true};
      } else {
        print('Cannot launch URL: $fileUrl');
        return {'success': false, 'error': 'Cannot open file'};
      }
    } catch (e) {
      print('Error viewing file: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Downloads a file based on its path
  /// Returns a map with success status and error message if applicable
  static Future<Map<String, dynamic>> downloadFile(String filePath) async {
    try {
      if (filePath.isEmpty) {
        return {'success': false, 'error': 'File path is empty'};
      }
      
      // Construct the full URL to the file with download parameter
      String fileUrl;
      if (filePath.startsWith('http')) {
        // If it's already a full URL, use it directly
        fileUrl = filePath;
      } else if (filePath.startsWith('/')) {
        // If it starts with a slash, append it to the base URL
        fileUrl = '${ApiClient.baseUrl}/$filePath';
      } else {
        // Otherwise, add a path separator and append
        fileUrl = '${ApiClient.baseUrl}/$filePath';
      }
      
      // Launch the URL to download the file
      final Uri uri = Uri.parse(fileUrl);
      final bool canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return {'success': true};
      } else {
        print('Cannot launch download URL: $fileUrl');
        return {'success': false, 'error': 'Cannot download file'};
      }
    } catch (e) {
      print('Error downloading file: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
    
}