import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../models/business_network_models.dart';
import 'api_service.dart';
import 'auth_service.dart';

class BusinessNetworkService {
  static String get _baseUrl => '${ApiService.baseUrl}/bn';
  
  /// Get Business Network logo
  static Future<String?> getBusinessNetworkLogo() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/bn-logo/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // The endpoint returns a single object with 'image' field
        String? logoUrl;
        if (data is Map<String, dynamic>) {
          logoUrl = data['image'] as String?;
        } else if (data is List && data.isNotEmpty) {
          // Fallback for list response
          logoUrl = data[0]['image'] as String?;
        }
        
        if (logoUrl != null && logoUrl.isNotEmpty) {
          // Convert relative URL to absolute (MEDIA base URL), keep absolute URLs as-is
          return ApiService.getAbsoluteUrl(logoUrl);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching business network logo: $e');
      return null;
    }
  }
  
  /// Get posts feed with pagination
  static Future<Map<String, dynamic>> getPosts({
    int page = 1,
    int pageSize = 5,
    String? olderThan,
  }) async {
    try {
      String url = '$_baseUrl/posts/?page=$page&page_size=$pageSize';
      if (olderThan != null) {
        url += '&older_than=$olderThan';
      }
      
      // First try without auth to avoid token issues
      final basicHeaders = {'Content-Type': 'application/json'};
      final headers = await ApiService.getHeaders();
      final hasAuthHeader = headers.keys.any((k) => k.toLowerCase() == 'authorization');

      var response = await http.get(
        Uri.parse(url),
        headers: hasAuthHeader ? headers : basicHeaders,
      );

      if (hasAuthHeader && (response.statusCode == 401 || response.statusCode == 403)) {
        response = await http.get(
          Uri.parse(url),
          headers: basicHeaders,
        );
      }
      
      print('=== Business Network API Debug ===');
      print('URL: $url');
      print('Response status: ${response.statusCode}');
      print('Response body length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Decoded data: $data');
        final results = data['results'] as List;
        print('Results count: ${results.length}');

        final currentUserIdStr = AuthService.currentUser?.id;
        final currentUserId = int.tryParse((currentUserIdStr ?? '').toString());

        final posts = results.map((e) {
          final raw = e is Map<String, dynamic>
              ? e
              : (e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{});

          var post = BusinessNetworkPost.fromJson(raw);

          final hasIsLikedField = raw.containsKey('is_liked') || raw.containsKey('isLiked');
          if (!hasIsLikedField && currentUserId != null) {
            final inferredLiked = post.postLikes.any((l) => l.user == currentUserId);
            if (inferredLiked != post.isLiked) {
              post = post.copyWith(isLiked: inferredLiked);
            }
          }

          return post;
        }).toList();
        print('Parsed ${posts.length} posts successfully');
        
        return {
          'posts': posts,
          'hasMore': data['next'] != null,
          'count': data['count'] ?? 0,
        };
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
    List<String>? videos,
    List<String>? videoPaths,
    String? category,
    List<String>? tags,
    String visibility = 'public',
  }) async {
    try {
      final hasVideoFiles = videoPaths != null && videoPaths.isNotEmpty;

      if (hasVideoFiles) {
        final headers = await ApiService.getHeaders();
        headers.remove('Content-Type');
        headers.remove('content-type');
        headers.remove('Content-type');
        headers.removeWhere((k, _) => k.toLowerCase() == 'content-type');

        final formData = FormData();
        if (title != null && title.isNotEmpty) {
          formData.fields.add(MapEntry('title', title));
        }
        if (content != null && content.isNotEmpty) {
          formData.fields.add(MapEntry('content', content));
        }
        formData.fields.add(MapEntry('visibility', visibility));
        if (category != null && category.isNotEmpty) {
          formData.fields.add(MapEntry('category', category));
        }
        if (tags != null && tags.isNotEmpty) {
          for (final tag in tags) {
            if (tag.trim().isEmpty) continue;
            formData.fields.add(MapEntry('tags', tag));
          }
        }
        if (images != null && images.isNotEmpty) {
          for (final img in images) {
            if (img.trim().isEmpty) continue;
            formData.fields.add(MapEntry('images', img));
          }
        }
        if (videos != null && videos.isNotEmpty) {
          for (final v in videos) {
            if (v.trim().isEmpty) continue;
            formData.fields.add(MapEntry('videos', v));
          }
        }

        for (final path in videoPaths) {
          if (path.trim().isEmpty) continue;
          final file = File(path);
          if (!file.existsSync()) {
            throw Exception('Selected video file not found at path: $path');
          }

          final p = path.replaceAll('\\', '/');
          final filename = p.split('/').isNotEmpty ? p.split('/').last : 'video.mp4';
          formData.files.add(
            MapEntry(
              'videos',
              await MultipartFile.fromFile(path, filename: filename),
            ),
          );
        }

        final dio = Dio(
          BaseOptions(
            responseType: ResponseType.json,
          ),
        );
        final response = await dio.post(
          '$_baseUrl/posts/',
          data: formData,
          options: Options(
            headers: headers,
            contentType: null,
            validateStatus: (status) => true,
          ),
        );

        print('=== Create Post Debug ===');
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.data}');

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = response.data is Map
              ? Map<String, dynamic>.from(response.data)
              : json.decode(response.data.toString());
          final post = BusinessNetworkPost.fromJson(data);
          return post;
        }

        throw Exception('Failed to create post: ${response.statusCode} ${response.data}');
      }

      final headers = await ApiService.getHeaders();

      final body = {
        if (title != null && title.isNotEmpty) 'title': title,
        if (content != null && content.isNotEmpty) 'content': content,
        'visibility': visibility,
        if (images != null && images.isNotEmpty) 'images': images,
        if (videos != null && videos.isNotEmpty) 'videos': videos,
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
        final data = json.decode(response.body);
        final post = BusinessNetworkPost.fromJson(data);
        return post;
      }

      throw Exception('Failed to create post: ${response.statusCode} ${response.body}');
    } catch (e, stackTrace) {
      print('Error creating post: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Like a post
  static Future<bool> likePost(int postId) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/like/'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to like post: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on http.ClientException {
      throw Exception('Connection error');
    } on TimeoutException {
      throw Exception('Request timeout');
    } catch (e) {
      rethrow;
    }
  }

  /// Unlike a post
  static Future<bool> unlikePost(int postId) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/posts/$postId/unlike/'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      // 200/204 = success, 404 = already unliked (treat as success)
      if (response.statusCode == 200 || 
          response.statusCode == 204 || 
          response.statusCode == 404) {
        return true;
      } else {
        throw Exception('Failed to unlike post: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on http.ClientException {
      throw Exception('Connection error');
    } on TimeoutException {
      throw Exception('Request timeout');
    } catch (e) {
      rethrow;
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

  static Future<List<BusinessNetworkComment>> getPostComments({
    required int postId,
  }) async {
    try {
      final headers = await ApiService.getHeaders();

      final url = '$_baseUrl/posts/$postId/comments/';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode != 200) {
        return <BusinessNetworkComment>[];
      }

      final data = json.decode(response.body);
      final List<dynamic> rawList;
      if (data is List) {
        rawList = data;
      } else if (data is Map<String, dynamic>) {
        final results = data['results'];
        if (results is List) {
          rawList = results;
        } else {
          final comments = data['comments'];
          rawList = comments is List ? comments : <dynamic>[];
        }
      } else {
        rawList = <dynamic>[];
      }

      return rawList
          .whereType<Map>()
          .map((e) => BusinessNetworkComment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Error fetching comments: $e');
      return <BusinessNetworkComment>[];
    }
  }

  /// Add a comment to a post
  static Future<BusinessNetworkComment?> addComment({
    required int postId,
    required String content,
    int? parentCommentId,
    bool isGiftComment = false,
    int? diamondAmount,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final body = {
        'content': content,
        if (parentCommentId != null) 'parent_comment': parentCommentId,
        if (isGiftComment) 'is_gift_comment': true,
        if (diamondAmount != null && diamondAmount > 0) 'diamond_amount': diamondAmount,
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

  /// Update a comment
  static Future<BusinessNetworkComment?> updateComment({
    required int commentId,
    required String content,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final body = {
        'content': content,
      };
      
      print('=== Update Comment Debug ===');
      print('URL: $_baseUrl/comments/$commentId/');
      print('Content: $content');
      
      // Use PATCH for partial update instead of PUT
      final response = await http.patch(
        Uri.parse('$_baseUrl/comments/$commentId/'),
        headers: headers,
        body: json.encode(body),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BusinessNetworkComment.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error updating comment: $e');
      return null;
    }
  }

  /// Delete a comment
  static Future<bool> deleteComment(int commentId) async {
    try {
      final headers = await ApiService.getHeaders();
      
      print('=== Delete Comment Debug ===');
      print('URL: $_baseUrl/comments/$commentId/');
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/comments/$commentId/'),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
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

  /// Get user followers list
  static Future<Map<String, dynamic>> getUserFollowers(String userId, {int page = 1}) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/followers/?page=$page'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'results': [], 'count': 0};
    } catch (e) {
      print('Error fetching followers: $e');
      return {'results': [], 'count': 0};
    }
  }

  /// Get user following list
  static Future<Map<String, dynamic>> getUserFollowing(String userId, {int page = 1}) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/following/?page=$page'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'results': [], 'count': 0};
    } catch (e) {
      print('Error fetching following: $e');
      return {'results': [], 'count': 0};
    }
  }

  /// Get user profile data
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final headers = await ApiService.getHeaders();
      
      print('=== Get User Profile Debug ===');
      print('User ID: $userId');
      print('URL: ${ApiService.baseUrl}/user/$userId/');
      
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/user/$userId/'),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('ERROR: Failed to load user profile - ${response.statusCode}');
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      rethrow;
    }
  }

  /// Get user posts
  static Future<Map<String, dynamic>> getUserPosts(String userId, {int page = 1, int pageSize = 10}) async {
    try {
      final headers = await ApiService.getHeaders();
      
      print('=== Get User Posts Debug ===');
      print('User ID: $userId');
      print('URL: $_baseUrl/user/$userId/posts/?page=$page&page_size=$pageSize');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/user/$userId/posts/?page=$page&page_size=$pageSize'),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Posts data received: ${data['count']} posts');
        
        final posts = (data['results'] as List)
            .map((json) => BusinessNetworkPost.fromJson(json))
            .toList();
        
        return {
          'posts': posts,
          'hasMore': data['next'] != null,
          'count': data['count'] ?? 0,
        };
      } else {
        print('ERROR: Failed to load user posts - ${response.statusCode}');
        return {'posts': <BusinessNetworkPost>[], 'hasMore': false, 'count': 0};
      }
    } catch (e) {
      print('Error fetching user posts: $e');
      return {'posts': <BusinessNetworkPost>[], 'hasMore': false, 'count': 0};
    }
  }

  /// Upload profile picture
  static Future<bool> uploadProfilePicture(dynamic imageFile) async {
    try {
      final headers = await ApiService.getHeaders();
      
      print('=== Upload Profile Picture Debug ===');
      print('Image file type: ${imageFile.runtimeType}');
      
      final dio = Dio();
      
      // Prepare form data
      FormData formData;
      
      if (imageFile is File) {
        // For mobile (Android/iOS)
        print('Using File path: ${imageFile.path}');
        formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: 'profile.jpg',
          ),
        });
      } else {
        // For web (XFile)
        print('Using XFile/bytes');
        final bytes = await imageFile.readAsBytes();
        formData = FormData.fromMap({
          'image': MultipartFile.fromBytes(
            bytes,
            filename: 'profile.jpg',
          ),
        });
      }
      
      print('Sending request to: ${ApiService.baseUrl}/user/profile/update/');
      
      final response = await dio.patch(
        '${ApiService.baseUrl}/user/profile/update/',
        data: formData,
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      
      if (response.statusCode == 200) {
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return false;
    }
  }

  /// Get saved posts
  static Future<List<BusinessNetworkPost>> getSavedPosts() async {
    try {
      final headers = await ApiService.getHeaders();
      
      print('=== Get Saved Posts Debug ===');
      print('URL: $_baseUrl/posts/save/');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/posts/save/'),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data is List ? data : (data['results'] ?? []);

        return results
            .whereType<Map>()
            .map((e) {
              final item = Map<String, dynamic>.from(e);
              final postDetails = item['post_details'];
              if (postDetails is Map) {
                return BusinessNetworkPost.fromJson(Map<String, dynamic>.from(postDetails));
              }
              return BusinessNetworkPost.fromJson(item);
            })
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching saved posts: $e');
      return [];
    }
  }

  /// Get user by contact (email or phone)
  static Future<BusinessNetworkUser?> getUserByContact(String contact) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/users/search/?q=$contact&page_size=1'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        if (results.isNotEmpty) {
          return BusinessNetworkUser.fromJson(results.first);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user by contact: $e');
      return null;
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

  /// Get trending hashtags
  static Future<List<Map<String, dynamic>>> getTrendingTags({int limit = 7}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trending-tags/?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      
      return [];
    } catch (e) {
      print('Error fetching trending tags: $e');
      return [];
    }
  }

  /// Get top 100 hashtags
  static Future<List<Map<String, dynamic>>> getTopTags() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/top-tags/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      
      return [];
    } catch (e) {
      print('Error fetching top tags: $e');
      return [];
    }
  }

  static Future<int?> incrementMediaViews(String mediaId) async {
    try {
      final headers = await ApiService.getHeaders();

      final response = await http
          .post(
            Uri.parse('$_baseUrl/media/$mediaId/increment-views/'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) return null;
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          final raw = data['views'] ?? data['views_count'] ?? data['count'];
          if (raw is int) return raw;
          if (raw is String) return int.tryParse(raw);
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
