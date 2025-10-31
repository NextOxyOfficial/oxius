import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_service.dart';

class AdsyConnectService {
  static String get baseUrl => '${ApiService.baseUrl}/adsyconnect';

  // Get headers with auth token
  static Future<Map<String, String>> _getHeaders() async {
    final token = AuthService.accessToken;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get or create chat room with a user
  static Future<Map<String, dynamic>> getOrCreateChatRoom(String userId) async {
    try {
      final headers = await _getHeaders();
      print('🔵 API URL: $baseUrl/chatrooms/get_or_create/');
      print('🔵 Headers: $headers');
      print('🔵 Body: ${jsonEncode({'user_id': userId})}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/chatrooms/get_or_create/'),
        headers: headers,
        body: jsonEncode({'user_id': userId}),
      );

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get or create chat room: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🔴 Error getting or creating chat room: $e');
      rethrow;
    }
  }

  // Get all chat rooms
  static Future<List<dynamic>> getChatRooms({int page = 1}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chatrooms/?page=$page'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['results'] ?? [];
      } else {
        throw Exception('Failed to load chat rooms: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading chat rooms: $e');
      rethrow;
    }
  }

  // Get messages for a chat room
  static Future<List<dynamic>> getMessages(String chatroomId, {int page = 1}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/messages/?chatroom=$chatroomId&page=$page'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['results'] ?? [];
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading messages: $e');
      rethrow;
    }
  }

  // Send text message
  static Future<Map<String, dynamic>> sendTextMessage({
    required String chatroomId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/messages/'),
        headers: headers,
        body: jsonEncode({
          'chatroom': chatroomId,
          'receiver': receiverId,
          'message_type': 'text',
          'content': content,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Send media message (image, video, document, voice)
  static Future<Map<String, dynamic>> sendMediaMessage({
    required String chatroomId,
    required String receiverId,
    required String messageType,
    required File mediaFile,
    String? fileName,
    int? voiceDuration,
  }) async {
    try {
      final token = AuthService.accessToken;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/messages/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['chatroom'] = chatroomId;
      request.fields['receiver'] = receiverId;
      request.fields['message_type'] = messageType;

      if (fileName != null) {
        request.fields['file_name'] = fileName;
      }

      if (voiceDuration != null) {
        request.fields['voice_duration'] = voiceDuration.toString();
      }

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'media_file',
          mediaFile.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send media: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending media: $e');
      rethrow;
    }
  }

  // Mark message as read
  static Future<void> markMessageAsRead(String messageId) async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/messages/$messageId/mark_read/'),
        headers: headers,
      );
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  // Mark all messages in chatroom as read
  static Future<void> markChatroomAsRead(String chatroomId) async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/chatrooms/$chatroomId/mark_as_read/'),
        headers: headers,
      );
    } catch (e) {
      print('Error marking chatroom as read: $e');
    }
  }

  // Delete message
  static Future<void> deleteMessage(String messageId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/messages/$messageId/'),
        headers: headers,
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  // Block user
  static Future<void> blockUser(String chatroomId) async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/chatrooms/$chatroomId/block/'),
        headers: headers,
      );
    } catch (e) {
      print('Error blocking user: $e');
      rethrow;
    }
  }

  // Unblock user
  static Future<void> unblockUser(String chatroomId) async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/chatrooms/$chatroomId/unblock/'),
        headers: headers,
      );
    } catch (e) {
      print('Error unblocking user: $e');
      rethrow;
    }
  }

  // Report user/message
  static Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    String? description,
    String? messageId,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'reported_user': reportedUserId,
        'reason': reason,
      };

      if (description != null) {
        body['description'] = description;
      }

      if (messageId != null) {
        body['message'] = messageId;
      }

      await http.post(
        Uri.parse('$baseUrl/reports/'),
        headers: headers,
        body: jsonEncode(body),
      );
    } catch (e) {
      print('Error reporting user: $e');
      rethrow;
    }
  }

  // Update online status
  static Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/online-status/update_status/'),
        headers: headers,
        body: jsonEncode({'is_online': isOnline}),
      );
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  // Get online status for users
  static Future<List<dynamic>> getOnlineStatus(List<String> userIds) async {
    try {
      final headers = await _getHeaders();
      final queryParams = userIds.map((id) => 'user_ids[]=$id').join('&');
      final response = await http.get(
        Uri.parse('$baseUrl/online-status/?$queryParams'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting online status: $e');
      return [];
    }
  }

  // Update typing status
  static Future<void> updateTypingStatus(String chatroomId, bool isTyping) async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/typing-status/update_typing/'),
        headers: headers,
        body: jsonEncode({
          'chatroom': chatroomId,
          'is_typing': isTyping,
        }),
      );
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  // Get typing status for chatroom
  static Future<List<dynamic>> getTypingStatus(String chatroomId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/typing-status/?chatroom=$chatroomId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting typing status: $e');
      return [];
    }
  }
}
