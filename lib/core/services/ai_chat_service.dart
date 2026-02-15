import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service wrapping the Groq Cloud API for the AI assistant chat.
class AiChatService {
  // TODO: Replace with your real Groq API key
  static String get _apiKey {
    return dotenv.env['GROQ_API_KEY'] ?? '';
  }

  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _model = 'llama-3.3-70b-versatile';

  static const String _systemPrompt =
      'You are a helpful food delivery assistant for mtf Delivery. '
      'Help users find restaurants, explain delivery fees, and answer questions '
      'about their current order. Keep responses short and friendly. Use emojis.';

  /// Conversation history in OpenAI message format.
  final List<Map<String, String>> _messages = [
    {'role': 'system', 'content': _systemPrompt},
  ];

  /// Send a user message and return the AI response text.
  Future<String> sendMessage(String userMessage) async {
    _messages.add({'role': 'user', 'content': userMessage});

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': _messages,
          'temperature': 0.7,
          'max_tokens': 512,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>;
        final content = choices[0]['message']['content'] as String? ?? '';

        // Add assistant reply to history for multi-turn conversation
        _messages.add({'role': 'assistant', 'content': content});

        return content.isNotEmpty
            ? content
            : 'Sorry, I could not generate a response. 😅';
      } else {
        debugPrint('Groq API Error ${response.statusCode}: ${response.body}');

        if (response.statusCode == 401) {
          // Remove the failed user message from history
          _messages.removeLast();
          return 'Error: Invalid API Key. Please check your Groq key.';
        }
        if (response.statusCode == 429) {
          _messages.removeLast();
          return 'Rate limit reached. Please wait a moment and try again. ⏳';
        }

        _messages.removeLast();
        return 'Oops! Server returned ${response.statusCode}. Please try again.';
      }
    } catch (e) {
      debugPrint('Groq Chat Error: $e');
      // Remove the failed user message from history
      _messages.removeLast();
      return 'Oops! Could not connect to the AI service. Check your internet. 😅';
    }
  }

  /// Reset the conversation by clearing history and re-adding system prompt.
  void resetChat() {
    _messages.clear();
    _messages.add({'role': 'system', 'content': _systemPrompt});
  }
}
