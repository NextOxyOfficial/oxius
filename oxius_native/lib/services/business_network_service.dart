import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/business_network_models.dart';
import 'api_service.dart';

class BusinessNetworkService {
  /// Get posts feed with pagination
  static Future<Map<String, dynamic>> getPosts({
    int page = 1,
    int pageSize = 5,
    String? olderThan,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      
      String url = 'http://localhost:8000/api/bn/posts/?page=$page&page_size=$pageSize';
      if (olderThan != null) {
        url += '&older_than=$olderThan';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Decoded data: $data');
        final results = data['results'] as List;
        print('Results count: ${results.length}');
        final posts = results.map((e) => BusinessNetworkPost.fromJson(e)).toList();
        
        return {
          'posts': posts,
          'hasMore': data['next'] != null,
          'count': data['count'] ?? 0,
        };
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        return {'posts': <BusinessNetworkPost>[], 'hasMore': false, 'count': 0};
      }
    } catch (e, stackTrace) {
      print('Error fetching posts: $e');
      print('Stack trace: $stackTrace');
      return {'posts': <BusinessNetworkPost>[], 'hasMore': false, 'count': 0};
    }
  }

  /// Create a new post
  static Future<BusinessNetworkPost?> createPost({
    required String content,
    List<String>? images,
    String? category,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final body = {
        'content': content,
        if (images != null && images.isNotEmpty) 'images': images,
        if (category != null) 'category': category,
      };
      
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/bn/posts/'),
        headers: headers,
        body: json.encode(body),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return BusinessNetworkPost.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  /// Like or unlike a post
  static Future<bool> toggleLike(int postId) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/bn/posts/$postId/like/'),
        headers: headers,
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  /// Add a comment to a post
  static Future<BusinessNetworkComment?> addComment({
    required int postId,
    required String content,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/bn/posts/$postId/comment/'),
        headers: headers,
        body: json.encode({'content': content}),
      );
      
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
        Uri.parse('http://localhost:8000/api/bn/posts/$postId/'),
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
        Uri.parse('http://localhost:8000/api/bn/posts/$postId/'),
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
        Uri.parse('http://localhost:8000/api/bn/posts/$postId/'),
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
}
