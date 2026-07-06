import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/elearning/batch_selector.dart';
import '../widgets/elearning/division_selector.dart';
import '../widgets/elearning/subject_selector.dart';
import '../widgets/elearning/video_lessons.dart';
import '../widgets/elearning/elearning_banner_slider.dart';
import '../services/translation_service.dart';

class ElearningScreen extends StatefulWidget {
  const ElearningScreen({super.key});

  @override
  State<ElearningScreen> createState() => _ElearningScreenState();
}

class _ElearningScreenState extends State<ElearningScreen> {
  static const _slate50 = Color(0xFFF8FAFC);
  static const _slate100 = Color(0xFFF1F5F9);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate500 = Color(0xFF64748B);
  static const _slate800 = Color(0xFF1E293B);
  static const _indigo = Color(0xFF6366F1);
  static const _violet = Color(0xFF8B5CF6);

  final TranslationService _i18n = TranslationService();

  String? _selectedBatch;
  String? _selectedDivision;
  String? _selectedSubject;
  String _expandedStep = 'batch';

  @override
  void initState() {
    super.initState();
    // Rebuild (and cascade to all step widgets) when the language changes.
    _i18n.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _i18n.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  void _handleBatchSelection(String batchCode) {
    setState(() {
      _selectedBatch = batchCode;
      // Reset subsequent selections
      _selectedDivision = null;
      _selectedSubject = null;
      _expandedStep = 'division';
    });
  }

  void _handleDivisionSelection(String divisionCode) {
    setState(() {
      _selectedDivision = divisionCode;
      // Reset subject selection
      _selectedSubject = null;
      _expandedStep = 'subject';
    });
  }

  void _handleSubjectSelection(String subjectCode) {
    setState(() {
      _selectedSubject = subjectCode;
      _expandedStep = 'videos';
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final horizontalPadding = isMobile ? 4.0 : 12.0;

    return Scaffold(
      backgroundColor: _slate50,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ElearningBannerSlider(),
                  _buildStepsCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepsCard() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      alignment: Alignment.topCenter,
      curve: Curves.easeOut,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _slate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BatchSelector(
              selectedBatch: _selectedBatch,
              isExpanded: _expandedStep == 'batch',
              onTapExpand: () => setState(() => _expandedStep = 'batch'),
              onSelectBatch: _handleBatchSelection,
            ),
            if (_selectedBatch != null) ...[
              _divider(),
              _RevealStep(
                // Re-key per batch so the reveal replays when batch changes.
                key: ValueKey('division_$_selectedBatch'),
                child: DivisionSelector(
                  batch: _selectedBatch,
                  selectedDivision: _selectedDivision,
                  isExpanded: _expandedStep == 'division',
                  onTapExpand: () => setState(() => _expandedStep = 'division'),
                  onSelectDivision: _handleDivisionSelection,
                ),
              ),
            ],
            if (_selectedDivision != null) ...[
              _divider(),
              _RevealStep(
                key: ValueKey('subject_$_selectedDivision'),
                child: SubjectSelector(
                  batch: _selectedBatch,
                  division: _selectedDivision,
                  selectedSubject: _selectedSubject,
                  isExpanded: _expandedStep == 'subject',
                  onTapExpand: () => setState(() => _expandedStep = 'subject'),
                  onSelectSubject: _handleSubjectSelection,
                ),
              ),
            ],
            if (_selectedSubject != null) ...[
              _divider(),
              _RevealStep(
                key: ValueKey('videos_$_selectedSubject'),
                child: VideoLessons(subject: _selectedSubject),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: _slate100,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _slate100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: _slate800,
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_indigo, _violet],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _i18n.t('el_title', fallback: 'eLearning'),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _slate800,
                ),
              ),
              Text(
                _i18n.t('el_subtitle', fallback: 'Structured study path'),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _slate500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: _i18n.t('el_how_it_works', fallback: 'How it works'),
          onPressed: _showLearningInfo,
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _slate100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: _slate500,
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _slate200),
      ),
    );
  }

  void _showLearningInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          _i18n.t('el_how_title', fallback: 'How eLearning works'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          _i18n.t('el_how_body',
              fallback:
                  'Start with your batch, narrow it down by division and subject, then continue directly into the lesson videos.'),
          style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: _slate500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              _i18n.t('el_close', fallback: 'Close'),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reveals its child with a gentle fade + upward slide the moment it is
/// inserted into the tree — used to animate each subsequent study step in.
class _RevealStep extends StatefulWidget {
  final Widget child;

  const _RevealStep({super.key, required this.child});

  @override
  State<_RevealStep> createState() => _RevealStepState();
}

class _RevealStepState extends State<_RevealStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _fade = curve;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
