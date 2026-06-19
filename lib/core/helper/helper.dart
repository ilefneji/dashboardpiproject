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
      // Create form data with file
      final dioConnect.FormData formData = dioConnect.FormData.fromMap({});
      
      // Print file details for debugging (safely)
      print('File details: name=${file.name}, size=${file.size}, hasBytes=${file.bytes != null}');
      
      // Safe way to handle file upload for both web and native platforms
      if (file.bytes != null) {
        // Use bytes for upload (works on all platforms)
        print('Using bytes for upload');
        formData.files.add(MapEntry(
          'file',
          dioConnect.MultipartFile.fromBytes(file.bytes!, filename: file.name)
        ));
      } else if (!kIsWeb && file.path != null) {
        // Only use path on non-web platforms
        print('Using path for upload (non-web platform)');
        formData.files.add(MapEntry(
          'file',
          await dioConnect.MultipartFile.fromFile(file.path!, filename: file.name)
        ));
      } else {
        throw Exception('No valid file data available for upload');
      }
      
      // Get token from storage for authentication
      const FlutterSecureStorage storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      
      final dioConnect.Options options = dioConnect.Options(
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
        },
        validateStatus: (_) => true,
      );

      // Use a configurable base URL
      final dioConnect.Response response = await dio.post(
        '${ApiClient.baseUrl}/files/upload',
        data: formData,
        options: options,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data['data'];
        final int fileId = responseData['id'];
        final String filePath = responseData['path'];
        return {'fileId': fileId, 'filePath': filePath};
      } else {
        print('File upload failed with status: ${response.statusCode}  ${response.statusMessage}');
        return {'fileId': 0, 'filePath': ''}; // Return default values on failure
      }
    } catch (e) {
      print('Error uploading file: $e');
      return {'fileId': 0, 'filePath': ''}; // Return default values on error
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