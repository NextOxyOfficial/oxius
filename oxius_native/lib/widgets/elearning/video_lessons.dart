import 'package:flutter/material.dart';
import '../../models/elearning_models.dart';
import '../../services/elearning_service.dart';
import '../../services/user_state_service.dart';
import '../../services/translation_service.dart';
import '../ios_web_redirect_screen.dart';
import '../../screens/elearning/video_player_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'elearning_step_header.dart';

class VideoLessons extends StatefulWidget {
  final String? subject;

  const VideoLessons({
    super.key,
    this.subject,
  });

  @override
  State<VideoLessons> createState() => _VideoLessonsState();
}

class _VideoLessonsState extends State<VideoLessons> {
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate800 = Color(0xFF1E293B);
  static const _indigo = Color(0xFF6366F1);
  static const _violet = Color(0xFF8B5CF6);

  final TranslationService _i18n = TranslationService();

  List<VideoLesson> _videos = [];
  List<VideoLesson> _filteredVideos = [];
  bool _loading = false;
  String? _error;
  String _selectedLesson = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  bool get _isPro => UserStateService().isPro;

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      _loadVideos();
    }
  }

  @override
  void didUpdateWidget(VideoLessons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.subject != oldWidget.subject) {
      if (widget.subject != null) {
        _loadVideos();
      } else {
        setState(() {
          _videos = [];
          _filteredVideos = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    if (widget.subject == null) return;
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final videos =
          await ElearningService.fetchVideoLessonsForSubject(widget.subject!);
      setState(() {
        _videos = videos;
        _filteredVideos = videos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = _i18n.t('el_error_videos',
            fallback: 'Failed to load videos. Please try again.');
        _loading = false;
      });
    }
  }

  List<String> get _lessons {
    final lessons = _videos.map((v) => v.lessonName).toSet().toList();
    lessons.sort();
    return lessons;
  }

  int _durationToSeconds(String d) {
    final parts = d.split(':');
    try {
      if (parts.length == 3) {
        return int.parse(parts[0]) * 3600 +
            int.parse(parts[1]) * 60 +
            int.parse(parts[2]);
      } else if (parts.length == 2) {
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
      return int.parse(parts[0]);
    } catch (_) {
      return 0;
    }
  }

  String get _totalDuration {
    final total =
        _videos.fold<int>(0, (sum, v) => sum + _durationToSeconds(v.duration));
    if (total == 0) return '--';
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '<1m';
  }

  void _filterVideos() {
    setState(() {
      _filteredVideos = _videos.where((video) {
        final matchesLesson =
            _selectedLesson == 'all' || video.lessonName == _selectedLesson;
        final matchesSearch = _searchQuery.isEmpty ||
            video.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            video.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
        return matchesLesson && matchesSearch;
      }).toList();
    });
  }

  void _playVideo(VideoLesson video) {
    // Video playback is a Pro-only feature.
    if (!_isPro) {
      _showProGate();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(video: video),
      ),
    );
  }

  void _showProGate() {
    if (isIOSPlatform) {
      _showIOSDialog();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ProGateSheet(
        onUpgrade: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, '/upgrade-to-pro');
        },
      ),
    );
  }

  void _showIOSDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFED7AA), width: 2),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Color(0xFFEA580C), size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                _i18n.t('el_pro_feature', fallback: 'Pro Feature'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _i18n.t('el_ios_pro_body',
                    fallback:
                        'Video lessons are available to Pro members. Pro upgrades cannot be purchased inside the iOS app due to App Store guidelines — please upgrade from our website.'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(_i18n.t('el_got_it', fallback: 'Got it'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subject == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElearningStepHeader(
            number: 4,
            title: _i18n.t('el_video_lessons', fallback: 'Video Lessons'),
            subtitle: _i18n.t('el_video_sub',
                fallback: 'Watch and learn at your own pace'),
            icon: Icons.play_circle_fill_rounded,
            isActive: true,
            isDone: false,
            onTapExpand: () {},
          ),

          // Pro-only notice for non-members.
          if (!_isPro && !_loading && _error == null && _videos.isNotEmpty)
            _buildProNotice(),

          // Stats strip
          if (!_loading && _error == null && _videos.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _statPill(
                    Icons.play_circle_fill_rounded,
                    '${_videos.length}',
                    _i18n.t('el_videos', fallback: 'Videos'),
                    Colors.red.shade500),
                const SizedBox(width: 8),
                _statPill(
                    Icons.playlist_play_rounded,
                    '${_lessons.length}',
                    _i18n.t('el_lessons', fallback: 'Lessons'),
                    _indigo),
                const SizedBox(width: 8),
                _statPill(Icons.schedule_rounded, _totalDuration,
                    _i18n.t('el_total', fallback: 'Total'),
                    Colors.teal.shade600),
              ],
            ),
          ],

          // Filter + search
          if (!_loading && _error == null && _videos.isNotEmpty)
            _buildFilterBar(),

          // Loading
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28.0),
                child: AdsyLoadingIndicator(),
              ),
            ),

          // Error
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      style:
                          TextStyle(fontSize: 14, color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadVideos,
                      child:
                          Text(_i18n.t('el_try_again', fallback: 'Try Again')),
                    ),
                  ],
                ),
              ),
            ),

          // Video list
          if (!_loading && _error == null && _filteredVideos.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 12),
              itemCount: _filteredVideos.length,
              itemBuilder: (context, index) =>
                  _buildVideoCard(_filteredVideos[index]),
            ),

          // Empty (no videos at all)
          if (!_loading && _error == null && _videos.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  children: [
                    Icon(Icons.video_library_outlined,
                        size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                        _i18n.t('el_no_videos',
                            fallback: 'No videos available yet'),
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),

          // Empty (filtered)
          if (!_loading &&
              _error == null &&
              _filteredVideos.isEmpty &&
              _videos.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  children: [
                    Icon(Icons.search_off,
                        size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                        _i18n.t('el_no_videos_filter',
                            fallback: 'No videos match your filters'),
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProNotice() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_indigo.withValues(alpha: 0.08), _violet.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _indigo.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, size: 18, color: _indigo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _i18n.t('el_pro_notice',
                  fallback:
                      'Playback is a Pro feature. Upgrade to watch every lesson.'),
              style: const TextStyle(
                  fontSize: 12, height: 1.35, color: _slate800),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showProGate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_indigo, _violet]),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _i18n.t('el_upgrade', fallback: 'Upgrade'),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _slate800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: _slate200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list_rounded, size: 18, color: _indigo),
              const SizedBox(width: 8),
              Text(
                _i18n.t('el_filter_search', fallback: 'Filter & search'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _slate800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedLesson,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: _i18n.t('el_lesson', fallback: 'Lesson'),
              labelStyle: const TextStyle(fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: Colors.white,
            ),
            items: [
              DropdownMenuItem(
                  value: 'all',
                  child: Text(
                      _i18n.t('el_all_lessons', fallback: 'All lessons'))),
              ..._lessons.map((lesson) => DropdownMenuItem(
                    value: lesson,
                    child: Text(lesson, overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: (value) {
              setState(() => _selectedLesson = value ?? 'all');
              _filterVideos();
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText:
                  _i18n.t('el_search_hint', fallback: 'Search by title or description'),
              hintStyle:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _filterVideos();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _filterVideos();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(VideoLesson video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _slate200),
      ),
      child: InkWell(
        onTap: () => _playVideo(video),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 120,
                  height: 68,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        video.getYoutubeThumbnail(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.play_circle_outline, size: 32),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: (_isPro ? Colors.red : _indigo)
                                .withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPro ? Icons.play_arrow : Icons.lock_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.duration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.displayTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _slate800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              video.displayLessonName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        if (!_isPro) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [_indigo, _violet]),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.visibility,
                            size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${video.viewsCount} ${_i18n.t('el_views', fallback: 'views')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet shown when a non-Pro user tries to play a lesson.
class _ProGateSheet extends StatelessWidget {
  static const _slate500 = Color(0xFF64748B);
  static const _slate800 = Color(0xFF1E293B);
  static const _indigo = Color(0xFF6366F1);
  static const _violet = Color(0xFF8B5CF6);

  final VoidCallback onUpgrade;

  const _ProGateSheet({required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final i18n = TranslationService();
    final perks = <(IconData, String)>[
      (
        Icons.play_circle_fill_rounded,
        i18n.t('el_perk_1',
            fallback: 'Unlimited access to every video lesson')
      ),
      (
        Icons.workspace_premium_rounded,
        i18n.t('el_perk_2',
            fallback: 'Pro badge and premium features across the app')
      ),
      (
        Icons.all_inclusive_rounded,
        i18n.t('el_perk_3', fallback: 'One membership, all learning content')
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_indigo, _violet]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _indigo.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            i18n.t('el_pro_gate_title', fallback: 'Unlock video lessons'),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _slate800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            i18n.t('el_pro_gate_sub',
                fallback:
                    'Video playback is available for AdsyClub Pro members. Upgrade once to watch every lesson.'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.5, color: _slate500),
          ),
          const SizedBox(height: 18),
          ...perks.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _indigo.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(p.$1, size: 17, color: _indigo),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      p.$2,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: _slate800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: _indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                i18n.t('el_upgrade_pro', fallback: 'Upgrade to Pro'),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              i18n.t('el_maybe_later', fallback: 'Maybe later'),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _slate500),
            ),
          ),
        ],
      ),
    );
  }
}
