import 'api_service.dart';

/// Service to track which chat user is currently viewing
/// This prevents push notifications when user is already in the chat
class ActiveChatTracker {
  static String? _activeChatId;
  
  /// Set the currently active chat
  static void setActiveChat(String? chatId) {
    _activeChatId = chatId;
    print('📍 Active chat set to: $chatId');
  }
  
  /// Get the currently active chat ID
  static String? get activeChatId => _activeChatId;
  
  /// Clear active chat (when leaving chat screen)
  static void clearActiveChat() {
    _activeChatId = null;
    print('📍 Active chat cleared');
  }
  
  /// Get headers with active chat ID for API requests
  /// This tells backend not to send push notification if user is in this chat
  static Future<Map<String, String>> getHeadersWithActiveChat() async {
    final headers = await ApiService.getHeaders();
    
    // Add active chat ID to headers if available
    if (_activeChatId != null) {
      headers['X-Active-Chat-ID'] = _activeChatId!;
    }
    
    return headers;
  }
}
