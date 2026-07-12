import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import 'auth_storage.dart';

class UploadApiService {
  /// Uploads raw file bytes to the backend server and returns the relative URL of the uploaded image.
  static Future<String> uploadImage(Uint8List fileBytes, String filename) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/upload');
    final request = http.MultipartRequest('POST', uri);

    // Fetch stored token for authentication header
    final token = await AuthStorage.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Determine the content type based on file extension
    final ext = filename.split('.').last.toLowerCase();
    String mimeType = 'image/jpeg';
    if (ext == 'png') {
      mimeType = 'image/png';
    } else if (ext == 'gif') {
      mimeType = 'image/gif';
    } else if (ext == 'webp') {
      mimeType = 'image/webp';
    }

    // Add multipart file from bytes
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['url'] as String;
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Falló la carga de la imagen');
    }
  }
}
