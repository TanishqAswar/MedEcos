import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/utils/constants.dart';

class AgoraService {
  Future<String?> fetchToken(String channelName, int uid) async {
    try {
      final baseUrl = '${AppConstants.apiBaseUrl}/api';
      final response = await http.get(
        Uri.parse('$baseUrl/agora/token?channelName=$channelName&uid=$uid'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['token'];
      } else {
        print('Failed to fetch token: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching token: $e');
      return null;
    }
  }
}
