import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = String.fromEnvironment('API_BASE_URL');
const String apiPort = "8080";

class EventSender {

  static Future<void> sendEvent({
    required String eventType,
    required Map<String, dynamic> payload,
  }) async {
    final url = Uri.parse("$baseUrl:$apiPort/event");

    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'eventType': eventType,
        'payload': payload,
      }),
    );
  }
}