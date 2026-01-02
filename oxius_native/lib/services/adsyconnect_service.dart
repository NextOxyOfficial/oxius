import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_service.dart';
import 'api_service.dart';
import 'active_chat_tracker.dart';

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
      final response = await http.post(
        Uri.parse('$baseUrl/chatrooms/get_or_create/'),
        headers: headers,
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get or create chat room: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting or creating chat room: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getChatRoomDetails(String chatroomId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chatrooms/$chatroomId/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }

      return null;
    } catch (e) {
      print('Error fetching chatroom details: $e');
      return null;
    }
  }

  // Get all chat rooms
  static Future<List<dynamic>> getChatRooms({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      print('🔵 Fetching chat rooms from: $baseUrl/chatrooms/?page=$page&page_size=$pageSize');
      
      final response = await http.get(
        Uri.parse('$baseUrl/chatrooms/?page=$page&page_size=$pageSize'),
        headers: headers,
      );

      print('🔵 Chat rooms response status: ${response.statusCode}');
      print('🔵 Chat rooms response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if it's a paginated response with 'results' key
        if (data is Map && data.containsKey('results')) {
          return List<dynamic>.from(data['results'] ?? []);
        }
        
        // Otherwise assume it's a direct list
        if (data is List) {
          final full = List<dynamic>.from(data);
          final start = (page - 1) * pageSize;
          if (start >= full.length) {
            return [];
          }
          final end = (start + pageSize) > full.length ? full.length : (start + pageSize);
          return full.sublist(start, end);
        }
        
        // If neither, return empty list
        return [];
      } else {
        throw Exception('Failed to load chat rooms: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🔴 Error loading chat rooms: $e');
      rethrow;
    }
  }

  // Get messages for a chat room
  static Future<List<dynamic>> getMessages(
    String chatroomId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      print('🔵 Fetching messages from: $baseUrl/messages/?chatroom=$chatroomId&page=$page&page_size=$pageSize');
      
      final response = await http.get(
        Uri.parse('$baseUrl/messages/?chatroom=$chatroomId&page=$page&page_size=$pageSize'),
        headers: headers,
      );

      print('🔵 Messages response status: ${response.statusCode}');
      print('🔵 Messages response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if it's a paginated response with 'results' key
        if (data is Map && data.containsKey('results')) {
          return List<dynamic>.from(data['results'] ?? []);
        }
        
        // Otherwise assume it's a direct list
        if (data is List) {
          final full = List<dynamic>.from(data);
          final total = full.length;

          final end = total - (page - 1) * pageSize;
          if (end <= 0) {
            return [];
          }
          final start = max(0, end - pageSize);
          return full.sublist(start, end);
        }
        
        // If neither, return empty list
        return [];
      } else {
        throw Exception('Failed to load messages: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🔴 Error loading messages: $e');
      rethrow;
    }
  }

  // Mark all messages in chatroom as read
  static Future<void> markChatroomAsRead(String chatroomId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/chatrooms/$chatroomId/mark_as_read/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print('🟢 Messages marked as read for chatroom: $chatroomId');
      } else {
        print('⚠️ Failed to mark messages as read: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 Error marking messages as read: $e');
      // Don't rethrow - this is a non-critical operation
    }
  }

  // Send text message
  static Future<Map<String, dynamic>> sendTextMessage({
    required String chatroomId,
    required String receiverId,
    required String content,
  }) async {
    try {
      // Get headers with active chat ID to prevent unnecessary notifications
      final headers = await _getHeaders();
      
      // Add active chat ID if available (imported at top of file)
      final activeChatId = ActiveChatTracker.activeChatId;
      if (activeChatId != null) {
        headers['X-Active-Chat-ID'] = activeChatId;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/messages/'),
        headers: headers,
        body: jsonEncode({
          'chatroom': chatroomId,
          'receiver': receiverId,
          'message_type': 'text',
          'content': content,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired');
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied');
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } on http.ClientException {
      throw Exception('Connection error');
    } on TimeoutException {
      throw Exception('Request timeout');
    } catch (e) {
      // Check if it's a network-related error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socket') || errorStr.contains('network')) {
        throw Exception('No internet connection');
      }
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Send media message (image, video, document, voice)
  // Accepts either file path (mobile) or bytes (web)
  static Future<Map<String, dynamic>> sendMediaMessage({
    required String chatroomId,
    required String receiverId,
    required String messageType,
    String? mediaFilePath,
    List<int>? mediaBytes,
    String? fileName,
    int? voiceDuration,
  }) async {
    try {
      final token = AuthService.accessToken;
      
      if (mediaFilePath == null && mediaBytes == null) {
        throw Exception('Either mediaFilePath or mediaBytes must be provided');
      }
      
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

      // Add file - handle both web (bytes) and mobile (path)
      if (kIsWeb && mediaBytes != null) {
        // Web: Use bytes
        request.files.add(
          http.MultipartFile.fromBytes(
            'media_file',
            mediaBytes,
            filename: fileName ?? 'upload.${_getFileExtension(messageType)}',
          ),
        );
      } else if (mediaFilePath != null) {
        // Mobile: Use file path
        request.files.add(
          await http.MultipartFile.fromPath(
            'media_file',
            mediaFilePath,
            filename: fileName,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired');
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied');
      } else if (response.statusCode == 413) {
        throw Exception('File too large');
      } else {
        throw Exception('Failed to send media: ${response.statusCode}');
      }
    } on http.ClientException {
      throw Exception('Connection error');
    } on TimeoutException {
      throw Exception('Upload timeout - file may be too large');
    } catch (e) {
      // Check if it's a network-related error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socket') || errorStr.contains('network')) {
        throw Exception('No internet connection');
      }
      print('Error sending media: $e');
      rethrow;
    }
  }

  static String _getFileExtension(String messageType) {
    switch (messageType) {
      case 'image':
        return 'jpg';
      case 'video':
        return 'mp4';
      case 'voice':
        return 'm4a';
      case 'document':
        return 'pdf';
      default:
        return 'bin';
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

  // Delete message (soft delete - returns updated message data)
  static Future<Map<String, dynamic>> deleteMessage(String messageId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/messages/$messageId/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Backend returns the updated message with is_deleted=true
        return jsonDecode(response.body);
      } else {
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
