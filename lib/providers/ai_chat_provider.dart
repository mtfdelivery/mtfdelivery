import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/ai_chat_service.dart';

/// A chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

/// Provider for the AI Chat Service
final aiChatServiceProvider = Provider<AiChatService>((ref) {
  return AiChatService();
});

/// Notifier to manage AI Chat messages history
class AiChatNotifier extends StateNotifier<List<ChatMessage>> {
  final AiChatService _aiService;
  final Ref _ref;

  AiChatNotifier(this._aiService, this._ref)
    : super([
        ChatMessage(
          text:
              'Hey there! 👋 I\'m your mtf Delivery assistant. How can I help you today? 🍕',
          isUser: false,
        ),
      ]);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    state = [...state, ChatMessage(text: text, isUser: true)];

    _ref.read(aiTypingProvider.notifier).state = true;

    final response = await _aiService.sendMessage(text);

    _ref.read(aiTypingProvider.notifier).state = false;

    // Add AI response
    state = [...state, ChatMessage(text: response, isUser: false)];
  }

  void clearHistory() {
    _aiService.resetChat();
    state = [
      ChatMessage(
        text:
            'Hey there! 👋 I\'m your mtf Delivery assistant. How can I help you today? 🍕',
        isUser: false,
      ),
    ];
  }
}

/// Provider for AI Chat messages
final aiChatProvider = StateNotifierProvider<AiChatNotifier, List<ChatMessage>>(
  (ref) {
    final aiService = ref.watch(aiChatServiceProvider);
    return AiChatNotifier(aiService, ref);
  },
);

/// Provider for typing state
final aiTypingProvider = StateProvider<bool>((ref) => false);
