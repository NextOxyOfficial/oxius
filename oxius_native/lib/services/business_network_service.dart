import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/business_network_models.dart';
import 'api_service.dart';

class BusinessNetworkService {
  static const String _baseUrl = 'http://127.0.0.1:8000/api/bn';
  
  /// Get posts feed with pagination
  static Future<Map<String, dynamic>> getPosts({
    int page = 1,
    int pageSize = 5,
    String? olderThan,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      
      String url = '$_baseUrl/posts/?page=$page&page_size=$pageSize';
      if (olderThan != null) {
        url += '&older_than=$olderThan';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('=== Business Network API Debug ===');
      print('URL: $url');
      print('Headers: $headers');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Decoded data: $data');
        final results = data['results'] as List;
        print('Results count: ${results.length}');
        final posts = results.map((e) => BusinessNetworkPost.fromJson(e)).toList();
        print('Parsed ${posts.length} posts successfully');
        
        return {
          'posts': posts,
          'hasMore': data['next'] != null,
          'count': data['count'] ?? 0,
        };
      } else if (response.statusCode == 401) {
        print('ERROR: Unauthorized - User not authenticated');
        print('Response: ${response.body}');
        return {'posts': <BusinessNetworkPost>[], 'hasMore': false, 'count': 0, 'error': 'unauthorized'};
      } else {
        print('ERROR: ${response.statusCode} - ${response.body}');
        return {'posts': <BusinessNetworkPost>[], 'hasMore': false, 'count': 0, 'error': response.body};
      }
    } catch (e, stackTrace) {
      print('Error fetching posts: $e');
      print('Stack trace: $stackTrace');
      return {'posts': <BusinessNetworkPost>[], 'hasMore': false, 'count': 0};
    }
  }

  /// Create a new post
  static Future<BusinessNetworkPost?> createPost({
    String? title,
    String? content,
    List<String>? images,
    String? category,
    List<String>? tags,
    String visibility = 'public',
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final body = {
        if (title != null && title.isNotEmpty) 'title': title,
        if (content != null && content.isNotEmpty) 'content': content,
        'visibility': visibility,
        if (images != null && images.isNotEmpty) 'images': images,
        if (category != null) 'category': category,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      };
      
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/'),
        headers: headers,
        body: json.encode(body),
      );
      
      print('=== Create Post Debug ===');
      print('Request body: ${json.encode(body)}');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('Decoded response data: $data');
          final post = BusinessNetworkPost.fromJson(data);
          print('Successfully created post with ID: ${post.id}');
          return post;
        } catch (parseError) {
          print('Error parsing response: $parseError');
          return null;
        }
      } else {
        print('Failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error creating post: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Like a post
  static Future<bool> likePost(int postId) async {
    try {
      final headers = await ApiService.getHeaders();
      
      print('=== Like Post Debug ===');
      print('URL: $_baseUrl/posts/$postId/like/');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/like/'),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, stackTrace) {
      print('Error liking post: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Unlike a post
  static Future<bool> unlikePost(int postId) async {
    try {
      final headers = await ApiService.getHeaders();
      
      print('=== Unlike Post Debug ===');
      print('URL: $_baseUrl/posts/$postId/unlike/');
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/posts/$postId/unlike/'),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      // 404 means like doesn't exist - treat as success
      if (response.statusCode == 404) {
        print('Like not found - already unliked');
        return true;
      }
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e, stackTrace) {
      print('Error unliking post: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Toggle like/unlike a post
  static Future<bool> toggleLike(int postId, bool isCurrentlyLiked) async {
    if (isCurrentlyLiked) {
      return await unlikePost(postId);
    } else {
      return await likePost(postId);
    }
  }

  /// Add a comment to a post
  static Future<BusinessNetworkComment?> addComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final body = {
        'content': content,
        if (parentCommentId != null) 'parent_comment': parentCommentId,
      };
      
      print('=== Add Comment Debug ===');
      print('URL: $_baseUrl/posts/$postId/comments/');
      print('Content: $content');
      print('Parent Comment ID: $parentCommentId');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/comments/'),
        headers: headers,
        body: json.encode(body),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return BusinessNetworkComment.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  /// Get a single post by ID
  static Future<BusinessNetworkPost?> getPost(int postId) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/posts/$postId/'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BusinessNetworkPost.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching post: $e');
      return null;
    }
  }

  /// Delete a post
  static Future<bool> deletePost(int postId) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/posts/$postId/'),
        headers: headers,
      );
      
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  /// Update a post
  static Future<BusinessNetworkPost?> updatePost({
    required int postId,
    required String content,
    List<String>? images,
    String? category,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final body = {
        'content': content,
        if (images != null) 'images': images,
        if (category != null) 'category': category,
      };
      
      final response = await http.put(
        Uri.parse('$_baseUrl/posts/$postId/'),
        headers: headers,
        body: json.encode(body),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BusinessNetworkPost.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error updating post: $e');
      return null;
    }
  }

  /// Save a post
  static Future<bool> savePost(int postId) async {
    try {
      final headers = await ApiService.getHeaders();
      
      print('=== Save Post Debug ===');
      print('URL: $_baseUrl/posts/save/');
      print('Post ID: $postId');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/save/'),
        headers: headers,
        body: json.encode({'post': postId}),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error saving post: $e');
      return false;
    }
  }

  /// Unsave a post
  static Future<bool> unsavePost(int postId) async {
    try {
      final headers = await ApiService.getHeaders();
      
      print('=== Unsave Post Debug ===');
      print('URL: $_baseUrl/saved-posts/delete/$postId/');
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/saved-posts/delete/$postId/'),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error unsaving post: $e');
      return false;
    }
  }

  /// Toggle save/unsave a post
  static Future<bool> toggleSave(int postId, bool isCurrentlySaved) async {
    if (isCurrentlySaved) {
      return await unsavePost(postId);
    } else {
      return await savePost(postId);
    }
  }

  /// Follow a user
  static Future<bool> followUser(String userId) async {
    try {
      final headers = await ApiService.getHeaders();
      
      print('=== Follow User Debug ===');
      print('URL: $_baseUrl/users/$userId/follow/');
      print('Headers: $headers');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/users/$userId/follow/'),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      // Handle success (200 = already following, 201 = newly created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Successfully followed user (status: ${response.statusCode})');
        return true;
      }
      
      // If 400, check if it's a duplicate follow (unique constraint error)
      if (response.statusCode == 400) {
        try {
          final responseBody = response.body;
          if (responseBody.isNotEmpty) {
            final bodyLower = responseBody.toLowerCase();
            // Check for unique constraint error - means already following
            if (bodyLower.contains('unique') || bodyLower.contains('follower')) {
              print('User already following (unique constraint)');
              // Return false so UI reloads and syncs with backend
              return false;
            }
          }
        } catch (e) {
          print('Error parsing response body: $e');
        }
        print('ERROR 400: ${response.body}');
        return false;
      }
      
      print('Unexpected status code: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error following user: $e');
      return false;
    }
  }

  /// Unfollow a user
  static Future<bool> unfollowUser(String userId) async {
    try {
      final headers = await ApiService.getHeaders();
      
      print('=== Unfollow User Debug ===');
      print('URL: $_baseUrl/users/$userId/unfollow/');
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$userId/unfollow/'),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  /// Toggle follow/unfollow a user
  static Future<bool> toggleFollow(String userId, bool isCurrentlyFollowing) async {
    print('=== Toggle Follow Debug ===');
    print('User ID: $userId');
    print('Currently Following: $isCurrentlyFollowing');
    print('Action: ${isCurrentlyFollowing ? "UNFOLLOW" : "FOLLOW"}');
    
    if (isCurrentlyFollowing) {
      return await unfollowUser(userId);
    } else {
      return await followUser(userId);
    }
  }

  /// Search users for @mentions
  static Future<List<BusinessNetworkUser>> searchUsers(String query) async {
    try {
      final headers = await ApiService.getHeaders();
      
      print('=== Search Users Debug ===');
      print('Query: $query');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/users/search/?q=$query'),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? data;
        
        return results
            .map((json) => BusinessNetworkUser.fromJson(json))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Hide a post from feed
  static Future<bool> hidePost(int postId) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/hide/'),
        headers: headers,
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Post hidden successfully');
        return true;
      }
      
      print('Failed to hide post: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error hiding post: $e');
      return false;
    }
  }

  /// Report a post
  static Future<bool> reportPost(int postId, String reason) async {
    try {
      final headers = await ApiService.getHeaders();
      
      // Map Flutter reason to backend reason
      final reasonMap = {
        'Spam or misleading': 'spam',
        'Harassment or hate speech': 'harassment',
        'Violence or dangerous content': 'violence',
        'Inappropriate content': 'inappropriate',
        'Other': 'other',
      };
      
      final backendReason = reasonMap[reason] ?? 'other';
      
      final body = {
        'reason': backendReason,
        'description': '',
      };
      
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/report/'),
        headers: headers,
        body: json.encode(body),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Post reported successfully');
        return true;
      }
      
      print('Failed to report post: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error reporting post: $e');
      return false;
    }
  }
}
