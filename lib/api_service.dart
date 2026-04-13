import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.55.141.15:5000"; // 🔥 change if needed

  static Future<Map<String, dynamic>> predict(File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseUrl/predict"),
    );

    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      return json.decode(responseData);
    } else {
      throw Exception("Failed to get prediction");
    }
  }
}