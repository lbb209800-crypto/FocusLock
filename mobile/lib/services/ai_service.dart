import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/lock_screen.dart';

class AiService {
  // TODO: Replace with your backend URL
  static const String _baseUrl = 'http://localhost:3000';

  Future<LockScreenData> generateLockScreen(String mood) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ai/generate-lock-screen'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'mood': mood,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LockScreenData(
          id: data['id'] ?? 'temp_id',
          title: data['title'] ?? 'Untitled',
          description: data['description'] ?? '',
          bioCode: data['bioCode'] ?? '',
          mood: mood,
          createdAt: DateTime.now(),
          isActive: true,
        );
      } else {
        throw Exception('Failed to generate lock screen: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
