import 'package:flutter/foundation.dart';

import '../models/business_network_models.dart';
import '../utils/video_upload_helper.dart';
import 'business_network_service.dart';

/// What the composer is doing right now.
enum PostUploadStage { preparing, uploading, success, failed }

@immutable
class PostUploadState {
  final PostUploadStage stage;

  /// 0..1 while [stage] is uploading; null when indeterminate (preparing).
  final double? progress;
  final String message;
  final BusinessNetworkPost? post;
  final String? error;

  const PostUploadState({
    required this.stage,
    required this.message,
    this.progress,
    this.post,
    this.error,
  });

  bool get isBusy =>
      stage == PostUploadStage.preparing || stage == PostUploadStage.uploading;
}

/// Uploads a Business Network post in the BACKGROUND.
///
/// The composer hands the job here and pops immediately, so posting feels
/// instant (Facebook-style) and heavy work no longer blocks the UI:
///
///  * video compression runs HERE, not when the video is picked — picking a
///    clip used to trigger a full 720p re-encode that looked like a stalled
///    upload and could abort;
///  * the job outlives the composer screen, so leaving the page (or scrolling
///    the feed) can't cancel it;
///  * [state] drives a progress strip on the feed.
///
/// Only one post uploads at a time — [isBusy] guards a second submit.
class PostUploadService {
  PostUploadService._();
  static final PostUploadService instance = PostUploadService._();

  /// Null when idle. Listened to by the feed to show progress.
  final ValueNotifier<PostUploadState?> state =
      ValueNotifier<PostUploadState?>(null);

  bool get isBusy => state.value?.isBusy ?? false;

  /// Clears a finished (success/failed) state — e.g. when the feed dismisses
  /// its banner. No-op while a job is still running.
  void clear() {
    if (!isBusy) state.value = null;
  }

  /// Starts a post upload. Returns immediately; watch [state] for progress.
  Future<BusinessNetworkPost?> start({
    String? content,
    List<String>? images,
    List<String>? videoPaths,
    /// Clips whose file is still being copied off the photo library when Post
    /// is pressed. The composer shows the poster frame the instant a clip is
    /// picked and hands the copy over here, so the only place anyone waits for
    /// it is behind the progress strip.
    List<Future<String?>>? pendingVideos,
    List<String>? tags,
    String visibility = 'public',
  }) async {
    if (isBusy) return null;

    final hasPending = pendingVideos != null && pendingVideos.isNotEmpty;
    if (hasPending) {
      state.value = const PostUploadState(
        stage: PostUploadStage.preparing,
        message: 'ভিডিও প্রস্তুত হচ্ছে…',
      );
      final resolved = await Future.wait(pendingVideos);
      videoPaths = [
        ...?videoPaths,
        ...resolved.whereType<String>(),
      ];
    }

    final hasVideos = videoPaths != null && videoPaths.isNotEmpty;
    state.value = PostUploadState(
      stage: PostUploadStage.preparing,
      message: hasVideos ? 'ভিডিও প্রস্তুত হচ্ছে…' : 'পোস্ট প্রস্তুত হচ্ছে…',
    );

    try {
      // 1) Compress videos here so picking stays instant.
      List<String>? prepared;
      if (hasVideos) {
        prepared = <String>[];
        for (var i = 0; i < videoPaths.length; i++) {
          state.value = PostUploadState(
            stage: PostUploadStage.preparing,
            message: videoPaths.length > 1
                ? 'ভিডিও প্রস্তুত হচ্ছে… (${i + 1}/${videoPaths.length})'
                : 'ভিডিও প্রস্তুত হচ্ছে…',
          );
          prepared.add(await VideoUploadHelper.compressOnly(videoPaths[i]));
        }
      }

      // 2) Upload with real byte progress.
      state.value = const PostUploadState(
        stage: PostUploadStage.uploading,
        message: 'পোস্ট আপলোড হচ্ছে…',
        progress: 0,
      );

      final post = await BusinessNetworkService.createPost(
        title: null,
        content: content,
        images: images,
        videoPaths: prepared,
        tags: tags,
        visibility: visibility,
        onProgress: (p) {
          // Keep the last known message; only the bar moves.
          state.value = PostUploadState(
            stage: PostUploadStage.uploading,
            message: 'পোস্ট আপলোড হচ্ছে…',
            progress: p.clamp(0.0, 1.0),
          );
        },
      );

      if (post != null) {
        state.value = PostUploadState(
          stage: PostUploadStage.success,
          message: 'পোস্ট প্রকাশিত হয়েছে',
          progress: 1,
          post: post,
        );
      } else {
        state.value = const PostUploadState(
          stage: PostUploadStage.failed,
          message: 'পোস্ট করা যায়নি',
          error: 'unknown',
        );
      }
      return post;
    } catch (e) {
      state.value = PostUploadState(
        stage: PostUploadStage.failed,
        message: 'পোস্ট করা যায়নি — আবার চেষ্টা করুন',
        error: e.toString(),
      );
      return null;
    }
  }
}
