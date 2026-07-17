import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'auth_service.dart';
import 'api_service.dart';
import 'active_chat_tracker.dart';

/// A user-facing chat error: `message` is plain text safe to show in a
/// snackbar (already in Bangla from the backend when available).
class AdsyChatException implements Exception {
  final String message;
  AdsyChatException(this.message);
  @override
  String toString() => message;
}

class AdsyConnectService {
  static String get baseUrl => '${ApiService.baseUrl}/adsyconnect';

  static Map<String, dynamic> _normalizeChatroomPayload(dynamic payload) {
    if (payload is! Map) {
      throw Exception('Invalid chat room response');
    }

    final map = Map<String, dynamic>.from(payload);
    final data = map['data'];
    if (data is Map && data['id'] != null) {
      return Map<String, dynamic>.from(data);
    }

    if (map['id'] != null) {
      return map;
    }

    throw Exception('Chat room ID missing from response');
  }

  static Map<String, dynamic>? _matchChatRoomForUser(
    List<dynamic> rooms,
    String userId,
  ) {
    for (final room in rooms) {
      if (room is! Map) continue;
      final map = Map<String, dynamic>.from(room);
      final otherUser = map['other_user'];
      if (otherUser is Map && otherUser['id']?.toString() == userId) {
        return map;
      }
      if (map['user1']?.toString() == userId ||
          map['user2']?.toString() == userId) {
        return map;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> findExistingChatRoom(
      String userId) async {
    try {
      final rooms = await getChatRooms(pageSize: 100);
      return _matchChatRoomForUser(rooms, userId);
    } catch (e) {
      debugPrint('Error finding existing chat room: $e');
      return null;
    }
  }

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
      final existingChatroom = await findExistingChatRoom(userId);
      if (existingChatroom != null && existingChatroom['id'] != null) {
        return existingChatroom;
      }

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/chatrooms/get_or_create/'),
        headers: headers,
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _normalizeChatroomPayload(jsonDecode(response.body));
      } else {
        // Surface only the backend's plain message (error/detail) — never the
        // raw status code + body, which looked like leaked backend code.
        String message = 'চ্যাট খোলা যায়নি, একটু পরে আবার চেষ্টা করুন।';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            final m = decoded['error'] ?? decoded['detail'];
            if (m is String && m.trim().isNotEmpty) message = m.trim();
          }
        } catch (_) {}
        throw AdsyChatException(message);
      }
    } catch (e) {
      debugPrint('Error getting or creating chat room: $e');
      if (e is AdsyChatException) rethrow; // clean user-facing message
      final existingChatroom = await findExistingChatRoom(userId);
      if (existingChatroom != null && existingChatroom['id'] != null) {
        return existingChatroom;
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getChatRoomDetails(
      String chatroomId) async {
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
      debugPrint('Error fetching chatroom details: $e');
      return null;
    }
  }

  // Get all chat rooms
  static Future<List<dynamic>> getChatRooms({
    int page = 1,
    int pageSize = 20,
    bool archived = false,
  }) async {
    try {
      final headers = await _getHeaders();

      final archivedParam = archived ? '&archived=true' : '';
      final response = await http.get(
        Uri.parse(
            '$baseUrl/chatrooms/?page=$page&page_size=$pageSize$archivedParam'),
        headers: headers,
      );

      // The home screen polls this every 10s, so it's our fastest signal that
      // the account was suspended while logged in — lock the app immediately.
      if (AuthService.maybeHandleSuspendedResponse(
          response.statusCode, response.body)) {
        return [];
      }

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
          final end = (start + pageSize) > full.length
              ? full.length
              : (start + pageSize);
          return full.sublist(start, end);
        }

        // If neither, return empty list
        return [];
      } else {
        throw Exception(
            'Failed to load chat rooms: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
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
      debugPrint(
          '🔵 Fetching messages from: $baseUrl/messages/?chatroom=$chatroomId&page=$page&page_size=$pageSize');

      final response = await http.get(
        Uri.parse(
            '$baseUrl/messages/?chatroom=$chatroomId&page=$page&page_size=$pageSize'),
        headers: headers,
      );

      debugPrint('🔵 Messages response status: ${response.statusCode}');
      debugPrint('🔵 Messages response body: ${response.body}');

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
        throw Exception(
            'Failed to load messages: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('🔴 Error loading messages: $e');
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
        debugPrint('🟢 Messages marked as read for chatroom: $chatroomId');
      } else {
        debugPrint('⚠️ Failed to mark messages as read: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 Error marking messages as read: $e');
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

      final response = await http
          .post(
            Uri.parse('$baseUrl/messages/'),
            headers: headers,
            body: jsonEncode({
              'chatroom': chatroomId,
              'receiver': receiverId,
              'message_type': 'text',
              'content': content,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired');
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied');
      } else {
        throw Exception(
          'Failed to send message: ${response.statusCode} - ${response.body}',
        );
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
      debugPrint('Error sending message: $e');
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

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
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
        throw Exception(
          'Failed to send media: ${response.statusCode} - ${response.body}',
        );
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
      debugPrint('Error sending media: $e');
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
      debugPrint('Error marking message as read: $e');
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
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  // Edit message
  static Future<Map<String, dynamic>> editMessage(
      String messageId, String newContent) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/messages/$messageId/'),
        headers: headers,
        body: jsonEncode({'content': newContent}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to edit message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error editing message: $e');
      rethrow;
    }
  }

  // Block user
  static Future<void> blockUser(String chatroomId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/chatrooms/$chatroomId/block/'),
        headers: headers,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Failed to block user: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error blocking user: $e');
      rethrow;
    }
  }

  /// Archive/unarchive this conversation for the current user (hidden from the
  /// main list, still receives messages).
  static Future<bool> setArchived(String chatroomId, bool archived) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/chatrooms/$chatroomId/archive/'),
        headers: await _getHeaders(),
        body: json.encode({'archived': archived}),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      debugPrint('setArchived failed: $e');
      return false;
    }
  }

  /// Mute/unmute push notifications for this conversation (current user only).
  static Future<bool> setMuted(String chatroomId, bool muted) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/chatrooms/$chatroomId/mute/'),
        headers: await _getHeaders(),
        body: json.encode({'muted': muted}),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      debugPrint('setMuted failed: $e');
      return false;
    }
  }

  /// Clear this conversation for the CURRENT user only. The other participant
  /// keeps their history; once both sides have cleared, the server hard-deletes
  /// the records nobody can see anymore. Returns the server response
  /// ({both_cleared, purged}) or null on failure.
  static Future<Map<String, dynamic>?> clearConversation(
      String chatroomId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/chatrooms/$chatroomId/clear/'),
        headers: headers,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Map<String, dynamic>.from(json.decode(response.body));
      }
      debugPrint(
          'clearConversation -> ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error clearing conversation: $e');
      return null;
    }
  }

  // Unblock user
  static Future<void> unblockUser(String chatroomId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/chatrooms/$chatroomId/unblock/'),
        headers: headers,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Failed to unblock user: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error unblocking user: $e');
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

      final response = await http.post(
        Uri.parse('$baseUrl/reports/'),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to report user: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error reporting user: $e');
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
      debugPrint('Error updating online status: $e');
    }
  }

  // Get online status for users (multiple)
  static Future<List<dynamic>> getOnlineStatusList(List<String> userIds) async {
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
      debugPrint('Error getting online status: $e');
      return [];
    }
  }

  // Get online status for single user
  static Future<Map<String, dynamic>?> getOnlineStatus(String userId) async {
    try {
      final results = await getOnlineStatusList([userId]);
      if (results.isNotEmpty && results.first is Map) {
        return Map<String, dynamic>.from(results.first as Map);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting online status for user $userId: $e');
      return null;
    }
  }

  // Update typing status
  static Future<void> updateTypingStatus(
      String chatroomId, bool isTyping) async {
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
      debugPrint('Error updating typing status: $e');
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
      debugPrint('Error getting typing status: $e');
      return [];
    }
  }

  static Future<void> setActiveChat(String? chatroomId) async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/set-active-chat/'),
        headers: headers,
        body: jsonEncode({'chatroom_id': chatroomId}),
      );
      debugPrint('📍 Active chat set on server: $chatroomId');
    } catch (e) {
      debugPrint('Error setting active chat: $e');
    }
  }

  static Future<void> clearActiveChat() async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/clear-active-chat/'),
        headers: headers,
      );
      debugPrint('📍 Active chat cleared on server');
    } catch (e) {
      debugPrint('Error clearing active chat: $e');
    }
  }

  static Future<void> sendHeartbeat() async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/heartbeat/'),
        headers: headers,
      );
    } catch (e) {
      debugPrint('Error sending heartbeat: $e');
    }
  }

  // ── Group chats ─────────────────────────────────────────────────────────

  static Future<List<dynamic>> getGroups() async {
    try {
      final headers = await _getHeaders();
      final response =
          await http.get(Uri.parse('$baseUrl/groups/'), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('results')) {
          return List<dynamic>.from(data['results'] ?? []);
        }
        if (data is List) return List<dynamic>.from(data);
      }
      return [];
    } catch (e) {
      debugPrint('getGroups failed: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createGroup({
    required String name,
    required List<String> memberIds,
    String? imagePath,
  }) async {
    try {
      final headers = await _getHeaders();
      headers.remove('Content-Type'); // multipart sets its own boundary
      final req =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/groups/'));
      req.headers.addAll(headers);
      req.fields['name'] = name;
      req.fields['member_ids'] = memberIds.join(',');
      if (imagePath != null && imagePath.isNotEmpty) {
        req.files.add(await http.MultipartFile.fromPath('image', imagePath));
      }
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(body));
      }
      debugPrint('createGroup -> ${streamed.statusCode} $body');
      return null;
    } catch (e) {
      debugPrint('createGroup failed: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getGroupMessages(String groupId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/groups/$groupId/messages/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return List<dynamic>.from(data);
      }
      return [];
    } catch (e) {
      debugPrint('getGroupMessages failed: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> sendGroupMessage(
      String groupId, String content) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/messages/'),
        headers: headers,
        body: jsonEncode({'content': content}),
      );
      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('sendGroupMessage failed: $e');
      return null;
    }
  }

  static Future<bool> addGroupMembers(
      String groupId, List<String> userIds) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/add_members/'),
        headers: headers,
        body: jsonEncode({'user_ids': userIds}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('addGroupMembers failed: $e');
      return false;
    }
  }

  static Future<bool> removeGroupMember(String groupId, String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/remove_member/'),
        headers: headers,
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('removeGroupMember failed: $e');
      return false;
    }
  }

  static Future<bool> leaveGroup(String groupId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/leave/'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('leaveGroup failed: $e');
      return false;
    }
  }

  /// Admin: rename the group and/or change its photo.
  static Future<Map<String, dynamic>?> updateGroup(
    String groupId, {
    String? name,
    String? imagePath,
  }) async {
    try {
      final headers = await _getHeaders();
      headers.remove('Content-Type');
      final req = http.MultipartRequest(
          'PATCH', Uri.parse('$baseUrl/groups/$groupId/'));
      req.headers.addAll(headers);
      if (name != null && name.trim().isNotEmpty) {
        req.fields['name'] = name.trim();
      }
      if (imagePath != null && imagePath.isNotEmpty) {
        req.files.add(await http.MultipartFile.fromPath('image', imagePath));
      }
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(body));
      }
      return null;
    } catch (e) {
      debugPrint('updateGroup failed: $e');
      return null;
    }
  }

  static Future<bool> deleteGroup(String groupId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/groups/$groupId/'),
        headers: headers,
      );
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('deleteGroup failed: $e');
      return false;
    }
  }

  static Future<bool> promoteGroupAdmin(String groupId, String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/promote_admin/'),
        headers: headers,
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('promoteGroupAdmin failed: $e');
      return false;
    }
  }

  static Future<bool> demoteGroupAdmin(String groupId, String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/demote_admin/'),
        headers: headers,
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('demoteGroupAdmin failed: $e');
      return false;
    }
  }

  static Future<bool> setGroupMuted(String groupId, bool muted) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/mute/'),
        headers: headers,
        body: jsonEncode({'muted': muted}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('setGroupMuted failed: $e');
      return false;
    }
  }

  /// Heartbeat: tell the group I'm typing right now.
  static Future<void> setGroupTyping(String groupId) async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/groups/$groupId/typing/'),
        headers: headers,
      );
    } catch (_) {}
  }

  /// Names of OTHER members typing right now.
  static Future<List<String>> getGroupTyping(String groupId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/groups/$groupId/typing/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['typing'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Send a media message (voice/image/video/document) into a group.
  /// Pass either [filePath] or [mediaBytes] (+ [fileName]).
  static Future<Map<String, dynamic>?> sendGroupMediaMessage({
    required String groupId,
    required String messageType,
    String? filePath,
    List<int>? mediaBytes,
    String? fileName,
    int? voiceDuration,
  }) async {
    try {
      final headers = await _getHeaders();
      headers.remove('Content-Type');
      final req = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/groups/$groupId/messages/'));
      req.headers.addAll(headers);
      req.fields['message_type'] = messageType;
      if (voiceDuration != null) {
        req.fields['voice_duration'] = '$voiceDuration';
      }
      if (fileName != null && fileName.isNotEmpty) {
        req.fields['file_name'] = fileName;
      }
      if (filePath != null) {
        req.files
            .add(await http.MultipartFile.fromPath('media_file', filePath));
      } else if (mediaBytes != null) {
        req.files.add(http.MultipartFile.fromBytes(
          'media_file',
          mediaBytes,
          filename: fileName ?? 'upload.bin',
        ));
      } else {
        return null;
      }
      final streamed = await req.send().timeout(const Duration(minutes: 3));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(body));
      }
      debugPrint('sendGroupMediaMessage -> ${streamed.statusCode} $body');
      return null;
    } catch (e) {
      debugPrint('sendGroupMediaMessage failed: $e');
      return null;
    }
  }
}
