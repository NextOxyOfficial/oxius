// Temporary probe: parse a REAL /api/bn/posts/<id>/ response through
// BusinessNetworkPost.fromJson to see whether any null->bool cast throws.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oxius_native/models/business_network_models.dart';

void main() {
  test('parse real single-post JSON', () {
    final raw = File('test_parse_input.json').readAsStringSync();
    final data = json.decode(raw);
    final post = BusinessNetworkPost.fromJson(data);
    // Touch every bool the shorts page reads.
    // ignore: unused_local_variable
    final touched = [
      post.isLiked,
      post.isSaved,
      post.user.isVerified,
      post.user.isPro,
      post.user.isFollowing,
      for (final m in post.media) m.isVideo,
      for (final c in post.comments) c.isGiftComment,
      for (final c in post.comments) c.user.isVerified,
      for (final c in post.comments) c.user.isFollowing,
      for (final l in post.postLikes) l.isVerified,
      for (final l in post.postLikes) l.isFollowing,
      for (final f in post.likedByPreview) f.isFollowing,
    ];
    expect(post.id, isNonZero);
  });
}
