import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../models/business_network_models.dart';
import 'api_service.dart';
import 'api_cache.dart';
import '../utils/api_error.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class BusinessNetworkService {
  static String get _baseUrl => '${ApiService.baseUrl}/bn';
  static final Random _shortsRandom = Random();

  static List<BusinessNetworkPost> _mixShortsPosts(
    List<BusinessNetworkPost> posts, {
    Set<int> excludePostIds = const {},
  }) {
    final currentUser = AuthService.currentUser;
    final currentUserId = int.tryParse((currentUser?.id ?? '').toString());
    final uniquePosts = <int, BusinessNetworkPost>{};

    for (final post in posts) {
      if (excludePostIds.contains(post.id)) {
        continue;
      }

      if (!post.media.any((media) => media.isVideo)) {
        continue;
      }

      uniquePosts.putIfAbsent(post.id, () => post);
    }

    final ownPosts = <BusinessNetworkPost>[];
    final followedPosts = <BusinessNetworkPost>[];
    final unfollowedPosts = <BusinessNetworkPost>[];

    for (final post in uniquePosts.values) {
      final isOwnPost = currentUserId != null && post.user.id == currentUserId;

      if (isOwnPost) {
        ownPosts.add(post);
      } else if (post.user.isFollowing) {
        followedPosts.add(post);
      } else {
        unfollowedPosts.add(post);
      }
    }

    ownPosts.shuffle(_shortsRandom);
    followedPosts.shuffle(_shortsRandom);
    unfollowedPosts.shuffle(_shortsRandom);

    final mixedPosts = <BusinessNetworkPost>[];

    while (ownPosts.isNotEmpty ||
        followedPosts.isNotEmpty ||
        unfollowedPosts.isNotEmpty) {
      if (mixedPosts.isEmpty && ownPosts.isNotEmpty) {
        mixedPosts.add(ownPosts.removeLast());
      }

      if (unfollowedPosts.isNotEmpty) {
        mixedPosts.add(unfollowedPosts.removeLast());
      }

      if (followedPosts.isNotEmpty) {
        mixedPosts.add(followedPosts.removeLast());
      }

      if (ownPosts.isNotEmpty) {
        mixedPosts.add(ownPosts.removeLast());
      }
    }

    return mixedPosts;
  }

  /// Get Business Network logo
  /// Reshare (repost) a post to the current user's profile/feed. Returns the
  /// newly created reshare post, or null on failure.
  static Future<BusinessNetworkPost?> resharePost(int postId,
      {String caption = ''}) async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/reshare/'),
        headers: headers,
        body: jsonEncode({'caption': caption}),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return BusinessNetworkPost.fromJson(jsonDecode(res.body));
      }
      debugPrint('reshare -> ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      debugPrint('reshare failed: $e');
      return null;
    }
  }

  /// Attach a NEW video to an existing post (edit flow). Multipart upload;
  /// returns the full updated post, or null on failure.
  static Future<BusinessNetworkPost?> addPostVideo(
      int postId, String filePath) async {
    try {
      final headers = await ApiService.getHeaders();
      headers.remove('Content-Type');
      final req = http.MultipartRequest(
          'POST', Uri.parse('$_baseUrl/posts/$postId/add-video/'));
      req.headers.addAll(headers);
      req.files.add(await http.MultipartFile.fromPath('video', filePath));
      final streamed = await req.send().timeout(const Duration(minutes: 5));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) {
        return BusinessNetworkPost.fromJson(jsonDecode(body));
      }
      debugPrint('addPostVideo -> ${streamed.statusCode} $body');
      return null;
    } catch (e) {
      debugPrint('addPostVideo failed: $e');
      return null;
    }
  }

  /// App-wide share-count updates: (postId, authoritative server count).
  /// Every surface that shows a share badge (feed card, post detail, shorts)
  /// listens here, so a share made anywhere updates everywhere — no reload.
  static final StreamController<MapEntry<int, int>> _shareCountCtrl =
      StreamController<MapEntry<int, int>>.broadcast();
  static Stream<MapEntry<int, int>> get shareCountUpdates =>
      _shareCountCtrl.stream;

  /// Count a non-repost share (send-to-chat, WhatsApp, etc.) on a post.
  /// Returns the new total share count, or null on failure.
  static Future<int?> trackShare(int postId) async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/track-share/'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final count = int.tryParse('${data['share_count']}');
        if (count != null) {
          _shareCountCtrl.add(MapEntry(postId, count));
        }
        return count;
      }
      return null;
    } catch (e) {
      debugPrint('trackShare failed: $e');
      return null;
    }
  }

  /// Reshare an Adsy News story to the user's Business Network feed. News ids
  /// are strings, and the story is always the source, so there is no root to
  /// collapse the way [resharePost] does.
  static Future<BusinessNetworkPost?> reshareNews(String newsId,
      {String caption = ''}) async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.post(
        Uri.parse('$_baseUrl/news/$newsId/reshare/'),
        headers: headers,
        body: jsonEncode({'caption': caption}),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return BusinessNetworkPost.fromJson(jsonDecode(res.body));
      }
      debugPrint('reshareNews -> ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      debugPrint('reshareNews failed: $e');
      return null;
    }
  }

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
      debugPrint('Error fetching business network logo: $e');
      return null;
    }
  }

  /// Get posts feed with pagination.
  ///
  /// [forceRefresh] bypasses the first-page cache so an explicit user refresh
  /// (pull-to-refresh or tapping the active feed tab) always pulls fresh data.
  static Future<Map<String, dynamic>> getPosts({
    int page = 1,
    int pageSize = 5,
    String? olderThan,
    bool forceRefresh = false,
  }) async {
    try {
      String url = '$_baseUrl/posts/?page=$page&page_size=$pageSize';
      if (olderThan != null) {
        url += '&older_than=$olderThan';
      }

      // First try without auth to avoid token issues
      final basicHeaders = {'Content-Type': 'application/json'};
      final headers = await ApiService.getHeaders();
      final hasAuthHeader =
          headers.keys.any((k) => k.toLowerCase() == 'authorization');

      // Single fetch closure — routed through the shared keep-alive client.
      Future<Map<String, dynamic>> fetchData() async {
        var response = await ApiService.client.get(
          Uri.parse(url),
          headers: hasAuthHeader ? headers : basicHeaders,
        );
        if (hasAuthHeader &&
            (response.statusCode == 401 || response.statusCode == 403)) {
          response = await ApiService.client.get(
            Uri.parse(url),
            headers: basicHeaders,
          );
        }
        if (response.statusCode != 200) {
          throw Exception('Feed request failed: ${response.statusCode}');
        }
        return json.decode(response.body) as Map<String, dynamic>;
      }

      // P3: cache the first page per-user so returning to the feed renders
      // instantly from cache, then refreshes in the background (SWR). Any cache
      // failure falls back to a direct fetch, so behaviour never regresses.
      Map<String, dynamic> data;
      if (page == 1 && olderThan == null) {
        final uid = AuthService.currentUser?.id ?? 'anon';
        try {
          data = await ApiCache.getOrFetch<Map<String, dynamic>>(
            'bn:feed:$uid:p1:s$pageSize',
            fetchData,
            freshTtl: const Duration(seconds: 45),
            staleTtl: const Duration(hours: 6),
            forceRefresh: forceRefresh,
          );
        } catch (_) {
          data = await fetchData();
        }
      } else {
        data = await fetchData();
      }

      final results = data['results'] as List;

      final currentUserIdStr = AuthService.currentUser?.id;
      final currentUserId = int.tryParse((currentUserIdStr ?? '').toString());

      final posts = results.map((e) {
        final raw = e is Map<String, dynamic>
            ? e
            : (e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{});

        var post = BusinessNetworkPost.fromJson(raw);

        final hasIsLikedField =
            raw.containsKey('is_liked') || raw.containsKey('isLiked');
        if (!hasIsLikedField && currentUserId != null) {
          final inferredLiked =
              post.postLikes.any((l) => l.user == currentUserId);
          if (inferredLiked != post.isLiked) {
            post = post.copyWith(isLiked: inferredLiked);
          }
        }

        return post;
      }).toList();

      return {
        'posts': posts,
        'hasMore': data['next'] != null,
        'count': data['count'] ?? 0,
      };
    } catch (e, stackTrace) {
      debugPrint('Error fetching posts: $e');
      debugPrint('Stack trace: $stackTrace');
      return {'posts': <BusinessNetworkPost>[], 'hasMore': false, 'count': 0};
    }
  }

  static Future<Map<String, dynamic>> getShortsFeed({
    int startPage = 1,
    int pageSize = 12,
    int pageWindow = 3,
    Set<int> excludePostIds = const {},
  }) async {
    // Fetch the whole page window IN PARALLEL. The old serial loop made
    // opening Shorts wait for up to three back-to-back feed requests —
    // the single biggest reason the screen took so long to appear.
    final results = await Future.wait(
      List.generate(
        pageWindow,
        (index) => getPosts(page: startPage + index, pageSize: pageSize),
      ),
    );

    final collectedPosts = <BusinessNetworkPost>[];
    var hasMore = true;
    var currentPage = startPage;

    for (final result in results) {
      final pagePosts = (result['posts'] as List<BusinessNetworkPost>?) ??
          <BusinessNetworkPost>[];
      collectedPosts.addAll(pagePosts);
      hasMore = result['hasMore'] as bool? ?? false;
      currentPage += 1;
      if (pagePosts.isEmpty) {
        hasMore = false;
        break;
      }
    }

    final shortsPosts = _mixShortsPosts(
      collectedPosts,
      excludePostIds: excludePostIds,
    );

    return {
      'posts': shortsPosts,
      'hasMore': hasMore,
      'nextPage': currentPage,
    };
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
    // 0..1 upload progress; only fires for the multipart (video) path, where
    // uploads are big enough to need feedback.
    void Function(double progress)? onProgress,
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
          final filename =
              p.split('/').isNotEmpty ? p.split('/').last : 'video.mp4';
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
          onSendProgress: (sent, total) {
            if (onProgress != null && total > 0) onProgress(sent / total);
          },
        );

        debugPrint('=== Create Post Debug ===');
        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response body: ${response.data}');

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = response.data is Map
              ? Map<String, dynamic>.from(response.data)
              : json.decode(response.data.toString());
          final post = BusinessNetworkPost.fromJson(data);
          return post;
        }

        throw ApiError.fromResponse(
            response.statusCode ?? 0, response.data?.toString() ?? '');
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

      // Dio so photo posts (base64 payloads are large) can report real upload
      // progress the same way video posts do.
      final dio = Dio(BaseOptions(responseType: ResponseType.json));
      final response = await dio.post(
        '$_baseUrl/posts/',
        data: json.encode(body),
        options: Options(
          headers: headers,
          contentType: 'application/json',
          validateStatus: (status) => true,
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) onProgress(sent / total);
        },
      );

      debugPrint('=== Create Post Debug ===');
      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : json.decode(response.data.toString());
        final post = BusinessNetworkPost.fromJson(data);
        return post;
      }

      throw ApiError.fromResponse(
          response.statusCode ?? 0, response.data?.toString() ?? '');
    } catch (e, stackTrace) {
      debugPrint('Error creating post: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Like a post
  static Future<bool> likePost(int postId) async {
    try {
      final headers = await ApiService.getHeaders();

      final response = await http
          .post(
            Uri.parse('$_baseUrl/posts/$postId/like/'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

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

      final response = await http
          .delete(
            Uri.parse('$_baseUrl/posts/$postId/unlike/'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

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
          .map((e) =>
              BusinessNetworkComment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Error fetching comments: $e');
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
        if (diamondAmount != null && diamondAmount > 0)
          'diamond_amount': diamondAmount,
      };

      debugPrint('=== Add Comment Debug ===');
      debugPrint('URL: $_baseUrl/posts/$postId/comments/');
      debugPrint('Content: $content');
      debugPrint('Parent Comment ID: $parentCommentId');

      final response = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/comments/'),
        headers: headers,
        body: json.encode(body),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return BusinessNetworkComment.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error adding comment: $e');
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

      debugPrint('=== Update Comment Debug ===');
      debugPrint('URL: $_baseUrl/comments/$commentId/');
      debugPrint('Content: $content');

      // Use PATCH for partial update instead of PUT
      final response = await http.patch(
        Uri.parse('$_baseUrl/comments/$commentId/'),
        headers: headers,
        body: json.encode(body),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BusinessNetworkComment.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error updating comment: $e');
      return null;
    }
  }

  /// Delete a comment
  static Future<bool> deleteComment(int commentId) async {
    try {
      final headers = await ApiService.getHeaders();

      debugPrint('=== Delete Comment Debug ===');
      debugPrint('URL: $_baseUrl/comments/$commentId/');

      final response = await http.delete(
        Uri.parse('$_baseUrl/comments/$commentId/'),
        headers: headers,
      );

      debugPrint('Response status: ${response.statusCode}');

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      return false;
    }
  }

  /// Get a single post by ID.
  static Future<BusinessNetworkPost?> getPost(int postId) async {
    return getPostByIdentifier(postId.toString());
  }

  /// Get a single post by ID-like identifier from deep links.
  static Future<BusinessNetworkPost?> getPostByIdentifier(
      String postIdentifier) async {
    try {
      final headers = await ApiService.getHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/posts/$postIdentifier/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BusinessNetworkPost.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching post: $e');
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
      debugPrint('Error deleting post: $e');
      return false;
    }
  }

  /// Update a post
  static Future<BusinessNetworkPost?> updatePost({
    required int postId,
    String? title,
    String? content,
    List<String>? images,
    String? category,
    String? visibility,
    List<String>? tags,
    // Ids of existing media to detach+delete from the post.
    List<int>? removeMediaIds,
  }) async {
    try {
      final headers = await ApiService.getHeaders();

      final body = {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (images != null) 'images': images,
        if (category != null) 'category': category,
        if (visibility != null) 'visibility': visibility,
        // Send even when empty — clearing the last tag is a valid edit.
        if (tags != null) 'tags': tags,
        if (removeMediaIds != null && removeMediaIds.isNotEmpty)
          'remove_media_ids': removeMediaIds,
      };

      // PATCH (partial update) — PUT requires every writable serializer
      // field, so a content-only edit could 400 on required fields the app
      // never sends.
      final response = await http.patch(
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
      debugPrint('Error updating post: $e');
      return null;
    }
  }

  /// Save a post
  static Future<bool> savePost(int postId) async {
    try {
      final headers = await ApiService.getHeaders();

      debugPrint('=== Save Post Debug ===');
      debugPrint('URL: $_baseUrl/posts/save/');
      debugPrint('Post ID: $postId');

      final response = await http.post(
        Uri.parse('$_baseUrl/posts/save/'),
        headers: headers,
        body: json.encode({'post': postId}),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error saving post: $e');
      return false;
    }
  }

  /// Unsave a post
  static Future<bool> unsavePost(int postId) async {
    try {
      final headers = await ApiService.getHeaders();

      debugPrint('=== Unsave Post Debug ===');
      debugPrint('URL: $_baseUrl/saved-posts/delete/$postId/');

      final response = await http.delete(
        Uri.parse('$_baseUrl/saved-posts/delete/$postId/'),
        headers: headers,
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error unsaving post: $e');
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

      debugPrint('=== Follow User Debug ===');
      debugPrint('URL: $_baseUrl/users/$userId/follow/');
      debugPrint('Headers: $headers');

      final response = await http.post(
        Uri.parse('$_baseUrl/users/$userId/follow/'),
        headers: headers,
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      // Handle success (200 = already following, 201 = newly created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
            'Successfully followed user (status: ${response.statusCode})');
        return true;
      }

      // If 400, check if it's a duplicate follow (unique constraint error)
      if (response.statusCode == 400) {
        try {
          final responseBody = response.body;
          if (responseBody.isNotEmpty) {
            final bodyLower = responseBody.toLowerCase();
            // Check for unique constraint error - means already following
            if (bodyLower.contains('unique') ||
                bodyLower.contains('follower')) {
              debugPrint('User already following (unique constraint)');
              // Return false so UI reloads and syncs with backend
              return false;
            }
          }
        } catch (e) {
          debugPrint('Error parsing response body: $e');
        }
        debugPrint('ERROR 400: ${response.body}');
        return false;
      }

      debugPrint('Unexpected status code: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Error following user: $e');
      return false;
    }
  }

  /// Unfollow a user
  static Future<bool> unfollowUser(String userId) async {
    try {
      final headers = await ApiService.getHeaders();

      debugPrint('=== Unfollow User Debug ===');
      debugPrint('URL: $_baseUrl/users/$userId/unfollow/');

      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$userId/unfollow/'),
        headers: headers,
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      return false;
    }
  }

  /// Toggle follow/unfollow a user
  static Future<bool> toggleFollow(
      String userId, bool isCurrentlyFollowing) async {
    debugPrint('=== Toggle Follow Debug ===');
    debugPrint('User ID: $userId');
    debugPrint('Currently Following: $isCurrentlyFollowing');
    debugPrint('Action: ${isCurrentlyFollowing ? "UNFOLLOW" : "FOLLOW"}');

    if (isCurrentlyFollowing) {
      return await unfollowUser(userId);
    } else {
      return await followUser(userId);
    }
  }

  /// Get user followers list
  static Future<Map<String, dynamic>> getUserFollowers(String userId,
      {int page = 1}) async {
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
      debugPrint('Error fetching followers: $e');
      return {'results': [], 'count': 0};
    }
  }

  /// Get user following list
  static Future<Map<String, dynamic>> getUserFollowing(String userId,
      {int page = 1}) async {
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
      debugPrint('Error fetching following: $e');
      return {'results': [], 'count': 0};
    }
  }

  /// Get user profile data
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final headers = await ApiService.getHeaders();

      debugPrint('=== Get User Profile Debug ===');
      debugPrint('User ID: $userId');
      debugPrint('URL: ${ApiService.baseUrl}/user/$userId/');

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/user/$userId/'),
        headers: headers,
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        debugPrint(
            'ERROR: Failed to load user profile - ${response.statusCode}');
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      rethrow;
    }
  }

  /// Get user posts
  static Future<Map<String, dynamic>> getUserPosts(String userId,
      {int page = 1, int pageSize = 10}) async {
    try {
      final headers = await ApiService.getHeaders();

      debugPrint('=== Get User Posts Debug ===');
      debugPrint('User ID: $userId');
      debugPrint(
          'URL: $_baseUrl/user/$userId/posts/?page=$page&page_size=$pageSize');

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/user/$userId/posts/?page=$page&page_size=$pageSize'),
        headers: headers,
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Posts data received: ${data['count']} posts');

        final posts = (data['results'] as List)
            .map((json) => BusinessNetworkPost.fromJson(json))
            .toList();

        return {
          'posts': posts,
          'hasMore': data['next'] != null,
          'count': data['count'] ?? 0,
        };
      } else {
        debugPrint('ERROR: Failed to load user posts - ${response.statusCode}');
        return {'posts': <BusinessNetworkPost>[], 'hasMore': false, 'count': 0};
      }
    } catch (e) {
      debugPrint('Error fetching user posts: $e');
      return {'posts': <BusinessNetworkPost>[], 'hasMore': false, 'count': 0};
    }
  }

  /// Upload profile picture
  /// Upload the profile cover/banner — same endpoint, 'banner_image' field.
  static Future<bool> uploadProfileBanner(
    dynamic imageFile, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final dio = Dio();
      FormData formData;
      if (imageFile is File) {
        formData = FormData.fromMap({
          'banner_image': await MultipartFile.fromFile(
            imageFile.path,
            filename: 'banner.jpg',
          ),
        });
      } else {
        final bytes = await imageFile.readAsBytes();
        formData = FormData.fromMap({
          'banner_image': MultipartFile.fromBytes(
            bytes,
            filename: 'banner.jpg',
          ),
        });
      }
      final response = await dio.patch(
        '${ApiService.baseUrl}/user/profile/update/',
        data: formData,
        options: Options(headers: headers),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) onProgress(sent / total);
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error uploading profile banner: $e');
      return false;
    }
  }

  static Future<bool> uploadProfilePicture(dynamic imageFile) async {
    try {
      final headers = await ApiService.getHeaders();

      debugPrint('=== Upload Profile Picture Debug ===');
      debugPrint('Image file type: ${imageFile.runtimeType}');

      final dio = Dio();

      // Prepare form data
      FormData formData;

      if (imageFile is File) {
        // For mobile (Android/iOS)
        debugPrint('Using File path: ${imageFile.path}');
        formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: 'profile.jpg',
          ),
        });
      } else {
        // For web (XFile)
        debugPrint('Using XFile/bytes');
        final bytes = await imageFile.readAsBytes();
        formData = FormData.fromMap({
          'image': MultipartFile.fromBytes(
            bytes,
            filename: 'profile.jpg',
          ),
        });
      }

      debugPrint(
          'Sending request to: ${ApiService.baseUrl}/user/profile/update/');

      final response = await dio.patch(
        '${ApiService.baseUrl}/user/profile/update/',
        data: formData,
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return false;
    }
  }

  /// Get saved posts
  static Future<List<BusinessNetworkPost>> getSavedPosts() async {
    try {
      final headers = await ApiService.getHeaders();

      debugPrint('=== Get Saved Posts Debug ===');
      debugPrint('URL: $_baseUrl/posts/save/');

      final response = await http.get(
        Uri.parse('$_baseUrl/posts/save/'),
        headers: headers,
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results =
            data is List ? data : (data['results'] ?? []);

        return results.whereType<Map>().map((e) {
          final item = Map<String, dynamic>.from(e);
          final postDetails = item['post_details'];
          if (postDetails is Map) {
            return BusinessNetworkPost.fromJson(
                Map<String, dynamic>.from(postDetails));
          }
          return BusinessNetworkPost.fromJson(item);
        }).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching saved posts: $e');
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
      debugPrint('Error fetching user by contact: $e');
      return null;
    }
  }

  /// Search users for @mentions
  static Future<List<BusinessNetworkUser>> searchUsers(String query) async {
    try {
      final headers = await ApiService.getHeaders();

      debugPrint('=== Search Users Debug ===');
      debugPrint('Query: $query');

      final response = await http.get(
        Uri.parse('$_baseUrl/users/search/?q=$query'),
        headers: headers,
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? data;

        return results
            .map((json) => BusinessNetworkUser.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error searching users: $e');
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
        debugPrint('Post hidden successfully');
        return true;
      }

      debugPrint('Failed to hide post: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Error hiding post: $e');
      return false;
    }
  }

  /// Report a user's profile (fake/impersonating account, spam, etc.).
  static Future<bool> reportProfile(String userId, String reason,
      {String description = ''}) async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.post(
        Uri.parse('$_baseUrl/users/$userId/report/'),
        headers: headers,
        body: json.encode({'reason': reason, 'description': description}),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      debugPrint('reportProfile failed: $e');
      return false;
    }
  }

  /// Undo [hidePost] — the backend unhides on DELETE of the same route.
  static Future<bool> unhidePost(int postId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/posts/$postId/hide/'),
        headers: headers,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error unhiding post: $e');
      return false;
    }
  }

  /// Report a post
  static Future<bool> reportPost(int postId, String reason) async {
    try {
      final headers = await ApiService.getHeaders();

      // Accept the option VALUE directly (spam/harassment/...). The label map
      // remains as a fallback for old call sites — 'Fraudulent or scam' used
      // to fall through this map and silently became 'other'.
      const validReasons = {
        'spam', 'harassment', 'violence', 'inappropriate', 'other'
      };
      const reasonMap = {
        'Spam or misleading': 'spam',
        'Harassment or hate speech': 'harassment',
        'Violence or dangerous content': 'violence',
        'Inappropriate content': 'inappropriate',
        'Fraudulent or scam': 'spam',
        'Other': 'other',
      };

      final backendReason = validReasons.contains(reason)
          ? reason
          : (reasonMap[reason] ?? 'other');

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
        debugPrint('Post reported successfully');
        return true;
      }

      debugPrint('Failed to report post: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Error reporting post: $e');
      return false;
    }
  }

  /// Block a user by their user ID (UUID primary key)
  static Future<bool> blockUser(String userId, {String reason = ''}) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/adsyconnect/blocked-users/'),
        headers: headers,
        body: json.encode({
          'blocked': userId,
          if (reason.isNotEmpty) 'reason': reason,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
      if (response.statusCode == 400 &&
          response.body.toLowerCase().contains('unique')) {
        return true;
      }
      debugPrint(
          'Failed to block user: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error blocking user: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/adsyconnect/blocked-users/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data is List ? data : (data['results'] ?? []);
        return List<Map<String, dynamic>>.from(
          results.map((item) => Map<String, dynamic>.from(item as Map)),
        );
      }

      debugPrint('Failed to load blocked users: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error loading blocked users: $e');
      return [];
    }
  }

  static Future<bool> unblockUser(String userId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/adsyconnect/blocked-users/unblock/'),
        headers: headers,
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      debugPrint(
          'Failed to unblock user: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      return false;
    }
  }

  /// Get trending hashtags
  static Future<List<Map<String, dynamic>>> getTrendingTags(
      {int limit = 7}) async {
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
      debugPrint('Error fetching trending tags: $e');
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
      debugPrint('Error fetching top tags: $e');
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

  /// Content monetization: progress + application state for the current user.
  static Future<Map<String, dynamic>?> getMonetizationStatus() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/monetization/status/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching monetization status: $e');
      return null;
    }
  }

  /// Approved creator's earnings: live points, pool share, history.
  /// Null when not approved or on error.
  static Future<Map<String, dynamic>?> getMonetizationEarnings() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/monetization/earnings/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching monetization earnings: $e');
      return null;
    }
  }

  /// Submit a content monetization application (terms must be accepted).
  /// Returns null on success, or an error message.
  static Future<String?> applyForMonetization() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/monetization/apply/'),
        headers: headers,
        body: json.encode({'terms_accepted': true}),
      );
      if (response.statusCode == 201) return null;
      try {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return (data['error'] ?? 'Failed to submit application').toString();
      } catch (_) {
        return 'Failed to submit application';
      }
    } catch (e) {
      debugPrint('Error applying for monetization: $e');
      return 'Network error — please try again';
    }
  }

  /// Likers of a post, from the post detail endpoint. Used by the likers
  /// sheet when the feed item doesn't carry the embedded list (e.g. right
  /// after an optimistic like).
  static Future<List<PostLike>> fetchPostLikes(dynamic postId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/posts/$postId/'),
        headers: headers,
      );
      if (response.statusCode != 200) return [];
      final data = json.decode(response.body);
      final raw = (data is Map ? data['post_likes'] : null) ?? [];
      return (raw is List ? raw : [])
          .map((e) {
            try {
              return PostLike.fromJson(Map<String, dynamic>.from(e as Map));
            } catch (_) {
              return null;
            }
          })
          .whereType<PostLike>()
          .toList();
    } catch (e) {
      debugPrint('Error fetching post likes: $e');
      return [];
    }
  }
}
